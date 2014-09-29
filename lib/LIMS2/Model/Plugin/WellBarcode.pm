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
        barcode           => { validate => 'alphanumeric_string', optional => 1 },
        REQUIRE_SOME      => { id_or_barcode => [ 1, qw( well_id barcode ) ] }
    };
}

sub retrieve_well_barcode {
    my ( $self, $params, $search_opts ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_well_barcode, ignore_unknown => 1 );

    return $self->retrieve(
    	Well => { slice_def $validated_params, qw( well_id barcode ) },
    	$search_opts,
    );
}

sub delete_well_barcode {
# only allowed if barcode has no events
}

sub create_well_barcode {
# input: well, well_barcode, state(optional), event details(optional)
}

sub update_well_barcode {
# input: well_barcode, well_id and/or barcode_state, comment(optional)
# performs update and creates well barcode event showing change in well and/or state
# plus comment, user and date info
}

sub create_well_barcode_event {
# input: well_barcode, old_state, new_state, old_well, new_well, user, comment
}

1;
