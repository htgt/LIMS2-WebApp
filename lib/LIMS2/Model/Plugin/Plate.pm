package LIMS2::Model::Plugin::Plate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use List::MoreUtils qw( none );
use LIMS2::Model::Util qw( sanitize_like_expr );
use LIMS2::Model::Util::CreateProcess qw( process_aux_data_field_list );
use LIMS2::Model::Constants
    qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS %PROCESS_TEMPLATE );
use Const::Fast;
use Try::Tiny;
use Text::CSV_XS;
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
        wells      => { optional => 1 }
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

sub create_plate {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_plate );

    my $current_plate = $self->schema->resultset('Plate')->find( { name => $validated_params->{name} } );
    if ( $current_plate ) {
        $self->throw( Validation => 'Plate ' . $validated_params->{name} . ' already exists' );
    }

    my $plate = $self->schema->resultset('Plate')->create(
        {   slice_def(
                $validated_params,
                qw( name species_id type_id description created_by_id created_at )
            )
        }
    );

    # refresh object data from database, sets created_by value
    # if it was set by database
    $plate->discard_changes;

    for my $c ( @{ $validated_params->{comments} || [] } ) {
        my $validated_c = $self->check_params( $c, $self->pspec_create_plate_comment );
        $plate->create_related( plate_comments =>
                { slice_def( $validated_c, qw( comment_text created_by_id created_at ) ) } );
    }

    if ( exists $validated_params->{wells} ) {
        $self->create_plate_well( $_, $plate ) for @{ $validated_params->{wells} };
    }

    return $plate;
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
    my ( $self, $params ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec_retrieve_plate, ignore_unknown => 1 );

    return $self->retrieve(
        Plate => { slice_def $validated_params, qw( me.name me.id me.type_id me.species_id ) } );
}

sub delete_plate {
    my ( $self, $params ) = @_;

    # retrieve_plate() will validate the parameters
    my $plate = $self->retrieve_plate($params);

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

    for my $well ( $plate->wells ) {
        $self->set_well_assay_complete(
            {   id           => $well->id,
                completed_at => $validated_params->{completed_at}
            }
        );
    }

    return $plate;
}

sub pspec_create_plate_well {
    return {
        well_name    => { validate => 'well_name' },
        process_type => { validate => 'existing_process_type' },
    };
}

# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub create_plate_well {
    my ( $self, $params, $plate ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec_create_plate_well, ignore_unknown => 1 );

    my $parent_well_ids = $self->find_parent_well_ids($params);

    my %well_params = (
        plate_name => $plate->name,
        well_name  => $validated_params->{well_name},
        created_by => $plate->created_by->name,
        created_at => $plate->created_at->iso8601,
    );

    # the remaining params are specific to the process
    delete @{$params}{qw( well_name process_type )};

    $well_params{process_data} = $params;
    $well_params{process_data}{type} = $validated_params->{process_type};
    $well_params{process_data}{input_wells} = [ map { { id => $_ } } @{$parent_well_ids} ];

    $self->create_well( \%well_params, $plate );

    return;
}

sub pspec_find_parent_well_ids {
    return {
        parent_plate      => { validate => 'plate_name', optional => 1 },
        parent_well       => { validate => 'well_name',  optional => 1 },
        allele_plate      => { validate => 'plate_name', optional => 1 },
        allele_well       => { validate => 'well_name',  optional => 1 },
        vector_plate      => { validate => 'plate_name', optional => 1 },
        vector_well       => { validate => 'well_name',  optional => 1 },
        DEPENDENCY_GROUPS => { parent   => [qw( parent_plate parent_well )] },
        DEPENDENCY_GROUPS => { vector   => [qw( vector_plate vector_well )] },
        DEPENDENCY_GROUPS => { allele   => [qw( allele_plate allele_well )] },
    };
}

sub find_parent_well_ids {
    my ( $self, $params ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec_find_parent_well_ids, ignore_unknown => 1 );

    my @parent_well_ids;

    if ( $params->{process_type} eq 'second_electroporation' ) {
        push @parent_well_ids,
            $self->get_well_id( $validated_params->{allele_plate},
            $validated_params->{allele_well} );

        push @parent_well_ids,
            $self->get_well_id( $validated_params->{vector_plate},
            $validated_params->{vector_well} );

        delete @{$params}{qw( allele_plate vector_plate allele_well vector_well )};
    }
    else {
        push @parent_well_ids,
            $self->get_well_id( $validated_params->{parent_plate},
            $validated_params->{parent_well} );

        delete @{$params}{qw( parent_plate parent_well )};
    }

    return \@parent_well_ids;
}

sub get_well_id {
    my ( $self, $plate_name, $well_name ) = @_;

    my $well = $self->retrieve_well(
        {   plate_name => $plate_name,
            well_name  => substr( $well_name, -3 ),
        }
    );

    return $well->id;
}

sub create_plate_csv_upload {
    my ( $self, $params, $well_data_fh ) = @_;

    #validation done of create_plate, not needed here
    my %plate_data = map { $_ => $params->{$_} } qw( plate_name species plate_type description created_by );
    $plate_data{name} = delete $plate_data{plate_name};
    $plate_data{type} = delete $plate_data{plate_type};

    my %plate_process_data = map { $_ => $params->{$_} }
        grep { exists $params->{$_} } @{ process_aux_data_field_list() };
    $plate_process_data{process_type} = $params->{process_type};

    my $well_data = $self->_parse_csv( $well_data_fh );

    for my $datum ( @{$well_data} ) {
        $self->_merge_plate_process_data( $datum, \%plate_process_data );
    }
    $plate_data{wells} = $well_data;

    return $self->create_plate( \%plate_data );
}

## no critic(RequireFinalReturn)
sub _merge_plate_process_data {
    my ( $self, $well_data, $plate_data ) = @_;

    for my $process_field ( keys %{ $plate_data } ) {
        # insert plate process data only if it is not present in well data
        $well_data->{$process_field} = $plate_data->{$process_field}
            if !exists $well_data->{$process_field}
                || !$well_data->{$process_field};
    }

    #recombinse data needs to be array ref
    $well_data->{recombinase} = [ delete $well_data->{recombinase} ]
        if exists $well_data->{recombinase};
}
## use critic


sub plate_help_info {
    my ($self) = @_;
    my %plate_info;

    for my $process ( keys %PROCESS_PLATE_TYPES ) {
        next if $process eq 'create_di';
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

use Smart::Comments;
#TODO move this to a better plugin, or create new one
sub update_plate_dna_status {
    my ( $self, $params, $dna_status_fh ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_plate_dna_status );

    my $data = $self->_parse_csv( $validated_params->{csv_fh} );

    my $plate = $self->retrieve_plate( { name => $validated_params->{plate_name} } );
    $self->_check_plate_type( $plate, [ qw(DNA) ]  );

    for my $datum ( @{$data} ) {
        my $dna_status_params = $self->_check_dna_status( $datum, $plate );
        $self->create_well_dna_status(
            +{
                %{ $dna_status_params },
                plate_name => $validated_params->{plate_name},
                created_by => $validated_params->{user_name},
            }
        );
    }

    return;
}

sub _check_plate_type {
    my ( $self, $plate, $types ) = @_;

    ### $types
    ### name : $plate->name

    if ( none{ $plate->type_id eq $_ } @{ $types } ) {
        $self->throw( Validation => 'Invalid plate type '
                . $plate->type_id . ' for plate '
                . $plate->name
                . ',expected plates of of type(s) ' . join( ',', @{$types} ) );
    }
}

sub pspec__check_dna_status {
    return {
        well_name => { validate  => 'well_name' },
        pass      => { validate  => 'pass_or_fail', post_filter => 'pass_to_boolean' },
        comments  => { validated => 'non_empty_string', optional => 1, rename => 'comment_text' },
    };
}

#TODO test csv file with empty lines
sub _check_dna_status {
    my ( $self, $params, $plate ) = @_;
    ### $params

    my $validated_params = $self->check_params( $params, $self->pspec__check_dna_status );
    ### $validated_params

    my $dna_status;
    try {
        $dna_status = $self->retrieve_well_dna_status(
            { plate_name => $plate->name, well_name => $validated_params->{well_name} } );
    };

    $self->throw( Validation => 'Well ' . $plate->name . '['
            . $validated_params->{well_name} . '] already has a dna status' )
        if $dna_status;

    return $validated_params;
}

sub _parse_csv {
    my ( $self, $fh ) = @_;
    my $data;

    my $csv = Text::CSV_XS->new();
    try {
        $csv->column_names( $csv->getline($fh) );
        $data = $csv->getline_hr_all($fh);
    }
    catch {
        $self->log->debug( sprintf( "Error parsing csv file '%s': %s", $csv->error_input || '', '' . $csv->error_diag) );
        $self->throw( Validation => "Invalid csv file" );
    };

    $self->throw( Validation => 'No data in file')
        unless @{$data};

    #delete keys from each hash where we have no value
    for my $datum ( @{ $data } ) {
        my @empty_keys = grep{ !$datum->{$_} } keys %{ $datum };
        delete @{ $datum }{ @empty_keys };
    }

    return $data;
}

1;

__END__
