package LIMS2::SummaryGeneration::SummariesWellDescend;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::SummaryGeneration::SummariesWellDescend::VERSION = '0.461';
}
## use critic


use strict;
use warnings;
use LIMS2::Model;
use List::MoreUtils qw(uniq any);
use Try::Tiny;                              # Exception handling
use Log::Log4perl ':easy';                  # TRACE to INFO to WARN to ERROR to LOGDIE
use Time::HiRes;
use Data::Dumper;

#------------------------------------------------------------------
#  Accessible methods
#------------------------------------------------------------------
# Given a design well id, generate summaries for all leaf nodes in well hierarchy and return result counts
sub generate_summary_rows_for_design_well {

    # passed design well ID, model
    my ($design_well_id, $model, $paths, $well_ancestors) = @_;

    INFO caller()." Well ID $design_well_id passed in";

    my %results = ();

    if($model){
        DEBUG "Model passed in";
    }
    else{
        DEBUG "Creating LIMS2 model";
        $model = LIMS2::Model->new( user => 'lims2' );  # DB connection
    }

    my %stored_values = (); # to re-use well data as much as possible rather than re-fetching
    my $status_counts = {
        wells_deleted => 0,
        well_inserts_succeeded => 0,
        well_inserts_failed => 0,
    };

    try {
        generate_summary_rows_for_all_trails($design_well_id, $model, \%stored_values, $status_counts, $paths, $well_ancestors);
        $results{ exit_code } = 0;
        $results{ count_deletes } = $status_counts->{wells_deleted};
        $results{ count_inserts } = $status_counts->{well_inserts_succeeded};
        $results{ count_fails } = $status_counts->{well_inserts_failed};
    } catch {
        # error
        WARN caller()." Well ID $design_well_id : Exception caught:\nException message : $_";
        $results{ exit_code } = 1;
        $results{ error_msg } = $_;
    };
    return \%results;
}

#------------------------------------------------------------------
#  Internal methods
#------------------------------------------------------------------
# Given a design well id, generate and insert summaries table rows for all the leaf nodes
# in that design well hierarchy
sub generate_summary_rows_for_all_trails {

    my ($design_well_id, $model, $stored_values, $status_counts, $paths, $well_ancestors) = @_;

    my $design_well = try { $model->retrieve_well( { id => $design_well_id } ) };

    if (defined $design_well) {
        # delete existing rows for this design well (if any)
        my $rows_deleted = delete_summary_rows_for_design_well($design_well_id, $model);
        if(defined $rows_deleted && $rows_deleted > 0) {
            $status_counts->{wells_deleted} = $rows_deleted;
        }
    } else {
        # no design well exists for that ID, error
        LOGDIE caller()." Well ID $design_well_id : No design well object found, cannot fetch descendant trails";
    }

    $paths ||= {};
    my $design_well_trails = $paths->{$design_well_id};
    unless($design_well_trails){
        # Call ProcessTree to fetch paths
        DEBUG "getting well process path";
        $design_well_trails = $model->get_paths_for_well_id_depth_first( { well_id => $design_well_id, direction => 1 } );
        DEBUG "well process path done";
    }

    if(!$well_ancestors){
        DEBUG "getting list of unique well ids";
        my @well_ids = uniq map { @{$_} } @{ $design_well_trails };
        DEBUG scalar(@well_ids)." unique well ids found";

        $well_ancestors = $model->fast_get_well_ancestors(@well_ids);
    }

    # initialise hash of previously retrieved wells
    my %wells_retrieved = ();

    # insert design well into hash so doesn't get retrieved again
    $wells_retrieved{ $design_well_id } = $design_well;

    my $trails_index = 0;
    my @summaries_to_insert = ();
    while ( $design_well_trails->[$trails_index] ) {

        my %summary_row_values; # hash to contain column values for a single row
        my %done = ();          # hash keeping track of done plate types

        # Loop through the wells in the trail
        foreach my $curr_well_id (reverse @{$design_well_trails->[$trails_index]}){
            DEBUG "Generating summary values for well $curr_well_id, trail $trails_index";
            TRACE caller()." Well ID $design_well_id : Path well ID $curr_well_id";

            my $curr_well;
            # check wells hash to see if we already retrieved this well object previously
            if (exists $wells_retrieved{$curr_well_id}) {

                TRACE caller()." Re-using well ID: $curr_well_id";

                # re-use same well object
                $curr_well = $wells_retrieved{$curr_well_id};
            } else {
                # otherwise fetch current well object for id
                $curr_well = try { $model->retrieve_well( { id => $curr_well_id } ) };

                # Add the ancestor edges to the well that we got in batch query
                if($well_ancestors->{$curr_well_id}){
                    $curr_well->set_ancestors( $well_ancestors->{ $curr_well_id } );
                }

                # and insert into hash
                $wells_retrieved{ $curr_well_id } = $curr_well;

                foreach my $key (keys %wells_retrieved)
                {
                    TRACE caller()." Key: $key\n";
                }
            }

            if (defined $curr_well) {

                DEBUG "well id: ".$curr_well->id;

                my $params = {
                    'summary_row_values' => \%summary_row_values,
                    'done'               => \%done,
                    'curr_well'          => $curr_well,
                    'stored_values'      => $stored_values,
                    'model'              => $model,
                };

                # create the output array for this well
                add_to_output_for_well($params);

            } else {
                # no design well exists for that ID, error
                LOGDIE caller()." Well ID $design_well_id : No well object found for path well id : $curr_well_id, cannot continue";
            }
        }
        DEBUG "summary values done";

        # Add the insert timestamp and set to_report to default of true
        # as this is not done automatically by populate
        $summary_row_values{ 'insert_timestamp' } = 'now()';
        $summary_row_values{ 'to_report' } //= 1;
        push @summaries_to_insert, \%summary_row_values;
        %done = ();

        # increment index
        $trails_index++;
    }

    # Attempt to insert the rows into the summaries table using populate for efficiency
    my $summary_row_count = scalar @summaries_to_insert;
    DEBUG "Inserting $summary_row_count new summary rows";
    if(@summaries_to_insert){
        try{
            $model->schema->resultset('Summary')->populate(\@summaries_to_insert);
            $status_counts->{well_inserts_succeeded} = $summary_row_count;
        }
        catch{
            INFO "Summary table populate failed with error $!";
            $status_counts->{well_inserts_failed} = $summary_row_count;
        }
    }
    DEBUG "summary rows inserted";

    INFO caller()." Well ID $design_well_id : Leaf node deletes/inserts/fails = "
                 .$status_counts->{wells_deleted}."/"
                 .$status_counts->{well_inserts_succeeded}."/"
                 .$status_counts->{well_inserts_failed};
    return;
}


# append to array for one well in one trail
sub add_to_output_for_well {
    my $params = shift;

    my $curr_plate_type_id = $params->{ curr_well }->last_known_plate->type->id;
    DEBUG "plate type: $curr_plate_type_id";

    # dispatch table
    my $dispatch_fetch_values = {
        DESIGN     => \&fetch_values_for_type_DESIGN,
        INT        => \&fetch_values_for_type_INT,
        FINAL      => \&fetch_values_for_type_FINAL,
        FINAL_PICK => \&fetch_values_for_type_FINAL_PICK,
        DNA        => \&fetch_values_for_type_DNA,
        EP         => \&fetch_values_for_type_EP,
        EP_PICK    => \&fetch_values_for_type_EP_PICK,
        XEP        => \&fetch_values_for_type_XEP,
        SEP        => \&fetch_values_for_type_SEP,
        SEP_PICK   => \&fetch_values_for_type_SEP_PICK,
        FP         => \&fetch_values_for_type_FP,
        PIQ        => \&fetch_values_for_type_PIQ,
        SFP        => \&fetch_values_for_type_SFP,
        ASSEMBLY   => \&fetch_values_for_type_ASSEMBLY,
        CRISPR_EP  => \&fetch_values_for_type_CRISPR_EP,
    };

    my @include_types = ('DESIGN','INT','FINAL','FINAL_PICK','DNA','EP','EP_PICK','XEP','SEP','SEP_PICK','FP','PIQ','SFP','ASSEMBLY','CRISPR_EP');

    # checks for recognised plate type, and if an instance of this plate type already processed
    return unless any { $curr_plate_type_id eq $_ } @include_types;
    return if exists $params->{done}->{$curr_plate_type_id};

    TRACE caller()." Calling method to process plate type = $curr_plate_type_id";

    # check plate type exists in the dispatch table, and run it passing in params
    defined $dispatch_fetch_values->{ $curr_plate_type_id } && $dispatch_fetch_values->{ $curr_plate_type_id }->($params);

    # add to done hash so we don't process another well of the same type for this trail
    # N.B. because trail is processed in reverse we store the LAST use of a plate type, e.g.
    # if 3 INT plates were used then we store details for the third (final) one.
    $params->{done}->{$curr_plate_type_id} = 1;

    return;
}
# --------------DESIGN-----------------
# values specific to DESIGN wells
# -------------------------------------
sub fetch_values_for_type_DESIGN {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };
    my $model = $params->{ model };

    if( (not exists $stored_values->{ stored_design_well_id }) || ($curr_well->id != $stored_values->{ stored_design_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for DESIGN well : ".$curr_well->id;
        $stored_values->{ 'stored_design_id' }                  = try{ $curr_well->design->id }; # design DB identifier
        $stored_values->{ 'stored_design_name' }                = try{ $curr_well->design->name }; # design name
        $stored_values->{ 'stored_design_type_id' }             = try{ $curr_well->design->design_type_id }; # design type, e.g. conditional, deletion, insertion, artificial-intron, intron-replacement, cre-bac
        $stored_values->{ 'stored_design_species_id' }          = try{ $curr_well->design->species_id }; # design species id, e.g. Mouse, Human
        $stored_values->{ 'stored_design_well_id' }             = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_design_well_name' }           = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_design_plate_id' }            = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_design_plate_name' }          = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_design_well_created_ts' }     = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_design_well_assay_complete' } = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_design_well_accepted' }       = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_design_phase' }               = try{ $curr_well->design->phase }; # e.g. -1,0,1,2
        $stored_values->{ 'stored_design_bacs_string' }         = fetch_well_bacs_string( $curr_well ); # BACs associated with this design
        my @genes_array = fetch_well_gene_symbols_and_ids( $curr_well, $model );
        $stored_values->{ 'stored_design_gene_symbols' }        = $genes_array[0]; # gene symbols
        $stored_values->{ 'stored_design_gene_ids' }            = $genes_array[1]; # gene ids
        $stored_values->{ 'stored_design_sponsor' }             = try{ $curr_well->plate_sponsor }; # sponsor
    }

    # copy stored values into the current summary output row
    $summary_row_values->{ 'design_id' }                  = $stored_values->{ stored_design_id };
    $summary_row_values->{ 'design_name' }                = $stored_values->{ stored_design_name };
    $summary_row_values->{ 'design_type' }                = $stored_values->{ stored_design_type_id };
    $summary_row_values->{ 'design_species_id' }          = $stored_values->{ stored_design_species_id };
    $summary_row_values->{ 'design_well_id' }             = $stored_values->{ stored_design_well_id };
    $summary_row_values->{ 'design_well_name' }           = $stored_values->{ stored_design_well_name };
    $summary_row_values->{ 'design_plate_id' }            = $stored_values->{ stored_design_plate_id };
    $summary_row_values->{ 'design_plate_name' }          = $stored_values->{ stored_design_plate_name };
    $summary_row_values->{ 'design_well_created_ts' }     = $stored_values->{ stored_design_well_created_ts };
    $summary_row_values->{ 'design_well_assay_complete' } = $stored_values->{ stored_design_well_assay_complete };
    $summary_row_values->{ 'design_well_accepted' }       = $stored_values->{ stored_design_well_accepted };
    $summary_row_values->{ 'design_phase' }               = $stored_values->{ stored_design_phase };
    $summary_row_values->{ 'design_bacs' }                = $stored_values->{ stored_design_bacs_string };
    $summary_row_values->{ 'design_gene_symbol' }         = $stored_values->{ stored_design_gene_symbols };
    $summary_row_values->{ 'design_gene_id' }             = $stored_values->{ stored_design_gene_ids };
    if ($stored_values->{ 'stored_design_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_design_sponsor } };

    # We work out the project and sponsors for the crispr_ep_well here
    # because we need the design information
    if(my $ep_well_id = $summary_row_values->{'crispr_ep_well_id'}){
        my $project = fetch_crispr_ep_well_project($model,$ep_well_id,$summary_row_values);
        $summary_row_values->{ 'crispr_ep_well_project_id'}         = try{ $project->id };
        $summary_row_values->{ 'crispr_ep_well_project_sponsors'}   = try{ join "/", $project->sponsor_ids };
    }

    return;
}

# --------------INT-----------------
# values specific to INT wells
# ----------------------------------
sub fetch_values_for_type_INT {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_int_well_id }) || ($curr_well->id != $stored_values->{ stored_int_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values

        DEBUG "Searching for DNA template";
        my $dna_template = fetch_dna_template($curr_well);
        DEBUG "DNA template search complete";

        my $cassette = fetch_cassette($curr_well);
        TRACE caller()." Fetching new values for INT well : ".$curr_well->id;
        $stored_values->{ 'stored_int_plate_name' }           = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_int_plate_id' }             = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_int_well_name' }            = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_int_well_id' }              = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_int_well_created_ts' }      = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_int_recombinase_id' }       = join( '_', @{$curr_well->recombinases}); # process recombinase
        $stored_values->{ 'stored_int_qc_seq_pass' }          = try{ $curr_well->well_qc_sequencing_result->pass }; # qc sequencing test result
        $stored_values->{ 'stored_int_cassette_name' }        = try{ $cassette->name }; # cassette name
        $stored_values->{ 'stored_int_cassette_promoter' }    = try{ $cassette->promoter }; # cassette_promoter
        $stored_values->{ 'stored_int_cassette_cre' }         = try{ $cassette->cre }; # cassette_cre
        $stored_values->{ 'stored_int_cassette_conditional' } = try{ $cassette->conditional }; # cassette_conditional
        $stored_values->{ 'stored_int_cassette_resistance' }  = try{ $cassette->resistance }; # cassette_resistance, e.g. neoR
        $stored_values->{ 'stored_int_backbone_name' }        = try{ $curr_well->backbone->name };   # backbone name
        $stored_values->{ 'stored_int_well_assay_complete' }  = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_int_well_accepted' }        = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_int_sponsor' }              = try{ $curr_well->plate_sponsor }; # sponsor
        $stored_values->{ 'stored_dna_template' }             = $dna_template;

        # is well the output of a global_arm_shortening process
        if ( my $short_arm_design = $curr_well->global_arm_shortened_design ) {
            $stored_values->{ 'stored_int_global_arm_shortening_design' } = $short_arm_design->id;
        }
    }

    # copy stored values into the current summary output row
    $summary_row_values->{ 'int_plate_name' }           = $stored_values->{ stored_int_plate_name };
    $summary_row_values->{ 'int_plate_id' }             = $stored_values->{ stored_int_plate_id };
    $summary_row_values->{ 'int_well_name' }            = $stored_values->{ stored_int_well_name };
    $summary_row_values->{ 'int_well_id' }              = $stored_values->{ stored_int_well_id };
    $summary_row_values->{ 'int_well_created_ts' }      = $stored_values->{ stored_int_well_created_ts };
    $summary_row_values->{ 'int_recombinase_id' }       = $stored_values->{ stored_int_recombinase_id };
    $summary_row_values->{ 'int_qc_seq_pass' }          = $stored_values->{ stored_int_qc_seq_pass };
    $summary_row_values->{ 'int_cassette_name' }        = $stored_values->{ stored_int_cassette_name };
    $summary_row_values->{ 'int_cassette_promoter' }    = $stored_values->{ stored_int_cassette_promoter };
    $summary_row_values->{ 'int_cassette_cre' }         = $stored_values->{ stored_int_cassette_cre };
    $summary_row_values->{ 'int_cassette_conditional' } = $stored_values->{ stored_int_cassette_conditional };
    $summary_row_values->{ 'int_cassette_resistance' }  = $stored_values->{ stored_int_cassette_resistance };
    $summary_row_values->{ 'int_backbone_name' }        = $stored_values->{ stored_int_backbone_name };
    $summary_row_values->{ 'int_well_assay_complete' }  = $stored_values->{ stored_int_well_assay_complete };
    $summary_row_values->{ 'int_well_accepted' }        = $stored_values->{ stored_int_well_accepted };
    $summary_row_values->{ 'dna_template' }             = $stored_values->{ stored_dna_template };
    if ($stored_values->{ 'stored_int_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_int_sponsor } };

    $summary_row_values->{'int_well_global_arm_shortening_design'}
        = $stored_values->{'stored_int_global_arm_shortening_design'}
        if exists $stored_values->{'stored_int_global_arm_shortening_design'};

    # valid primers?    -> qc test result and valid primers are outputs of QC system and should be linked to each well for INT, FINAL, POSTINT, DNA, EP_PICK
    return;
}

# --------------FINAL-----------------
# values specific to FINAL wells
# ------------------------------------
sub fetch_values_for_type_FINAL {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_final_well_id }) || ($curr_well->id != $stored_values->{ stored_final_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        DEBUG "finding cassette";
        my $cassette = fetch_cassette($curr_well);
        DEBUG "cassette found";

        DEBUG "finding backbone";
        my $backbone = $curr_well->backbone;
        DEBUG "backbone found";

        DEBUG "finding recombinases";
        my $recombinases = $curr_well->recombinases;
        DEBUG "recombinases found";

        DEBUG "finding sequencing";
        my $seq = $curr_well->well_qc_sequencing_result;
        DEBUG "sequencing found";

        TRACE caller()." Fetching new values for FINAL well : ".$curr_well->id;
        $stored_values->{ 'stored_final_well_id' }              = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_final_well_name' }            = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_final_plate_id' }             = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_final_plate_name' }           = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_final_well_created_ts' }      = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_final_well_assay_complete' }  = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_final_well_accepted' }        = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_final_backbone_name' }        = try{ $backbone->name }; # backbone name
        $stored_values->{ 'stored_final_cassette_name' }        = try{ $cassette->name }; # cassette name
        $stored_values->{ 'stored_final_qc_seq_pass' }          = try{ $seq->pass }; # qc sequencing test result
        $stored_values->{ 'stored_final_cassette_promoter' }    = try{ $cassette->promoter }; # final_cassette_promoter
        $stored_values->{ 'stored_final_cassette_cre' }         = try{ $cassette->cre }; # final_cassette_cre
        $stored_values->{ 'stored_final_cassette_conditional' } = try{ $cassette->conditional };      # final_cassette_conditional
        $stored_values->{ 'stored_final_cassette_resistance' }  = try{ $cassette->resistance };      # final_cassette_resistance, e.g. neoR
        $stored_values->{ 'stored_final_recombinase_id' }       = join( '_', @$recombinases); # process recombinase
        $stored_values->{ 'stored_final_sponsor' }              = try{ $curr_well->plate_sponsor }; # sponsor
    }

    $summary_row_values->{ 'final_well_id' }              = $stored_values->{ stored_final_well_id };
    $summary_row_values->{ 'final_well_name' }            = $stored_values->{ stored_final_well_name };
    $summary_row_values->{ 'final_plate_id' }             = $stored_values->{ stored_final_plate_id };
    $summary_row_values->{ 'final_plate_name' }           = $stored_values->{ stored_final_plate_name };
    $summary_row_values->{ 'final_well_assay_complete' }  = $stored_values->{ stored_final_well_assay_complete };
    $summary_row_values->{ 'final_well_created_ts' }      = $stored_values->{ stored_final_well_created_ts };
    $summary_row_values->{ 'final_well_accepted' }        = $stored_values->{ stored_final_well_accepted };
    $summary_row_values->{ 'final_backbone_name' }        = $stored_values->{ stored_final_backbone_name };
    $summary_row_values->{ 'final_cassette_name' }        = $stored_values->{ stored_final_cassette_name };
    $summary_row_values->{ 'final_qc_seq_pass' }          = $stored_values->{ stored_final_qc_seq_pass };
    $summary_row_values->{ 'final_cassette_promoter' }    = $stored_values->{ stored_final_cassette_promoter };
    $summary_row_values->{ 'final_cassette_cre' }         = $stored_values->{ stored_final_cassette_cre };
    $summary_row_values->{ 'final_cassette_conditional' } = $stored_values->{ stored_final_cassette_conditional };
    $summary_row_values->{ 'final_cassette_resistance' }  = $stored_values->{ stored_final_cassette_resistance };
    $summary_row_values->{ 'final_recombinase_id' }       = $stored_values->{ stored_final_recombinase_id };
    if ($stored_values->{ 'stored_final_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_final_sponsor } };
    # valid primers?
    return;
}

# --------------FINAL_PICK-----------------
# values specific to FINAL_PICK wells
# -----------------------------------------
sub fetch_values_for_type_FINAL_PICK {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_final_pick_well_id }) || ($curr_well->id != $stored_values->{ stored_final_pick_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        my $cassette = fetch_cassette($curr_well);
        TRACE caller()." Fetching new values for FINAL_PICK well : ".$curr_well->id;
        $stored_values->{ 'stored_final_pick_well_id' }              = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_final_pick_well_name' }            = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_final_pick_plate_id' }             = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_final_pick_plate_name' }           = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_final_pick_well_created_ts' }      = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_final_pick_well_assay_complete' }  = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_final_pick_well_accepted' }        = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_final_pick_backbone_name' }        = try{ $curr_well->backbone->name }; # backbone name
        $stored_values->{ 'stored_final_pick_cassette_name' }        = try{ $cassette->name }; # cassette name
        $stored_values->{ 'stored_final_pick_qc_seq_pass' }          = try{ $curr_well->well_qc_sequencing_result->pass }; # qc sequencing test result
        $stored_values->{ 'stored_final_pick_cassette_promoter' }    = try{ $cassette->promoter }; # final_cassette_promoter
        $stored_values->{ 'stored_final_pick_cassette_cre' }         = try{ $cassette->cre }; # final_cassette_cre
        $stored_values->{ 'stored_final_pick_cassette_conditional' } = try{ $cassette->conditional }; # final_cassette_conditional
        $stored_values->{ 'stored_final_pick_cassette_resistance' }  = try{ $cassette->resistance }; # final_pick_cassette_resistance, e.g. neoR
        $stored_values->{ 'stored_final_pick_recombinase_id' }       = join( '_', @{$curr_well->recombinases}); # process recombinase
        $stored_values->{ 'stored_final_pick_sponsor' }              = try{ $curr_well->plate_sponsor }; # sponsor
    }

    $summary_row_values->{ 'final_pick_well_id' }              = $stored_values->{ stored_final_pick_well_id };
    $summary_row_values->{ 'final_pick_well_name' }            = $stored_values->{ stored_final_pick_well_name };
    $summary_row_values->{ 'final_pick_plate_id' }             = $stored_values->{ stored_final_pick_plate_id };
    $summary_row_values->{ 'final_pick_plate_name' }           = $stored_values->{ stored_final_pick_plate_name };
    $summary_row_values->{ 'final_pick_well_assay_complete' }  = $stored_values->{ stored_final_pick_well_assay_complete };
    $summary_row_values->{ 'final_pick_well_created_ts' }      = $stored_values->{ stored_final_pick_well_created_ts };
    $summary_row_values->{ 'final_pick_well_accepted' }        = $stored_values->{ stored_final_pick_well_accepted };
    $summary_row_values->{ 'final_pick_backbone_name' }        = $stored_values->{ stored_final_pick_backbone_name };
    $summary_row_values->{ 'final_pick_cassette_name' }        = $stored_values->{ stored_final_pick_cassette_name };
    $summary_row_values->{ 'final_pick_qc_seq_pass' }          = $stored_values->{ stored_final_pick_qc_seq_pass };
    $summary_row_values->{ 'final_pick_cassette_promoter' }    = $stored_values->{ stored_final_pick_cassette_promoter };
    $summary_row_values->{ 'final_pick_cassette_cre' }         = $stored_values->{ stored_final_pick_cassette_cre };
    $summary_row_values->{ 'final_pick_cassette_conditional' } = $stored_values->{ stored_final_pick_cassette_conditional };
    $summary_row_values->{ 'final_pick_cassette_resistance' }  = $stored_values->{ stored_final_pick_cassette_resistance };
    $summary_row_values->{ 'final_pick_recombinase_id' }       = $stored_values->{ stored_final_pick_recombinase_id };
    if ($stored_values->{ 'stored_final_pick_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_final_pick_sponsor } };
    return;
}
# --------------DNA-----------------
# values specific to DNA wells
# ----------------------------------
sub fetch_values_for_type_DNA {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_dna_well_id }) || ($curr_well->id != $stored_values->{ stored_dna_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for DNA well : ".$curr_well->id;
        $stored_values->{ 'stored_dna_well_id' }              = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_dna_well_name' }            = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_dna_plate_id' }             = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_dna_plate_name' }           = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_dna_well_created_ts' }      = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_dna_well_assay_complete' }  = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_dna_well_accepted' }        = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_dna_quality' }              = try{ $curr_well->well_dna_quality->quality }; # well dna quality e.g. M, L, ML, U
        $stored_values->{ 'stored_dna_quality_comment' }      = try{ $curr_well->well_dna_quality->comment }; # well dna quality comment
        $stored_values->{ 'stored_dna_status_pass' }          = try{ $curr_well->well_dna_status->pass }; # well dna status e.g. t or f
        $stored_values->{ 'stored_dna_qc_seq_pass' }          = try{ $curr_well->well_qc_sequencing_result->pass }; # qc sequencing test result
        $stored_values->{ 'stored_dna_sponsor' }              = try{ $curr_well->plate_sponsor }; # sponsor
    }
    $summary_row_values->{ 'dna_well_id' }             = $stored_values->{ stored_dna_well_id };
    $summary_row_values->{ 'dna_well_name' }           = $stored_values->{ stored_dna_well_name };
    $summary_row_values->{ 'dna_plate_id' }            = $stored_values->{ stored_dna_plate_id };
    $summary_row_values->{ 'dna_plate_name' }          = $stored_values->{ stored_dna_plate_name };
    $summary_row_values->{ 'dna_well_assay_complete' } = $stored_values->{ stored_dna_well_assay_complete };
    $summary_row_values->{ 'dna_well_created_ts' }     = $stored_values->{ stored_dna_well_created_ts };
    $summary_row_values->{ 'dna_well_accepted' }       = $stored_values->{ stored_dna_well_accepted };
    $summary_row_values->{ 'dna_quality' }             = $stored_values->{ stored_dna_quality };
    $summary_row_values->{ 'dna_quality_comment' }     = $stored_values->{ stored_dna_quality_comment };
    $summary_row_values->{ 'dna_status_pass' }         = $stored_values->{ stored_dna_status_pass };
    $summary_row_values->{ 'dna_qc_seq_pass' }         = $stored_values->{ stored_dna_qc_seq_pass };
    if ($stored_values->{ 'stored_dna_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_dna_sponsor } };
    # valid primers?
    return;
}

# --------------EP-----------------
# values specific to EP wells
# ---------------------------------
sub fetch_values_for_type_EP {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_ep_well_id }) || ($curr_well->id != $stored_values->{ stored_ep_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for EP well : ".$curr_well->id;
        $stored_values->{ 'stored_ep_well_id' }                = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_ep_well_name' }              = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_ep_plate_id' }               = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_ep_plate_name' }             = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_ep_well_created_ts' }        = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_ep_well_assay_complete' }    = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_ep_well_accepted' }          = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_ep_colonies_rem_unstained' } = fetch_well_colony_count_remaining_unstained( $curr_well ); # count colonies remaining unstained
        $stored_values->{ 'stored_ep_colonies_total' }         = fetch_well_colony_count_total( $curr_well ); # count colonies total
        $stored_values->{ 'stored_ep_colonies_picked' }        = fetch_well_colony_count_picked( $curr_well ); # count colonies picked
        $stored_values->{ 'stored_ep_first_cell_line_name' }   = try { $curr_well->first_cell_line->name }; # first cell line name
        $stored_values->{ 'stored_ep_well_recombinase_id' }    = fetch_well_process_recombinases( $curr_well ); # process recombinase(s)
        $stored_values->{ 'stored_ep_sponsor' }                = try{ $curr_well->plate_sponsor }; # sponsor
        $stored_values->{ 'stored_to_report' }                 = try{ $curr_well->to_report // 1 }; # to_report flag
    }

    $summary_row_values->{ 'ep_well_id' }                = $stored_values->{ stored_ep_well_id };
    $summary_row_values->{ 'ep_well_name' }              = $stored_values->{ stored_ep_well_name };
    $summary_row_values->{ 'ep_plate_id' }               = $stored_values->{ stored_ep_plate_id };
    $summary_row_values->{ 'ep_plate_name' }             = $stored_values->{ stored_ep_plate_name };
    $summary_row_values->{ 'ep_well_assay_complete' }    = $stored_values->{ stored_ep_well_assay_complete };
    $summary_row_values->{ 'ep_well_created_ts' }        = $stored_values->{ stored_ep_well_created_ts };
    $summary_row_values->{ 'ep_well_accepted' }          = $stored_values->{ stored_ep_well_accepted };
    $summary_row_values->{ 'ep_colonies_rem_unstained' } = $stored_values->{ stored_ep_colonies_rem_unstained };
    $summary_row_values->{ 'ep_colonies_total' }         = $stored_values->{ stored_ep_colonies_total };
    $summary_row_values->{ 'ep_colonies_picked' }        = $stored_values->{ stored_ep_colonies_picked };
    $summary_row_values->{ 'ep_first_cell_line_name' }   = $stored_values->{ stored_ep_first_cell_line_name };
    $summary_row_values->{ 'ep_well_recombinase_id' }    = $stored_values->{ stored_ep_well_recombinase_id };
    if ($stored_values->{ 'stored_ep_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_ep_sponsor } };
    $summary_row_values->{ 'to_report' }                 = $stored_values->{ stored_to_report };
    return;
}

# --------------EP_PICK-----------------
# values specific to EP_PICK wells
# --------------------------------------
sub fetch_values_for_type_EP_PICK {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_ep_pick_well_id }) || ($curr_well->id != $stored_values->{ stored_ep_pick_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for EP_PICK well : ".$curr_well->id;
        $stored_values->{ 'stored_ep_pick_well_id' }                = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_ep_pick_well_name' }              = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_ep_pick_plate_id' }               = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_ep_pick_plate_name' }             = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_ep_pick_well_created_ts' }        = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_ep_pick_well_assay_complete' }    = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_ep_pick_well_accepted' }          = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_ep_pick_qc_seq_pass' }            = try{ $curr_well->well_qc_sequencing_result->pass };  # qc sequencing test result
        $stored_values->{ 'stored_ep_pick_well_recombinase_id' }    = fetch_well_process_recombinases( $curr_well ); # process recombinase(s)
        $stored_values->{ 'stored_ep_pick_sponsor' }                = try{ $curr_well->plate_sponsor }; # sponsor
        DEBUG "Getting ep_pick crispr QC";
        my $crispr_qc_well = fetch_crispr_qc_well($curr_well);
        $stored_values->{ 'stored_ep_pick_well_crispr_es_qc_well_id' } = try{ $crispr_qc_well->id };
        $stored_values->{ 'stored_ep_pick_well_crispr_es_qc_well_call' } = try{ $crispr_qc_well->crispr_damage_type_id };
        DEBUG "Got crispr QC";
    }

    $summary_row_values->{ 'ep_pick_well_id' }              = $stored_values->{ stored_ep_pick_well_id };
    $summary_row_values->{ 'ep_pick_well_name' }            = $stored_values->{ stored_ep_pick_well_name };
    $summary_row_values->{ 'ep_pick_plate_id' }             = $stored_values->{ stored_ep_pick_plate_id };
    $summary_row_values->{ 'ep_pick_plate_name' }           = $stored_values->{ stored_ep_pick_plate_name };
    $summary_row_values->{ 'ep_pick_well_assay_complete' }  = $stored_values->{ stored_ep_pick_well_assay_complete };
    $summary_row_values->{ 'ep_pick_well_created_ts' }      = $stored_values->{ stored_ep_pick_well_created_ts };
    $summary_row_values->{ 'ep_pick_well_accepted' }        = $stored_values->{ stored_ep_pick_well_accepted };
    $summary_row_values->{ 'ep_pick_qc_seq_pass' }          = $stored_values->{ stored_ep_pick_qc_seq_pass };
    $summary_row_values->{ 'ep_pick_well_recombinase_id' }  = $stored_values->{ stored_ep_pick_well_recombinase_id };
    if ($stored_values->{ 'stored_ep_pick_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_ep_pick_sponsor } };
    $summary_row_values->{ 'ep_pick_well_crispr_es_qc_well_id' } = $stored_values->{ 'stored_ep_pick_well_crispr_es_qc_well_id' };
    $summary_row_values->{ 'ep_pick_well_crispr_es_qc_well_call' } = $stored_values->{ 'stored_ep_pick_well_crispr_es_qc_well_call' };
    return;
}

# ------------XEP--------------
# values specific to XEP wells
# -----------------------------
sub fetch_values_for_type_XEP {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_xep_well_id }) || ($curr_well->id != $stored_values->{ stored_xep_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for XEP well : ".$curr_well->id;
        $stored_values->{ 'stored_xep_well_id' }                = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_xep_well_name' }              = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_xep_plate_id' }               = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_xep_plate_name' }             = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_xep_well_created_ts' }        = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_xep_well_assay_complete' }    = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_xep_well_accepted' }          = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_xep_qc_seq_pass' }            = try{ $curr_well->well_qc_sequencing_result->pass };  # qc sequencing test result
        $stored_values->{ 'stored_xep_well_recombinase_id' }    = fetch_well_process_recombinases( $curr_well ); # process recombinase(s)
        $stored_values->{ 'stored_xep_sponsor' }                = try{ $curr_well->plate_sponsor }; # sponsor
    }

    $summary_row_values->{ 'xep_well_id' }              = $stored_values->{ stored_xep_well_id };
    $summary_row_values->{ 'xep_well_name' }            = $stored_values->{ stored_xep_well_name };
    $summary_row_values->{ 'xep_plate_id' }             = $stored_values->{ stored_xep_plate_id };
    $summary_row_values->{ 'xep_plate_name' }           = $stored_values->{ stored_xep_plate_name };
    $summary_row_values->{ 'xep_well_assay_complete' }  = $stored_values->{ stored_xep_well_assay_complete };
    $summary_row_values->{ 'xep_well_created_ts' }      = $stored_values->{ stored_xep_well_created_ts };
    $summary_row_values->{ 'xep_well_accepted' }        = $stored_values->{ stored_xep_well_accepted };
    $summary_row_values->{ 'xep_qc_seq_pass' }          = $stored_values->{ stored_xep_qc_seq_pass };
    $summary_row_values->{ 'xep_well_recombinase_id' }  = $stored_values->{ stored_xep_well_recombinase_id };
    if ($stored_values->{ 'stored_xep_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_xep_sponsor } };

    return;
}

# --------------SEP-----------------
# values specific to SEP wells
# ----------------------------------
sub fetch_values_for_type_SEP {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_sep_well_id }) || ($curr_well->id != $stored_values->{ stored_sep_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for SEP well : ".$curr_well->id;
        $stored_values->{ 'stored_sep_well_id' }                = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_sep_well_name' }              = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_sep_plate_id' }               = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_sep_plate_name' }             = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_sep_well_created_ts' }        = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_sep_well_assay_complete' }    = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_sep_well_accepted' }          = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_sep_well_recombinase_id' }    = fetch_well_process_recombinases( $curr_well ); # process recombinase(s)
        $stored_values->{ 'stored_sep_sponsor' }                = try{ $curr_well->plate_sponsor }; # sponsor
    }

    $summary_row_values->{ 'sep_well_id' }               = $stored_values->{ stored_sep_well_id };
    $summary_row_values->{ 'sep_well_name' }             = $stored_values->{ stored_sep_well_name };
    $summary_row_values->{ 'sep_plate_id' }              = $stored_values->{ stored_sep_plate_id };
    $summary_row_values->{ 'sep_plate_name' }            = $stored_values->{ stored_sep_plate_name };
    $summary_row_values->{ 'sep_well_assay_complete' }   = $stored_values->{ stored_sep_well_assay_complete };
    $summary_row_values->{ 'sep_well_created_ts' }       = $stored_values->{ stored_sep_well_created_ts };
    $summary_row_values->{ 'sep_well_accepted' }         = $stored_values->{ stored_sep_well_accepted };
    $summary_row_values->{ 'sep_well_recombinase_id' }   = $stored_values->{ stored_sep_well_recombinase_id };
    if ($stored_values->{ 'stored_sep_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_sep_sponsor } };
    return;
}

# --------------SEP_PICK-----------------
# values specific to SEP_PICK wells
# ---------------------------------------
sub fetch_values_for_type_SEP_PICK {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_sep_pick_well_id }) || ($curr_well->id != $stored_values->{ stored_sep_pick_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for SEP_PICK well : ".$curr_well->id;
        $stored_values->{ 'stored_sep_pick_well_id' }                = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_sep_pick_well_name' }              = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_sep_pick_plate_id' }               = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_sep_pick_plate_name' }             = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_sep_pick_well_created_ts' }        = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_sep_pick_well_assay_complete' }    = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_sep_pick_well_accepted' }          = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_sep_pick_qc_seq_pass' }            = try{ $curr_well->well_qc_sequencing_result->pass }; # qc sequencing test result
        $stored_values->{ 'stored_sep_pick_well_recombinase_id' }    = fetch_well_process_recombinases( $curr_well ); # process recombinase(s)
        $stored_values->{ 'stored_sep_pick_sponsor' }                = try{ $curr_well->plate_sponsor }; # sponsor
    }

    $summary_row_values->{ 'sep_pick_well_id' }               = $stored_values->{ stored_sep_pick_well_id };
    $summary_row_values->{ 'sep_pick_well_name' }             = $stored_values->{ stored_sep_pick_well_name };
    $summary_row_values->{ 'sep_pick_plate_id' }              = $stored_values->{ stored_sep_pick_plate_id };
    $summary_row_values->{ 'sep_pick_plate_name' }            = $stored_values->{ stored_sep_pick_plate_name };
    $summary_row_values->{ 'sep_pick_well_assay_complete' }   = $stored_values->{ stored_sep_pick_well_assay_complete };
    $summary_row_values->{ 'sep_pick_well_created_ts' }       = $stored_values->{ stored_sep_pick_well_created_ts };
    $summary_row_values->{ 'sep_pick_well_accepted' }         = $stored_values->{ stored_sep_pick_well_accepted };
    $summary_row_values->{ 'sep_pick_qc_seq_pass' }           = $stored_values->{ stored_sep_pick_qc_seq_pass };
    $summary_row_values->{ 'sep_pick_well_recombinase_id' }   = $stored_values->{ stored_sep_pick_well_recombinase_id };
    if ($stored_values->{ 'stored_sep_pick_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_sep_pick_sponsor } };
    return;
}

# --------------FP-----------------
# values specific to FP wells
# ---------------------------------
sub fetch_values_for_type_FP {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_fp_well_id }) || ($curr_well->id != $stored_values->{ stored_fp_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for FP well : ".$curr_well->id;
        $stored_values->{ 'stored_fp_well_id' }                = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_fp_well_name' }              = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_fp_plate_id' }               = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_fp_plate_name' }             = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_fp_well_created_ts' }        = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_fp_well_assay_complete' }    = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_fp_well_accepted' }          = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_fp_sponsor' }                = try{ $curr_well->plate_sponsor }; # sponsor
    }

    $summary_row_values->{ 'fp_well_id' }               = $stored_values->{ stored_fp_well_id };
    $summary_row_values->{ 'fp_well_name' }             = $stored_values->{ stored_fp_well_name };
    $summary_row_values->{ 'fp_plate_id' }              = $stored_values->{ stored_fp_plate_id };
    $summary_row_values->{ 'fp_plate_name' }            = $stored_values->{ stored_fp_plate_name };
    $summary_row_values->{ 'fp_well_assay_complete' }   = $stored_values->{ stored_fp_well_assay_complete };
    $summary_row_values->{ 'fp_well_created_ts' }       = $stored_values->{ stored_fp_well_created_ts };
    $summary_row_values->{ 'fp_well_accepted' }         = $stored_values->{ stored_fp_well_accepted };
    if ($stored_values->{ 'stored_fp_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_fp_sponsor } };
    return;
}

# ------------PIQ--------------
# values specific to PIQ wells
# -----------------------------
sub fetch_values_for_type_PIQ {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };
    my $ancestor_well = $curr_well->ancestor_piq;

    if( (not exists $stored_values->{ stored_piq_well_id }) || ($curr_well->id != $stored_values->{ stored_piq_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for PIQ well : ".$curr_well->id;
        $stored_values->{ 'stored_piq_well_id' }                  = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_piq_well_name' }                = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_piq_plate_id' }                 = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_piq_plate_name' }               = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_piq_well_created_ts' }          = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_piq_well_assay_complete' }      = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_piq_well_accepted' }            = try{ $curr_well->is_accepted }; # well accepted (with override)

        $stored_values->{ 'stored_ancestor_piq_well_id' }         = try{ $ancestor_well->id }; # well id
        $stored_values->{ 'stored_ancestor_piq_well_name' }       = try{ $ancestor_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_ancestor_piq_plate_id' }        = try{ $ancestor_well->plate_id }; # plate id
        $stored_values->{ 'stored_ancestor_piq_plate_name' }      = try{ $ancestor_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_ancestor_piq_well_created_ts' } = try{ $ancestor_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_ancestor_piq_well_accepted' }   = try{ $ancestor_well->is_accepted }; # well accepted (with override)

        $stored_values->{ 'stored_piq_sponsor' }                  = try{ $curr_well->plate_sponsor }; # sponsor

        DEBUG "Getting PIQ crispr QC";
        my $crispr_qc_well = fetch_crispr_qc_well($curr_well);
        $stored_values->{ 'stored_piq_well_crispr_es_qc_well_id' } = try{ $crispr_qc_well->id };
        $stored_values->{ 'stored_piq_well_crispr_es_qc_well_call' } = try{ $crispr_qc_well->crispr_damage_type_id };
        DEBUG "Got crispr QC";
    }

    $summary_row_values->{ 'piq_well_id' }                  = $stored_values->{ stored_piq_well_id };
    $summary_row_values->{ 'piq_well_name' }                = $stored_values->{ stored_piq_well_name };
    $summary_row_values->{ 'piq_plate_id' }                 = $stored_values->{ stored_piq_plate_id };
    $summary_row_values->{ 'piq_plate_name' }               = $stored_values->{ stored_piq_plate_name };
    $summary_row_values->{ 'piq_well_assay_complete' }      = $stored_values->{ stored_piq_well_assay_complete };
    $summary_row_values->{ 'piq_well_created_ts' }          = $stored_values->{ stored_piq_well_created_ts };
    $summary_row_values->{ 'piq_well_accepted' }            = $stored_values->{ stored_piq_well_accepted };

    $summary_row_values->{ 'ancestor_piq_well_id' }         = $stored_values->{ stored_ancestor_piq_well_id };
    $summary_row_values->{ 'ancestor_piq_well_name' }       = $stored_values->{ stored_ancestor_piq_well_name };
    $summary_row_values->{ 'ancestor_piq_plate_id' }        = $stored_values->{ stored_ancestor_piq_plate_id };
    $summary_row_values->{ 'ancestor_piq_plate_name' }      = $stored_values->{ stored_ancestor_piq_plate_name };
    $summary_row_values->{ 'ancestor_piq_well_created_ts' } = $stored_values->{ stored_ancestor_piq_well_created_ts };
    $summary_row_values->{ 'ancestor_piq_well_accepted' }   = $stored_values->{ stored_ancestor_piq_well_accepted };

    if ($stored_values->{ 'stored_piq_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_piq_sponsor } };

    $summary_row_values->{ 'piq_crispr_es_qc_well_id' } = $stored_values->{ 'stored_piq_well_crispr_es_qc_well_id' };
    $summary_row_values->{ 'piq_crispr_es_qc_well_call' } = $stored_values->{ 'stored_piq_well_crispr_es_qc_well_call' };

    return;
}

# --------------SFP-----------------
# values specific to SFP wells
# ----------------------------------
sub fetch_values_for_type_SFP {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_sfp_well_id }) || ($curr_well->id != $stored_values->{ stored_sfp_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for SFP well : ".$curr_well->id;
        $stored_values->{ 'stored_sfp_well_id' }                = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_sfp_well_name' }              = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_sfp_plate_id' }               = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_sfp_plate_name' }             = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_sfp_well_created_ts' }        = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_sfp_well_assay_complete' }    = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_sfp_well_accepted' }          = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_sfp_sponsor' }                = try{ $curr_well->plate_sponsor }; # sponsor
    }

    $summary_row_values->{ 'sfp_well_id' }               = $stored_values->{ stored_sfp_well_id };
    $summary_row_values->{ 'sfp_well_name' }             = $stored_values->{ stored_sfp_well_name };
    $summary_row_values->{ 'sfp_plate_id' }              = $stored_values->{ stored_sfp_plate_id };
    $summary_row_values->{ 'sfp_plate_name' }            = $stored_values->{ stored_sfp_plate_name };
    $summary_row_values->{ 'sfp_well_assay_complete' }   = $stored_values->{ stored_sfp_well_assay_complete };
    $summary_row_values->{ 'sfp_well_created_ts' }       = $stored_values->{ stored_sfp_well_created_ts };
    $summary_row_values->{ 'sfp_well_accepted' }         = $stored_values->{ stored_sfp_well_accepted };
    if ($stored_values->{ 'stored_sfp_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_sfp_sponsor } };
    return;
}

# --------------ASSEMBLY-----------------
# values specific to crispr ASSEMBLY wells
# ----------------------------------
sub fetch_values_for_type_ASSEMBLY {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_assembly_well_id }) || ($curr_well->id != $stored_values->{ stored_assembly_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        DEBUG "finding experiments";
        my @experiments = @{ fetch_experiments($curr_well) };
        DEBUG "found experiments";
        TRACE caller()." Fetching new values for ASSEMBLY well : ".$curr_well->id;
        $stored_values->{ 'stored_assembly_well_id' }                = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_assembly_well_name' }              = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_assembly_plate_id' }               = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_assembly_plate_name' }             = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_assembly_well_created_ts' }        = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_assembly_well_assay_complete' }    = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_assembly_well_accepted' }          = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_assembly_sponsor' }                = try{ $curr_well->plate_sponsor }; # sponsor
        $stored_values->{ 'stored_experiments' }                     = try{ join ",", map { $_->id } @experiments }; # experiment
        $stored_values->{ 'stored_requesters' }                      = try{ join ",", uniq( map { check_requester($_->requester) } @experiments) }; # experiment
    }

    $summary_row_values->{ 'assembly_well_id' }               = $stored_values->{ stored_assembly_well_id };
    $summary_row_values->{ 'assembly_well_name' }             = $stored_values->{ stored_assembly_well_name };
    $summary_row_values->{ 'assembly_plate_id' }              = $stored_values->{ stored_assembly_plate_id };
    $summary_row_values->{ 'assembly_plate_name' }            = $stored_values->{ stored_assembly_plate_name };
    $summary_row_values->{ 'assembly_well_assay_complete' }   = $stored_values->{ stored_assembly_well_assay_complete };
    $summary_row_values->{ 'assembly_well_created_ts' }       = $stored_values->{ stored_assembly_well_created_ts };
    $summary_row_values->{ 'assembly_well_accepted' }         = $stored_values->{ stored_assembly_well_accepted };
    $summary_row_values->{ 'experiments' }                    = $stored_values->{ stored_experiments };
    $summary_row_values->{ 'requester' }                      = $stored_values->{ stored_requesters };
    if ($stored_values->{ 'stored_assembly_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_assembly_sponsor } };
    return;
}

# Perlcritic doesn't like map one liners.
sub check_requester {
    my $req = shift;

    if (!defined $req) {
        return '';
    }

    return $req;
}


# --------------CRISPR_EP-----------------
# values specific to CRISPR_EP wells
# ----------------------------------
sub fetch_values_for_type_CRISPR_EP {
    my $params = shift;
    my $summary_row_values = $params->{ summary_row_values };
    my $stored_values = $params->{ stored_values };
    my $curr_well = $params->{ curr_well };

    if( (not exists $stored_values->{ stored_crispr_ep_well_id }) || ($curr_well->id != $stored_values->{ stored_crispr_ep_well_id }) ) {
        # different well to previous cycle, so must fetch and store new values
        TRACE caller()." Fetching new values for crispr_ep well : ".$curr_well->id;
        $stored_values->{ 'stored_crispr_ep_well_id' }                = try{ $curr_well->id }; # well id
        $stored_values->{ 'stored_crispr_ep_well_name' }              = try{ $curr_well->name }; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values->{ 'stored_crispr_ep_plate_id' }               = try{ $curr_well->plate_id }; # plate id
        $stored_values->{ 'stored_crispr_ep_plate_name' }             = try{ $curr_well->plate_name }; # plate name e.g. MOHSAQ60001_C_1
        $stored_values->{ 'stored_crispr_ep_well_created_ts' }        = try{ $curr_well->created_at->iso8601 }; # well created timestamp
        $stored_values->{ 'stored_crispr_ep_well_assay_complete' }    = try{ $curr_well->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values->{ 'stored_crispr_ep_well_accepted' }          = try{ $curr_well->is_accepted }; # well accepted (with override)
        $stored_values->{ 'stored_crispr_ep_well_nuclease' }          = try{ $curr_well->nuclease->name };
        $stored_values->{ 'stored_crispr_ep_well_cell_line' }         = try{ $curr_well->first_cell_line->name };
        $stored_values->{ 'stored_crispr_ep_sponsor' }                = try{ $curr_well->plate_sponsor }; # sponsor
        $stored_values->{ 'stored_to_report' }                        = try{ $curr_well->to_report // 1}; # to_report flag
        DEBUG "Getting crispr_ep colony counts";
        $stored_values->{ 'stored_crispr_ep_colonies_rem_unstained' } = fetch_well_colony_count_remaining_unstained( $curr_well ); # count colonies remaining unstained
        $stored_values->{ 'stored_crispr_ep_colonies_total' }         = fetch_well_colony_count_total( $curr_well ); # count colonies total
        $stored_values->{ 'stored_crispr_ep_colonies_picked' }        = fetch_well_colony_count_picked( $curr_well ); # count colonies picked
        DEBUG "Got colony counts";
    }

    $summary_row_values->{ 'crispr_ep_well_id' }               = $stored_values->{ stored_crispr_ep_well_id };
    $summary_row_values->{ 'crispr_ep_well_name' }             = $stored_values->{ stored_crispr_ep_well_name };
    $summary_row_values->{ 'crispr_ep_plate_id' }              = $stored_values->{ stored_crispr_ep_plate_id };
    $summary_row_values->{ 'crispr_ep_plate_name' }            = $stored_values->{ stored_crispr_ep_plate_name };
    $summary_row_values->{ 'crispr_ep_well_assay_complete' }   = $stored_values->{ stored_crispr_ep_well_assay_complete };
    $summary_row_values->{ 'crispr_ep_well_created_ts' }       = $stored_values->{ stored_crispr_ep_well_created_ts };
    $summary_row_values->{ 'crispr_ep_well_accepted' }         = $stored_values->{ stored_crispr_ep_well_accepted };
    $summary_row_values->{ 'crispr_ep_well_nuclease' }         = $stored_values->{ stored_crispr_ep_well_nuclease };
    $summary_row_values->{ 'crispr_ep_well_cell_line' }        = $stored_values->{ stored_crispr_ep_well_cell_line };
    if ($stored_values->{ 'stored_crispr_ep_sponsor' }) { $summary_row_values->{ 'sponsor_id' } = $stored_values->{ stored_crispr_ep_sponsor } };
    $summary_row_values->{ 'to_report' }                       = $stored_values->{ stored_to_report };
    $summary_row_values->{ 'crispr_ep_colonies_rem_unstained' } = $stored_values->{ stored_crispr_ep_colonies_rem_unstained };
    $summary_row_values->{ 'crispr_ep_colonies_total' }         = $stored_values->{ stored_crispr_ep_colonies_total };
    $summary_row_values->{ 'crispr_ep_colonies_picked' }        = $stored_values->{ stored_crispr_ep_colonies_picked };
    return;
}

# BACS ids as a simple combined field, if any
sub fetch_well_bacs_string {

    my $well = shift;

    my $process = try{ $well->process_output_wells->first->process };

    my $return_string;

    if (defined $process) {
        my @bacs_names = uniq( map { $_->bac_clone->name } $process->process_bacs );
        $return_string = join( '_', @bacs_names);
    }

    return $return_string;
}

# gene(s) associated with this well combined as single symbol and id strings
sub fetch_well_gene_symbols_and_ids {
    my ( $well, $model ) = @_;

    my @gene_ids = try { uniq map { $_->gene_id } $well->design->genes };
    my $species = $well->design->species_id;

    # try to fetch gene symbols
    my @gene_symbols;
    try {
        for my $gene_id ( @gene_ids ) {
            my $gene_symbol = $model->retrieve_gene( { search_term => $gene_id,  species => $species } )->{gene_symbol};
            push @gene_symbols, $gene_symbol;
        }
    };

    # concat to create strings
    my $gene_symbols_string = join( '_', uniq @gene_symbols);
    my $gene_ids_string = join( '_', @gene_ids);

    return ( $gene_symbols_string, $gene_ids_string );
}

# count of colonies picked for a well, if count exists
sub fetch_well_colony_count_picked {
    my $well = shift;

    my $colony_count_rs = $well->well_colony_counts( { colony_count_type_id => 'picked_colonies' },{ order_by => { -desc => [ 'created_at' ] } } );

    if (my $colony_count_row = $colony_count_rs->first) {
        return $colony_count_row->colony_count;
    }
    return;
}

# count of colonies total for a well, if count exists
sub fetch_well_colony_count_total {
    my $well = shift;

    my $colony_count_rs = $well->well_colony_counts( { colony_count_type_id => 'total_colonies' },{ order_by => { -desc => [ 'created_at' ] } } );

    if (my $colony_count_row = $colony_count_rs->first) {
        return $colony_count_row->colony_count;
    }
    return;
}

# count of colonies remaining unstained for a well, if count exists
sub fetch_well_colony_count_remaining_unstained {
    my $well = shift;

    my $colony_count_rs = $well->well_colony_counts( { colony_count_type_id => 'remaining_unstained_colonies' },{ order_by => { -desc => [ 'created_at' ] } } );

    if (my $colony_count_row = $colony_count_rs->first) {
        return $colony_count_row->colony_count;
    }
    return;
}

# fetch recombinase(s) on a well
sub fetch_well_process_recombinases {

    my $well = shift;

    my $process = try{ $well->process_output_wells->first->process };

    my $return_string;

    if (defined $process) {
        my $process_recombinases = try{ $process->process_recombinases };

        if ( defined $process_recombinases ) {

            my @recombinase_ids;
            while ( my $next_recomb = $process_recombinases->next ) {
                push ( @recombinase_ids, $next_recomb->recombinase->id );
            }

            $return_string = join( '_', @recombinase_ids );
        }

        if ( defined $return_string ) {
            TRACE 'Recombinases for process id '.$process->id.' = '.$return_string;
        }
    }

    return $return_string;
}

# select the rows for this design well and delete them
sub delete_summary_rows_for_design_well {
    my ( $well_id, $model ) = @_;

    DEBUG "deleting summaries for design well $well_id";
    my $wells_rs = $model->schema->resultset('Summary')->search({
        design_well_id => $well_id,
    });

    my $number_deletes;

    try { $number_deletes = $wells_rs->delete() };
    DEBUG "deletion done";
    return $number_deletes;
}


# Caching cassettes probably won't speed things up much
# I suspect that the lazy_build of the well's ancestor ProcessGraph is
# the bit that takes time and since the well is already cached any
# repeat call of well->cassette will be fast.
# (well->backbone calls in this module are very fast - I think this is becasue
# we always do the backbone search after the ancestor ProcessGraph has been built)

# Caching experiments and dna_templates should increase speed

my $cassette_cache;
sub fetch_cassette{
    my ($curr_well) = @_;
    DEBUG "finding cassette for well id: ".$curr_well->id;
    my $cassette;
    if(exists $cassette_cache->{ $curr_well->id }){
        $cassette = $cassette_cache->{ $curr_well->id };
        DEBUG "using cached cassette";
    }
    else{
        try{ $cassette = $curr_well->cassette };
        $cassette_cache->{ $curr_well->id } = $cassette;
        DEBUG "using newly found cassette";
    }
    return $cassette;
}


my $experiments_cache;
sub fetch_experiments{
    my ($curr_well) = @_;
    my $experiments = [];
    if(exists $experiments_cache->{ $curr_well->id }){
        $experiments = $experiments_cache->{ $curr_well->id };
    }
    else{
        try{ $experiments = [ $curr_well->experiments ] };
        $experiments_cache->{ $curr_well->id } = $experiments;
    }
    return $experiments;
}

my $template_cache;
sub fetch_dna_template{
    my ($curr_well) = @_;
    my $template;
    if(exists $template_cache->{ $curr_well->id }){
        $template = $template_cache->{ $curr_well->id }
    }
    else{
        foreach my $process ($curr_well->parent_processes){
            try {
                    $template = $process->dna_template->id;
                };
        }
        $template_cache->{ $curr_well->id } = $template;
    }
    return $template;
}

my $project_cache;
sub fetch_crispr_ep_well_project{
    my ($model,$ep_well_id, $summary_row_values) = @_;
    DEBUG "Fetching project for crispr_ep_well $ep_well_id";
    my $project;
    if(exists $project_cache->{ $ep_well_id }){
        DEBUG "Found project in cache";
        $project = $project_cache->{ $ep_well_id }
    }
    else{
        try{
            $project = $model->retrieve_project({
                cell_line => $summary_row_values->{'crispr_ep_well_cell_line'},
                species_id   => $summary_row_values->{'design_species_id'},
                gene_id      => $summary_row_values->{'design_gene_id'},
            });
            DEBUG "Got project ".$project->id." for crispr_ep_well $ep_well_id";
        }
        catch{
            ERROR "project query failed: $_";
        };
        $project_cache->{ $ep_well_id } = $project;
    }
    return $project;
}

my $crispr_qc_cache;
sub fetch_crispr_qc_well{
    my ($curr_well) = @_;
    my $qc_well;
    if(exists $crispr_qc_cache->{$curr_well->id}){
        DEBUG "Found crispr QC in cache";
        $qc_well = $crispr_qc_cache->{$curr_well->id};
    }
    else{
        $qc_well = $curr_well->accepted_crispr_es_qc_well;
        $crispr_qc_cache->{$curr_well->id} = $qc_well;
        DEBUG "Got crispr QC well from database";
    }
    return $qc_well;
}

1;
