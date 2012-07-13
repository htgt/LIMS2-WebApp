package LIMS2::Model::Plugin::Plate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Plate::VERSION = '0.006';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_plate {
    return {
        name        => { validate => 'plate_name' },
        type        => { validate => 'existing_plate_type', rename => 'type_id' },
        description => { validate => 'non_empty_string', optional => 1 },
        created_by => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        comments   => { optional => 1 },
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
        { slice_def( $validated_params, qw( name type_id description created_by_id created_at ) ) }
    );

    for my $c ( @{ $validated_params->{comments} || [] } ) {
        my $validated_c = $self->check_params( $c, $self->pspec_create_plate_comment );
        $plate->create_related( plate_comments =>
                { slice_def( $validated_c, qw( comment_text created_by_id created_at ) ) } );
    }

    # XXX Should this return profile-specific data?
    return $plate;
}

sub pspec_retrieve_plate {
    return {
        name         => { validate   => 'plate_name', optional => 1 },
        id           => { validate   => 'integer',    optional => 1 },
        REQUIRE_SOME => { name_or_id => [ 1,          qw( name id ) ] }
    };
}

sub retrieve_plate {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_plate, ignore_unknown => 1 );

    my $plate = $self->retrieve( Plate => $validated_params );

    return $plate;
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

1;

__END__
