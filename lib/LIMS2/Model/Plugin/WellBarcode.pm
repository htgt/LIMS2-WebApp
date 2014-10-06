package LIMS2::Model::Plugin::WellBarcode;

use strict;
use warnings FATAL => 'all';
use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use Hash::Merge qw( merge );
use List::MoreUtils qw (any uniq);
use namespace::autoclean;
use Try::Tiny;

requires qw( schema check_params throw retrieve log trace );

sub pspec_retrieve_well_barcode {
    return {
        well_id           => { validate => 'integer', optional => 1 },
        barcode           => { validate => 'well_barcode', optional => 1 },
        REQUIRE_SOME      => { id_or_barcode => [ 1, qw( well_id barcode ) ] }
    };
}

sub retrieve_well_barcode {
    my ( $self, $params, $search_opts ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_well_barcode, ignore_unknown => 1 );

    return $self->retrieve(
    	WellBarcode => { slice_def $validated_params, qw( well_id barcode ) },
    	$search_opts,
    );
}

sub delete_well_barcode {
# only allowed if barcode has no events
}

sub create_well_barcode {
# input: well, well_barcode, state(optional), event details(optional)
}

sub pspec_update_well_barcode {
    return {
        barcode      => { validate => 'well_barcode'},
        new_well_id  => { validate => 'integer', optional => 1 },
        new_state    => { validate => 'alphanumeric_string', optional => 1 },
        comment      => { validate => 'non_empty_string', optional => 1 },
        user         => { validate => 'existing_user' },
        REQUIRE_SOME => { new_well_id_or_state => [1, qw(new_well_id new_state)]},
    };
}

sub update_well_barcode {

    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_well_barcode );

    my $barcode = $self->retrieve_well_barcode({ barcode => $validated_params->{barcode}})
        or $self->throw( NotFound => { entity_class => 'WellBarcode', search_params => $params } );

    my $old_state = $barcode->barcode_state->id;
    my $old_well_id = $barcode->well_id;

    if(defined $validated_params->{new_well_id}){
        $barcode->update({ well_id => $validated_params->{new_well_id} });
    }

    if(defined $validated_params->{new_state}){
        $barcode->update({ barcode_state => $validated_params->{new_state} });
    }

    $self->create_well_barcode_event({
        barcode     => $validated_params->{barcode},
        old_state   => $old_state,
        new_state   => $barcode->barcode_state->id,
        old_well_id => $old_well_id,
        new_well_id => $barcode->well_id,
        user        => $validated_params->{user},
        comment     => $validated_params->{comment},
    });

    return $barcode;
}

sub pspec_create_well_barcode_event {
    return {
        barcode      => { validate => 'well_barcode'},
        old_state    => { validate => 'alphanumeric_string', optional => 1 },
        new_state    => { validate => 'alphanumeric_string', optional => 1 },
        old_well_id  => { validate => 'integer', optional => 1 },
        new_well_id  => { validate => 'integer', optional => 1 },
        comment      => { validate => 'non_empty_string', optional => 1 },
        user         => { validate => 'existing_user', rename => 'created_by', post_filter => 'user_id_for' },
    };
}

sub create_well_barcode_event {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_barcode_event );

    my $event = $self->schema->resultset('BarcodeEvent')->create({
        slice_def(
            $validated_params,
            qw( barcode old_state new_state old_well_id new_well_id comment created_by )
        )
    });

    return $event;
}


1;
