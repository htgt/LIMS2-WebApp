package LIMS2::Model::Plugin::Plate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use LIMS2::Model::Util qw( sanitize_like_expr );
use LIMS2::Model::Util::CreateProcess qw( process_aux_data_field_list );
use LIMS2::Model::Util::DataUpload qw( upload_plate_dna_status parse_csv_file );
use LIMS2::Model::Util::CreatePlate qw( create_plate_well merge_plate_process_data );
use LIMS2::Model::Util::QCTemplates qw( create_qc_template_from_wells );
use LIMS2::Model::Constants
    qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS %PROCESS_TEMPLATE );
use Const::Fast;
use Try::Tiny;
use Log::Log4perl qw( :easy );
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub list_plate_types {
    my $self = shift;

    return [
        $self->schema->resultset('PlateType')->search( {}, { order_by => { -asc => 'id' } } ) ];
}

sub pspec_list_plates {
    return {
        species    => { validate => 'existing_species' },
        plate_name => { validate => 'non_empty_string', optional => 1 },
        plate_type => { validate => 'existing_plate_type', optional => 1 },
        page       => { validate => 'integer', optional => 1, default => 1 },
        pagesize   => { validate => 'integer', optional => 1, default => 15 }
    };
}

sub list_plates {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_list_plates );

    my %search = ( 'me.species_id' => $validated_params->{species} );

    if ( $validated_params->{plate_name} ) {
        $search{'me.name'}
            = { -like => '%' . sanitize_like_expr( $validated_params->{plate_name} ) . '%' };
    }

    if ( $validated_params->{plate_type} ) {
        $search{'me.type_id'} = $validated_params->{plate_type};
    }

    my $resultset = $self->schema->resultset('Plate')->search(
        \%search,
        {   prefetch => ['created_by'],
            order_by => { -desc => 'created_at' },
            page     => $validated_params->{page},
            rows     => $validated_params->{pagesize}
        }
    );

    return ( [ $resultset->all ], $resultset->pager );
}

sub pspec_create_plate {
    return {
        name        => { validate => 'plate_name' },
        species     => { validate => 'existing_species', rename => 'species_id' },
        type        => { validate => 'existing_plate_type', rename => 'type_id' },
        description => { validate => 'non_empty_string', optional => 1 },
        created_by => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        comments   => { optional => 1 },
        wells      => { optional => 1 },
        is_virtual => { validate => 'boolean', optional => 1 },
    };
}

sub pspec_create_plate_comment {
    return {
        comment_text => { validate => 'non_empty_string' },
        created_by   => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    };
}

=item create_plate

The optional wells parameter takes an ArrayRef of hashes which contain the following params:

well_name
parent_plate (name)
parent_well (name)
accepted (boolean - optional)
process_type
...any additional process data which is required for the specific process type, e.g. cassette

See module LIMS2::Model::Util::CreateProcess to find out what process data is required
for each process type

=cut

sub create_plate {
    my ( $self, $params ) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_create_plate );
    $self->log->info( 'Creating plate: ' . $validated_params->{name} );

    my $current_plate
        = $self->schema->resultset('Plate')->find( { name => $validated_params->{name} } );
    if ($current_plate) {
        $self->throw( Validation => 'Plate ' . $validated_params->{name} . ' already exists' );
    }

    my $plate = $self->schema->resultset('Plate')->create(
        {   slice_def(
                $validated_params,
                qw( name species_id type_id description created_by_id created_at is_virtual )
            )
        }
    );

    # refresh object data from database, sets created_by value if it was set by database
    $plate->discard_changes;

    for my $c ( @{ $validated_params->{comments} || [] } ) {
        my $validated_c = $self->check_params( $c, $self->pspec_create_plate_comment );
        $plate->create_related( plate_comments =>
                { slice_def( $validated_c, qw( comment_text created_by_id created_at ) ) } );
    }
    if ( exists $validated_params->{wells} ) {
        # check for xep_pool process on the wells and rewrite the wells hash if necessary
        my $revised_wells = check_xep_pool_wells($self, $validated_params->{wells});
        #create_plate_well( $self, $_, $plate ) for @{ $validated_params->{wells} };
        create_plate_well( $self, $_, $plate ) for @{ $revised_wells };
    }

    return $plate;
}

=head
check_xep_pool_wells takes a well hash and generates a new hash with a list of parent wells
to be pooled into each unique output well.

If the input hash has no xep_pool processes, the hash will remain unchanged.

Any wells without xep_pool processes will be passed through unchanged.
=cut
sub check_xep_pool_wells {
    my $self = shift;
    my $original_wells = shift;

    my @revised_wells;

    WELL_HASH: foreach my $well_hash ( @$original_wells ) {
        if ( $well_hash->{'process_type'} ne 'xep_pool' ) {
            push @revised_wells, $well_hash;
            next WELL_HASH;
        }
        my $target_well = $well_hash->{'well_name'};
        my $parent_well = $well_hash->{'parent_well'};
        my $parent_plate = $well_hash->{'parent_plate'};
        # search the revised hash for an entry with the same target well
        # create a new well hash entry if it doesn't exist
        # and add the current parent well to the parent_well_list
        # note that parent wells are expected to be from the same plate.

        my $found_revised_well = 0;
        REVISED_SEARCH: foreach my $revised_well ( @revised_wells ) {
            $self->throw( Validation => 'Wells from different plates cannot be pooled to the same output well: '
                . 'Already seen: '
                . $revised_well->{'parent_plate'}
                . ' and was not expecting: '
                . $parent_plate
            ) if  $parent_plate ne $revised_well->{'parent_plate'};

            if ($revised_well->{'well_name'} eq $target_well ){
                push @{$revised_well->{'parent_well_list'}}, $parent_well;
                $found_revised_well = 1;
                last REVISED_SEARCH;
            }
        }
        if ( !$found_revised_well ) {
            # transfer well to revised wells and update the parent_well_list
            #
            push @{$well_hash->{'parent_well_list'}}, $parent_well;
            delete $well_hash->{'parent_well'};
            push @revised_wells, $well_hash;
        }
    }

    return \@revised_wells;
}

sub pspec_retrieve_plate {
    return {
        name => { validate => 'plate_name',          optional => 1, rename => 'me.name' },
        id   => { validate => 'integer',             optional => 1, rename => 'me.id' },
        type => { validate => 'existing_plate_type', optional => 1, rename => 'me.type_id' },
        species => { validate => 'existing_species', rename => 'me.species_id', optional => 1 },
        REQUIRE_SOME => { name_or_id => [ 1, qw( name id ) ] }
    };
}

sub retrieve_plate {
    my ( $self, $params, $search_opts ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec_retrieve_plate, ignore_unknown => 1 );

    return $self->retrieve(
        Plate => { slice_def $validated_params, qw( me.name me.id me.type_id me.species_id ) },
        $search_opts
    );
}

sub delete_plate {
    my ( $self, $params ) = @_;

    # retrieve_plate() will validate the parameters
    my $plate = $self->retrieve_plate($params);
    $self->log->info( "Deleting plate: $plate" );

    $self->throw( Validation => "Plate $plate can not be deleted, has child plates" )
        if $plate->has_child_wells;

    for my $well ( $plate->wells ) {
        $self->delete_well( { id => $well->id } );
    }

    $plate->search_related_rs('plate_comments')->delete;
    $plate->delete;
    return;
}

sub pspec_set_plate_assay_complete {
    return {
        completed_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    };
}

sub set_plate_assay_complete {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_set_plate_assay_complete,
        ignore_unknown => 1 );

    my $plate = $self->retrieve_plate($params);
    $self->log->info( "Set assay complete on plate $plate" );

    for my $well ( $plate->wells ) {
        $self->set_well_assay_complete(
            {   id           => $well->id,
                completed_at => $validated_params->{completed_at}
            }
        );
    }

    return $plate;
}

=head
Method: create_plate_by_copy

Takes an input plate (that must exist), and creates a copy of the plate ready for well
data to be imported by csv upload.
=cut

sub pspec_create_plate_by_copy {
    return {
        from_plate_name  =>  { validate => 'plate_name' },
        to_plate_name    =>  { validate => 'plate_name' },
        created_by       =>  { validate => 'existing_user' },
        created_at       =>  { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    };
}

sub create_plate_by_copy {
    my ( $self, $params ) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_create_plate_by_copy );

    my $from_plate_name = $validated_params->{'from_plate_name'};
    my $to_plate_name = $validated_params->{'to_plate_name'};
    my $this_user = $validated_params->{'created_by'};
    $self->log->info( "Creating plate: $to_plate_name, as copy of $from_plate_name" );

    my $from_plate
        = $self->schema->resultset('Plate')->find( { name => $from_plate_name } );
    if (! $from_plate) {
        $self->throw( Validation => 'Plate ' . $from_plate_name . ' does not exist' );
    }

    my $to_plate
        = $self->schema->resultset('Plate')->find( { name => $to_plate_name } );
    if ( $to_plate ) {
        $self->throw( Validation => 'Plate ' . $to_plate_name . ' already exists' );
    }
#
# Get the wells from the plate we need to copy
#
#
    my $well_rs = $self->schema->resultset( 'Well' );

    my @wells_on_plate = $well_rs->search( { 'plate.name' => $from_plate_name },
        {
            join => [ 'plate' ],
        }
    );

# process the well data into @well_data
    my $process_type = 'dna_prep';
    my @well_data = ();

    foreach my $well ( @wells_on_plate ) {
        my %well_hash;
        $well_hash{'well_name'} = $well->name;
        $well_hash{'parent_plate'} = $from_plate->name;
        $well_hash{'parent_well'} = $well->name;
        $well_hash{'process_type'} = $process_type;
        push @well_data, \%well_hash;
    }


    my $plate = $self->create_plate(
        {
            name =>  $to_plate_name ,
            description => $from_plate->description,
            type => 'DNA',
            created_by => $this_user,
            species => $from_plate->species->id,
            wells => \@well_data,
        }
    );
    $plate->discard_changes;

    return $plate;
}

sub create_plate_csv_upload {
    my ( $self, $params, $well_data_fh ) = @_;
    #validation done of create_plate, not needed here
    my %plate_data = map { $_ => $params->{$_} }
        qw( plate_name species plate_type description created_by is_virtual process_type);
    $plate_data{name} = delete $plate_data{plate_name};
    $plate_data{type} = delete $plate_data{plate_type};

    # validate the is_virtual flag (can only be true for process:rearray and plate:INT)

    if ( $plate_data{is_virtual} ) {
        if ( ($plate_data{type} ne 'INT') or ($plate_data{process_type} ne 'rearray') ) {
            $self->throw(
                Validation => 'Plate type (' . $plate_data{type} . ') and process (' . $plate_data{process_type}
                . ') combination invalid for virtual plate');
        }
    }
    delete $plate_data{process_type};

    my %plate_process_data = map { $_ => $params->{$_} }
        grep { exists $params->{$_} } @{ process_aux_data_field_list() };
    $plate_process_data{process_type} = $params->{process_type};

    my $expected_csv_headers;
    if ($params->{process_type} eq 'second_electroporation') {
        $expected_csv_headers = [ 'well_name', 'xep_plate', 'xep_well', 'dna_plate', 'dna_well' ];
    } elsif ($params->{process_type} eq 'assembly_single') {
        $expected_csv_headers = [ 'well_name', 'final_pick_plate', 'final_pick_well', 'crispr_vector_plate', 'crispr_vector_well' ];
    } elsif ($params->{process_type} eq 'assembly_paired') {
        $expected_csv_headers = [ 'well_name', 'final_pick_plate', 'final_pick_well', 'crispr_vector1_plate', 'crispr_vector1_well',
                                'crispr_vector2_plate', 'crispr_vector2_well' ];
    } else {
        $expected_csv_headers = [ 'well_name', 'parent_plate', 'parent_well' ];
    }

    my $well_data = parse_csv_file( $well_data_fh, $expected_csv_headers );

    for my $datum ( @{$well_data} ) {
        merge_plate_process_data( $datum, \%plate_process_data );
    }
    $plate_data{wells} = $well_data;
    return $self->create_plate( \%plate_data );
}

sub plate_help_info {
    my ($self) = @_;
    my %plate_info;

    for my $process ( keys %PROCESS_PLATE_TYPES ) {
        next unless exists $PROCESS_TEMPLATE{$process};

        $plate_info{$process}{plate_types} = $PROCESS_PLATE_TYPES{$process};
        $plate_info{$process}{data}
            = exists $PROCESS_SPECIFIC_FIELDS{$process} ? $PROCESS_SPECIFIC_FIELDS{$process} : [];
        $plate_info{$process}{template} = $PROCESS_TEMPLATE{$process};

    }

    return \%plate_info;
}

sub pspec_update_plate_dna_status {
    return {
        plate_name => { validate => 'existing_plate_name' },
        species    => { validate => 'existing_species' },
        user_name  => { validate => 'existing_user' },
        csv_fh     => { validate => 'file_handle' },
    };
}

sub update_plate_dna_status {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_plate_dna_status );

    return upload_plate_dna_status( $self, $validated_params );
}

sub pspec_rename_plate {
    return {
        name         => { validate => 'plate_name', optional => 1  },
        id           => { validate => 'integer',  optional => 1 },
        species      => { validate => 'existing_species', optional => 1 },
        new_name     => { validate => 'plate_name' },
        REQUIRE_SOME => { name_or_id => [ 1, qw( name id ) ] },
    };
}

sub rename_plate {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_rename_plate );

    my $plate = $self->retrieve_plate( { slice_def( $validated_params, qw( name id species ) ) } );
    $self->log->info( "Renaming plate: $plate to" . $validated_params->{new_name} );

    $self->throw( Validation => 'Plate '
            . $validated_params->{new_name}
            . ' already exists, can not use this new plate name' )
        if try { $self->retrieve_plate( { name => $validated_params->{new_name} } ) };

    return $plate->update( { name => $validated_params->{new_name} } );
}

1;

__END__
