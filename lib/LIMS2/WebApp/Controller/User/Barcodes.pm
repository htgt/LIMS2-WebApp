package LIMS2::WebApp::Controller::User::Barcodes;
use Moose;
use TryCatch;
use Data::Dump 'pp';
use List::MoreUtils qw (uniq);
use LIMS2::Model::Util::BarcodeActions qw(discard_well_barcode);
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

        my $well_details = $self->_well_display_details($c, $well);

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

sub view_checked_out_barcodes : Path( '/user/view_checked_out_barcodes' ) : Args(1){
    my ($self, $c, $plate_type) = @_;

    $c->assert_user_roles( 'read' );

    my @checked_out = $c->model('Golgi')->schema->resultset('WellBarcode')->search(
        {
            'me.barcode_state' => 'checked_out',
            'plate.species_id' => $c->session->{selected_species},
            'plate.type_id'    => $plate_type,
        },
        {
            join => { well => 'plate' },
        }
    );

    my @barcodes;
    foreach my $bc (@checked_out){
        my $well_details = $self->_well_display_details($c, $bc->well);
        push @barcodes, $well_details;
    }

    my @sorted = sort { $a->{checkout_date} cmp $b->{checkout_date} } @barcodes;
    $c->stash->{plate_type} = $plate_type;
    $c->stash->{barcodes} = \@sorted;
    return;
}

sub fp_freeze_back : Path( '/user/fp_freeze_back' ) : Args(0){
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    my $barcode = $c->request->param('barcode');
    $c->stash->{barcode} = $barcode;

    if($barcode){
        # stash well details
        my $well;
        try{
            $well = $c->model('Golgi')->retrieve_well({
                barcode => $barcode,
            });
        };
        if($well){
            $c->stash->{well_details} = $self->_well_display_details($c, $well);
        }
        else{
            $c->stash->{error_msg} = "Barcode $barcode not found";
            return;
        }
    }
    else{
        $c->stash->{error_msg} = "No barcode provided";
        return;
    }

    if($c->request->param('create_piq_wells')){
        # Requires: number of PIQ wells, lab number,
        # PIQ sequencing plate name, PIQ seq well
        # Create seq plate if it does not exist
        # Add well to seq plate
        # Create n daughter wells on temp plate
    }
    elsif($c->request->param('submit_piq_barcodes')){
        # Requires: well->barcode mapping
    }
    return;
}

sub discard_barcode : Path( '/user/discard_barcode' ) : Args(0){
    # Page should ask user to confirm and then update the barcode state
    # and create a new copy of the plate which does not include the discarded barcode
    # barcode will remain linked to well_id on old plate which will be flagged as virtual
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    my $barcode = $c->request->param('barcode');
    my $plate_type = $c->request->param('plate_type');

    $c->stash->{barcode} = $barcode;
    $c->stash->{reason} = $c->request->param('reason');

    if($c->request->param('cancel_discard')){
        $c->flash->{info_msg} = "Cancelled discard of barcode $barcode";
        $c->res->redirect( $c->uri_for("/user/view_checked_out_barcodes/$plate_type") );
        return;
    }
    elsif($c->request->param('confirm_discard')){

        my $failed;
        $c->model('Golgi')->txn_do( sub {
            try{
                discard_well_barcode(
                    $c->model('Golgi'),
                    {
                        barcode => $barcode,
                        user    => $c->user->name,
                        reason  => $c->request->param('reason'),
                    }
                );
            }
            catch($e){
                $c->flash->{error_msg} = "Discard of barcode $barcode failed with error $e";
                $c->log->debug("rolling back barcode discard actions");
                $c->model('Golgi')->txn_rollback;
                $failed = 1;
            };
        });

        $c->flash->{success_msg} = "Barcode $barcode has been discarded" unless $failed;
        $c->res->redirect( $c->uri_for("/user/view_checked_out_barcodes/$plate_type") );
    }
    elsif($barcode){
        # return well details
        my $well;
        try{
            $well = $c->model('Golgi')->retrieve_well({
                barcode => $barcode,
            });
        };
        if($well){
            $c->stash->{well_details} = $self->_well_display_details($c, $well);
        }
        else{
            $c->stash->{error_msg} = "Barcode $barcode not found";
        }
        return;
    }
    else{
        $c->stash->{error_msg} = "No barcode provided";
    }
    return;
}

sub _well_display_details{
    my ($self, $c, $well) = @_;

    my $well_details = $well->as_hash;
    $well_details->{well_as_string} = $well->as_string;

    if(my $epd = $well->first_ep_pick){
        $well_details->{parent_epd} = $epd->plate->name."_".$epd->name;
    }

    my($gene_ids, $gene_symbols) = $c->model('Golgi')->design_gene_ids_and_symbols({
        design_id => $well->design->id,
    });

    $well_details->{design_gene_symbol} = $gene_symbols->[0];
    $well_details->{barcode_state} = $well->well_barcode->barcode_state->id;
    $well_details->{barcode} = $well->well_barcode->barcode;

    if($well_details->{barcode_state} eq "checked_out"){
        # Find most recent checkout date
        my $checkout = $well->well_barcode->search_related('barcode_events',
            {
                new_state => 'checked_out',
                old_state => {'!=' => 'checked_out'}
            },
            {
                order_by => { -desc => [qw/created_at/] }
            }
        )->first;

        if($checkout){
            $well_details->{checkout_date} = $checkout->created_at;
            $well_details->{checkout_user} = $checkout->created_by->name;
        }
    }

    return $well_details;
}
1;