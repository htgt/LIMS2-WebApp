package LIMS2::Model::Plugin::GenotypingQC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::GenotypingQC::VERSION = '0.065';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use LIMS2::Model::Util qw( sanitize_like_expr );
use List::MoreUtils qw( uniq );
use Log::Log4perl qw( :easy );
use namespace::autoclean;

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
    my @primer_bands = qw(tr_pcr lr_pcr gr3 gr4 gf3 gf4);
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
        foreach my $overall qw(targeting_pass targeting-puro_pass chromosome_fail){
            if (my $result = $datum->{$overall}){

                # Change targeting-puro (targeting minus puro) to targeting_puro
                # for consistency with naming of db tables
                my $table = $overall;
                $table =~ s/targeting-puro/targeting_puro/;

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
                die "Invalid data \"$value\" provided for well ".$datum->{well_name}." $primer" unless $value eq "yes";

                # FIXME: need an update or create method
                # update_or_create_well_primer_band now implemented and this code should be updated to use it
                $self->create_well_primer_bands({
                    well_id          => $well->id,
                    primer_band_type => $primer,
                    pass             => 1,
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

sub _valid_column_names{
    my ($self, $assay_types, $primer_bands) = @_;

    # Overall results including primer bands
    my %recognized = map { $_ => 1 } qw(well_name targeting_pass targeting-puro_pass chromosome_fail),
                                     @$primer_bands;

    # Assay specific results
    foreach my $assay (@$assay_types){
        foreach my $colname qw( pass confidence copy_number copy_number_range){
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
        'accepted_override'     => \&well_assay_update,
        'tr_pcr'                => \&primer_band_update,
        'gr3'                   => \&primer_band_update,
        'gr4'                   => \&primer_band_update,
        'gf3'                   => \&primer_band_update,
        'gf4'                   => \&primer_band_update,
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
    if ( $assay_name =~ /
            (g[r|f]) |
            tr_pcr   |
            accepted_override
            /xgms ){
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

    if ( $assay_value eq '-' ){
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

# Use a direct SQL query to return data quickly to the browser. This means we do not use the model
# to populate the interface.
# However, the model must be used for the database updates.

# The next two methods are used by the caller to return a plate of data or a set of wells' data

sub get_genotyping_qc_plate_data {
    my $self = shift;
    my $plate_name = shift;
    my $species = shift;
    my $sql_query = $self->sql_plate_qc_query( $plate_name );
    return $self->get_genotyping_qc_browser_data( $sql_query, $species );
}

sub get_genotyping_qc_well_data {
    my $self = shift;
    my $well_list = shift;
    my $plate_name = shift;
    my $species = shift;

    my $sql_query = $self->sql_well_qc_query( $plate_name, $well_list );
    return $self->get_genotyping_qc_browser_data( $sql_query, $species );
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
             'well' => 1,
             'Chr fail' => 1,
             'Tgt pass' => 1,
             'Puro pass' => 1,
             'Primer band type' => 1,
             'Primer pass?' => 1,
             'genotyping_result_type_id' => 1,
             'call' => 1,
             'copy_number' => 1,
             'confidence' => 1,
             'copy_number_range' => 1,
             'Accepted' => 1,
             'Override' => 1,
         });
    }
);
my @all_data;
my $saved_id = -1;
my $datum = {};
my $gene_cache;

# Extract the well_ids from $sql_result and send them to create_well_cache to generate
# a cache of well objects as a hashref. Squeeze out the duplicates along the way.
my @well_id_list = $self->get_uniq_wells( $sql_result);
my $design_well_cache = $self->create_design_well_cache( \@well_id_list );

$self->log->debug ('SQL query brought back ' . @{$sql_result} . ' rows.' );
foreach my $row ( @{$sql_result} ) {
    if ( $row->{'Well ID'} != $saved_id ) {
        push @all_data, $datum if $datum->{'id'};
        $datum = {};
        $self->initialize_all_datum_fields($datum);
        $self->populate_well_attributes($row, $datum);
        # simply lookup the source well id in the design_well_cache
        my $design_well = $design_well_cache->{$datum->{'id'}}->{'design_well_ref'};
        my $design = $design_well_cache->{$datum->{'id'}}->{'design_ref'};
        $datum->{'gene_id'} = $design->genes->first->gene_id if $design;
        # If we have already seen this gene_id don't go searching for it again
        if ( $gene_cache->{$datum->{'gene_id'} } ) {
            $datum->{'gene_name'} = $gene_cache->{ $datum->{'gene_id'} };
        }
        else {
            if ( $design_well ) {
                $datum->{'gene_name'} = $self->get_gene_symbol_for_accession( $design_well, $species);
                $gene_cache->{$datum->{'gene_id'}} = $datum->{'gene_name'};
            }
        }
        $datum->{'design_id'} = $design_well->id if $design_well;
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
    return;
}


sub populate_well_attributes {
    my $self = shift;
    my $row = shift;
    my $datum = shift;

    $datum->{'id'} = $row->{'Well ID'};
    $datum->{'plate_name'} = $row->{'plate'};
    $datum->{'well'} = $row->{'well'};
    if (defined $row->{'Accepted'} ) {
        $datum->{'accepted'} = ($row->{'Accepted'} ? 'yes' : 'no') // '-';
    }
    if (defined $row->{'Override'} ) {
        $datum->{'accepted_override'} = ($row->{'Override'} ? 'yes' : 'no') // '-';
    }
    $datum->{'chromosome_fail'} = $row->{'Chr fail'} // '-';
    $datum->{'targeting_pass'} = $row->{'Tgt pass'} // '-';
    $datum->{'targeting_puro_pass'} = $row->{'Puro pass'} // '-';
    return;
}

sub fill_out_genotyping_results {
    my $self = shift;
    my $row = shift;
    my $datum = shift;

        if ($row->{'Primer band type'} ) {
            $datum->{$row->{'Primer band type'}} = ($row->{'Primer pass?'} ? 'true' : 'false') // '-' ;
        }

        if ( $row->{'genotyping_result_type_id'}) {
            $datum->{$row->{'genotyping_result_type_id'} . '#' . 'call'} =  $row->{'call'} // '-';
            $datum->{$row->{'genotyping_result_type_id'} . '#' . 'copy_number'} =  $row->{'copy_number'} // '-';
            $datum->{$row->{'genotyping_result_type_id'} . '#' . 'copy_number_range'} =  $row->{'copy_number_range'} // '-';
            $datum->{$row->{'genotyping_result_type_id'} . '#' . 'confidence'} =  $row->{'confidence'} // '-';
        }
    return;
}

# Template pspec. Parameter validation takes time and we want speed here. If it is required
# this stub could be completed.
sub pspec_get_gene_symbol_for_accession {
    return {

    };
}


# This will return a '/' separated list of symbols for a given accession and species.
sub get_gene_symbol_for_accession{
    my ($self, $design_well, $species, $params) = @_;

    my $genes;
    my $gene_symbols;
    my @gene_symbols;

    my ($design) = $design_well->designs;
    if ( $design ) {
        my @gene_ids = uniq map { $_->gene_id } $design->genes;
        foreach my $gene_id ( @gene_ids ) {
            $genes = $self->search_genes(
                { search_term => $gene_id, species =>  $species } );
            push @gene_symbols,  map { $_->{gene_symbol} } @{$genes || [] };
        }
    }
    $gene_symbols = join q{/}, @gene_symbols;

    return $gene_symbols;
}

# We need a design well cache so that we can call methodgit diff remote branchs on the design well itself
#
sub create_design_well_cache {
    my $self = shift;
    my $well_id_list_ref = shift;

    # Use a ProcessTree method to get the list of design wells.
    my $design_well_hash = $self->get_design_wells_for_well_id_list( $well_id_list_ref );

    # create a list of wells to fetch
    # also keep a record of design_id => source_well_id for later use
    my @design_well_id_list;
    my %seen;
    foreach my $well_id ( keys %{$design_well_hash} ) {
        my $design_well_id = $design_well_hash->{$well_id}->{'design_well_id'};
        if ( !$seen{$design_well_id} ) {
            push @design_well_id_list, $design_well_id;
            $seen{$design_well_id} = 1;
        }
    }
    my $design_well_rs = $self->schema->resultset( 'Well' );
    my @design_wells = $design_well_rs->search(
        {
            'me.id' => { '-in' => \@design_well_id_list }
        },
    );
    # Get the designs for each design well and cache them ...
    my $designs_hash_ref;

    foreach my $design_well ( @design_wells ) {
        ($designs_hash_ref->{$design_well->id}) = $design_well->designs;
    }

    # save a reference to the design well in the appropriate key/value
    foreach my $well_id ( keys %{$design_well_hash} ) {
        # match up the design_well_id
        my $design_well_id = $design_well_hash->{$well_id}->{'design_well_id'};
        MATCH_DESIGN_WELL: foreach my $design_well ( @design_wells ) {
            if ( $design_well->id == $design_well_id ) {
               $design_well_hash->{$well_id}->{'design_well_ref'} = $design_well;
               $design_well_hash->{$well_id}->{'design_ref'} = $designs_hash_ref->{$design_well->id};
               last MATCH_DESIGN_WELL;
            }
        }
    }
    return $design_well_hash;
}


sub sql_plate_qc_query {
    my $self = shift;
    my $plate_name = shift;

    return <<"SQL_END";
with wd as (
    select p.id "Plate ID"
    , p.name "plate"
    , w.name "well"
    , w.id "Well ID"
    , w.accepted "Accepted"
    , wgt.genotyping_result_type_id
    , wgt.call
    , wgt.copy_number
    , wgt.copy_number_range
    , wgt.confidence
    from plates p, wells w
        left join well_genotyping_results wgt
        on wgt.well_id = w.id
        where p.name = '$plate_name'
        and w.plate_id = p.id
    order by w.name, wgt.genotyping_result_type_id )
select wd."Plate ID", wd."plate", wd."Well ID", wd."well", wd.genotyping_result_type_id, wd.call,
    wd."Accepted",
    wd.copy_number, wd.copy_number_range, wd.confidence,
    well_chromosome_fail.result "Chr fail",
    well_targeting_pass.result "Tgt pass",
    well_targeting_puro_pass.result "Puro pass",
    well_primer_bands.primer_band_type_id "Primer band type",
    well_primer_bands.pass "Primer pass?",
    well_accepted_override.accepted "Override"
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
    join well_primer_bands
        on wd."Well ID" = well_primer_bands.well_id
left outer
    join well_accepted_override
        on wd."Well ID" = well_accepted_override.well_id
order by wd."Well ID"
SQL_END
}


sub sql_well_qc_query {
    my $self = shift;
    my $plate_name = shift;
    my $well_list = shift;
    # create a comma separated list for SQL

    $well_list = join q{,}, @{$well_list};

    return <<"SQL_END";
with wd as (
    select p.id "Plate ID"
    , p.name "plate"
    , w.name "well"
    , w.id "Well ID"
    , w.accepted "Accepted"
    , wgt.genotyping_result_type_id
    , wgt.call
    , wgt.copy_number
    , wgt.copy_number_range
    , wgt.confidence
    from plates p, wells w
        left join well_genotyping_results wgt
        on wgt.well_id = w.id
        where w.id IN ($well_list)
        and p.name = '$plate_name'
        and w.plate_id = p.id
    order by w.name, wgt.genotyping_result_type_id )
select wd."Plate ID", wd."plate", wd."Well ID", wd."well", wd.genotyping_result_type_id, wd.call,
    wd."Accepted",
    wd.copy_number, wd.copy_number_range, wd.confidence,
    well_chromosome_fail.result "Chr fail",
    well_targeting_pass.result "Tgt pass",
    well_targeting_puro_pass.result "Puro pass",
    well_primer_bands.primer_band_type_id "Primer band type",
    well_primer_bands.pass "Primer pass?",
    well_accepted_override.accepted "Override"
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
    join well_primer_bands
        on wd."Well ID" = well_primer_bands.well_id
left outer
    join well_accepted_override
        on wd."Well ID" = well_accepted_override.well_id
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
    return exists $lookup_boolean{$string_value} ? $lookup_boolean{$string_value}
            : $string_value ;
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
        'Distribute',
        'Override',
        'Chromosome Fail',
        'Targeting Pass',
        'Targeting Puro Pass',
        'TRPCR band',
        'gr3',
        'gr4',
        'gf3',
        'gf4',
    );

    # Add the generic assay headers
    foreach my $assay_name ( @{$assay_types} ) {
        push @header_words ,
            $assay_name . '#call',
            $assay_name . '#copy_number',
            $assay_name . '#copy_number_range',
            $assay_name . '#confidence' ;
    }

    return @header_words;
}

sub translate_header_items {
    my $self = shift;
    my $item = shift;

    my %tr_headers = (
        'Plate' => 'plate_name',
        'Well' => 'well',
        'Gene Name' => 'gene_name',
        'Gene ID' => 'gene_id',
        'Design ID' => 'design_id',
        'Distribute' => 'accepted',
        'Override' => 'accepted_override',
        'Chromosome Fail' => 'chromosome_fail',
        'Targeting Pass' => 'targeting_pass',
        'Targeting Puro Pass' => 'targeting_puro_pass',
        'TRPCR band' => 'trpcr',
    );

    return $tr_headers{$item} // $item;
}

1;
