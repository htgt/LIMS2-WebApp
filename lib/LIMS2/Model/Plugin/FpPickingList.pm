package LIMS2::Model::Plugin::FpPickingList;

use strict;
use warnings FATAL => 'all';
use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use Hash::Merge qw( merge );
use List::MoreUtils qw (any uniq);
use namespace::autoclean;
use Try::Tiny;

requires qw( schema check_params throw retrieve log trace );

sub pspec_retrieve_fp_picking_list {
    return {
        id           => { validate => 'integer' },
    };
}

sub retrieve_fp_picking_list {
	my ($self, $params) = @_;

	my $validated_params = $self->check_params($params, $self->pspec_retrieve_fp_picking_list);

	return $self->retrieve(
		'FpPickingList' => $validated_params,

	);
}

sub pspec_generate_fp_picking_list {
    return {
        symbols      => { validate => 'non_empty_string' },
        species      => { validate => 'existing_species' },
        user         => { validate => 'existing_user' },
    };
}

sub generate_fp_picking_list{
    my ($self, $params) = @_;

    ref $params->{symbols} eq ref []
        or die "symbols must be an arrayref";
    my $symbol_string = join ", ", @{ $params->{symbols} };

    my $validated_params = $self->check_params($params, $self->pspec_generate_fp_picking_list);

	my $summary_rs = $self->schema->resultset("Summary")->search({
		design_gene_symbol => { -in => $validated_params->{symbols} },
		fp_well_id         => {'!=', undef },
		design_species_id  => $validated_params->{species},
	});

    my @well_ids = map { $_->fp_well_id } $summary_rs->all;

    my $barcode_rs = $self->schema->resultset("WellBarcode")->search(
        {
    	    well_id       => { -in => \@well_ids },
    	    barcode_state => 'in_freezer',
        }
    );

    my $barcode_count = $barcode_rs->count;
    $self->log->debug("$barcode_count barcodes found for symbols $symbol_string");

    die "No barcodes found for symbols $symbol_string" unless $barcode_count;

    my $pick_list = $self->create_fp_picking_list({
        barcodes => [ map { $_->barcode } $barcode_rs->all ],
        user     => $validated_params->{user},
    });

    return $pick_list;
}

sub pspec_create_fp_picking_list {
    return {
    	barcodes     => { validate => 'existing_well_barcode' },
    	user         => { validate => 'existing_user', rename => 'created_by', post_filter => 'user_id_for' },
    };
}

sub create_fp_picking_list {
	my ($self, $params) = @_;

    ref $params->{barcodes} eq ref []
        or die "barcodes must be an arrayref";

	my $validated_params = $self->check_params($params, $self->pspec_create_fp_picking_list);

    my $pick_list = $self->schema->resultset('FpPickingList')->create({
        created_by => $validated_params->{created_by},
    });

    $self->log->debug('Created FpPickingList '.$pick_list->id);

    foreach my $barcode (@{ $validated_params->{barcodes} }){
        $pick_list->create_related('fp_picking_list_well_barcodes',
        {
            well_barcode => $barcode,
        });
    }

    return $pick_list;
}

sub pspec_pick_barcode_from_list{
    return {
        fp_picking_list_id => { validate => 'integer' },
        well_barcode       => { validate => 'existing_well_barcode' },
    }
}

sub pick_barcode_from_list{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, $self->pspec_pick_barcode_from_list);

    my $list_barcode = $self->schema->resultset('FpPickingListWellBarcode')->search(
        {
            'me.fp_picking_list_id' => $validated_params->{fp_picking_list_id},
            'well_barcode.barcode' => $validated_params->{well_barcode},
        },
        {
            join => 'well_barcode',
        }
    )->first();

    die "Could not find barcode in list" unless $list_barcode;

    $list_barcode->update({ picked => 1 });

    return $list_barcode;
}

1;

