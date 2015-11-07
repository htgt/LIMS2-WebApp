package LIMS2::WebApp::Controller::User::Barcodes;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Barcodes::VERSION = '0.352';
}
## use critic

use Moose;
use TryCatch;
use Data::Dump 'pp';
use List::MoreUtils qw (uniq);
use LIMS2::Model::Util::BarcodeActions qw(
    checkout_well_barcode
    discard_well_barcode
    freeze_back_fp_barcode
    freeze_back_piq_barcode
    add_barcodes_to_wells
    upload_plate_scan
    send_out_well_barcode
    do_picklist_checkout
    start_doubling_well_barcode
    upload_qc_plate
);
use namespace::autoclean;
use JSON;

use LIMS2::Model::Util::MutationSignatures qw(get_mutation_signatures_barcode_data);
use LIMS2::Model::Util::CGAP;

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
    if($c->request->param('submit_barcode') or $c->request->param('barcode')){
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

    my @wells = map { $_->well } @checked_out;
    my $display_details = $self->_multiple_well_display_details($c,\@wells);

    my @sorted = sort { $a->{checkout_date} cmp $b->{checkout_date} } @$display_details;
    $c->stash->{plate_type} = $plate_type;
    $c->stash->{barcodes} = \@sorted;
    $c->stash->{discard_reasons} = [ "contamination", "failed QC", "failed to recover",  "used for testing" ];
    return;
}

## no critic(ProhibitExcessComplexity)
# FIXME: factor out processing and stashing of form params
sub freeze_back : Path( '/user/freeze_back' ) : Args(0){
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    my $barcode = $c->request->param('barcode');
    $c->stash->{barcode} = $barcode;

    my $type = $c->req->param('freeze_back_type');
    my $redirect_on_completion;
    if($type eq 'FP'){
        $c->stash->{template} = 'user/barcodes/fp_freeze_back.tt';
        $redirect_on_completion = $c->uri_for('/user/scan_barcode');
    }
    elsif($type eq 'PIQ'){
        $c->stash->{template} = 'user/barcodes/piq_freeze_back.tt';
        $redirect_on_completion = $c->uri_for('/user/scan_barcode');
    }

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
        my $freeze_back_method;
        my $freeze_back_params = {
            barcode => $barcode,
        };

        if($c->req->param('freeze_back_type') eq 'PIQ'){
            $freeze_back_method = \&freeze_back_piq_barcode;
            foreach my $item ( qw(number_of_doublings) ){
                $c->stash->{$item} = $c->req->param($item);
                $freeze_back_params->{$item} = $c->req->param($item);
            }
        }
        elsif($c->req->param('freeze_back_type') eq 'FP'){
            $freeze_back_method = \&freeze_back_fp_barcode;
        }
        else{
            die "Freeze back type not specified in form";
        }

        # For each QC well stash the form parameters
        # and generate hash of params to send to freeze back method
        my $number_of_qc_wells = $c->req->param('number_of_qc_wells');
        my @qc_well_params;
        foreach my $num (1..$number_of_qc_wells){
            my $params = {
                barcode => $barcode,
                user    => $c->user->name,
            };
            foreach my $item ( qw(number_of_wells lab_number qc_piq_plate_name qc_piq_well_name qc_piq_well_barcode) ){
                my $form_param = $item."_$num";

                next unless defined ($c->req->param($form_param));

                $c->stash->{$form_param} = $c->req->param($form_param);
                $params->{$item} = $c->req->param($form_param);
            }
            push @qc_well_params, $params;
        }

        # Requires: orig FP or PIQ barcode, number of PIQ wells, lab number,
        # PIQ sequencing plate name, PIQ seq well
        my @freeze_back_outputs;
        $freeze_back_params->{qc_well_params} = \@qc_well_params;
        $c->model('Golgi')->txn_do( sub {
            try{
                @freeze_back_outputs = $freeze_back_method->($c->model('Golgi'), $freeze_back_params);
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

        my $num = 0;
        my $child_piq_count = 0;
        foreach my $output (@freeze_back_outputs){
            $num++;
            my $tmp_piq_plate = $output->{tmp_piq_plate};
            $c->stash->{"piq_plate_name_$num"} = $tmp_piq_plate ? $tmp_piq_plate->name : "" ;
            $c->stash->{"piq_wells_$num"} = $tmp_piq_plate ? [ $tmp_piq_plate->wells ] : [] ;

            if($tmp_piq_plate){
                $child_piq_count += $tmp_piq_plate->wells;
            }

            if($output->{qc_well}->well_barcode){
                $c->stash->{"qc_piq_well_barcode_$num"} = $output->{qc_well}->well_barcode->barcode;
            }
        }

        if($child_piq_count == 0){
            $c->flash->{success_msg} = ("Barcode $barcode frozen back. QC PIQ well has been added to "
                .$c->stash->{qc_piq_plate_name_1}." well ".$c->stash->{qc_piq_well_name_1});
            $c->res->redirect( $redirect_on_completion );
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

            # Stash scanned barcodes
            my @barcode_fields = grep { $_ =~ /^barcode_([0-9]+)$/ } keys %{$c->request->parameters};
            foreach my $field_name (@barcode_fields){
                $c->log->debug("Stashing $field_name");
                $c->stash->{$field_name} = $c->req->param($field_name);
            }

            my $number_of_qc_wells = $c->req->param('number_of_qc_wells');
            foreach my $num (1..$number_of_qc_wells){
                foreach my $item ( qw(number_of_wells lab_number qc_piq_plate_name qc_piq_well_name qc_piq_well_barcode piq_plate_name) ){
                    my $form_param = $item."_$num";
                    $c->stash->{$form_param} = $c->req->param($form_param);
                }

                my $tmp_piq_plate = $c->model('Golgi')->retrieve_plate({
                    name => $c->req->param("piq_plate_name_$num")
                });
                $c->stash->{"piq_wells_$num"} = [ $tmp_piq_plate->wells ];
            }
            return;
        }

        $c->flash->{success_msg} = join "<br>", @$messages;
        $c->res->redirect( $redirect_on_completion );
    }

    return;
}
## use critic

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
        $c->res->redirect( $c->uri_for("/user/scan_barcode") );
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
        $c->res->redirect( $c->uri_for("/user/scan_barcode") );
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
        $c->res->redirect( $c->uri_for("/user/scan_barcode") );
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
        $c->res->redirect( $c->uri_for("/user/scan_barcode") );
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

sub piq_start_doubling : Path( '/user/piq_start_doubling' ) : Args(0){
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    $c->stash->{oxygen_condition_list} = [ qw(normoxic hypoxic) ];

    my $barcode = $c->request->param('barcode');

    $c->stash->{barcode} = $barcode;

    my $well;
    if($barcode){
        # get well details
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

    if($c->request->param('cancel_start_doubling')){
        $c->flash->{info_msg} = "Cancelled start doubling of barcode $barcode";
        $c->res->redirect( $c->uri_for("/user/scan_barcode") );
        return;
    }
    elsif($c->request->param('confirm_start_doubling')){

        my $failed;
        $c->model('Golgi')->txn_do( sub {
            try{
                start_doubling_well_barcode(
                    $c->model('Golgi'),
                    {
                        barcode => $barcode,
                        user    => $c->user->name,
                        oxygen_condition => $c->request->param('oxygen_condition'),
                    }
                );
            }
            catch($e){
                $c->stash->{error_msg} = "Start doubling of barcode $barcode failed with error $e";
                $c->log->debug("rolling back barcode start doubling actions");
                $c->model('Golgi')->txn_rollback;
                $failed = 1;
            };
        });

        return if $failed;

        $c->flash->{success_msg} = "Barcode $barcode has begun doubling";
        $c->res->redirect( $c->uri_for("/user/scan_barcode") );
    }
    return;
}

sub create_qc_plate : Path( '/user/create_qc_plate' ) : Args(0){
    my ($self, $c) = @_;

    # Store mapping so user does not have to select both plate and process type
    my $process_type_for_plate = {
        CGAP_QC => 'cgap_qc',
        MS_QC   => 'ms_qc',
        PIQ     => 'rearray',
    };

    $c->assert_user_roles('edit');

    $c->stash->{plate_type_list} = [ keys %{ $process_type_for_plate } ];
    $c->stash->{plate_type} = $c->req->param('plate_type');

    if($c->request->param('create_plate')){
        my ($plate_name,$data_file) = $self->_plate_upload_checks($c);
        return unless $data_file;

        my $plate_type = $c->req->param('plate_type');

        unless($plate_type){
            $c->stash->{'error_msg'} = "No plate type provided";
            return;
        }

        my $process_type = $process_type_for_plate->{$plate_type};

        unless($process_type){
            $c->stash->{'error_msg'} = "No default process type found for plate type $plate_type";
            return;
        }

        my $plate;

        $c->model('Golgi')->txn_do(
            sub {
                try{
                    my $upload_params = {
                        new_plate_name      => $plate_name,
                        plate_type          => $plate_type,
                        process_type        => $process_type,
                        species             => $c->session->{selected_species},
                        user                => $c->user->name,
                        csv_fh              => $data_file->fh,
                    };

                    if(my $doublings = $c->req->param('number_of_doublings')){
                        $upload_params->{doublings} = $doublings;
                    }

                    $plate = upload_qc_plate($c->model('Golgi'), $upload_params);
                }
                catch($e){
                    $c->stash->{ 'error_msg' } = 'Error encountered while uploading qc plate: ' . $e;
                    $c->log->debug('rolling back qc plate upload actions');
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

sub create_barcoded_plate : Path( '/user/create_barcoded_plate' ) : Args(0){
    # Upload a barcode scan file to create a new plate
    # which contains tubes that have already been registered in LIMS2
    # e.g. creating PIQ plate using daughter wells which are currently located on tmp plate
    my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    if($c->request->param('create_plate')){
        my ($plate_name,$csv_barcodes_data_file) = $self->_plate_upload_checks($c);
        return unless $csv_barcodes_data_file;

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

# Check we have an upload file and a new plate name
sub _plate_upload_checks{
    my ($self, $c) = @_;

    $c->log->debug("Checking plate upload params");

    my $plate_name = $c->request->param('plate_name');

    unless($plate_name){
        $c->log->debug("plate name missing");
        $c->flash->{ 'error_msg' } = "No plate name provided";
        return;
    }
    $c->stash->{plate_name} = $plate_name;

    my $csv_barcodes_data_file = $c->request->upload('wellbarcodesfile');

    unless ( $csv_barcodes_data_file ) {
        $c->flash->{ 'error_msg' } = 'You must select a barcode csv file to upload';
        return;
    }

    my $plate_exists = $c->model('Golgi')->schema->resultset('Plate')->search({
        name => $plate_name,
    })->first;

    if($plate_exists){
        $c->flash->{ 'error_msg' } = "Plate $plate_name already exists. Please use a different name.";
        return;
    }

    return ($plate_name,$csv_barcodes_data_file);
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
                order_by => { -desc => [qw/created_at id/] }
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

## no critic(RequireFinalReturn)
sub mutation_signatures_barcodes : Path( '/user/mutation_signatures_barcodes' ) : Args(0){
    my ($self, $c) = @_;

    try{
        my $ms_barcode_data = get_mutation_signatures_barcode_data($c->model('Golgi'),$c->session->{selected_species});
        my $barcodes_by_state = {};
        foreach my $barcode (@$ms_barcode_data){
            my $state = $barcode->{state};
            $barcodes_by_state->{$state} ||= [];
            push @{ $barcodes_by_state->{$state} }, $barcode;
        }
        $c->stash->{data} = $barcodes_by_state;
    }
    catch($e){
        $c->stash->{error_msg} = $e;
    }

    return;
}
## use critic

sub search_cgap_friendly_name : Path( '/user/search_cgap_friendly_name' ) : Args(0){
    my ($self, $c) = @_;

    if($c->req->param('search') or $c->req->param('cgap_name')){
        my $name = $c->req->param('cgap_name');
        if($name){
            $c->stash->{name} = $name;
            try{
                my $cgap = LIMS2::Model::Util::CGAP->new;
                my $barcode = $cgap->get_barcode_for_cgap_name($name);
                $c->flash->{success_msg} = "Found barcode $barcode for CGAP name $name";
                $c->res->redirect( $c->uri_for('/user/scan_barcode', { barcode => $barcode }) );
            }
            catch($e){
                $c->stash->{error_msg} = "Error searching for cgap name $name: $e";
            }
        }
        else{
            $c->stash->{error_msg} = "You must provide a name";
        }
    }

    return;
}

sub _well_display_details{
    my ($self, $c, $well) = @_;

    my $well_details = $self->_basic_well_display_details($well);

    my $epd;
    try{
        $epd = $well->first_ep_pick;
    };

    if($epd){
        $well_details->{parent_epd} = $epd->plate->name."_".$epd->name;
    }

    if($well->design){
        my($gene_ids, $gene_symbols) = $c->model('Golgi')->design_gene_ids_and_symbols({
            design_id => $well->design->id,
        });

        $well_details->{design_gene_symbol} = $gene_symbols->[0];
    }


    return $well_details;
}

sub _multiple_well_display_details{
    my ($self, $c, $wells) = @_;

    my @display_data;
    my @well_ids = map { $_->id } @{ $wells || [] };

    return [] unless @well_ids;

    # Use ProcessTree to get ancestors and design data for all well IDs
    my $well_designs = $c->model('Golgi')->get_design_data_for_well_id_list(\@well_ids);

    # Use design IDs to get gene symbols from summary table
    # $well_designs->{<well_id>}->{design_id}
    my @design_ids = map { $well_designs->{$_}->{design_id} } keys %$well_designs;
    my @summaries = $c->model('Golgi')->schema->resultset('Summary')->search({
        design_id => { '-in' => \@design_ids }
    });

    # Generate hash of design IDs to gene symbols
    my $design_gene_symbols = {};
    foreach my $summary (@summaries){
        $design_gene_symbols->{$summary->design_id} = $summary->design_gene_symbol;
    }

    # Find ancestor EP_PICK wells
    my $well_ancestors = $c->model('Golgi')->get_ancestors_for_well_id_list(\@well_ids);
    my @all_ancestors = map { @{ $_->[0] } } @$well_ancestors;

    # Generate hash of all EPD ancestor well IDs to well names
    my %epd_ancestor_names = map { $_->id => $_->as_string } $c->model('Golgi')->schema->resultset('Well')->search({
        'me.id' => { '-in' => \@all_ancestors },
        'plate.type_id' => 'EP_PICK',
    }, { join => 'plate' });

    # Generate hash of starting well IDs to their ancestors
    my $ancestors_for_well;
    foreach my $ancestor_list (@$well_ancestors){
        my @list = @{ $ancestor_list->[0] };
        $ancestors_for_well->{$list[0]} = [ @list[1..$#list] ];
    }


    foreach my $well (@$wells){
        my $well_details = $self->_basic_well_display_details($well);

        # Find first ancestor of this well which is an EPD (we have stored the names of all EPD ancestors)
        my $ancestors = $ancestors_for_well->{$well->id};
        my ($epd_name) = grep {$_} map { $epd_ancestor_names{$_} } @$ancestors;
        if($epd_name){
            $well_details->{parent_epd} = $epd_name;
        }

        # Find gene symbol for this well using design IDs and symbols retrieved by batch query
        my $design_id = $well_designs->{$well->id}->{design_id};
        $well_details->{design_gene_symbol} = $design_gene_symbols->{$design_id};


        push @display_data, $well_details;
    }

    # return array of display hashes
    return \@display_data;
}

sub _basic_well_display_details{
    my ($self, $well) = @_;

    my $well_details = $well->as_hash;

    $well_details->{well_as_string} = $well->as_string;

    $well_details->{barcode_state} = ( $well->well_barcode->barcode_state ? $well->well_barcode->barcode_state->id
                                                                      : "" );
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
            my $ep_pick;
            try{
               $ep_pick = $bc->well->first_ep_pick;
            };
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
