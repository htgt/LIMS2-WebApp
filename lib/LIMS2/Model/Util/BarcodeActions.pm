package LIMS2::Model::Util::BarcodeActions;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
              checkout_well_barcode
              discard_well_barcode
              freeze_back_barcode
              add_barcodes_to_wells
              upload_plate_scan
              send_out_well_barcode
          )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( uniq any );
use LIMS2::Exception;
use TryCatch;
use Hash::MoreUtils qw( slice_def );

# Input: model, params from web form, state to create new barcodes with
# Where form sends params named "barcode_<well_id>"
# e.g. <input type="text" name="barcode_[% well.id %]">
sub add_barcodes_to_wells{
    my ($model, $params, $state) = @_;

    my @messages;
    my @well_ids = grep { $_ } map { $_ =~ /barcode_([0-9]+)$/ } keys %{$params};

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

        my $existing_barcode = $model->schema->resultset('WellBarcode')->search({
            barcode => $barcode,
        })->first;

        if($existing_barcode){
            die "Barcode $barcode entered for $well_name already exists at ".$existing_barcode->well->as_string;
        }

        my $well_barcode = $model->create_well_barcode({
            well_id => $well_id,
            barcode => $barcode,
            state   => $state,
        });

        push @messages, "Barcode ".$well_barcode->barcode
                        ." added to well $well_name"
                        ." with state ".$well_barcode->barcode_state->id;
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

    my $well_bc = $model->update_well_barcode({
        barcode   => $validated_params->{barcode},
        new_state => 'checked_out',
        user      => $validated_params->{user},
    });

    my $plate = $well_bc->well->plate;
    unless($plate->is_virtual){
        remove_well_barcodes_from_plate(
            $model,
            [ $validated_params->{barcode} ],
            $plate,
            $validated_params->{user}
        );
    }

    return $well_bc;
}

sub pspec_freeze_back_barcode{
    return {
        barcode           => { validate => 'well_barcode' },
        number_of_wells   => { validate => 'integer' },
        lab_number        => { validate => 'non_empty_string', optional => 1 },
        qc_piq_plate_name => { validate => 'plate_name' },
        qc_piq_well_name  => { validate => 'well_name' },
        user              => { validate => 'existing_user' },
    }
}

sub freeze_back_barcode{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_freeze_back_barcode, ignore_unknown => 1);

    my $barcode = $validated_params->{barcode};

    # Fetch FP well_barcode
    my $bc = $model->retrieve_well_barcode({
        barcode => $barcode,
    });
    my $fp_plate = $bc->well->plate;

    die "Barcode $barcode not found\n" unless $bc;

    my $state = $bc->barcode_state->id;
    unless ($state eq 'checked_out'){
        die "Cannot freeze back barcode $barcode as it is not checked_out (state: $state)\n"
    }

    # Fetch QC PIQ plate or create it if not found
    my $qc_plate = $model->schema->resultset('Plate')->search({
        name => $validated_params->{qc_piq_plate_name},
    })->first;

    if($qc_plate){
        # Make sure the well we want to create does not already exist
        my $qc_piq_well = $qc_plate->search_related('wells',
            { name => $validated_params->{qc_piq_well_name} }
        )->first;
        die "Well ".$qc_piq_well->name." already exists on plate ".$qc_plate->name if $qc_piq_well;
    }
    else{
        $qc_plate = $model->create_plate({
            name       => $validated_params->{qc_piq_plate_name},
            species    => $bc->well->plate->species_id,
            type       => 'PIQ',
            created_by => $validated_params->{user},
        });
    }

    # Create the QC PIQ well
    my $process_data = {
        type        => 'dist_qc',
        input_wells => [ { id => $bc->well->id } ],
    };
    if($validated_params->{lab_number}){
        $process_data->{lab_number} = $validated_params->{lab_number};
    }

    my $qc_well = $model->create_well({
        plate_name   => $qc_plate->name,
        well_name    => $validated_params->{qc_piq_well_name},
        created_by   => $validated_params->{user},
        process_data => $process_data,
    });

    # Create temporary plate containing daughter PIQ wells
    my @child_well_data;
    foreach my $num (1..$validated_params->{number_of_wells}){
        my $well_data = {
            well_name => sprintf("A%02d",$num),
            parent_plate => $qc_plate->name,
            parent_well => $qc_well->name,
            process_type => 'rearray',
        };

        if($validated_params->{lab_number}){
            $well_data->{lab_number} = $validated_params->{lab_number}."_$num";
        }

        push @child_well_data, $well_data;
    }

    my $tmp_piq_plate = $model->create_plate({
        name       => 'PIQ_'.$bc->well->as_string,
        species    => $bc->well->plate->species_id,
        type       => 'PIQ',
        created_by => $validated_params->{user},
        wells      => \@child_well_data,
        is_virtual => 1,
    });

    # Set FP well_status to 'frozen_back'
    $model->update_well_barcode({
        barcode   => $validated_params->{barcode},
        new_state => 'frozen_back',
        user      => $validated_params->{user},
    });

    # remove frozen_back barcode from FP plate (by creating new version)
    # unless well was already on a virtual plate
    unless($fp_plate->is_virtual){
        remove_well_barcodes_from_plate(
            $model,
            [ $barcode ],
            $fp_plate,
            $validated_params->{user}
        );
    }

    return $tmp_piq_plate;
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
    my $bc = $model->update_well_barcode({
        barcode   => $validated_params->{barcode},
        new_state => 'discarded',
        user      => $validated_params->{user},
        comment   => $validated_params->{reason},
    });

	  # find plate on which barcode well resides
    my $plate = $bc->well->plate;

	# remove_well_barcodes_from_plate(wells,plate,comment,user)
    # unless it was already on virtual plate
    my $new_plate = $plate;
    unless($plate->is_virtual){
        $new_plate = remove_well_barcodes_from_plate(
            $model,
            [ $validated_params->{barcode} ],
            $plate,
            $validated_params->{user}
        );
    }

    return $new_plate;
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

    # FIXME: check it is a PIQ plate
    my $well_barcode = $model->retrieve_well_barcode({ barcode => $validated_params->{barcode} });
    my $plate_type = $well_barcode->well->plate->type_id;

    die "Cannot send out well from $plate_type plate (must be PIQ)\n" unless $plate_type eq "PIQ";

    my $bc = $model->update_well_barcode({
        barcode   => $validated_params->{barcode},
        new_state => 'sent_out',
        user      => $validated_params->{user},
        comment   => $validated_params->{comment},
    });

    my $plate = $bc->well->plate;

    # remove_well_barcodes_from_plate(wells,plate,comment,user)
    # unless it was already on virtual plate
    my $new_plate = $plate;
    unless($plate->is_virtual){
        $new_plate = remove_well_barcodes_from_plate(
            $model,
            [ $validated_params->{barcode} ],
            $plate,
            $validated_params->{user}
        );
    }

    return $new_plate;
}

sub remove_well_barcodes_from_plate{
    my ($model, $barcodes, $plate, $user) = @_;

    # rename existing plate
    my $plate_name = $plate->name;
    my $versioned_name = rename_plate_with_version($model, $plate);

    # create new well name->barcode hash
    my %barcode_for_well;
    my @wells_without_barcode; # This is used in cases where well has no barcode
    foreach my $well ($plate->wells){
        if (my $bc = $well->well_barcode){
            my $barcode = $bc->barcode;

            # Skip barcode to be removed
            next if any { $_ eq $barcode } @$barcodes;

            $barcode_for_well{$well->name} = $barcode;
        }
        else{
            # Well has no barcode so store parent well details
            push @wells_without_barcode, $well;
        }
    }

    # create_barcoded_plate_copy
    my $comment = "Barcodes ".(join ", ", @$barcodes)." removed (previous version: $versioned_name)";
    my $new_plate = create_barcoded_plate_copy(
        $model,
        {
            new_plate_name   => $plate_name,
            barcode_for_well => \%barcode_for_well,
            wells_without_barcode  => \@wells_without_barcode,
            user             => $user,
            comment          => $comment,
        }
    );
    return $new_plate;
}

sub add_well_barcodes_to_plate{
  # rename existing plate
  # create new well name->barcode hash
  # create_barcoded_plate_copy
}

sub move_well_barcodes_within_plate{
  # rename existing plate
  # create new well name->barcode hash
  # create_barcoded_plate_copy
}

sub move_well_barcodes_between_plates{
  # rename all existing plates changed
  # create new well name->barcode hash for each plate
  # create_barcoded_plate_copy for each plate
}

sub rename_plate_with_version{
    my ($model, $plate) = @_;

    my $plate_name = $plate->name;

    my @previous_versions = $model->schema->resultset('Plate')->search({
        name    => { like => $plate_name.'(v%)' },
        type_id => $plate->type,
    });

    my $max_version_num = 0;

    foreach my $plate_version (@previous_versions){
        my $name = $plate_version->name;
        my ($number) = ( $name =~ /\(v([0-9]+)\)$/g );
        if($number > $max_version_num){
            $max_version_num = $number;
        }
    }

    my $rename_to = $plate_name.'(v'.($max_version_num + 1).')';

    DEBUG "Renaming plate $plate_name to $rename_to";

    $plate->update({ name => $rename_to, is_virtual => 1 });
    return $plate->name;
}

sub pspec_create_barcoded_plate_copy{
    return{
        new_plate_name   => { validate => 'plate_name'},
        barcode_for_well => { validate => 'hashref' },
        user             => { validate => 'existing_user' },
        comment          => { validate => 'non_empty_string', optional => 1 },
        wells_without_barcode  => { optional => 1 },
        new_state        => { validate => 'non_empty_string', optional => 1 },
    }
}

# Generic method to create a new plate with barcodes at specified positions
# Each barcode's current well location will be identified
# New wells will be parented off them
# Process is always rearray
# well_barcode table will be updated (can provide comment for the barcode event table at this point if needed)
sub create_barcoded_plate_copy{
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_create_barcoded_plate_copy);

    # Create the new plate with new wells parented by wells that each barcode is currently linked to
    my @wells;
    my $barcode_for_well = $validated_params->{barcode_for_well};
    my $plate_type;
    my $plate_species;
    my $child_processes = {};

    # Handle parenting of barcoded wells
    foreach my $well (keys %$barcode_for_well){
        my $new_well_details = {};
        my $barcode = $barcode_for_well->{$well};
        # NB: if we are using input from full FP plate scan unknown barcodes (empty tubes)
        # need to be removed before this point
        # If unknown barcodes are seen on a PIQ plate this is an error
        my $bc = $model->retrieve_well_barcode({ barcode => $barcode })
            or die "Method create_barcoded_plate_copy cannot be used to add unknown barcode $barcode to plate ".$validated_params->{new_plate_name} ;

        $new_well_details->{well_name}    = $well;
        $new_well_details->{parent_well}  = $bc->well->name;
        $new_well_details->{parent_plate} = $bc->well->plate->name;
        $new_well_details->{accepted}     = $bc->well->accepted;
        $new_well_details->{process_type} = 'rearray';
        push @wells, $new_well_details;

        $child_processes->{$well} = [ $bc->well->child_processes ];

        # Some sanity checking
        my $species = $bc->well->plate->species_id;
        $plate_species ||= $species;
        die "All wells on plate must have same species" unless $species eq $plate_species;

        my $type = $bc->well->plate->type_id;
        $plate_type ||= $type;
        die "All wells on plate must be of the same type" unless $type eq $plate_type;
    }

    # Handle copy of wells which have no barcode, always e.g. A01->A01
    if ( $validated_params->{wells_without_barcode} ){
        foreach my $well ( @{ $validated_params->{wells_without_barcode} || [] } ){
            # FIXME: copy lab numbers
            my $new_well_details = {};
            $new_well_details->{well_name}    = $well->name;
            $new_well_details->{parent_well}  = $well->name;
            $new_well_details->{parent_plate} = $well->plate->name;
            $new_well_details->{accepted}     = $well->accepted;
            $new_well_details->{process_type} = 'rearray';

            push @wells, $new_well_details;

            $child_processes->{$well->name} = [ $well->child_processes ];

            # Some sanity checking
            my $species = $well->plate->species_id;
            $plate_species ||= $species;
            die "All wells on plate must have same species" unless $species eq $plate_species;

            my $type = $well->plate->type_id;
            $plate_type ||= $type;
            die "All wells on plate must be of the same type" unless $type eq $plate_type;
        }
    }

    my $create_params = {
        name       => $validated_params->{new_plate_name},
        species    => $plate_species,
        type       => $plate_type,
        created_by => $validated_params->{user},
        wells      => \@wells,
    };

    if($validated_params->{comment}){
        $create_params->{comments} = [
            {
                comment_text => $validated_params->{comment},
                created_by   => $validated_params->{user},
            },
        ]
    }

    my $new_plate = $model->create_plate($create_params);

    # Update well_barcodes to point barcodes to new wells
    foreach my $well (keys %$barcode_for_well){
        my $barcode = $barcode_for_well->{$well};
        my $new_well = $new_plate->search_related('wells',{name => $well})->first
            or die "Cannot find well $well on new plate ".$new_plate->name;
        my $update_params = {
            barcode     => $barcode,
            new_well_id => $new_well->id,
            user        => $validated_params->{user},
            comment     => "barcode moved to plate ".$new_plate->name,
        };

        if($validated_params->{new_state}){
            $update_params->{new_state} = $validated_params->{new_state};
        }
        $model->update_well_barcode($update_params);
    }

    # Update processes to use new wells as input
    foreach my $new_well ($new_plate->wells){
        my $processes = $child_processes->{$new_well->name};
        foreach my $process (@$processes){
            foreach my $process_input ($process->process_input_wells){
                $process_input->update({
                  well_id => $new_well->id,
                });
            }
        }
    }

    return $new_plate;
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
            slice_def($validated_params, qw(new_plate_name user comment))
        };
        $plate_create_params->{barcode_for_well} = $csv_data;
        $plate_create_params->{new_state} = 'in_freezer';
        $new_plate = create_barcoded_plate_copy($model,$plate_create_params);
    }
    else{
        my $existing_plate = $model->retrieve_plate({
            name => $validated_params->{existing_plate_name}
        });

        my @barcoded_wells = grep { $_->well_barcode } $existing_plate->wells;

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
                DEBUG "Removing any extra barcodes from upload";
                my $removed_count = 0;
                my %existing_barcode_for_well = map { $_->name => $_->well_barcode->barcode } $existing_plate->wells;
                foreach my $well_name (keys %$csv_data){
                    unless (exists $existing_barcode_for_well{$well_name}){
                        my $barcode = $csv_data->{$well_name};
                        my $well_barcode = $model->schema->resultset('WellBarcode')->search({
                            barcode => $barcode
                        })->first;
                        unless($well_barcode){
                            delete $csv_data->{$well_name};
                            $removed_count++;
                            push @list_messages, {
                                'well_name' => $well_name,
                                'error' => 2,
                                'message' => 'A barcode <' . $barcode . '> has been scanned for a location where no tube was present, ignoring.'
                            };
                        }
                    }
                }
                DEBUG "$removed_count extra barcodes removed";
            }

            # If well barcodes have not changed at all do nothing
            if(_csv_barcodes_match_existing($existing_plate, $csv_data)){

                DEBUG "Uploaded barcodes match existing plate - no action needed";

                push @list_messages, {
                    'well_name' => 'All',
                    'error' => 0,
                    'message' => 'Uploaded barcodes match existing plate. No changes made.'
                };
                return ($existing_plate, \@list_messages);
            }

            # Otherwise create new plate version

            my $versioned_name = rename_plate_with_version($model, $existing_plate);

            my $plate_create_params = {
                slice_def($validated_params, qw(user comment))
            };
            $plate_create_params->{barcode_for_well} = $csv_data;
            $plate_create_params->{new_plate_name} = $validated_params->{existing_plate_name};
            $plate_create_params->{new_state} = 'in_freezer';
            $new_plate = create_barcoded_plate_copy($model, $plate_create_params);

            DEBUG "New plate layout created for ".$new_plate->name;

            push @list_messages, {
                'well_name' => 'All',
                'error' => 0,
                'message' => 'New plate layout created for '.$new_plate->name,
            };

            # any barcodes remaining on existing plate should be set to 'checked_out'
            foreach my $well ($existing_plate->wells){
                my $well_bc = $well->well_barcode;
                next unless $well_bc;
                $model->update_well_barcode({
                    barcode     => $well_bc->barcode,
                    new_state   => 'checked_out',
                    user        => $validated_params->{user},
                    comment     => 'barcode not on latest scan of '.$new_plate->name,
                });

                push @list_messages, {
                    'well_name' => $well->name,
                    'error'     => 2,
                    'message'   => 'Barcode '.$well_bc->barcode.' has been checked_out as it is not present in latest scan',
                };
            }
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

sub _csv_barcodes_match_existing{
    my ($plate, $barcode_for_well) = @_;

    my %existing_barcode_for_well = map { $_->name => $_->well_barcode->barcode } $plate->wells;

    my $well_count = scalar $plate->wells;
    my $uploaded_well_count = scalar keys %$barcode_for_well;
    if($uploaded_well_count != $well_count){
        DEBUG "Found $well_count existing wells on plate and $uploaded_well_count wells in csv file";
        return 0;
    }

    # For each csv well-barcode see if it is the same as plate
    foreach my $well_name (keys %$barcode_for_well){
        if( $barcode_for_well->{$well_name} ne $existing_barcode_for_well{$well_name} ){
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
            my $existing_barcode = $model->schema->resultset('WellBarcode')->search({
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

    while ( my $line = $csv->getline( $fh )) {
        my @fields = split "," , $line;
        my $curr_well = $line->[0];
        my $curr_barcode = $line->[1];
        $csv_data->{ $curr_well } = $curr_barcode;
    }

    unless ( keys %$csv_data > 0 ) {
        die 'Error encountered while parsing plate well barcodes file, no data found in file';
    }

    return $csv_data;
}

1;
