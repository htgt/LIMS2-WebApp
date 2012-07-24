package LIMS2::Model::Plugin::Plate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use LIMS2::Model::Util qw( sanitize_like_expr );
use Const::Fast;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub list_plate_types {
    my $self = shift;

    return [ $self->schema->resultset('PlateType')->search( {}, { order_by => { -asc => 'id' } } ) ];
}

sub pspec_list_plates {
    return {
        species    => { validate => 'existing_species' },
        plate_name => { validate => 'non_empty_string',    optional => 1 },
        plate_type => { validate => 'existing_plate_type', optional => 1 },
        page       => { validate => 'integer',             optional => 1, default => 1 },
        pagesize   => { validate => 'integer',             optional => 1, default => 15 }
    }
}

sub list_plates {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_list_plates );

    my %search = ( 'me.species_id' => $validated_params->{species} );

    if ( $validated_params->{plate_name} ) {
        $search{'me.name'} = { -like => '%' . sanitize_like_expr( $validated_params->{plate_name} ) . '%' };
    }

    if ( $validated_params->{plate_type} ) {
        $search{'me.type_id'} = $validated_params->{plate_type};
    }

    my $resultset = $self->schema->resultset('Plate')->search(
        \%search,
        {
            prefetch => [ 'created_by' ],
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

    my $plate = $self->schema->resultset('Plate')->create(
        { slice_def( $validated_params, qw( name species_id type_id description created_by_id created_at ) ) }
    );

    for my $c ( @{ $validated_params->{comments} || [] } ) {
        my $validated_c = $self->check_params( $c, $self->pspec_create_plate_comment );
        $plate->create_related( plate_comments =>
                { slice_def( $validated_c, qw( comment_text created_by_id created_at ) ) } );
    }

    $self->create_plate_wells( $validated_params->{wells}, $plate )
        if exists $validated_params->{wells} and @{ $validated_params->{wells} };

    return $plate;
}

sub pspec_retrieve_plate {
    return {
        name         => { validate => 'plate_name', optional => 1, rename => 'me.name' },
        id           => { validate => 'integer', optional => 1, rename => 'me.id' },
        type         => { validate => 'existing_plate_type', optional => 1, rename => 'me.type_id' },
        species      => { validate => 'existing_species', rename => 'me.species_id', optional => 1 },
        REQUIRE_SOME => { name_or_id => [ 1, qw( name id ) ] }
    };
}

sub retrieve_plate {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_plate, ignore_unknown => 1 );

    return $self->retrieve( Plate => { slice_def $validated_params, qw( me.name me.id me.type_id me.species_id ) } );
}

sub delete_plate {
    my ( $self, $params ) = @_;

    # retrieve_plate() will validate the parameters
    my $plate = $self->retrieve_plate($params);

    for my $well ( $plate->wells ) {
        $self->delete_well( { id => $well->id } );
    }

    $plate->search_related_rs( 'plate_comments' )->delete;
    $plate->delete;
    return;
}

sub pspec_set_plate_assay_complete {
    my $self = shift;
    return +{
        %{ $self->pspec_retrieve_plate },
        completed_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    };
}

sub set_plate_assay_complete {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_set_plate_assay_complete );

    my $plate = $self->retrieve_plate( $validated_params );

    for my $well ( $plate->wells ) {
        $self->set_well_assay_complete(
            {
                id           => $well->id,
                completed_at => $validated_params->{completed_at}
            }
        );
    }

    return $plate;
}

sub create_plate_wells {
    my ( $self, $wells, $plate ) = @_;

    for my $well_data ( @{ $wells } ) {
        my $parent_well_ids = $self->find_parent_well_ids( $well_data );

        my %well_params = (
            plate_name => $plate->name,
            well_name  => delete $well_data->{well_name},
            created_by => $plate->created_by->name,
            created_at => $plate->created_at->iso8601,
        );
        my $process_type = delete $well_data->{process_type};

        $well_params{process_data}              = $well_data;
        $well_params{process_data}{type}        = $process_type;
        $well_params{process_data}{input_wells} = [ map{ { id => $_ } } @{ $parent_well_ids } ];

        $self->create_well( \%well_params, $plate );
    }
}

sub find_parent_well_ids {
    my ( $self, $well_data, $plate_type ) = @_;
    my @parent_well_ids;

    if ( $well_data->{process_type} eq 'second_electroporation' ) {
        push @parent_well_ids,
            $self->get_well_id( $well_data->{allele_plate}, $well_data->{allele_well} );

        push @parent_well_ids,
            $self->get_well_id( $well_data->{vector_plate}, $well_data->{vector_well} );

        delete @{$well_data}
            {qw( allele_plate vector_plate allele_well vector_well )};
    }
    else {
        push @parent_well_ids,
            $self->get_well_id( $well_data->{parent_plate}, $well_data->{parent_well} );

        delete @{$well_data}{qw( parent_plate parent_well )};
    }

    return \@parent_well_ids;
}

sub get_well_id {
    my ( $self, $plate_name, $well_name ) = @_;

    my $well = $self->retrieve_well(
        {
            plate_name => $plate_name,
            well_name  => substr( $well_name, -3),
        }
    );

    return $well->id;
}

1;

__END__
