package LIMS2::Model::Plugin::Well;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub pspec_retrieve_well {
    return {
        id                => { validate => 'integer',    optional => 1 },
        plate_name        => { validate => 'plate_name', optional => 1 },
        well_name         => { validate => 'well_name',  optional => 1 },
        DEPENDENCY_GROUPS => { name_group => [ qw( plate_name well_name ) ] },
        REQUIRE_SOME      => { id_or_name => [ 1, qw( id plate_name well_name ) ] }
    }
}

sub retrieve_well {
    my ( $self, $params ) = @_;

    my $data = $self->check_params( $params, $self->pspec_retrieve_well, ignore_unknown => 1 );

    my %search;
    if ( $data->{id} ) {
        $search{ 'me.id' } = $data->{id};
    }
    if ( $data->{well_name} ) {
        $search{ 'me.name' } = $data->{well_name};
    }
    if ( $data->{plate_name} ) {
        $search{ 'plate.name' } = $data->{plate_name};
    }

    return $self->retrieve( Well => \%search, { join => 'plate', prefetch => 'plate' } );
}

sub pspec_create_well {
    return {
        plate_name   => { validate => 'existing_plate_name' },
        well_name    => { validate => 'well_name' },
        process_data => { validate => 'hashref', optional => 1, default => {} },
        created_by   => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at   => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    }
}

sub create_well {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well );

    my $plate = $self->retrieve_plate( { name => $validated_params->{plate_name} } );

    my $validated_well_params
        = { slice_def $validated_params, qw( well_name created_at created_by_id ) };

    my $well = $plate->create_related( wells => \$validated_well_params );

    $self->create_process( slice_def $validated_params, qw( process_data ), output_wells => [ { id => $well->id  } ]);
}

sub pspec_create_well_accepted_override {
    return {
        plate_name => { validate => 'existing_plate_name', optional => 1 },
        well_name  => { validate => 'well_name', optional => 1 },
        well_id    => { validate => 'integer', optional => 1 },
        created_by => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        accepted   => { validate => 'boolean' }
    }
}

sub create_well_accepted_override {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_accepted_override );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( plate_name well_name well_id ) } );

    my $override = $well->create_related(
        well_accepted_override => { slice_def $validated_params, qw( created_by_id created_at accepted ) }
    );

    return $override;
}

sub pspec_update_well_accepted_override {
    return shift->pspec_create_well_accepted_override;
}

sub update_well_accepted_override {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_well_accepted_override );

    my $override = $self->retrieve(
        WellAcceptedOverride => { 'plate.name' => $validated_params->{plate_name},
                                  'well.name'  => $validated_params->{well_name}
                              },
        { join => { well => 'plate' } }
    );

    $self->throw( InvalidState => "Well already has accepted override with value "
                      . ( $validated_params->{accepted} ? 'TRUE' : 'FALSE' ) )
        unless $override->accepted xor $validated_params->{accepted};

    $override->update( { slice_def $validated_params, qw( created_by_id created_at accepted ) } );
}

1;

__END__
