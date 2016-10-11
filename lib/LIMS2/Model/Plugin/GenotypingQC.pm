package LIMS2::Model::Plugin::GenotypingQC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::GenotypingQC::VERSION = '0.426';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use LIMS2::Model::Util qw( sanitize_like_expr );
use LIMS2::Model::Util::AlleleDetermination qw( determine_allele_types_for_genotyping_results );
use List::MoreUtils qw( uniq );
use Log::Log4perl qw( :easy );
use namespace::autoclean;
use Data::Dumper;

requires qw( schema check_params throw );

sub pspec_update_genotyping_qc_data{
    return {
        csv_fh     => { validate => 'file_handle' },
        created_by => { validate => 'existing_user' },
    };
}

sub update_genotyping_qc_data{
    my ($self, $params) = @_;

    my $val_params = $self->check_params( $params, $self->pspec_update_genotyping_qc_data );
    my $data = parse_csv_file( $val_params->{csv_fh});

    my @assay_types = sort map { $_->id } $self->schema->resultset('GenotypingResultType')->all;
    my @primer_bands = qw(tr_pcr lr_pcr gr3 gr4 gf3 gf4 lr_pcr_pass);
    my @messages;

    # Build a hash of all valid col names so we can report anything not recognized
    my $recognized = $self->_valid_column_names(\@assay_types, \@primer_bands);
    my $not_recognized = {};
    my $counter;
    foreach my $datum (@$data){
        $counter++;

        # Store unrecognized columns to report to user
        # Perlcritic rejects use of grep in a void context and recommends a for loop
        # grep { $not_recognized->{$_} = 1 } grep { not $recognized->{$_} } keys %$datum;
        # Convert column names to lower case to avoid unnecessary upload failures on mixed case
        $datum = $self->hash_keys_to_lc( $datum);
        my @nr = grep { not $recognized->{$_} } keys %$datum;
        foreach my $nr_datum ( @nr ) {
            $not_recognized->{$nr_datum} = 1;
        }
        unless ($datum->{well_name}){
            die "No well name provided for line $counter";
        }

        # split well name and retrieve well
        my ($plate_name,$well_name) = ( $datum->{well_name} =~ /^(.*)_([A-Z]\d{2})$/g );
        my $search_params = { plate_name => $plate_name, well_name => $well_name };
        my $well = $self->retrieve_well( $search_params )
            or $self->throw(NotFound => { entity_class => 'Well', search_params => $search_params });

        push @messages, "Well ".$datum->{well_name}.":";
        # update targeting_pass and chromosome_fail if provided
        foreach my $overall ( qw(targeting_pass targeting-puro_pass targeting-neo_pass chromosome_fail)) {
            if (my $result = $datum->{$overall}){

                # Change targeting-puro (targeting minus puro) to targeting_puro
                # for consistency with naming of db tables
                my $table = $overall;
                $table =~ s/targeting-puro/targeting_puro/;
                $table =~ s/targeting-puro/targeting_neo/;

                # Tidy up result input values
                $result =~ s/\s*//g;
                $result = lc($result) unless $result eq "Y";

                my $method = "update_or_create_well_".$table;
                my ($result, $message) = $self->$method({
                    well_id    => $well->id,
                    result     => $result,
                    created_by => $val_params->{created_by},
                });
                push @messages, "- ".$message;
            }
        }
        # for each assay type see if we have pass/call
        # if we do and pass/call == na or fa then create/update with no values
        # for other pass/call values create/update result with all available data (confidence is optional)
        foreach my $assay (@assay_types){
            create_assay($self, $datum, $val_params, $assay, $well, \@messages);
        }

        # Handle well primer band status
        foreach my $primer (@primer_bands){
            my $value = $datum->{$primer};
            if (defined $value){
                    if( $primer eq 'lr_pcr_pass' ) {
                    die "Invalid data \"$value\" provided for well ".$datum->{well_name}." $primer" unless ($value eq 'pass' || $value eq 'passb' || $value eq 'fail');
                }
                else {
                    die "Invalid data \"$value\" provided for well ".$datum->{well_name}." $primer" unless ($value eq 'pass' || $value eq 'fail');
                }
                $self->update_or_create_well_primer_bands({
                    well_id          => $well->id,
                    primer_band_type => $primer,
                    pass             => $value,
                    created_by       => $val_params->{created_by},
                });

                push @messages, "- Created $primer primer band with pass";
            }
        }
    }

    if (keys %$not_recognized){
        unshift @messages, "The following unrecognized columns were ignored: "
                           .join ", ", sort keys %$not_recognized;
    }
    return \@messages;
}

sub hash_keys_to_lc {
    my $self = shift;
    my $hash_ref = shift;

    my $hash_copy_ref;
    foreach my $key ( keys %{$hash_ref} ) {
        $hash_copy_ref->{ lc( $key ) } = $hash_ref->{ $key };
    }
    return $hash_copy_ref;
}

sub _valid_column_names{
    my ($self, $assay_types, $primer_bands) = @_;
    # Overall results including primer bands
    my %recognized = map { lc $_ => 1 } qw(well_name targeting_pass targeting-puro_pass targeting-neo_pass chromosome_fail),
                                     @$primer_bands;

    # Assay specific results
    foreach my $assay (@$assay_types){
        foreach my $colname ( qw( pass confidence copy_number copy_number_range vic)){
            $recognized{$assay."_".$colname} = 1;
        }
    }
    return \%recognized;
}

sub create_assay{
    my ($self, $datum, $val_params, $assay, $well, $messages ) = @_;

    my @required_data = qw(copy_number copy_number_range);
    if (my $call = $datum->{$assay."_pass"}){
        my ($result, $message);

        # Tidy up call input values
        $call =~ s/\s*//g;
        $call = lc($call);

        if ($call eq "na" or $call eq "fa"){
            # Update call - any existing copy number etc will be removed from db
            ($result, $message) = $self->update_or_create_well_genotyping_result({
                well_id    => $well->id,
                genotyping_result_type_id => $assay,
                call       => $call,
                created_by => $val_params->{created_by},
            });
        }
        else{
            # Check required field's values are number and default blank values to zero
            my %new_values;
            foreach my $field (@required_data){
                defined( $new_values{$field} = $datum->{$assay."_$field"} )
                    or $new_values{$field} = 0;
                $self->throw( Validation => "$assay $field must be a number for well ".$well->name)
                    unless $new_values{$field} =~ /^\d+(\.\d+)?$/;
            }

            # confidence is optional
            if (defined (my $conf = $datum->{$assay."_confidence"}) ){
                $new_values{'confidence'} = $conf;
            }

            # VIC is optional
            if (defined (my $conf = $datum->{$assay."_vic"}) ){
                $new_values{'vic'} = $conf;
            }

            ($result, $message) = $self->update_or_create_well_genotyping_result({
                well_id => $well->id,
                genotyping_result_type_id => $assay,
                call => $call,
                created_by => $val_params->{created_by},
                %new_values,
            })
        }
        push @$messages, "- ".$message;
    }
return 1;
}

#    update_genotyping_qc_value updates one item on each call. As the user makes changes to
#    each cell in the user interface, the controller opens a transaction and calls this method.
#    Once an item is successfully updated the controller will close the transaction by issuing
#    a commit.

sub pspec_update_genotyping_qc_value {
    return {
        well_id           => { validate => 'integer' },
        assay_name        => { validate => 'non_empty_string' },
        assay_value       => { validate => 'non_empty_string' },
        created_by        => { validate => 'existing_user' },
    }

}

sub update_genotyping_qc_value {
    my ($self, $params) = @_;

# Define dispatch table for the various assay types
# The dispatch table is for matching specific assays to specified function calls.
# There are 3 kinds of assays, two of which are dealt with in the dispatch table,
# the last more generic assay method requires a different style of parameter list
# and is dealt with separately.
    my $assays_dispatch = {
        'chromosome_fail'       => \&well_assay_update,
        'targeting_pass'        => \&well_assay_update,
        'targeting_puro_pass'   => \&well_assay_update,
        'targeting_neo_pass'    => \&well_assay_update,
        'accepted_override'     => \&well_assay_update,
        'lab_number'            => \&well_assay_update,
        'tr_pcr'                => \&primer_band_update,
        'gr3'                   => \&primer_band_update,
        'gr4'                   => \&primer_band_update,
        'gf3'                   => \&primer_band_update,
        'gf4'                   => \&primer_band_update,
        'lr_pcr_pass'           => \&primer_band_update,
    };

#  The more generic assay, call, copy_number, copy_range, confidence call is easier to handle.
    my $vp = $self->check_params( $params, $self->pspec_update_genotyping_qc_value );

    my $assay_name = $vp->{'assay_name'};
    my $assay_value = $vp->{'assay_value'};
    my $well_id = $vp->{'well_id'};
    my $user = $vp->{'created_by'};

    # $assay_value needs translating from string to value before sending down the line
    # if it is a pcr band update
    # Possible values are 'true', 'false', '-' (the latter gets passed through as is)
    # /(g[r|f])|tr_pcr|accepted_override/ Obsolete, updated for accepted_override only
    if ( $assay_name =~ /accepted_override/xgms ) {
        $assay_value = $self->convert_bool( $assay_value );
    }
    my $genotyping_qc_result;

    if (exists $assays_dispatch->{$assay_name} ) {
        $genotyping_qc_result = $assays_dispatch->{$assay_name}->($self, $assay_name, $assay_value, $well_id, $user);
    }
    elsif ( $assay_name =~ /#/ ) {
        # deal with the generic genotyping_qc assays that all have the same format
        # $assay_name contains a '#' separating the actual assay name
        # from the field within that assay that is scheduled for an update operation
        # So we fish those out of the $assay_name variable and call the generic update
        # or create method.
        my ($genotyping_assay, $assay_field) = split( '#', $assay_name);
        $genotyping_qc_result = $self->generic_assay_update(
            $genotyping_assay, $assay_field, $assay_value, $well_id, $user,
        );
    }
    else {
        # throw an error
        require LIMS2::Exception::Implementation;
        LIMS2::Exception::Implementation->throw( "Assay $assay_name not found in dispatch table" );
    }


    return $genotyping_qc_result;
}

# TODO: Update these methods to use the 'params' and slice_def technique. However, the code works as is.
# DP-S: Actually not sure that is wise as validation takes too much time. Validation is for forms where users can
# enter potentially invalid data.
#
sub well_assay_update{
    my $self = shift;
    my $assay_name = shift;
    my $assay_value = shift;
    my $well_id = shift;
    my $user = shift;
    my $well_assay_tag;
    my $update_method;

    # Define the specific hash key to update for each different assay
    # normally, this is 'result' for for accepted_override it is 'accepted'
    # which is, of course, not an assay ...
    #
    my $update_key = $assay_name eq 'accepted_override' ? 'accepted' : 'result';

    if ($assay_value eq '-' || $assay_value eq 'reset') {
            $update_method = 'delete_well_' . $assay_name;
            $well_assay_tag = $self->$update_method({
                    created_by  => $user,
                    well_id     => $well_id,
                });
    }
    else {
            $update_method = 'update_or_create_well_' . $assay_name;
            $well_assay_tag = $self->$update_method({
                created_by      => $user,
                $update_key     => $assay_value,
                well_id         => $well_id,
            });
    }
    return $well_assay_tag;
}

sub primer_band_update {
    my $self = shift;
    my $assay_name = shift;
    my $assay_value = shift;
    my $well_id = shift;
    my $user = shift;

    my $well_primer_band;

    if ( $assay_value eq '-' || $assay_value eq 'reset' ){
        $well_primer_band = $self->delete_well_primer_band({
                primer_band_type => $assay_name,
                created_by => $user,
                well_id => $well_id,
            });
    }
    else {
        $well_primer_band = $self->update_or_create_well_primer_bands({
            primer_band_type => $assay_name,
            pass => $assay_value,
            created_by => $user,
            well_id    => $well_id,
        });
    }
    return $well_primer_band;

}

# Generic assay update method wrapper
sub generic_assay_update{
    my $self = shift;
    my $genotyping_assay = shift;
    my $assay_field = shift;
    my $assay_value = shift;
    my $well_id = shift;
    my $user = shift;

    my $well_genotyping_result;

    if ($assay_value eq '-' || $assay_value eq 'reset') {
        $well_genotyping_result = $self->delete_well_genotyping_result({
                well_id => $well_id,
                genotyping_result_type_id => $genotyping_assay,
            });
    }
    else {
        $well_genotyping_result = $self->update_or_create_well_genotyping_result({
                well_id => $well_id,
                genotyping_result_type_id => $genotyping_assay,
                $assay_field => $assay_value,
                created_by => $user,
            });
    }

    return $well_genotyping_result;
}

=head
delete_plate_genotyping_qc_data - deletes all the data associated with a plate
This is a rather slow but sure way!
=cut

sub delete_plate_genotyping_qc_data {
    my $self = shift;
    my $plate_name = shift;
    my $species = shift;
    my $user = shift;

    my @qc_ref = $self->get_genotyping_qc_plate_data( $plate_name, $species );

    foreach my $qc_row ( @qc_ref ) {
        $self->delete_genotyping_qc_data( $qc_row, $user );
    }

    return;
}

sub delete_well_genotyping_qc_data {
    my $self = shift;
    my $well_list = shift;
    my $plate_name = shift;
    my $species = shift;
    my $user = shift;

    my @qc_ref = $self->get_genotyping_qc_well_data( $well_list, $plate_name, $species);

    foreach my $qc_row ( @qc_ref ) {
        $self->delete_genotyping_qc_data( $qc_row, $user );
    }

    return;
}

sub delete_genotyping_qc_data {
    my $self = shift;
    my $qc_row = shift;
    my $user = shift;

    $self->log->debug('deleting data for well id ' . $qc_row->{'id'} . $qc_row->{'well'} . $qc_row->{'gene_name'} );
    my $params->{'well_id'} = $qc_row->{'id'};
    $params->{'created_by'} = $user;
    $params->{'assay_value'} = 'reset';

    if ( $qc_row->{'chromosome_fail'} ne '-' ) {
        $params->{'assay_name'} = 'chromosome_fail';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'targeting_pass'} ne '-' ) {
        $params->{'assay_name'} = 'targeting_pass';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'targeting_puro_pass'} ne '-' ) {
        $params->{'assay_name'} = 'targeting_puro_pass';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'targeting_neo_pass'} ne '-' ) {
        $params->{'assay_name'} = 'targeting_neo_pass';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'accepted_override'} ne '-' ) {
        $params->{'assay_name'} = 'accepted_override';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'lab_number'} ne '-' ) {
        $params->{'assay_name'} = 'lab_number';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'tr_pcr'} ne '-' ) {
        $params->{'assay_name'} = 'tr_pcr';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'gr3'} ne '-' ) {
        $params->{'assay_name'} = 'gr3';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'gr4'} ne '-' ) {
        $params->{'assay_name'} = 'gr4';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'gf3'} ne '-' ) {
        $params->{'assay_name'} = 'gf3';
        $self->update_genotyping_qc_value( $params );
    }
    if ( $qc_row->{'gf4'} ne '-' ) {
        $params->{'assay_name'} = 'gf4';
        $self->update_genotyping_qc_value( $params );
    }

    # Now for the generic assays

    my @assay_keys = grep { /#call/ } keys %$qc_row;

    foreach my $assay ( @assay_keys ) {
        $params->{'assay_name'} = $assay;
        $self->update_genotyping_qc_value ( $params );
    }

    return 1;
}

sub fast_delete_gqc_data {
    my $self = shift;
    my $qc_row = shift;

    $self->log->info( 'fast_delete_gqc_data not yet implemented, use the standard method');
    return;
}

# Use a direct SQL query to return data quickly to the browser. This means we do not use the model
# to populate the interface.
# However, the model must be used for the database updates.

# The next two methods are used by the caller to return a plate of data or a set of well data

sub get_genotyping_qc_plate_data {
    my $self = shift;
    my $plate_name = shift;
    my $species = shift;
    my $sql_query = $self->sql_plate_qc_query( $plate_name );
    my @gqc_data = $self->get_genotyping_qc_browser_data( $sql_query, $species );
    # append the allele determination and workflow information for each well
    my $AD = LIMS2::Model::Util::AlleleDetermination->new( 'model' => $self, 'species' => $species );
    my $gqc_data_with_allele_types = $AD->determine_allele_types_for_genotyping_results_array( \@gqc_data );
    return @{ $gqc_data_with_allele_types };
}

sub get_genotyping_qc_well_data {
    my $self = shift;
    my $well_list = shift;
    my $plate_name = shift;
    my $species = shift;
    my $sql_query = $self->sql_well_qc_query( $well_list );
    my @gqc_data = $self->get_genotyping_qc_browser_data( $sql_query, $species );
    # append the allele determination and workflow information for each well
    my $AD = LIMS2::Model::Util::AlleleDetermination->new( 'model' => $self, 'species' => $species );
    my $gqc_data_with_allele_types = $AD->determine_allele_types_for_genotyping_results_array( \@gqc_data );
    return @{ $gqc_data_with_allele_types };
}

sub get_genotyping_qc_browser_data {
    my $self = shift;
    my $sql_query = shift;
    my $species = shift;

# SQL query requires plate id as input
my $sql_result =  $self->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( $sql_query );
         $sth->execute( );
         $sth->fetchall_arrayref({
             'Well ID' => 1,
             'plate' => 1,
             'plate_type' => 1,
             'well' => 1,
             'Chr fail' => 1,
             'Tgt pass' => 1,
             'Puro pass' => 1,
             'Neo pass' => 1,
             'Primer band type' => 1,
             'Primer pass?' => 1,
             'genotyping_result_type_id' => 1,
             'call' => 1,
             'copy_number' => 1,
             'confidence' => 1,
             'copy_number_range' => 1,
             'vic' => 1,
             'Accepted' => 1,
             'Override' => 1,
             'Lab Number' => 1,
             'Barcode' => 1,
         });
    }
);
$self->log->debug ('SQL query brought back ' . @{$sql_result} . ' rows.' );
my @all_data;
my $saved_id = -1;
my $datum = {};
my $gene_cache;

$self->{plate_type} = $sql_result->[0]->{plate_type};

# Extract the well_ids from $sql_result and send them to create_well_cache to generate
# a cache of well objects as a hashref. Squeeze out the duplicates along the way.
my @well_id_list = $self->get_uniq_wells( $sql_result);
$self->log->debug('unique well list generated');
my $design_data_cache = $self->create_design_data_cache( \@well_id_list );
$self->log->debug('design data cache generated (' . @well_id_list . ' unique wells)');


# get array of arrays of ancestors
my $result =  $self->get_ancestors_for_well_id_list( \@well_id_list );

# transform in hash of well_id to clone_id
my %clone_id_hash;
if ($self->{plate_type} eq 'PIQ') {
    foreach my $ancestors (@$result) {
        my $well_id =  @{@$ancestors[0]}[0];
        my $clone_id =  @{@$ancestors[0]}[2];
        #TODO: avoid using retrieve well in genotyping QC - its slows the page load too much
        my $well = $self->retrieve_well( { id => $clone_id } );
        $clone_id_hash{$well_id} = $well->plate->name .'['. $well->name .']';
    }
}

foreach my $row ( @{$sql_result} ) {
    if ( $row->{'Well ID'} != $saved_id ) {
        push @all_data, $datum if $datum->{'id'};
        $datum = {};
        $self->initialize_all_datum_fields($datum);
        $self->populate_well_attributes($row, $datum);
        # simply lookup the source well id in the design_well_cache
        my $design_id = $design_data_cache->{$datum->{'id'}}->{'design_id'};
        $datum->{'gene_id'} = $design_data_cache->{$datum->{'id'}}->{'gene_id'};
        # If we have already seen this gene_id don't go searching for it again
        if ( $datum->{'gene_id'}) {
            if ( $gene_cache->{$datum->{'gene_id'} } ) {
                $datum->{'gene_name'} = $gene_cache->{ $datum->{'gene_id'} };
            }
            else {
                $datum->{'gene_name'} = $self->find_gene({
                    species => $species,
                    search_term => $datum->{'gene_id'}
                })->{'gene_symbol'};

                $gene_cache->{$datum->{'gene_id'}} = $datum->{'gene_name'};
            }
        }
        else {
            $datum->{'gene_id'} = '-';
        }
        $datum->{'design_id'} = $design_id;
        # get the clone_id
        $datum->{'clone_id'} = $clone_id_hash{ $datum->{'id'} };
        # get the generic assay data for this row
        $self->fill_out_genotyping_results($row, $datum );

        $saved_id = $row->{'Well ID'};

    }
    else {
        # just get the primer band and generic assay data for this row
        $self->fill_out_genotyping_results($row, $datum );
    }
}
push @all_data, $datum if $datum;
return @all_data;
}

sub initialize_all_datum_fields {
    my $self = shift;
    my $datum = shift;

#   Initialize fields with a hyphen, they will be overwritten by values from the query
    $datum->{'gf3'} = '-';
    $datum->{'gf4'} = '-';
    $datum->{'gr3'} = '-';
    $datum->{'gr4'} = '-';
    $datum->{'tr_pcr'} =  '-';
    $datum->{'gene_id'} = '-';
    $datum->{'gene_name'} = '-';
    $datum->{'design_id'} = '-';
    $datum->{'accepted'} = '-';
    $datum->{'accepted_override'} = '-';
    $datum->{'lab_number'} = '-';
    return;
}


sub populate_well_attributes {
    my $self = shift;
    my $row = shift;
    my $datum = shift;

    $datum->{'id'} = $row->{'Well ID'};
    $datum->{'plate_name'} = $row->{'plate'};
    $datum->{'plate_type'} = $row->{'plate_type'};
    $datum->{'well'} = $row->{'well'};
    $datum->{'barcode'} = $row->{'Barcode'};

    if (defined $row->{'Accepted'} ) {
        $datum->{'accepted'} = ($row->{'Accepted'} ? 'yes' : 'no') // '-';
    }
    if (defined $row->{'Override'} ) {
        $datum->{'accepted_override'} = ($row->{'Override'} ? 'yes' : 'no') // '-';
    }
    if (defined $row->{'Lab Number'} ) {
        $datum->{'lab_number'} = $row->{'Lab Number'};
    }

    $datum->{'chromosome_fail'} = $row->{'Chr fail'} // '-';
    $datum->{'targeting_pass'} = $row->{'Tgt pass'} // '-';
    $datum->{'targeting_puro_pass'} = $row->{'Puro pass'} // '-';
    $datum->{'targeting_neo_pass'} = $row->{'Neo pass'} // '-';

    # Retrieve the well so we can check it's actual release status
    # without rewriting the accepted/override logic here
    my $well = $self->retrieve_well({ id => $datum->{'id'} });
    $datum->{'release_status'} = ( $well->is_accepted ? 'released' : 'not released' );

    return;
}

sub fill_out_genotyping_results {
    my $self = shift;
    my $row = shift;
    my $datum = shift;

        if ($row->{'Primer band type'} ) {
            $datum->{$row->{'Primer band type'}} = $row->{'Primer pass?'} // '-' ;
        }

        if ( $row->{'genotyping_result_type_id'}) {
            $datum->{$row->{'genotyping_result_type_id'} . '#' . 'call'} =  $row->{'call'} // '-';
            $datum->{$row->{'genotyping_result_type_id'} . '#' . 'copy_number'} =  $row->{'copy_number'} // '-';
            $datum->{$row->{'genotyping_result_type_id'} . '#' . 'copy_number_range'} =  $row->{'copy_number_range'} // '-';
            $datum->{$row->{'genotyping_result_type_id'} . '#' . 'confidence'} =  $row->{'confidence'} // '-';
            $datum->{$row->{'genotyping_result_type_id'} . '#' . 'vic'} =  $row->{'vic'} // '-';
        }
    return;
}

sub create_design_data_cache {
    my $self = shift;
    my $well_id_list_ref = shift;
    # Use a ProcessTree method to get the list of design wells.

    my $design_data_hash = $self->get_design_data_for_well_id_list( $well_id_list_ref );
    return $design_data_hash;
}

sub sql_plate_qc_query {
    my $self = shift;
    my $plate_name = shift;

    return <<"SQL_END";
with wd as (
    select p.id "Plate ID"
    , p.name "plate"
    , p.type_id "plate_type"
    , w.name "well"
    , w.id "Well ID"
    , w.accepted "Accepted"
    , w.barcode "Barcode"
    , wgt.genotyping_result_type_id
    , wgt.call
    , wgt.copy_number
    , wgt.copy_number_range
    , wgt.confidence
    , wgt.vic
    from plates p, wells w
        left join well_genotyping_results wgt
        on wgt.well_id = w.id
        where p.name = '$plate_name'
        and w.plate_id = p.id
    order by w.name, wgt.genotyping_result_type_id )
select wd."Plate ID", wd."plate", wd."plate_type", wd."Well ID", wd."well", wd.genotyping_result_type_id, wd.call,
    wd."Accepted",wd."Barcode",
    wd.copy_number, wd.copy_number_range, wd.confidence, wd.vic,
    well_chromosome_fail.result "Chr fail",
    well_targeting_pass.result "Tgt pass",
    well_targeting_puro_pass.result "Puro pass",
    well_targeting_neo_pass.result "Neo pass",
    well_primer_bands.primer_band_type_id "Primer band type",
    well_primer_bands.pass "Primer pass?",
    well_accepted_override.accepted "Override",
    well_lab_number.lab_number "Lab Number"
from wd
left outer
    join well_chromosome_fail
        on wd."Well ID" = well_chromosome_fail.well_id
left outer
    join well_targeting_pass
        on wd."Well ID" = well_targeting_pass.well_id
left outer
    join well_targeting_puro_pass
        on wd."Well ID" = well_targeting_puro_pass.well_id
left outer
    join well_targeting_neo_pass
        on wd."Well ID" = well_targeting_neo_pass.well_id
left outer
    join well_primer_bands
        on wd."Well ID" = well_primer_bands.well_id
left outer
    join well_accepted_override
        on wd."Well ID" = well_accepted_override.well_id
left outer
    join well_lab_number
        on wd."Well ID" = well_lab_number.well_id
--order by wd."Well ID"
order by wd."well"
SQL_END
}

sub sql_well_qc_query {
    my $self = shift;
    my $well_list = shift;
    # create a comma separated list for SQL

    $well_list = join q{,}, @{$well_list};

    return <<"SQL_END";
with wd as (
    select p.id "Plate ID"
    , p.name "plate"
    , p.type_id "plate_type"
    , w.name "well"
    , w.id "Well ID"
    , w.accepted "Accepted"
    , w.barcode "Barcode"
    , wgt.genotyping_result_type_id
    , wgt.call
    , wgt.copy_number
    , wgt.copy_number_range
    , wgt.confidence
    , wgt.vic
    from plates p, wells w
        left join well_genotyping_results wgt
        on wgt.well_id = w.id
        where w.id IN ($well_list)
        and w.plate_id = p.id
    order by w.name, wgt.genotyping_result_type_id )
select wd."Plate ID", wd."plate", wd."plate_type", wd."Well ID", wd."well", wd.genotyping_result_type_id, wd.call,
    wd."Accepted",wd."Barcode",
    wd.copy_number, wd.copy_number_range, wd.confidence, wd.vic,
    well_chromosome_fail.result "Chr fail",
    well_targeting_pass.result "Tgt pass",
    well_targeting_puro_pass.result "Puro pass",
    well_targeting_neo_pass.result "Neo pass",
    well_primer_bands.primer_band_type_id "Primer band type",
    well_primer_bands.pass "Primer pass?",
    well_accepted_override.accepted "Override",
    well_lab_number.lab_number "Lab Number"
from wd
left outer
    join well_chromosome_fail
        on wd."Well ID" = well_chromosome_fail.well_id
left outer
    join well_targeting_pass
        on wd."Well ID" = well_targeting_pass.well_id
left outer
    join well_targeting_puro_pass
        on wd."Well ID" = well_targeting_puro_pass.well_id
left outer
    join well_targeting_neo_pass
        on wd."Well ID" = well_targeting_neo_pass.well_id
left outer
    join well_primer_bands
        on wd."Well ID" = well_primer_bands.well_id
left outer
    join well_accepted_override
        on wd."Well ID" = well_accepted_override.well_id
left outer
    join well_lab_number
        on wd."Well ID" = well_lab_number.well_id
order by wd."Well ID"
SQL_END
}

sub convert_bool {
    my $self = shift;
    my $string_value = shift;
    my %lookup_boolean = (
        'true'  => 1,
        'yes'   => 1,
        '1'     => 1,
        'false' => 0,
        'no'    => 0,
        '0'     => 0,
    );

    # Return the boolean as an integer, otherwise return the original string
    # This is because other strings like 'reset' or '-' might be present in
    # addition to 'yes', 'no', etc.
    return exists $lookup_boolean{$string_value} ?
    $lookup_boolean{$string_value} : $string_value ;
}


sub get_uniq_wells {
    my $self = shift;
    my $sql_result = shift;

    my %seen;
    my @well_id_list;
    foreach my $row ( @{$sql_result} ) {
        my $well_id = $row->{'Well ID'};
        if ( !$seen{$well_id} ) {
            push @well_id_list, $well_id;
            $seen{$well_id} = 1;
        }
    }
    return @well_id_list;
}


=head1
csv_genotyping_qc_data is a reporting method that returns CSV formatted data for a CSV download.

Users should call this method, rather than the get_genotyping_qc_plate_data method, which will resturn
data in a hash with useful keys but not easy to send back to a web browser for download.
=cut
sub csv_genotyping_qc_plate_data {
    my $self = shift;
    my $plate_name = shift;
    my $species = shift;
    my @plate_well_data = $self->get_genotyping_qc_plate_data(
        $plate_name,
        $species,
    );

    # Unpack the array of hashes and construct a csv format file.
    # first - define the header
    #

    my @value_names = (
        { 'call' => 'Call' },
        { 'copy_number' => 'Copy Number' },
        { 'copy_number_range' => 'Range' },
        { 'confidence' => 'Confidence' },
        { 'vic' => 'VIC' },
    );
    my @assay_types = sort map { $_->id } $self->schema->resultset('GenotypingResultType')->all;
    my @csv_header_array = $self->create_csv_header_array( \@assay_types );
    my $csv_header = join q{,}, @csv_header_array;

    my @csv_data; #This is the array of strings that gets pushed out to the caller
    push @csv_data, $csv_header;

    my $csv_row_line; # This is the string that gets pushed out to the caller
    @plate_well_data = reverse @plate_well_data;
    while ( @plate_well_data ) {
        my $datum = pop @plate_well_data;
        my @csv_row;
        foreach my $item ( @csv_header_array ) {
            my $tr_item = $self->translate_header_items($item);
            if ( defined $datum->{$tr_item} ) {
                push @csv_row, $datum->{$tr_item};
            }
            else {
                push @csv_row, '';
            }
        }
        $csv_row_line = join q{,}, @csv_row;
        push @csv_data, $csv_row_line;
    }
    return @csv_data;
}

sub create_csv_header_array {
    my $self = shift;
    my $assay_types = shift;

    my @header_words = (
        'Plate',
        'Well',
        'Gene Name',
        'Gene ID',
        'Design ID',
    );
    if ($self->{plate_type} eq 'PIQ') {
        push (@header_words, ('Clone ID','Lab Number'));
    }

    push (@header_words, (
        'Allele Type',
        'Calculated Pass',
        'Distribute',
        'Override',
        'Chromosome Fail',
        'Allele Info#Type',
        'Allele Info#Full allele determination',
        'Allele Info#Stage',
        'Allele Info#Workflow',
        'Allele Info#Assay pattern',
        'Allele Info#Vector cass resist',
        'Allele Info#Vector recombinase',
        'Allele Info#First EP recombinase',
        'Targeting Pass',
        'Targeting Puro Pass',
        'Targeting Neo Pass',
        'TRPCR band',
        'gr3',
        'gr4',
        'gf3',
        'gf4')
    );

    # Add the generic assay headers
    foreach my $assay_name ( @{$assay_types} ) {
        push @header_words ,
            $assay_name . '#call',
            $assay_name . '#copy_number',
            $assay_name . '#copy_number_range',
            $assay_name . '#confidence' ,
            $assay_name . '#vic' ;
    }

    return @header_words;
}

sub translate_header_items {
    my $self = shift;
    my $item = shift;

    my %tr_headers = (
        'Plate'                                 => 'plate_name',
        'Well'                                  => 'well',
        'Gene Name'                             => 'gene_name',
        'Gene ID'                               => 'gene_id',
        'Design ID'                             => 'design_id',
        'Allele Type'                           => 'allele_type',
        'Calculated Pass'                       => 'genotyping_pass',
        'Distribute'                            => 'accepted',
        'Clone ID'                              => 'clone_id',
        'Lab Number'                            => 'lab_number',
        'Override'                              => 'accepted_override',
        'Chromosome Fail'                       => 'chromosome_fail',
        'Allele Info#Type'                      => 'allele_type',
        'Allele Info#Full allele determination' => 'allele_determination',
        'Allele Info#Stage'                     => 'plate_type',
        'Allele Info#Workflow'                  => 'workflow',
        'Allele Info#Assay pattern'             => 'assay_pattern',
        'Allele Info#Vector cass resist'        => 'final_pick_cassette_resistance',
        'Allele Info#Vector recombinase'        => 'final_pick_recombinase_id',
        'Allele Info#First EP recombinase'      => 'ep_well_recombinase_id',
        'Targeting Pass'                        => 'targeting_pass',
        'Targeting Puro Pass'                   => 'targeting_puro_pass',
        'Targeting Neo Pass'                    => 'targeting_neo_pass',
        'TRPCR band'                            => 'trpcr',
    );

    return $tr_headers{$item} // $item;
}

1;
