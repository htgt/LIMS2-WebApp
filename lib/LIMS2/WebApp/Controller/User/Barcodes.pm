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

sub well_checkout : Path( '/user/well_checkout' ) : Args(0){
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    # User Scans a barcode
    if($c->request->param('submit_barcode')){
        # Fetches info about the well
        my $bc = $c->request->param('barcode');
        unless ($bc){
            $c->stash->{error_msg} = "No barcode entered";
            return;
        }

        $c->stash->{barcode} = $bc;

        my $well;
        try{
            $well = $c->model('Golgi')->retrieve_well({
                barcode => $bc,
            });
        };

        unless($well){
            $c->stash->{error_msg} = "Barcode $bc not found";
            return;
        }

        # FIXME: put in plugin or util module
        my $well_details = $well->as_hash;
        if(my $epd = $well->first_ep_pick){
            $well_details->{parent_epd} = $epd->plate->name."_".$epd->name;
        }
        my($gene_ids, $gene_symbols) = $c->model('Golgi')->design_gene_ids_and_symbols({
                design_id => $well->design->id,
            });

        $well_details->{design_gene_symbol} = $gene_symbols->[0];
        $well_details->{barcode_state} = $well->well_barcode->barcode_state->id;

        $c->stash->{well_details} = $well_details;
        return;
    }
    elsif($c->request->param('confirm_checkout')){
        # User Confirms checkout
        # Well status updated
        my $bc = $c->request->param('barcode');
        my $well_barcode = $c->model('Golgi')->update_well_barcode({
                barcode       => $bc,
                new_state     => 'checked_out',
                user          => $c->user->name,
            });
        my $well_name = $well_barcode->well->as_string;
        $c->stash->{success_msg} = "Well $well_name (Barcode: $bc) has been checked out of the freezer";
    }
    return;
}
1;