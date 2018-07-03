package LIMS2::Model::Util::BarcodeActions;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::BarcodeActions::VERSION = '0.508';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
              checkout_well_barcode
              checkout_well_barcode_list
              discard_well_barcode
              freeze_back_fp_barcode
              freeze_back_piq_barcode
              piq_expand_freeze_back_barcode
              add_barcodes_to_wells
              upload_plate_scan
              send_out_well_barcode
              do_picklist_checkout
              start_doubling_well_barcode
              upload_qc_plate

          )
    ]
};

use LIMS2::Model::Util::WellName qw( generate_96_well_annotations );
use Log::Log4perl qw( :easy );
use List::MoreUtils qw( uniq any );
use LIMS2::Exception;
use TryCatch;
use Hash::MoreUtils qw( slice_def );
use Data::Dumper;

# Input: model, params from web form, state to create new barcodes with
# Where form sends params named "barcode_<well_id>"
# e.g. <input type="text" name="barcode_[% well.id %]">
sub add_barcodes_to_wells{
    my ($model, $params, $state) = @_;

    my @csv_barcodes;
    my @barcode_keys;

    if ($params->{piq_barcode_csv}) {
        @csv_barcodes = @{$params->{piq_barcode_csv}};
        @barcode_keys = grep { $_ } map { $_ =~ /^(barcode_[0-9]+)$/ } keys %{$params};

        if (any {$params->{$_} ne ""} @barcode_keys) {
            ## no barcodes specified in input box
            die "Input already defined. Choose 1 entry mode.";
        } elsif (scalar @barcode_keys != scalar @csv_barcodes) {
            ## CSV content contains correct number of elements
            die "Incorrect number of barcodes in CSV file.";
        } else {
            ## set up the barcodes from CSV file content
            foreach my $indx (0..$#barcode_keys) {
                $params->{$barcode_keys[$indx]} = $csv_barcodes[$indx];
            }
        }
    }

    my @messages;
    my @well_ids = grep { $_ } map { $_ =~ /^barcode_([0-9]+)$/ } keys %{$params};

    foreach my $well_id (@well_ids){
        DEBUG "Adding barcode to well $well_id";
        my $well;
        try{
            $well = $model->retrieve_well({ id => $well_id });
        }
        die "Well ID $well_id not found\n" unless $well;

        my $barcode = $params->{"barcode_$well_id"};
        my $well_name = $well->well_lab_number ? $well->well_lab_number->lab_number
                                               : $well->as_string ;

        die "No barcode provided for well $well_name\n" unless $barcode;

        my $existing_barcode_well = $model->schema->resultset('Well')->search({
            barcode => $barcode,
        })->first;

        if($existing_barcode_well){
            die "Barcode $barcode entered for $well_name already exists at ".$existing_barcode_well->as_string;
        }

        $well = $model->create_well_barcode({
            well_id => $well_id,
            barcode => $barcode,
            state   => $state,
        });

        push @messages, "Barcode ".$well->barcode
                        ." added to well $well_name"
                        ." with state ".$well->barcode_state->id;
    }

    return \@messages;
}

sub pspec_checkout_well_barcode{
    return {
        barcode           => { validate => 'well_barcode' },
        user              => { validate => 'existing_user' },
    }
}

sub checkout_well_barcode{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_checkout_well_barcode);

    # FIXME: check barcode is "in_freezer" before doing checkout? or is this too strict

    my $well = $model->update_well_barcode({
        barcode       => $validated_params->{barcode},
        new_state     => 'checked_out',
        user          => $validated_params->{user},
        new_well_name => undef,
        new_plate_id  => undef,
    });

    return $well;
}

sub pspec_checkout_well_barcode_list{
    return {
        barcode_list      => { validate => 'well_barcode' },
        user              => { validate => 'existing_user' },
    }
}

sub checkout_well_barcode_list{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_checkout_well_barcode_list);

    # FIXME: check barcode is "in_freezer" before doing checkout? or is this too strict

    my $barcode_list = [];
    if (ref $validated_params->{barcode_list} eq ref []){
        $barcode_list = $validated_params->{barcode_list};
    }
    else{
        $barcode_list = [ $validated_params->{barcode_list} ];
    }

    my @messages;

    foreach my $barcode (@$barcode_list){
        DEBUG("checking out barcode $barcode");
        my $well = $model->retrieve_well({ barcode => $barcode });
        my $orig_well_location = $well->as_string;

        $model->checkout_well_barcode({
            barcode   => $barcode,
            user      => $validated_params->{user},
        });

        push @messages, "Barcode $barcode checked out from well $orig_well_location";
    }

    return \@messages;
}

sub pspec_do_picklist_checkout{
    return {
        id    => { validate => 'integer' },
        user  => { validate => 'existing_user' },
    };
}

sub do_picklist_checkout{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_do_picklist_checkout);
    my $list = $model->retrieve_fp_picking_list({ id => $validated_params->{id} });

    DEBUG("Retrieved pick list ".$list->id);

    my @barcodes = map { $_->barcode } $list->picked_well_barcodes;

    my $messages = checkout_well_barcode_list($model, {
        barcode_list => \@barcodes,
        user         => $validated_params->{user},
    });

    # deactivate picking list
    $list->update({ active => 0 });

    DEBUG("pick list deactivated");
    push @$messages, "FP picking list ".$list->id." is now inactive";

    return $messages;
}

# We may freeze back into multiple qc_wells so we need parent barcode
# and array of params for each qc well
sub pspec_freeze_back_piq_barcode{
    return {
        barcode             => { validate => 'well_barcode' },
        number_of_doublings => { validate => 'integer' },
        qc_well_params      => { },
    }
}

sub pspec_freeze_back_fp_barcode{
    return {
        barcode         => { validate => 'well_barcode' },
        qc_well_params  => { },
    }
}

sub pspec_piq_expand_freeze_back_barcode{
    return {
        barcode         => { validate => 'well_barcode' },
        qc_well_params  => { },
    }
}

# Each set of qc well params is validated as per this spec
sub pspec_freeze_back_barcode_common{
    # params common to both fp and piq freeze back
    return {
        barcode           => { validate => 'well_barcode' },
        number_of_wells   => { validate => 'integer' },
        lab_number        => { validate => 'non_empty_string', optional => 1 },
        qc_piq_plate_name => { validate => 'plate_name' },
        qc_piq_well_name  => { validate => 'well_name' },
        user              => { validate => 'existing_user' },
    }
}

sub pspec_freeze_back_piq_barcode_qc_well{
    my $common_params = pspec_freeze_back_barcode_common;
    return {
        %$common_params,
        qc_piq_well_barcode => { validate => 'non_empty_string' },
    }
}

sub pspec_freeze_back_fp_barcode_qc_well{
    return pspec_freeze_back_barcode_common;
}

sub freeze_back_fp_barcode{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_freeze_back_fp_barcode, ignore_unknown => 1);

    my $barcode = $validated_params->{barcode};

    # Fetch FP well_barcode
    my $bc_well = _fetch_barcode_for_freeze_back($model,$barcode,'checked_out');

    my @freeze_back_outputs;
    foreach my $qc_well_params (@{ $validated_params->{qc_well_params} }){
        $validated_params = $model->check_params($qc_well_params, pspec_freeze_back_fp_barcode_qc_well);

        # Fetch QC PIQ plate or create it if not found
        my $qc_plate = _fetch_qc_piq_for_freeze_back($model,$bc_well,$validated_params);

        # Create the QC PIQ well
        my $process_data = {
            type        => 'dist_qc',
            input_wells => [ { id => $bc_well->id } ],
        };
        if($validated_params->{lab_number}){
            $process_data->{lab_number} = $validated_params->{lab_number};
        }

        my ($qc_well,$tmp_piq_plate) = _create_qc_piq_and_child_wells($model, $qc_plate, $bc_well, $process_data, $validated_params);
        push @freeze_back_outputs, {
            qc_well => $qc_well,
            tmp_piq_plate => $tmp_piq_plate,
        };
    }
    die "No QC wells provided for freeze back" unless @freeze_back_outputs;
    return @freeze_back_outputs;
}

sub piq_expand_freeze_back_barcode{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_piq_expand_freeze_back_barcode, ignore_unknown => 1);

    my $barcode = $validated_params->{barcode};

    # Fetch well_barcode
    my $bc_well = _fetch_barcode_for_freeze_back($model,$barcode,'checked_out');

    my @freeze_back_outputs;
    foreach my $qc_well_params (@{ $validated_params->{qc_well_params} }){
        $validated_params = $model->check_params($qc_well_params, pspec_freeze_back_barcode_common);

        # Fetch QC PIQ plate or create it if not found
        my $qc_plate = _fetch_qc_piq_for_freeze_back($model,$bc_well,$validated_params);

        # Create the QC PIQ well
        my $process_data = {
            type        => 'rearray',
            input_wells => [ { id => $bc_well->id } ],
        };
        if($validated_params->{lab_number}){
            $process_data->{lab_number} = $validated_params->{lab_number};
        }

        my ($qc_well,$tmp_piq_plate) = _create_qc_piq_and_child_wells($model, $qc_plate, $bc_well, $process_data, $validated_params);
        push @freeze_back_outputs, {
            qc_well => $qc_well,
            tmp_piq_plate => $tmp_piq_plate,
        };
    }
    return @freeze_back_outputs;
}

sub freeze_back_piq_barcode{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_freeze_back_piq_barcode, ignore_unknown => 1);

    my $barcode = $validated_params->{barcode};

    my $bc_well = _fetch_barcode_for_freeze_back($model,$barcode,'doubling_in_progress');

    # Find the incomplete doubling process, get the oxygen condition
    # then delete the process
    my $incomplete_doubling = _get_incomplete_doubling_process($bc_well);

    my $oxygen_condition = $incomplete_doubling->get_parameter_value('oxygen_condition');
    DEBUG "Deleting incomplete doubling process with oxygen condition $oxygen_condition";
    $model->delete_process({ id => $incomplete_doubling->id });

    my $number_of_doublings = $validated_params->{number_of_doublings};

    my @freeze_back_outputs;
    foreach my $qc_well_params (@{ $validated_params->{qc_well_params} }){
        # check we have some info about this QC well. If not we can skip it.
        # this allows user to create fewer than the default number of subclones
        my $well_defined = grep { $qc_well_params->{$_} }
                           qw(number_of_wells lab_number qc_piq_plate_name qc_piq_well_name qc_piq_well_barcode);
        next unless $well_defined;

        $validated_params = $model->check_params($qc_well_params, pspec_freeze_back_piq_barcode_qc_well);

        my $qc_plate = _fetch_qc_piq_for_freeze_back($model,$bc_well,$validated_params);

        # Create the QC PIQ well as output of a new doubling process
        my $process_data = {
            type             => 'doubling',
            input_wells      => [ { id => $bc_well->id } ],
            oxygen_condition => $oxygen_condition,
            doublings        => $number_of_doublings,
        };
        if($validated_params->{lab_number}){
            $process_data->{lab_number} = $validated_params->{lab_number};
        }

        my ($qc_well,$tmp_piq_plate) = _create_qc_piq_and_child_wells($model, $qc_plate, $bc_well, $process_data, $validated_params);

        # Add barcode to the QC PIQ well
        # FIXME: what should the barcode state be for the QC PIQ pellet
        $model->create_well_barcode({
            barcode => $validated_params->{qc_piq_well_barcode},
            well_id => $qc_well->id,
            state   => 'in_freezer',
        });

        push @freeze_back_outputs, {
            qc_well => $qc_well,
            tmp_piq_plate => $tmp_piq_plate,
        };
    }
    return @freeze_back_outputs;
}

sub _fetch_barcode_for_freeze_back{
    my ($model, $barcode, $expected_state) = @_;

    my $well = $model->retrieve_well_barcode({
        barcode => $barcode,
    });

    die "Barcode $barcode not found\n" unless $well;

    my $state = $well->barcode_state->id;
    unless ($state eq $expected_state){
        die "Cannot freeze back barcode $barcode as it is not $expected_state (state: $state)\n"
    }

    return $well;
}

sub _fetch_qc_piq_for_freeze_back{
    my ($model, $well, $validated_params) = @_;

    my $type = 'PIQ';
    if ($well->plate_type eq 'SFP') {
        $type = 'S_PIQ';
    }

    my $qc_plate = $model->schema->resultset('Plate')->search({
        name => $validated_params->{qc_piq_plate_name},
    })->first;

    if($qc_plate){
        # Make sure the well we want to create does not already exist
        my $qc_piq_well = $qc_plate->search_related('wells',
            { name => $validated_params->{qc_piq_well_name} }
        )->first;
        die "Well ".$qc_piq_well->name." already exists on plate ".$qc_plate->as_string if $qc_piq_well;
    }
    else{
        $qc_plate = $model->create_plate({
            name       => $validated_params->{qc_piq_plate_name},
            species    => $well->last_known_plate->species_id,
            type       => $type,
            created_by => $validated_params->{user},
        });
    }

    return $qc_plate;
}

sub _get_incomplete_doubling_process{
    my ($bc_well) = @_;

    my $barcode = $bc_well->barcode;
    my $incomplete_doubling;
    foreach my $process (_get_doubling_processes($bc_well)){
        my @output_wells = $process->output_wells;
        next if @output_wells;

        if($incomplete_doubling){
            die "More than one incomplete doubling process found for barcode $barcode";
        }
        $incomplete_doubling = $process;
    }

    die "Could not find incomplete doubling process for barcode $barcode" unless $incomplete_doubling;

    return $incomplete_doubling;
}

sub _get_doubling_processes{
    my ($bc_well) = @_;
    my @doubling_processes;
    foreach my $process ($bc_well->child_processes){
        next unless $process->type_id eq 'doubling';
        push @doubling_processes, $process;
    }
    return @doubling_processes;
}

sub _create_qc_piq_and_child_wells{
    my ($model, $qc_plate, $bc_well, $process_data, $validated_params) = @_;

    my $wells_96 = &generate_96_well_annotations;

    my $qc_well = $model->create_well({
        plate_name   => $qc_plate->name,
        well_name    => $validated_params->{qc_piq_well_name},
        created_by   => $validated_params->{user},
        process_data => $process_data,
    });

    # Create a well accepted override with value "FALSE"
    # to prevent these wells being automatically released
    # when they pass QC
    # This is due to requirments change in April 2016
    $model->create_well_accepted_override({
       well_id    => $qc_well->id,
       created_by => $validated_params->{user},
       accepted   => 0,
    });

    # Create temporary plate containing daughter PIQ wells
    my @child_well_data;
    foreach my $num (1..$validated_params->{number_of_wells}){
        my $temp_well_name = $wells_96->{$num};
        my $well_data = {
            well_name => $temp_well_name,
            parent_plate => $qc_plate->name,
            parent_plate_version => $qc_plate->version,
            parent_well => $qc_well->name,
            process_type => 'rearray',
        };

        if($validated_params->{lab_number}){
            $well_data->{lab_number} = $validated_params->{lab_number}."_$num";
        }

        push @child_well_data, $well_data;
    }

    my $tmp_piq_plate;

    # In some cases there are no child wells
    if(@child_well_data){
        my $random_name = $model->random_plate_name({ prefix => 'TMP_'. $qc_plate->type_id .'_' });
        $tmp_piq_plate = $model->create_plate({
            name       => $random_name,
            species    => $bc_well->last_known_plate->species_id,
            type       => $qc_plate->type_id,
            created_by => $validated_params->{user},
            wells      => \@child_well_data,
            is_virtual => 1,
        });
    }

    # Set original barcode's status to 'frozen_back'
    $model->update_well_barcode({
        barcode   => $validated_params->{barcode},
        new_state => 'frozen_back',
        user      => $validated_params->{user},
        new_plate_id  => undef,
        new_well_name => undef,
    });

    return ($qc_well, $tmp_piq_plate);
}

sub pspec_discard_well_barcode{
    return {
        barcode  => { validate => 'well_barcode' },
        user     => { validate => 'existing_user' },
        reason   => { validate => 'non_empty_string', optional => 1 },
    };
}

sub discard_well_barcode{
    my ($model, $params) = @_;
      # input: model, {barcode, user, reason}

    my $validated_params = $model->check_params($params, pspec_discard_well_barcode);

      # set well barcode state to "discarded" (use update_well_barcode from model plugin)
    my $well = $model->update_well_barcode({
        barcode   => $validated_params->{barcode},
        new_state => 'discarded',
        user      => $validated_params->{user},
        comment   => $validated_params->{reason},
        new_plate_id  => undef,
        new_well_name => undef,
    });

    return $well;
}

sub pspec_send_out_well_barcode{
    return {
        barcode  => { validate => 'well_barcode' },
        user     => { validate => 'existing_user' },
        comment  => { validate => 'non_empty_string', optional => 1 },
    };
}

sub send_out_well_barcode{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_send_out_well_barcode);

    my $well = $model->retrieve_well_barcode({ barcode => $validated_params->{barcode} });
    my $plate_type = $well->last_known_plate->type_id;

    die "Cannot send out well from $plate_type plate (must be PIQ)\n" unless $plate_type eq "PIQ";

    $well = $model->update_well_barcode({
        barcode   => $validated_params->{barcode},
        new_state => 'sent_out',
        user      => $validated_params->{user},
        comment   => $validated_params->{comment},
        new_well_name => undef,
        new_plate_id  => undef,
    });

    return $well;
}

sub pspec_start_doubling_well_barcode{
    return {
        barcode  => { validate => 'well_barcode' },
        user     => { validate => 'existing_user' },
        oxygen_condition => { validate => 'oxygen_condition' },
    };
}

sub start_doubling_well_barcode{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_start_doubling_well_barcode);

    my $well = $model->retrieve_well_barcode({ barcode => $validated_params->{barcode} });
    my $plate_type = $well->plate_type;

    die "Cannot start doubling well from $plate_type plate (must be PIQ)\n" unless $plate_type eq "PIQ";

    $well = $model->update_well_barcode({
        barcode   => $validated_params->{barcode},
        new_state => 'doubling_in_progress',
        user      => $validated_params->{user},
        well_name => undef,
        plate_id  => undef,
    });

    # Start new output process from well
    # process will not have any output wells yet - will this cause problems?
    my $process = $model->create_process({
        input_wells => [ { id => $well->id }],
        type        => 'doubling',
        oxygen_condition => $validated_params->{oxygen_condition},
    });

    return $well;
}

sub pspec_create_barcoded_plate{
    return{
        plate_name       => { validate => 'plate_name'},
        barcode_for_well => { validate => 'hashref' },
        user             => { validate => 'existing_user' },
        comment          => { validate => 'non_empty_string', optional => 1 },
        new_state        => { validate => 'non_empty_string', optional => 1, default => 'in_freezer' },
    }
}

sub create_barcoded_plate{
    my ($model,$params) = @_;

    my $validated_params = $model->check_params($params, pspec_create_barcoded_plate);

    # Create the new plate with existing barcodes moved to it
    my $barcode_for_well = $validated_params->{barcode_for_well};
    my $plate_type;
    my $plate_species;
    my @list_messages;
    my $new_plate;

    foreach my $well_name (keys %$barcode_for_well){
        my $barcode = $barcode_for_well->{$well_name};

        my $well = $model->retrieve_well({ barcode => $barcode })
            or die "Method create_barcoded_plate cannot be used to add unknown barcode $barcode to plate ".$validated_params->{new_plate_name} ;

        # Some sanity checking to make sure we don't put different types and species on same plate
        _check_consistent_type(\$plate_type,$well);
        _check_consistent_species(\$plate_species,$well);

        unless($new_plate){
            my $create_params = {
                name       => $validated_params->{plate_name},
                species    => $plate_species,
                type       => $plate_type,
                created_by => $validated_params->{user},
            };

            if($validated_params->{comment}){
                $create_params->{comments} = [
                    {
                        comment_text => $validated_params->{comment},
                        created_by   => $validated_params->{user},
                    },
                ]
            }

            $new_plate = $model->create_plate($create_params);
        }

        $model->update_well_barcode({
            barcode   => $barcode,
            new_state => $validated_params->{new_state},
            new_well_name => $well_name,
            new_plate_id  => $new_plate->id,
            user          => $validated_params->{user},
            comment       => 'barcode moved to newly created plate',
        });

        push @list_messages, {
            'well_name' => $well_name,
            'error'     => 0,
            'message'   => "Barcode $barcode moved from ".$well->as_string,
        };
    }

    return wantarray ? ($new_plate, \@list_messages) : $new_plate;
}

sub pspec_update_barcoded_plate{
    return{
        plate_name       => { validate => 'existing_plate_name'},
        barcode_for_well => { validate => 'hashref' },
        user             => { validate => 'existing_user' },
        comment          => { validate => 'non_empty_string', optional => 1 },
        new_state        => { validate => 'non_empty_string', optional => 1, default => 'in_freezer' },
    };
}

sub update_barcoded_plate{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_update_barcoded_plate);

    my $plate = $model->retrieve_plate({ name => $validated_params->{plate_name} });
    my $barcode_for_well = $validated_params->{barcode_for_well};
    my $plate_type = $plate->type_id;
    my $plate_species = $plate->species_id;

    my @list_messages;

    # Identify barcodes which were on the orig plate but are not in the new scan
    # Set these as checked_out and remove from plate
    my @barcodes_on_orig_plate = grep { $_ } map { $_->barcode } $plate->wells;
    my %barcodes_on_new_plate = map { $_ => 1 } values %{ $validated_params->{barcode_for_well} };
    my @barcodes_to_remove = grep { !$barcodes_on_new_plate{$_} } @barcodes_on_orig_plate;
    foreach my $remove (@barcodes_to_remove){
        my $orig_well = $model->retrieve_well({ barcode => $remove });
        my $orig_well_name = $orig_well->as_string;
        $model->update_well_barcode({
            barcode       => $remove,
            new_state     => 'checked_out',
            new_well_name => undef,
            new_plate_id  => undef,
            user          => $validated_params->{user},
            comment       => 'barcode not on latest scan of plate '.$plate->name,
        });

        push @list_messages, {
            'well_name' => '',
            'error'     => 0,
            'message'   => "Barcode $remove removed from ".$orig_well_name,
        };
    }

    foreach my $well_name (keys %$barcode_for_well){
        my $barcode = $barcode_for_well->{$well_name};

        # If the well does not have a barcode just leave it as is
        next unless $barcode;

        my $orig_well = $model->retrieve_well({ barcode => $barcode });
        # Check if the barcode has moved from existing location
        if($orig_well->name ne $well_name or $orig_well->plate_id != $plate->id){

            my $orig_well_name = $orig_well->as_string;
            $model->update_well_barcode({
                barcode       => $barcode,
                new_state     => $validated_params->{new_state},
                new_well_name => $well_name,
                new_plate_id  => $plate->id,
                displace_existing => 1,
                user          => $validated_params->{user},
                comment       => 'barcode has new location in latest scan of plate '.$plate->name,
            });

            push @list_messages, {
                'well_name' => $well_name,
                'error'     => 0,
                'message'   => "Barcode $barcode moved from $orig_well_name",
            };
        }
    }

    return wantarray ? ($plate, \@list_messages) : $plate;
}

sub _check_consistent_type{
    my ($plate_type, $well) = @_;
    my $type = $well->plate_type;
    $$plate_type ||= $type;
    die "All wells on plate must be of the same type" unless $type eq $$plate_type;
    return;
}

sub _check_consistent_species{
    my ($plate_species, $well) = @_;
    my $species = $well->plate_species->id;
    $$plate_species ||= $species;
    die "All wells on plate must have same species" unless $species eq $$plate_species;
    return;
}

# Input: csv file of barcode locations, plate name
sub pspec_upload_plate_scan{
    return{
        new_plate_name      => { validate => 'plate_name', optional => 1 },
        existing_plate_name => { validate => 'existing_plate_name', optional => 1 },
        new_state           => { validate => 'non_empty_string', optional => 1 },
        species             => { validate => 'existing_species' },
        user                => { validate => 'existing_user' },
        comment             => { validate => 'non_empty_string', optional => 1 },
        csv_fh              => { validate => 'file_handle'},
        REQUIRE_SOME        => { new_or_existing_plate => [ 1, qw(new_plate_name existing_plate_name)]}
    }
}

# If uploaded barcodes exactly match those on plate then do nothing
# If existing wells have no barcodes then add barcodes to them (if some wells already have barcodes and some don't this is an error...)
# In all other cases rename plate with version number and create new plate using create_barcoded_plate_copy
# Probably best to discard previously unseen barcodes, e.g. empty tubes, before creating copy (FP only - this should not happen in PIQ)
# Any barcode seen in scan should have barcode state updated to 'in_freezer'
sub upload_plate_scan{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_upload_plate_scan);

    my $csv_data = _parse_plate_well_barcodes_csv_file($validated_params->{csv_fh});

    my $new_plate;
    my $success = 0;
    my @list_messages = ();

    # Brand new plate - create it using well->barcode mapping
    if($validated_params->{new_plate_name}){

        DEBUG 'Creating new plate '.$validated_params->{new_plate_name};

        my $plate_create_params = {
            plate_name => $validated_params->{new_plate_name},
            barcode_for_well => $csv_data,
            new_state  => 'in_freezer',
            user       => $validated_params->{user},
            comment    => $validated_params->{comment},
        };
        $new_plate = create_barcoded_plate($model,$plate_create_params);
    }
    else{
        my $existing_plate = $model->retrieve_plate({
            name => $validated_params->{existing_plate_name}
        });

        my @barcoded_wells = grep { $_->barcode } $existing_plate->wells;

        if(@barcoded_wells){
            # Error if some but not all wells have barcodes
            my $barcoded_count = scalar @barcoded_wells;
            my $well_count = scalar $existing_plate->wells;

            unless ($barcoded_count == $well_count){
                die "Plate ".$existing_plate->name
                    ." has $well_count wells but only $barcoded_count are barcoded";
            }

            # All wells on plate already have barcodes so this is a rescan

            # Remove extra barcodes if appropriate
            if ($existing_plate->type_id eq "FP"){
                _remove_empty_tube_barcodes($model,$existing_plate,$csv_data,\@list_messages);
            }

            # If well barcodes have not changed at all do nothing
            if(_csv_barcodes_match_existing($existing_plate, $csv_data)){

                DEBUG "Uploaded barcodes match existing plate - no action needed";

                push @list_messages, {
                    'well_name' => '_',
                    'error' => 0,
                    'message' => 'Uploaded barcodes match existing plate. No changes made.'
                };
                return ($existing_plate, \@list_messages);
            }

            # Otherwise update plate
            my $plate_update_params = {
                slice_def($validated_params, qw(user comment))
            };
            $plate_update_params->{barcode_for_well} = $csv_data;
            $plate_update_params->{plate_name} = $validated_params->{existing_plate_name};
            $plate_update_params->{new_state} = 'in_freezer';
            my $messages;
            ($new_plate, $messages) = update_barcoded_plate($model, $plate_update_params);

            DEBUG "Plate layout updated for ".$new_plate->name;

            push @list_messages, {
                'well_name' => '_',
                'error' => 0,
                'message' => 'Plate layout updated for '.$new_plate->name,
            };

            push @list_messages, @$messages;
        }
        else{

            DEBUG "Adding barcodes to existing wells";
            # These are new barcodes to add to wells that have been created manually in LIMS2
            # Method returns list of messages
            push @list_messages, _add_csv_barcodes_to_plate($model, $existing_plate, $csv_data);
        }
    }

    return ($new_plate, \@list_messages);
}

# Input: csv file of barcode locations, plate name
sub pspec_upload_qc_plate{
    return{
        new_plate_name      => { validate => 'plate_name' },
        species             => { validate => 'existing_species' },
        user                => { validate => 'existing_user' },
        comment             => { validate => 'non_empty_string', optional => 1 },
        csv_fh              => { validate => 'file_handle'},
        plate_type          => { validate => 'existing_plate_type' },
        process_type        => { validate => 'existing_process_type' },
        doublings           => { validate => 'integer', optional => 1 },
    }
}

# Use this method to create a plate for QC using barcodes which
# are no longer "in_freezer", e.g. when material comes back from CGAP for QC.
# The new plate will not have barcodes on it. The wells on the new plate will
# be parented by the well that is linked to the barcode in LIMS2
sub upload_qc_plate{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_upload_qc_plate);

    my $csv_data = _parse_plate_well_barcodes_csv_file($validated_params->{csv_fh});

    my @wells;

    foreach my $well_name (keys %{ $csv_data }){
        my $barcode = $csv_data->{$well_name};
        my $well_barcode;
        try{
            $well_barcode = $model->retrieve_well({
                barcode => $barcode,
            });
        }
        unless($well_barcode){
            die "Barcode $barcode not found\n";
        }

        if($well_barcode->barcode_state->id eq 'in_freezer' ){
            # This check might be too strict?
            die "Barcode $barcode state: in_freezer."
                ."QC plates can only be created for wells which are no longer in the freezer\n";
        }

        unless($well_barcode->plate_species->id eq $validated_params->{species}){
            die "Barcode $barcode does not have the expected species (expected: "
                .$validated_params->{species}.", got: ".$well_barcode->plate_species->id;
        }

        my $well_data = {
            well_name      => $well_name,
            parent_well_id => $well_barcode->id,
            process_type   => $validated_params->{process_type},
        };

        if($validated_params->{process_type} eq 'ms_qc'){
            # find the oxygen condition of doubling process
            # linked to barcoded well
            my @processes = _get_doubling_processes($well_barcode);
            my $oxygen_condition;
            foreach my $process (@processes){
                my $this_ox_condition = $process->get_parameter_value('oxygen_condition');
                if($oxygen_condition and $oxygen_condition ne $this_ox_condition){
                    my $well = $well_barcode;
                    die "Inconsistent oxygen conditions on doubling processes for input well $well";
                }
                $oxygen_condition = $this_ox_condition;
            }

            # Add this along with the doubling number to well_data hash
            $well_data->{oxygen_condition} = $oxygen_condition;
            $well_data->{doublings} = $validated_params->{doublings};
        }

        DEBUG "Well $well_name has parent well ".$well_barcode->as_string;
        push @wells, $well_data;
    }

    my $plate = $model->create_plate({
        name       => $validated_params->{new_plate_name},
        species    => $validated_params->{species},
        type       => $validated_params->{plate_type},
        created_by => $validated_params->{user},
        wells      => \@wells,
        is_virtual => 0,
    });

    return $plate;
}

sub _remove_empty_tube_barcodes{
    my($model,$existing_plate,$csv_data,$list_messages) = @_;
    DEBUG "Removing any extra barcodes from upload";
    my $removed_count = 0;
    my %existing_barcode_for_well = map { $_->name => $_->barcode } $existing_plate->wells;
    foreach my $well_name (keys %$csv_data){
        unless (exists $existing_barcode_for_well{$well_name}){
            my $barcode = $csv_data->{$well_name};
            my $well_barcode = $model->schema->resultset('Well')->find({ barcode => $barcode });
            unless($well_barcode){
                delete $csv_data->{$well_name};
                $removed_count++;
                push @$list_messages, {
                    'well_name' => $well_name,
                    'error' => 2,
                    'message' => 'A barcode <' . $barcode . '> has been scanned for a location where no tube was present, ignoring.'
                };
            }
        }
    }
    DEBUG "$removed_count extra barcodes removed";
    return;
}

sub _csv_barcodes_match_existing{
    my ($plate, $barcode_for_well) = @_;

    my %existing_barcode_for_well = map { $_->name => $_->barcode } $plate->wells;

    my $well_count = scalar $plate->wells;
    my $uploaded_well_count = scalar keys %$barcode_for_well;
    if($uploaded_well_count != $well_count){
        DEBUG "Found $well_count existing wells on plate and $uploaded_well_count wells in csv file";
        return 0;
    }

    # For each csv well-barcode see if it is the same as plate
    foreach my $well_name (keys %$barcode_for_well){
        my $existing_barcode = $existing_barcode_for_well{$well_name} || "";
        if( $barcode_for_well->{$well_name} ne $existing_barcode ){
            return 0;
        }
    }

    return 1;
}

# Method factored out of LIMS2::WebApp::Controller::User::PlateEdit
# update_plate_well_barcodes
sub _add_csv_barcodes_to_plate{
    my ($model, $plate, $barcode_for_well) = @_;

    my @list_messages;

    my $accepted_barcode_for_well_id = {};

    my %well_list = map { $_->name => $_ } $plate->wells;
    my @ordered_well_keys = sort keys %well_list;

    # check each well on the plate in alphabetic order
    for my $well_name ( @ordered_well_keys ) {
        my $well = $well_list{ $well_name };

        # all well names should have a barcode in the list
        unless ( exists $barcode_for_well->{ $well_name } ) {
            push ( @list_messages, {
                'well_name' => $well_name,
                'error' => 1,
                'message' => 'A barcode is missing from the uploaded file for this tube and needs to be included.'
            } );
            next;
        }

        # check for unsuccessful scan text
        if ( $barcode_for_well->{ $well_name } eq 'No Read' ) {
            push ( @list_messages, {
                'well_name' => $well_name,
                'error' => 1,
                'message' => 'Expected a tube in this location but the barcode scanner failed to read one, please re-scan the tube rack.'
            } );
            next;
        }

        # Store well ID to barcode mapping to add after upload has been fully checked for errors
        $accepted_barcode_for_well_id->{ $well->id } = $barcode_for_well->{ $well_name };

        push ( @list_messages, {
            'well_name' => $well_name,
            'error' => 0,
            'message' => 'This tube barcode will be set to the uploaded value <' . $barcode_for_well->{ $well_name } . '>.'
        } );
    }

    # check here to see if we have scanned more barcodes than there are tubes in the rack
    # this is Ok, lab may leave whole 96 tubes rather than risk compromising sterility
    # by moving some in or out
    my @uploaded_well_names = sort keys %$barcode_for_well;

    for my $uploaded_well_name ( @uploaded_well_names ) {

        next if $barcode_for_well->{ $uploaded_well_name } eq 'No Read';

        unless ( exists $well_list{ $uploaded_well_name } ) {

            # check the barcode is not already in LIMS2 as it should be an empty tube
            my $existing_barcode = $model->schema->resultset('Well')->search({
                barcode => $barcode_for_well->{$uploaded_well_name}
            })->first;

            if($existing_barcode){
                push ( @list_messages, {
                    'well_name' => $uploaded_well_name,
                    'error' => 1,
                    'message' => 'A barcode <' . $barcode_for_well->{ $uploaded_well_name } . '> has been scanned for a location where no tube was present. '
                                 .'This barcode already exists at '.$existing_barcode->well->as_string,
                } );
            }
            else{
                push ( @list_messages, {
                    'well_name' => $uploaded_well_name,
                    'error' => 2,
                    'message' => 'A barcode <' . $barcode_for_well->{ $uploaded_well_name } . '> has been scanned for a location where no tube was present, ignoring.'
                } );
            }
            next;
        }
    }

    # Check for type 1 errors before adding barcodes
    my $errors_found = grep { $_->{error} == 1 } @list_messages;
    if ($errors_found){
        DEBUG "$errors_found errors found when processing barcodes for plate ".$plate->name;
        DEBUG "No barcodes will be added";
    }
    else{
        foreach my $well_id (keys %$accepted_barcode_for_well_id){
            $model->create_well_barcode({
                well_id => $well_id,
                barcode => $accepted_barcode_for_well_id->{ $well_id },
                state   => 'in_freezer',
            });
        }
    }

    return @list_messages;
}

sub _parse_plate_well_barcodes_csv_file {
    my ( $fh ) = @_;

    my $csv_data = {};

    my $csv = Text::CSV_XS->new( { blank_is_undef => 1, allow_whitespace => 1 } );

    my $line_num = 0;
    while ( my $line = $csv->getline( $fh )) {
        $line_num++;
        if($line_num == 1){
            # Skip if first line looks like a header
            # NB: we are still assuming the well is in first col and barcode in second
            if($line->[0]=~/well/){
                next;
            }
        }
        my $curr_well = $line->[0];
        my $curr_barcode = $line->[1];

        # Skip if no data on line
        next unless ($curr_well or $curr_barcode);

        # Error if barcode but no well specified
        die "No well name provided for barcode $curr_barcode at line $line_num"
            unless $curr_well;
        # If well specified but no barcode we store this. It could be an error or could
        # be ignored so let the calling method handle this.

        $csv_data->{ $curr_well } = $curr_barcode;
    }

    unless ( keys %$csv_data > 0 ) {
        die 'Error encountered while parsing plate well barcodes file, no data found in file';
    }

    return $csv_data;
}

1;