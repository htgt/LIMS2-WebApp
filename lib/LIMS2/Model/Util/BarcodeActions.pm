package LIMS2::Model::Util::BarcodeActions;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
              discard_well_barcode
              freeze_back_barcode
              add_barcodes_to_wells
          )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( uniq any );
use LIMS2::Exception;
use TryCatch;

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

    die "Barcode $barcode not found\n" unless $bc;

    my $state = $bc->barcode_state->id;
    unless ($state eq 'checked_out'){
        die "Cannot freeze back barcode $barcode as it is not checked_out (state: $state)\n"
    }

    # Fetch QC PIQ plate or create it if not found
    my $qc_plate = $model->schema->resultset('Plate')->search({
        name => $validated_params->{qc_piq_plate_name},
    })->first;

    unless ($qc_plate){
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

    # FIXME: will die if well already exists on plate but would be better to
    # check and throw more meaningful error
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
    remove_well_barcodes_from_plate(
        $model,
        [ $validated_params->{barcode} ],
        $plate,
        $validated_params->{user}
    );

    return;
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
        name    => { like => $plate_name.'_v%' },
        type_id => $plate->type,
    });

    my $max_version_num = 0;

    foreach my $plate_version (@previous_versions){
        my $name = $plate_version->name;
        my ($number) = ( $name =~ /_v([0-9]+)$/g );
        if($number > $max_version_num){
            $max_version_num = $number;
        }
    }

    my $rename_to = $plate_name.'_v'.($max_version_num + 1);

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
    }
}

# Generic method to create a new plate with barcodes at specified positions
# Each barcode's current well location will be identified
# New wells will be parented off them
# Process is always rearray
# well_barcode table will be updated (can provide comment for the barcode event table at this point if needed)
sub create_barcoded_plate_copy{
    # input: new plate name, hash of well names to barcodes, user, comment(optional)
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_create_barcoded_plate_copy);

    # FIXME: Copy plate description??
    # FIXME: Copy plate comments??
    # probably not as new plate may combine wells for several parent plates

    # NB: if barcodes do not already exist we need to handle them in a different method
    # which can handle parent well and process info (probably just the standard plate create method)

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
        # need to be removed fore this point
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

    my $comment = {
        comment_text => $validated_params->{comment},
        created_by   => $validated_params->{user},
    };

    my $new_plate = $model->create_plate({
        name       => $validated_params->{new_plate_name},
        species    => $plate_species,
        type       => $plate_type,
        created_by => $validated_params->{user},
        wells      => \@wells,
        comments   => [ $comment ],
    });

    # Update well_barcodes to point barcodes to new wells
    foreach my $well (keys %$barcode_for_well){
        my $barcode = $barcode_for_well->{$well};
        my $new_well = $new_plate->search_related('wells',{name => $well})->first
            or die "Cannot find well $well on new plate ".$new_plate->name;
        $model->update_well_barcode({
            barcode     => $barcode,
            new_well_id => $new_well->id,
            user        => $validated_params->{user},
            comment     => "barcode moved to new plate ".$new_plate->name,
        });
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

# If uploaded barcodes exactly match those on plate then do nothing
# If existing wells have no barcodes then add barcodes to them (if some wells already have barcodes and some don't this is an error...)
# In all other cases rename plate with version number and create new plate using create_barcoded_plate_copy
# Probably best to discard previously unseen barcodes, e.g. empty tubes, before creating copy (FP only - this should not happen in PIQ)

# NB: some of this already implemented in LIMS2::WebApp::Controller::User::PlateEdit
# update_plate_well_barcodes - extract logic to util method and extend to allow moving
# of barcodes
sub upload_plate_scan{

}

1;
