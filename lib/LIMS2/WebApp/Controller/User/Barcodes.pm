package LIMS2::WebApp::Controller::User::Barcodes;
use Moose;
use TryCatch;
use Data::Dump 'pp';
use List::MoreUtils qw (uniq);
use LIMS2::Model::Util::BarcodeActions qw(
    checkout_well_barcode
    discard_well_barcode
    freeze_back_barcode
    add_barcodes_to_wells
    upload_plate_scan
    send_out_well_barcode
    do_picklist_checkout
);
use namespace::autoclean;
use JSON;

BEGIN { extends 'Catalyst::Controller'; }

sub generate_picklist : Path( '/user/generate_picklist' ) : Args(0){
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $generate = $c->request->param('generate');
    my $genes  = $c->request->param('genes');
    $c->stash->{genes} = $genes;;

    if ($generate){
        unless($genes){
        	$c->stash->{error_msg} = "No gene symbols entered";
        	return;
        }

    	# Enter list of gene symbols
    	my $sep = qr/[\s\n,;]+/;
    	my @symbols = split $sep, $genes;
    	$c->log->debug("generating picklist for symbols: ".join ", ",@symbols);

        my $pick_list;
        try{
            $pick_list = $c->model('Golgi')->generate_fp_picking_list({
                symbols => \@symbols,
                species => $c->session->{selected_species},
                user    => $c->user->name,
            });
        }
        catch($e){
            $c->stash->{error_msg} = "Failed to generate pick list: $e";
            return;
        };

        my $display_data = $self->_pick_list_display_data($c->model('Golgi')->schema, $pick_list);
        unless(@$display_data){
            $c->stash->{error_msg} = "No FP wells found";
            return;
        }

        $c->stash->{pick_list} = $pick_list;
        $c->stash->{columns} = $self->_pick_list_display_cols;
        $c->stash->{data} = $display_data;
        $c->stash->{title} = "FP Pick List ID: ".$pick_list->id;

    }

    return;
}

sub checkout_from_picklist : Path( '/user/checkout_from_picklist' ) : Args(0){

    my ($self, $c) = @_;

    $c->stash->{id} = $c->request->param('id');

    my $pick_list;

    if($c->request->param('checkout')){

        unless($c->request->param('id')){
            $c->stash->{error_msg} = "No pick list ID entered";
            return;
        }

        my $messages = [];
        $c->model('Golgi')->txn_do( sub {
            try{
                $messages = do_picklist_checkout($c->model('Golgi'),{
                   id   => $c->request->param('id'),
                   user => $c->user->name,
                });
            }
            catch($e){
                $c->stash->{error_msg} = "Picklist checkout failed with error $e";
                $c->log->debug("rolling back picklist checkout actions");
                $c->model('Golgi')->txn_rollback;
                return;
            }

            $c->flash->{success_msg} = join "<br>", @$messages;
            $c->res->redirect( $c->uri_for('/user/view_checked_out_barcodes/FP'));
        });
    }
    elsif($c->request->param('retrieve')){

        unless($c->request->param('id')){
            $c->stash->{error_msg} = "No pick list ID entered";
            return;
        }

        try{
            $pick_list = $c->model('Golgi')->retrieve_fp_picking_list({
                id     => $c->request->param('id'),
                active => 1,
            });
        }
        catch($e){
            $c->stash->{error_msg} = "Failed to retrieve pick list: $e";
            return;
        }

        my $display_data = $self->_pick_list_display_data($c->model('Golgi')->schema, $pick_list);
        unless(@$display_data){
            $c->stash->{error_msg} = "No FP wells found";
            return;
        }

        $c->stash->{pick_list} = $pick_list;
        $c->stash->{columns} = $self->_pick_list_display_cols;
        $c->stash->{data} = $display_data;
        $c->stash->{title} = "FP Pick List ID: ".$pick_list->id;
    }

    return;
}

# Returns JSON so this can be used in ajax request
sub pick_barcode : Path( '/user/pick_barcode' ) : Args(0) {
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    my $bc = $c->request->param('barcode');
    my $list_id = $c->request->param('list_id');

    if($bc and $list_id){
        my $pick_list_bc;
        try{
            $pick_list_bc = $c->model('Golgi')->pick_barcode_from_list({
                fp_picking_list_id => $list_id,
                well_barcode => $bc,
            });
        }
        catch($e){
            $c->stash->{json_data} = { error => "Failed to pick barcode $bc - $e" };
            $c->forward('View::JSON');
            return;
        };
        $c->stash->{json_data} = { success => "Barcode $bc has been picked" };
    }
    else{
        $c->stash->{json_data} = {error => "Barcode or pick list ID missing"};
    }

    $c->forward('View::JSON');

    return;
}

# Returns JSON so this can be used in ajax request
sub get_barcode_information : Path('/user/get_barcode_information/') : Args(1){
    my ($self, $c, $barcode) = @_;

    $c->assert_user_roles('read');

    my $well_barcode = $c->model('Golgi')->schema->resultset('WellBarcode')->search({
                           barcode => $barcode
                        })->first;

    unless($well_barcode){
        $c->stash->{json_data} = { message => "Barcode $barcode not found in LIMS2" };
        $c->forward('View::JSON');
        return;
    }

    if($well_barcode->barcode_state->id eq 'in_freezer'){
        $c->stash->{json_data} = { message => "Barcode $barcode found in freezer on plate "
                                              .$well_barcode->well->plate->as_string
                                              ." well ".$well_barcode->well->name };
    }
    else{
        $c->stash->{json_data} = { message => "Barcode $barcode not in freezer.<br>State: "
                                              .$well_barcode->barcode_state->id
                                              ."<br>Last known freezer location: plate "
                                              .$well_barcode->well->plate->as_string
                                              ." well ".$well_barcode->well->name };
    }

    $c->forward('View::JSON');

    return;
}

sub scan_barcode : Path( '/user/scan_barcode' ) : Args(0){
    my ($self, $c) = @_;

    $c->assert_user_roles( 'read' );

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
        $c->stash->{can_edit} = $c->check_user_roles( 'edit' );
    }
    return;
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
        # Well status updated and new plate version created
        my $bc = $c->request->param('barcode');
        my $well_barcode;

        $c->model('Golgi')->txn_do( sub {
            try{
                $well_barcode = checkout_well_barcode($c->model('Golgi'),{
                    barcode => $bc,
                    user    => $c->user->name,
                });
            }
            catch($e){
                $c->stash->{error_msg} = "Barcode checkout failed with error $e";
                $c->log->debug("rolling back checkout actions");
                $c->model('Golgi')->txn_rollback;
            };
        });

        if($well_barcode){
            my $well_name = $well_barcode->well->as_string;
            $c->stash->{success_msg} = "Well $well_name (Barcode: $bc) has been checked out of the freezer";
        }
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
    $c->stash->{discard_reasons} = [ qw(contamination )];
    return;
}

sub fp_freeze_back : Path( '/user/fp_freeze_back' ) : Args(0){
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    my $barcode = $c->request->param('barcode');
    $c->stash->{barcode} = $barcode;

    my $well;
    if($barcode){
        # stash well details
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
        foreach my $item ( qw(number_of_wells lab_number qc_piq_plate_name qc_piq_well_name) ){
            $c->stash->{$item} = $c->req->param($item);
        }

        # Requires: FP barcode, number of PIQ wells, lab number,
        # PIQ sequencing plate name, PIQ seq well
        my $tmp_piq_plate;
        $c->model('Golgi')->txn_do( sub {
            try{
                my $params = $c->request->parameters;
                $params->{user} = $c->user->name;
                $tmp_piq_plate = freeze_back_barcode( $c->model('Golgi'), $params );
            }
            catch($e){
                $c->stash->{error_msg} = "Attempt to freeze back $barcode failed with error $e";
                $c->log->debug("rolling back freeze back actions");
                $c->model('Golgi')->txn_rollback;
            };
        });

        # Refresh our FP well details
        $well = $c->model('Golgi')->retrieve_well({ barcode => $barcode });
        $c->stash->{well_details} = $self->_well_display_details($c, $well);

        if($tmp_piq_plate){
            $c->stash->{piq_plate_name} = $tmp_piq_plate->name;
            $c->stash->{piq_wells} = [ $tmp_piq_plate->wells ];
        }
    }
    elsif($c->request->param('submit_piq_barcodes')){
        # Requires: well->barcode mapping
        my $messages = [];
        $c->model('Golgi')->txn_do( sub {
            try{
                my $params = $c->request->parameters;
                $messages = add_barcodes_to_wells( $c->model('Golgi'), $params, 'checked_out' );
            }
            catch($e){
                $c->stash->{error_msg} = "Attempt to add barcodes to wells failed with error $e";
                $c->log->debug("rolling back add barcode actions");
                $c->model('Golgi')->txn_rollback;
            };
        });

        if($c->stash->{error_msg}){
            # Recreate stash for barcode upload form
            foreach my $item ( qw(number_of_wells lab_number qc_piq_plate_name qc_piq_well_name piq_plate_name) ){
                $c->stash->{$item} = $c->req->param($item);
            }

            # Stash scanned barcodes
            my @barcode_fields = grep { $_ =~ /barcode_([0-9]+)$/ } keys %{$c->request->parameters};
            foreach my $field_name (@barcode_fields){
                $c->log->debug("Stashing $field_name");
                $c->stash->{$field_name} = $c->req->param($field_name);
            }

            my $tmp_piq_plate = $c->model('Golgi')->retrieve_plate({
                name => $c->req->param('piq_plate_name')
            });
            $c->stash->{piq_wells} = [ $tmp_piq_plate->wells ];
            return;
        }

        # Redirect user to checked_out FP page
        $c->flash->{success_msg} = join "<br>", @$messages;
        $c->res->redirect( $c->uri_for("/user/view_checked_out_barcodes/FP") );
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

sub piq_send_out : Path( '/user/piq_send_out' ) : Args(0){
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    my $barcode = $c->request->param('barcode');

    $c->stash->{barcode} = $barcode;

    if($c->request->param('cancel_send_out')){
        $c->flash->{info_msg} = "Cancelled send out of barcode $barcode";
        $c->res->redirect( $c->uri_for("/user/view_checked_out_barcodes/PIQ") );
        return;
    }
    elsif($c->request->param('confirm_send_out')){

        my $failed;
        $c->model('Golgi')->txn_do( sub {
            try{
                send_out_well_barcode(
                    $c->model('Golgi'),
                    {
                        barcode => $barcode,
                        user    => $c->user->name,
                        comment => $c->request->param('comment'),
                    }
                );
            }
            catch($e){
                $c->flash->{error_msg} = "Send out of barcode $barcode failed with error $e";
                $c->log->debug("rolling back barcode send out actions");
                $c->model('Golgi')->txn_rollback;
                $failed = 1;
            };
        });

        $c->flash->{success_msg} = "Barcode $barcode has been sent out" unless $failed;
        $c->res->redirect( $c->uri_for("/user/view_checked_out_barcodes/PIQ") );
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

sub create_barcoded_plate : Path( '/user/create_barcoded_plate' ) : Args(0){
    # Upload a barcode scan file to create a new plate
    # which contains tubes that have already been registered in LIMS2
    # e.g. creating PIQ plate using daughter wells which are currently located on tmp plate
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    if($c->request->param('create_plate')){
        my $csv_barcodes_data_file = $c->request->upload('wellbarcodesfile');

        unless ( $csv_barcodes_data_file ) {
            $c->flash->{ 'error_msg' } = 'You must select a barcode csv file to upload';
            return;
        }

        my $plate_name = $c->request->param('plate_name');

        unless($plate_name){
            $c->flash->{ 'error_msg' } = "No plate name provided";
            return;
        }
        $c->stash->{plate_name} = $plate_name;

        my $plate_exists = $c->model('Golgi')->schema->resultset('Plate')->search({
            name => $plate_name,
        })->first;

        if($plate_exists){
            $c->flash->{ 'error_msg' } = "Plate $plate_name already exists. Please use a different name.";
            return;
        }

        my $list_messages = [];
        my $plate;

        $c->model('Golgi')->txn_do(
            sub {
                try{
                    my $upload_params = {
                        new_plate_name      => $plate_name,
                        new_state           => 'in_freezer',
                        species             => $c->session->{selected_species},
                        user                => $c->user->name,
                        csv_fh              => $csv_barcodes_data_file->fh,
                    };
                    ($plate, $list_messages) = upload_plate_scan($c->model('Golgi'), $upload_params);
                }
                catch($e){
                    $c->stash->{ 'error_msg' } = 'Error encountered while uploading plate tube barcodes: ' . $e;
                    $c->log->debug('rolling back barcode upload actions');
                    $c->model('Golgi')->txn_rollback;
                };
            }
        );

        if($plate){
            $c->flash->{'success_msg'} = "Plate $plate_name was created";
            $c->res->redirect( $c->uri_for("/user/view_plate", {id => $plate->id }) );
        }
    }

    return;
}

sub rescan_barcoded_plate : Path( '/user/rescan_barcoded_plate' ) : Args(0){
    # Upload a barcode scan file to update an existing plate
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    if($c->request->param('update_plate')){
        my $csv_barcodes_data_file = $c->request->upload('wellbarcodesfile');

        unless ( $csv_barcodes_data_file ) {
            $c->flash->{ 'error_msg' } = 'You must select a barcode csv file to upload';
            return;
        }

        my $plate_name = $c->request->param('plate_name');

        unless($plate_name){
            $c->flash->{ 'error_msg' } = "No plate name provided";
            return;
        }
        $c->stash->{plate_name} = $plate_name;

        my $plate_exists = $c->model('Golgi')->schema->resultset('Plate')->search({
            name => $plate_name,
        })->first;

        unless($plate_exists){
            $c->flash->{ 'error_msg' } = "Plate $plate_name not found\n";
            return;
        }

        my $list_messages = [];
        my $plate;

        $c->model('Golgi')->txn_do(
            sub {
                try{
                    my $upload_params = {
                        existing_plate_name => $plate_name,
                        species             => $c->session->{selected_species},
                        user                => $c->user->name,
                        csv_fh              => $csv_barcodes_data_file->fh,
                    };
                    ($plate, $list_messages) = upload_plate_scan($c->model('Golgi'), $upload_params);
                }
                catch($e){
                    $c->stash->{ 'error_msg' } = 'Error encountered while uploading plate tube barcodes: ' . $e;
                    $c->log->debug('rolling back barcode upload actions');
                    $c->model('Golgi')->txn_rollback;
                    return;
                };
            }
        );

        # encode messages as json string to send to well results view
        my $json_text = encode_json( $list_messages );

        # find plate by name rather than ID so we get current version
        my $updated_plate = $c->model('Golgi')->retrieve_plate( { name => $plate_name } );

        $c->stash(
            template            => 'user/browseplates/view_well_barcode_results.tt',
            plate               => $updated_plate,
            well_results_list   => $json_text,
            username            => $c->user->name,
        );
    }

    return;
}

sub well_barcode_history : Path( '/user/well_barcode_history' ) : Args(1){
    my ($self, $c, $barcode) = @_;

    $c->assert_user_roles( 'read' );

    unless($barcode){
        $c->stash->{error_msg} = "No barcode provided";
        return;
    }

    my $bc = $c->model('Golgi')->retrieve_well_barcode({ barcode => $barcode });

    my @events = $bc->search_related('barcode_events',
            {},
            {
                order_by => { -desc => [qw/created_at/] }
            }
    );

    $c->stash->{events} = \@events;
    return;
}

sub plate_well_barcode_history : Path( '/user/plate_well_barcode_history' ) : Args(1){
    my ($self, $c, $plate_id) = @_;

    $c->assert_user_roles( 'read' );
    # FIXME: plate_id sanity checks

    my $plate = $c->model('Golgi')->retrieve_plate({ id => $plate_id });
    my $historical_barcodes = $c->model('Golgi')->historical_barcodes_for_plate({ id => $plate_id });

    my @barcode_data;
    foreach my $barcode (@$historical_barcodes){
        my @events = $barcode->search_related('barcode_events',
            {},
            {
                order_by => { -desc => [qw/created_at/] }
            }
        );

        my $details = {
            barcode => $barcode->barcode,
            state   => $barcode->barcode_state->id,
            events  => \@events,
            current_plate => $barcode->well->plate->as_string,
            current_well  => $barcode->well->name,
        };

        if(@events){
            my $most_recent_event = $events[0];
            my @changes;

            if($most_recent_event->old_well->id != $most_recent_event->new_well->id){
                push @changes, 'Barcode moved from well '.$most_recent_event->old_well->as_string
                           .' to well '.$most_recent_event->new_well->as_string;
            }

            if($most_recent_event->old_state->id ne $most_recent_event->new_state->id){
                push @changes, 'Barcode state changed from '.$most_recent_event->old_state->id
                              .' to '.$most_recent_event->new_state->id;
            }

            $details->{most_recent_event_date} = $most_recent_event->created_at;
            $details->{most_recent_event_user} = $most_recent_event->created_by->name;
            $details->{most_recent_change} = (join ". ", @changes);
            $details->{most_recent_comment} = $most_recent_event->comment;
        }

        push @barcode_data, $details;
    }

    my @sorted_barcode_data = sort { $a->{barcode} cmp $b->{barcode} } @barcode_data;

    $c->stash->{barcode_data} = \@sorted_barcode_data;
    $c->stash->{plate} = $plate;

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

    if($well->well_lab_number){
        $well_details->{lab_number} = $well->well_lab_number->lab_number;
    }

    if($well_details->{barcode_state} eq "checked_out"){
        # Find most recent checkout date
        my $checkout = $well->well_barcode->most_recent_event('checked_out');

        if($checkout){
            $well_details->{checkout_date} = $checkout->created_at;
            $well_details->{checkout_user} = $checkout->created_by->name;
        }
    }

    return $well_details;
}

sub _pick_list_display_cols{
    # NB: underscores in column headings are needed as spaces in col headings caused
    # problems for ExtJS grid printing plugin

    return [ ("Gene","Plate","Well","Barcode","Parent_EPD","To_Pick","Picked") ];
}

sub _pick_list_display_data{
    my ($self, $schema, $pick_list) = @_;

    my @data;
    foreach my $list_bc ($pick_list->fp_picking_list_well_barcodes){
        my $bc = $list_bc->well_barcode;
        my $picked = ($list_bc->picked ? 'TRUE' : '');

        my @summaries = $schema->resultset('Summary')->search({
            fp_well_id => $bc->well_id,
        })->all;

        my $parent_epd;
        my $gene_symbols;

        if(@summaries){
            my @epd_names = map { $_->ep_pick_plate_name."_".$_->ep_pick_well_name } @summaries;
            $gene_symbols = $summaries[0]->design_gene_symbol;
            $parent_epd = (join ", ", uniq @epd_names);

        }
        else{
            # If this well ID is not yet in the summaries table
            # get gene symbols using design ID
            my $design_id = $bc->well->design->id;
            my $design_summaries = $schema->resultset('Summary')->search({
                design_id => $design_id
            })->first;

            # and get parent EP pick through process graph
            $gene_symbols = $design_summaries->design_gene_symbol;
            my $ep_pick = $bc->well->first_ep_pick;
            $parent_epd = ($ep_pick ? $ep_pick->as_string : "");
        }

        my @datum = (
            $gene_symbols,
            $bc->well->plate->name,
            $bc->well->name,
            $bc->barcode,
            $parent_epd,
            "",
            $picked,
        );

        push @data, \@datum;

    }

    return \@data;
}

1;