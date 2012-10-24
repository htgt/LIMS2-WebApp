package LIMS2::Model::Plugin::Plate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Plate::VERSION = '0.024';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use LIMS2::Model::Util qw( sanitize_like_expr );
use LIMS2::Model::Util::CreateProcess qw( process_aux_data_field_list );
use LIMS2::Model::Util::DataUpload qw( upload_plate_dna_status parse_csv_file );
use LIMS2::Model::Util::CreatePlate qw( create_plate_well merge_plate_process_data );
use LIMS2::Model::Constants
    qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS %PROCESS_TEMPLATE );
use Const::Fast;
use Try::Tiny;
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

    my $current_plate
        = $self->schema->resultset('Plate')->find( { name => $validated_params->{name} } );
    if ($current_plate) {
        $self->throw( Validation => 'Plate ' . $validated_params->{name} . ' already exists' );
    }

    my $plate = $self->schema->resultset('Plate')->create(
        {   slice_def(
                $validated_params,
                qw( name species_id type_id description created_by_id created_at )
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
        create_plate_well( $self, $_, $plate ) for @{ $validated_params->{wells} };
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

    for my $well ( $plate->wells ) {
        $self->set_well_assay_complete(
            {   id           => $well->id,
                completed_at => $validated_params->{completed_at}
            }
        );
    }

    return $plate;
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

    my $well_data = parse_csv_file( $well_data_fh );

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

    $self->throw( Validation => 'Plate '
            . $validated_params->{new_name}
            . ' already exists, can not use this new plate name' )
        if try { $self->retrieve_plate( { name => $validated_params->{new_name} } ) };

    return $plate->update( { name => $validated_params->{new_name} } );
}

sub pspec_qc_template_from_plate{
	return{
		name          => { validate => 'existing_plate_name', optional => '1'},
		id            => { validate => 'integer',             optional => '1'},
		species       => { validate => 'existing_species',    optional => '1'},
		template_name => { validate => 'plate_name'},
	};
}

sub create_qc_template_from_plate {
	my ( $self, $params ) = @_;

    # FIXME: include optional cassette, backbone, recombinase?

    my $validated_params = $self->check_params( $params, $self->pspec_qc_template_from_plate );

	my $plate = $self->retrieve_plate( { slice_def( $params, qw( name id species ) ) } );

	my $well_hash;

	foreach my $well ($plate->wells->all){
		my $name = $well->name;
        $well_hash->{$name}->{well_id} = $well->id;
	}

    my $template = $self->create_qc_template_from_wells({
		template_name => $params->{template_name},
		species       => $plate->species_id,
		wells         => $well_hash,
	});

	return $template;
}

1;

__END__
