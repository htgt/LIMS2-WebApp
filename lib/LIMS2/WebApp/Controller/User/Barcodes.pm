package LIMS2::WebApp::Controller::User::Barcodes;
use Moose;
use TryCatch;
use Data::Dump 'pp';
use List::MoreUtils qw (uniq);
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub generate_picklist : Path( '/user/generate_picklist' ) : Args(0){
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $generate = $c->request->param('generate');
    my $genes  = $c->request->param('genes');

    return unless $generate;

    unless($genes){
    	$c->stash->{error_msg} = "No gene symbols entered";
    	return;
    }

    $c->stash->{genes} = $genes;
	# Enter list of gene symbols
	my $sep = qr/[\s\n,;]+/;
	my @symbols = split $sep, $genes;
	$c->log->debug("generating picklist for symbols: ".join ", ",@symbols);

	# find all FP wells for it which are currently "in_freezer"
	# FIXME: this logic should go in plugin
	my $summary_rs = $c->model('Golgi')->schema->resultset("Summary")->search({
		design_gene_symbol => { -in => \@symbols },
		fp_well_id         => {'!=', undef },
		design_species_id  => $c->session->{selected_species},
	});

    my @well_ids = map { $_->fp_well_id } $summary_rs->all;

    my $barcode_rs = $c->model('Golgi')->schema->resultset("WellBarcode")->search(
        {
    	    well_id       => { -in => \@well_ids },
    	    barcode_state => 'in_freezer',
        },
        {
        	prefetch      => [ qw(well) ],
        }
    );

    my @data;
    foreach my $bc ($barcode_rs->all){
    	my @summaries = $summary_rs->search({
            fp_well_id => $bc->well_id,
    	})->all;

    	my @epd_names = map { $_->ep_pick_plate_name."_".$_->ep_pick_well_name } @summaries;

        my @datum = (
        	$summaries[0]->design_gene_symbol,
            $bc->well->plate->name,
            $bc->well->name,
            $bc->barcode,
            (join ", ", uniq @epd_names),
            "",
            "",
        );
        push @data, \@datum;
    }

    unless(@data){
    	$c->stash->{error_msg} = "No FP wells found in freezer for genes: ".join ", ",@symbols;
    	return;
    }

    # NB: underscores in column headings are needed as spaces in col headings caused
    # problems for ExtJS grid printing plugin
    $c->stash->{columns} = [ ("Gene","Plate","Well","Barcode","Parent_EPD","To_Pick","Picked") ];
    $c->stash->{data} = \@data;
    $c->stash->{title} = "Final Pick Plates in Freezer";

	# Provide as printable list contining plate/well position, barcodes, parent EPDs
	# blank columns for "to pick"/"picked"
}
1;