#!/usr/bin/perl
package LIMS2::SummaryGeneration::SummariesWellDescend;

use strict;
use warnings;
use LIMS2::Model;
use List::MoreUtils qw(uniq any);
use Try::Tiny;                              # Exception handling
use Log::Log4perl ':easy';                  # DEBUG to INFO to WARN to ERROR to LOGDIE
#use Smart::Comments;

#------------------------------------------------------------------
#  Variables
#------------------------------------------------------------------
my $model = LIMS2::Model->new( user => 'webapp' ); # DB connection
my %stored_values = (); # to re-use well data as much as possible rather than re-fetching
my $wells_deleted = 0; # count of deleted wells
my $well_inserts_succeeded = 0; # count of inserts
my $well_inserts_failed = 0; # count of failures

#------------------------------------------------------------------
#  Accessible method
#------------------------------------------------------------------
# Determine well decendants and write result string
sub well_descendants {

    # passed design well ID, output LOG filepath
    my $design_well_id = shift;

    my %results;

    try {
        _well_descendants($design_well_id);
        $results{ exit_code } = 0;
        $results{ count_deletes } = $wells_deleted;
        $results{ count_inserts } = $well_inserts_succeeded;
        $results{ count_fails } = $well_inserts_failed;
    } catch {
        # error
        WARN caller()." Well ID $design_well_id : Exception caught:\nException message : $_";
        $results{ exit_code } = 1;
        $results{ error_msg } = $_;
    };
    return \%results;
}

sub _well_descendants {
    my $design_well_id = shift;

    my $design_well = try { $model->retrieve_well( { id => $design_well_id } ) };

    if (defined $design_well) {
        # delete existing rows for this design well (if any)
        my $rows_deleted = delete_summary_rows_for_design_well($design_well_id);
        if(defined $rows_deleted && $rows_deleted > 0) {
            $wells_deleted = $rows_deleted;
            #warn "Well ID $design_well_id : deleted $rows_deleted summary rows.\n";
        }
    } else {
        # no design well exists for that ID, error
        LOGDIE caller()." Well ID $design_well_id : No design well object found, cannot fetch descendant trails :";
    }

    # returned array contains well list and trails list
    my @return_array = $design_well->descendants->depth_first_traversal_with_trails($design_well, [], [], [], 0);
    my ( $well_list, $all_trails ) = @return_array;         # return two array refs

    # dereference trails array
    my @design_well_trails = @{$all_trails};

    #TODO: can we weaken the circular ref within design_well here?
    $design_well = undef;                                   # free memory
    $well_list = undef;

    my $trails_index = 0;
    while ( $design_well_trails[$trails_index] ) {

        my %summary_row_values; # hash to contain column values for rows
        my %done = ();          # hash keeping track of done plate types

        # Loop through the wells in the trail
        foreach my $curr_well (reverse @{$design_well_trails[$trails_index]}){

            my $params = {
                'summary_row_values' => \%summary_row_values,
                'done' => \%done,
                'curr_well' => $curr_well,
            };

            # create the output array for this well
            add_to_output_for_well($params);

            $curr_well = undef;             # memory clear up
        }

        # insert to DB
        my $inserts = insert_summary_row_via_dbix ( \%summary_row_values ) or WARN caller()." Insert failed for well ID $design_well_id";

        if($inserts) {
            $well_inserts_succeeded += 1;
        } else {
            $well_inserts_failed += 1;
        }

        %done = ();

        # increment index
        $trails_index++;
    }

    INFO caller()." Well ID $design_well_id : Leaf node deletes/inserts/fails = $wells_deleted/$well_inserts_succeeded/$well_inserts_failed";
    return;
}


# append to array for a well in a trail
sub add_to_output_for_well {
    my $params = shift;

    my $curr_plate_type_id = $params->{ curr_well }->plate->type->id;

    my @include_types = ('DESIGN','INT','FINAL','FINAL_PICK','DNA','EP','EP_PICK','SEP','SEP_PICK','FP','SFP');

    return unless any { $curr_plate_type_id eq $_ } @include_types;

    return if exists $params->{done}->{$curr_plate_type_id};

    DEBUG caller()." Processing type = $curr_plate_type_id";

    fetch_values_for_type_DESIGN($params)     if ($curr_plate_type_id eq 'DESIGN');
    fetch_values_for_type_INT($params)        if ($curr_plate_type_id eq 'INT');
    fetch_values_for_type_FINAL($params)      if ($curr_plate_type_id eq 'FINAL');
    fetch_values_for_type_FINAL_PICK($params) if ($curr_plate_type_id eq 'FINAL_PICK');
    fetch_values_for_type_DNA($params)        if ($curr_plate_type_id eq 'DNA');
    fetch_values_for_type_EP($params)         if ($curr_plate_type_id eq 'EP');
    fetch_values_for_type_EP_PICK($params)    if ($curr_plate_type_id eq 'EP_PICK');
    fetch_values_for_type_SEP($params)        if ($curr_plate_type_id eq 'SEP');
    fetch_values_for_type_SEP_PICK($params)   if ($curr_plate_type_id eq 'SEP_PICK');
    fetch_values_for_type_FP($params)         if ($curr_plate_type_id eq 'FP');
    fetch_values_for_type_SFP($params)        if ($curr_plate_type_id eq 'SFP');

    # add element in hash to indicate type is done
    $params->{done}->{$curr_plate_type_id} = 1;

    return;
}

# values specific to DESIGN wells
sub fetch_values_for_type_DESIGN {
    my $params = shift;

	if( (not exists $stored_values{ stored_design_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_design_well_id }) ) {
		# different well to previous cycle, so must fetch and store new values
        DEBUG caller()."Fetching new values for DESIGN well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_design_well_id' }             = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_design_well_name' }           = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_design_plate_id' }            = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_design_plate_name' }          = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_design_well_created_ts' }     = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_design_well_assay_complete' } = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_design_well_accepted' }       = $params->{ curr_well }->is_accepted; # well accepted (with override)

        $stored_values{ 'stored_design_id' }                  = $params->{ curr_well }->design->id; # design DB identifier
        $stored_values{ 'stored_design_name' }                = $params->{ curr_well }->design->name; # design name
        $stored_values{ 'stored_design_phase' }               = $params->{ curr_well }->design->phase; # e.g. -1,0,1,2
        $stored_values{ 'stored_design_type_id' }             = $params->{ curr_well }->design->design_type_id; # design type, e.g. conditional, deletion, insertion, artificial-intron, intron-replacement, cre-bac
        $stored_values{ 'stored_design_bacs_string' }         = fetch_well_bacs_string( $params->{ curr_well } ); # BACs associated with this design 
        my @genes_array = fetch_well_gene_symbols_and_ids( $params->{ curr_well } );
        $stored_values{ 'stored_design_gene_symbols' }        = $genes_array[0]; # gene symbols
        $stored_values{ 'stored_design_gene_ids' }            = $genes_array[1]; # gene ids
    }

	# copy stored values into the current summary output row
    $params->{ summary_row_values }{ 'design_well_id' }             = $stored_values{ stored_design_well_id };
    $params->{ summary_row_values }{ 'design_well_name' }           = $stored_values{ stored_design_well_name };
    $params->{ summary_row_values }{ 'design_plate_id' }            = $stored_values{ stored_design_plate_id };
    $params->{ summary_row_values }{ 'design_plate_name' }          = $stored_values{ stored_design_plate_name };
    $params->{ summary_row_values }{ 'design_well_created_ts' }     = $stored_values{ stored_design_well_created_ts };
    $params->{ summary_row_values }{ 'design_well_assay_complete' } = $stored_values{ stored_design_well_assay_complete };
    $params->{ summary_row_values }{ 'design_well_accepted' }       = $stored_values{ stored_design_well_accepted };

    $params->{ summary_row_values }{ 'design_id' }                  = $stored_values{ stored_design_id };
    $params->{ summary_row_values }{ 'design_name' }                = $stored_values{ stored_design_name };
    $params->{ summary_row_values }{ 'design_phase' }               = $stored_values{ stored_design_phase };
    $params->{ summary_row_values }{ 'design_type' }                = $stored_values{ stored_design_type_id };
    $params->{ summary_row_values }{ 'design_bacs' }                = $stored_values{ stored_design_bacs_string };
    $params->{ summary_row_values }{ 'design_gene_symbol' }         = $stored_values{ stored_design_gene_symbols };
    $params->{ summary_row_values }{ 'design_gene_id' }             = $stored_values{ stored_design_gene_ids };
    return;
}

# values specific to INT wells
sub fetch_values_for_type_INT {
    my $params = shift;

    if( (not exists $stored_values{ stored_int_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_int_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for INT well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_int_well_id' }             = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_int_well_name' }           = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_int_plate_id' }            = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_int_plate_name' }          = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_int_well_created_ts' }     = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_int_well_assay_complete' } = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_int_well_accepted' }       = $params->{ curr_well }->is_accepted; # well accepted (with override)

		$stored_values{ 'stored_int_backbone_name' }       = $params->{ curr_well }->backbone->name;   # backbone name
		$stored_values{ 'stored_int_cassette_name' }       = $params->{ curr_well }->cassette->name; # cassette name
		$stored_values{ 'stored_int_qc_seq_pass' }         = try{ $params->{ curr_well }->well_qc_sequencing_result->pass }; # qc sequencing test result
    }

    # copy stored values into the current summary output row
    $params->{ summary_row_values }{ 'int_well_id' }             = $stored_values{ stored_int_well_id };
    $params->{ summary_row_values }{ 'int_well_name' }           = $stored_values{ stored_int_well_name };
    $params->{ summary_row_values }{ 'int_plate_id' }            = $stored_values{ stored_int_plate_id };
    $params->{ summary_row_values }{ 'int_plate_name' }          = $stored_values{ stored_int_plate_name };
    $params->{ summary_row_values }{ 'int_well_created_ts' }     = $stored_values{ stored_int_well_created_ts };
    $params->{ summary_row_values }{ 'int_well_assay_complete' } = $stored_values{ stored_int_well_assay_complete };
    $params->{ summary_row_values }{ 'int_well_accepted' }       = $stored_values{ stored_int_well_accepted };

    $params->{ summary_row_values }{ 'int_backbone_name' }       = $stored_values{ stored_int_backbone_name };
    $params->{ summary_row_values }{ 'int_cassette_name' }       = $stored_values{ stored_int_cassette_name };
    $params->{ summary_row_values }{ 'int_qc_seq_pass' }         = $stored_values{ stored_int_qc_seq_pass };

    # valid primers?    -> qc test result and valid primers are outputs of QC system and should be linked to each well for INT, FINAL, POSTINT, DNA, EP_PICK
    return;
}

# values specific to FINAL wells
sub fetch_values_for_type_FINAL {
    my $params = shift;

    if( (not exists $stored_values{ stored_final_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_final_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for FINAL well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_final_well_id' }              = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_final_well_name' }            = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_final_plate_id' }             = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_final_plate_name' }           = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_final_well_created_ts' }      = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_final_well_assay_complete' }  = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_final_well_accepted' }        = $params->{ curr_well }->is_accepted; # well accepted (with override)

		$stored_values{ 'stored_final_backbone_name' }        = $params->{ curr_well }->backbone->name; # backbone name
		$stored_values{ 'stored_final_cassette_name' }        = $params->{ curr_well }->cassette->name; # cassette name
		$stored_values{ 'stored_final_qc_seq_pass' }          = try{ $params->{ curr_well }->well_qc_sequencing_result->pass }; # qc sequencing test result
        $stored_values{ 'stored_final_cassette_promoter' }    = $params->{ curr_well }->cassette->promoter; # final_cassette_promoter
		$stored_values{ 'stored_final_cassette_cre' }         = $params->{ curr_well }->cassette->cre; # final_cassette_cre
		$stored_values{ 'stored_final_cassette_conditional' } = $params->{ curr_well }->cassette->conditional;      # final_cassette_conditional
		$stored_values{ 'stored_final_recombinase_id' }       = join( '_', @{$params->{ curr_well }->recombinases}); # process recombinase
    }

    $params->{ summary_row_values }{ 'final_well_id' }              = $stored_values{ stored_final_well_id };
    $params->{ summary_row_values }{ 'final_well_name' }            = $stored_values{ stored_final_well_name };
    $params->{ summary_row_values }{ 'final_plate_id' }             = $stored_values{ stored_final_plate_id };
    $params->{ summary_row_values }{ 'final_plate_name' }           = $stored_values{ stored_final_plate_name };
    $params->{ summary_row_values }{ 'final_well_assay_complete' }  = $stored_values{ stored_final_well_assay_complete };
    $params->{ summary_row_values }{ 'final_well_created_ts' }      = $stored_values{ stored_final_well_created_ts };
    $params->{ summary_row_values }{ 'final_well_accepted' }        = $stored_values{ stored_final_well_accepted };
    
    $params->{ summary_row_values }{ 'final_backbone_name' }        = $stored_values{ stored_final_backbone_name };
    $params->{ summary_row_values }{ 'final_cassette_name' }        = $stored_values{ stored_final_cassette_name };
    $params->{ summary_row_values }{ 'final_qc_seq_pass' }          = $stored_values{ stored_final_qc_seq_pass };
    $params->{ summary_row_values }{ 'final_cassette_promoter' }    = $stored_values{ stored_final_cassette_promoter };
    $params->{ summary_row_values }{ 'final_cassette_cre' }         = $stored_values{ stored_final_cassette_cre };
    $params->{ summary_row_values }{ 'final_cassette_conditional' } = $stored_values{ stored_final_cassette_conditional };
    $params->{ summary_row_values }{ 'final_recombinase_id' }       = $stored_values{ stored_final_recombinase_id };
    # valid primers?
    return;
}

# values specific to FINAL_PICK wells
sub fetch_values_for_type_FINAL_PICK {
    my $params = shift;

    if( (not exists $stored_values{ stored_final_pick_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_final_pick_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for FINAL_PICK well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_final_pick_well_id' }              = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_final_pick_well_name' }            = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_final_pick_plate_id' }             = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_final_pick_plate_name' }           = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_final_pick_well_created_ts' }      = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_final_pick_well_assay_complete' }  = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_final_pick_well_accepted' }        = $params->{ curr_well }->is_accepted; # well accepted (with override)

		$stored_values{ 'stored_final_pick_backbone_name' }        = $params->{ curr_well }->backbone->name; # backbone name
		$stored_values{ 'stored_final_pick_cassette_name' }        = $params->{ curr_well }->cassette->name; # cassette name
		$stored_values{ 'stored_final_pick_qc_seq_pass' }          = try{ $params->{ curr_well }->well_qc_sequencing_result->pass }; # qc sequencing test result
        $stored_values{ 'stored_final_pick_cassette_promoter' }    = $params->{ curr_well }->cassette->promoter; # final_cassette_promoter
		$stored_values{ 'stored_final_pick_cassette_cre' }         = $params->{ curr_well }->cassette->cre; # final_cassette_cre
		$stored_values{ 'stored_final_pick_cassette_conditional' } = $params->{ curr_well }->cassette->conditional;      # final_cassette_conditional
		$stored_values{ 'stored_final_pick_recombinase_id' }       = join( '_', @{$params->{ curr_well }->recombinases}); # process recombinase
    }

    $params->{ summary_row_values }{ 'final_pick_well_id' }              = $stored_values{ stored_final_pick_well_id };
    $params->{ summary_row_values }{ 'final_pick_well_name' }            = $stored_values{ stored_final_pick_well_name };
    $params->{ summary_row_values }{ 'final_pick_plate_id' }             = $stored_values{ stored_final_pick_plate_id };
    $params->{ summary_row_values }{ 'final_pick_plate_name' }           = $stored_values{ stored_final_pick_plate_name };
    $params->{ summary_row_values }{ 'final_pick_well_assay_complete' }  = $stored_values{ stored_final_pick_well_assay_complete };
    $params->{ summary_row_values }{ 'final_pick_well_created_ts' }      = $stored_values{ stored_final_pick_well_created_ts };
    $params->{ summary_row_values }{ 'final_pick_well_accepted' }        = $stored_values{ stored_final_pick_well_accepted };
    
    $params->{ summary_row_values }{ 'final_pick_backbone_name' }        = $stored_values{ stored_final_pick_backbone_name };
    $params->{ summary_row_values }{ 'final_pick_cassette_name' }        = $stored_values{ stored_final_pick_cassette_name };
    $params->{ summary_row_values }{ 'final_pick_qc_seq_pass' }          = $stored_values{ stored_final_pick_qc_seq_pass };
    $params->{ summary_row_values }{ 'final_pick_cassette_promoter' }    = $stored_values{ stored_final_pick_cassette_promoter };
    $params->{ summary_row_values }{ 'final_pick_cassette_cre' }         = $stored_values{ stored_final_pick_cassette_cre };
    $params->{ summary_row_values }{ 'final_pick_cassette_conditional' } = $stored_values{ stored_final_pick_cassette_conditional };
    $params->{ summary_row_values }{ 'final_pick_recombinase_id' }       = $stored_values{ stored_final_pick_recombinase_id };
    # valid primers?
    return;
}

# values specific to DNA wells
sub fetch_values_for_type_DNA {
    my $params = shift;

    if( (not exists $stored_values{ stored_dna_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_dna_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for DNA well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_dna_well_id' }              = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_dna_well_name' }            = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_dna_plate_id' }             = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_dna_plate_name' }           = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_dna_well_created_ts' }      = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_dna_well_assay_complete' }  = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_dna_well_accepted' }        = $params->{ curr_well }->is_accepted; # well accepted (with override)

		$stored_values{ 'stored_dna_quality' }              = try { $params->{ curr_well }->well_dna_quality->quality }; # well dna quality e.g. M, L, ML, U
        $stored_values{ 'stored_dna_status_pass' }          = try { $params->{ curr_well }->well_dna_status->pass }; # well dna status e.g. t or f
        $stored_values{ 'stored_dna_qc_seq_pass' }          = try { $params->{ curr_well }->well_qc_sequencing_result->pass }; # qc sequencing test result
    }

    $params->{ summary_row_values }{ 'dna_well_id' }             = $stored_values{ stored_dna_well_id };
    $params->{ summary_row_values }{ 'dna_well_name' }           = $stored_values{ stored_dna_well_name };
    $params->{ summary_row_values }{ 'dna_plate_id' }            = $stored_values{ stored_dna_plate_id };
    $params->{ summary_row_values }{ 'dna_plate_name' }          = $stored_values{ stored_dna_plate_id };
    $params->{ summary_row_values }{ 'dna_well_assay_complete' } = $stored_values{ stored_dna_well_assay_complete };
    $params->{ summary_row_values }{ 'dna_well_created_ts' }     = $stored_values{ stored_dna_well_created_ts };
    $params->{ summary_row_values }{ 'dna_well_accepted' }       = $stored_values{ stored_dna_well_accepted }; 
    
    $params->{ summary_row_values }{ 'dna_quality' }             = $stored_values{ stored_dna_quality };
    $params->{ summary_row_values }{ 'dna_status_pass' }         = $stored_values{ stored_dna_status_pass };
    $params->{ summary_row_values }{ 'dna_qc_seq_pass' }         = $stored_values{ stored_dna_qc_seq_pass };
    # valid primers?
    return;
}

# values specific to EP wells
sub fetch_values_for_type_EP {
    my $params = shift;

    if( (not exists $stored_values{ stored_ep_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_ep_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for EP well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_ep_well_id' }                = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_ep_well_name' }              = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_ep_plate_id' }               = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_ep_plate_name' }             = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_ep_well_created_ts' }        = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_ep_well_assay_complete' }    = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_ep_well_accepted' }          = $params->{ curr_well }->is_accepted; # well accepted (with override)

        $stored_values{ 'stored_ep_colonies_rem_unstained' } = fetch_well_colony_count_remaining_unstained( $params->{ curr_well } ); # count colonies remaining unstained 
        $stored_values{ 'stored_ep_colonies_total' }         = fetch_well_colony_count_total( $params->{ curr_well } ); # count colonies total
        $stored_values{ 'stored_ep_colonies_picked' }        = fetch_well_colony_count_picked( $params->{ curr_well } ); # count colonies picked
        $stored_values{ 'stored_ep_first_cell_line_name' }   = try { $params->{ curr_well }->first_cell_line->name }; # first cell line name
    }

    $params->{ summary_row_values }{ 'ep_well_id' }                = $stored_values{ stored_ep_well_id };
    $params->{ summary_row_values }{ 'ep_well_name' }              = $stored_values{ stored_ep_well_name };
    $params->{ summary_row_values }{ 'ep_plate_id' }               = $stored_values{ stored_ep_plate_id };
    $params->{ summary_row_values }{ 'ep_plate_name' }             = $stored_values{ stored_ep_plate_id };
    $params->{ summary_row_values }{ 'ep_well_assay_complete' }    = $stored_values{ stored_ep_well_assay_complete };
    $params->{ summary_row_values }{ 'ep_well_created_ts' }        = $stored_values{ stored_ep_well_created_ts };
    $params->{ summary_row_values }{ 'ep_well_accepted' }          = $stored_values{ stored_ep_well_accepted }; 

    $params->{ summary_row_values }{ 'ep_colonies_rem_unstained' } = $stored_values{ stored_ep_colonies_rem_unstained }; 
    $params->{ summary_row_values }{ 'ep_colonies_total' }         = $stored_values{ stored_ep_colonies_total }; 
    $params->{ summary_row_values }{ 'ep_colonies_picked' }        = $stored_values{ stored_ep_colonies_picked }; 
    $params->{ summary_row_values }{ 'ep_first_cell_line_name' }   = $stored_values{ stored_ep_first_cell_line_name }; 
    return;
}

# values specific to EP_PICK wells
sub fetch_values_for_type_EP_PICK {
    my $params = shift;

    if( (not exists $stored_values{ stored_ep_pick_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_ep_pick_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for EP_PICK well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_ep_pick_well_id' }                = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_ep_pick_well_name' }              = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_ep_pick_plate_id' }               = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_ep_pick_plate_name' }             = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_ep_pick_well_created_ts' }        = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_ep_pick_well_assay_complete' }    = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_ep_pick_well_accepted' }          = $params->{ curr_well }->is_accepted; # well accepted (with override)

        $stored_values{ 'stored_ep_pick_qc_seq_pass' }            = try{ $params->{ curr_well }->well_qc_sequencing_result->pass };  # qc sequencing test result
    }

    $params->{ summary_row_values }{ 'ep_pick_well_id' }              = $stored_values{ stored_ep_pick_well_id };
    $params->{ summary_row_values }{ 'ep_pick_well_name' }            = $stored_values{ stored_ep_pick_well_name };
    $params->{ summary_row_values }{ 'ep_pick_plate_id' }             = $stored_values{ stored_ep_pick_plate_id };
    $params->{ summary_row_values }{ 'ep_pick_plate_name' }           = $stored_values{ stored_ep_pick_plate_id };
    $params->{ summary_row_values }{ 'ep_pick_well_assay_complete' }  = $stored_values{ stored_ep_pick_well_assay_complete };
    $params->{ summary_row_values }{ 'ep_pick_well_created_ts' }      = $stored_values{ stored_ep_pick_well_created_ts };
    $params->{ summary_row_values }{ 'ep_pick_well_accepted' }        = $stored_values{ stored_ep_pick_well_accepted }; 

    $params->{ summary_row_values }{ 'ep_pick_qc_seq_pass' }          = $stored_values{ stored_ep_pick_qc_seq_pass }; 
    # valid primers?
    return;
}

# values specific to SEP wells
sub fetch_values_for_type_SEP {
    my $params = shift;

    if( (not exists $stored_values{ stored_sep_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_sep_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for SEP well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_sep_well_id' }                = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_sep_well_name' }              = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_sep_plate_id' }               = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_sep_plate_name' }             = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_sep_well_created_ts' }        = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_sep_well_assay_complete' }    = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_sep_well_accepted' }          = $params->{ curr_well }->is_accepted; # well accepted (with override)

        $stored_values{ 'stored_sep_second_cell_line_name' }  = try{ $params->{ curr_well }->second_cell_line->name }; # second cell line name
    }

    $params->{ summary_row_values }{ 'sep_well_id' }               = $stored_values{ stored_sep_well_id };
    $params->{ summary_row_values }{ 'sep_well_name' }             = $stored_values{ stored_sep_well_name };
    $params->{ summary_row_values }{ 'sep_plate_id' }              = $stored_values{ stored_sep_plate_id };
    $params->{ summary_row_values }{ 'sep_plate_name' }            = $stored_values{ stored_sep_plate_id };
    $params->{ summary_row_values }{ 'sep_well_assay_complete' }   = $stored_values{ stored_sep_well_assay_complete };
    $params->{ summary_row_values }{ 'sep_well_created_ts' }       = $stored_values{ stored_sep_well_created_ts };
    $params->{ summary_row_values }{ 'sep_well_accepted' }         = $stored_values{ stored_sep_well_accepted }; 

    $params->{ summary_row_values }{ 'sep_second_cell_line_name' } = try{ $params->{ curr_well }->second_cell_line->name }; # second cell line name
    # colony count or only on EP?
    return;
}

# values specific to SEP_PICK wells
sub fetch_values_for_type_SEP_PICK {
    my $params = shift;

    if( (not exists $stored_values{ stored_sep_pick_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_sep_pick_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for SEP_PICK well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_sep_pick_well_id' }                = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_sep_pick_well_name' }              = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_sep_pick_plate_id' }               = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_sep_pick_plate_name' }             = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_sep_pick_well_created_ts' }        = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_sep_pick_well_assay_complete' }    = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_sep_pick_well_accepted' }          = $params->{ curr_well }->is_accepted; # well accepted (with override)

        $stored_values{ 'stored_sep_pick_qc_seq_pass' }            = try{ $params->{ curr_well }->well_qc_sequencing_result->pass }; # qc sequencing test result
    }

    $params->{ summary_row_values }{ 'sep_pick_well_id' }               = $stored_values{ stored_sep_pick_well_id };
    $params->{ summary_row_values }{ 'sep_pick_well_name' }             = $stored_values{ stored_sep_pick_well_name };
    $params->{ summary_row_values }{ 'sep_pick_plate_id' }              = $stored_values{ stored_sep_pick_plate_id };
    $params->{ summary_row_values }{ 'sep_pick_plate_name' }            = $stored_values{ stored_sep_pick_plate_id };
    $params->{ summary_row_values }{ 'sep_pick_well_assay_complete' }   = $stored_values{ stored_sep_pick_well_assay_complete };
    $params->{ summary_row_values }{ 'sep_pick_well_created_ts' }       = $stored_values{ stored_sep_pick_well_created_ts };
    $params->{ summary_row_values }{ 'sep_pick_well_accepted' }         = $stored_values{ stored_sep_pick_well_accepted }; 

    $params->{ summary_row_values }{ 'sep_pick_qc_seq_pass' }           = $stored_values{ stored_sep_pick_qc_seq_pass }; 
    # valid primers?
    return;
}

# values specific to FP wells
sub fetch_values_for_type_FP {
    my $params = shift;

    if( (not exists $stored_values{ stored_fp_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_fp_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for FP well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_fp_well_id' }                = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_fp_well_name' }              = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_fp_plate_id' }               = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_fp_plate_name' }             = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_fp_well_created_ts' }        = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_fp_well_assay_complete' }    = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_fp_well_accepted' }          = $params->{ curr_well }->is_accepted; # well accepted (with override)
    }

    $params->{ summary_row_values }{ 'fp_well_id' }               = $stored_values{ stored_fp_well_id };
    $params->{ summary_row_values }{ 'fp_well_name' }             = $stored_values{ stored_fp_well_name };
    $params->{ summary_row_values }{ 'fp_plate_id' }              = $stored_values{ stored_fp_plate_id };
    $params->{ summary_row_values }{ 'fp_plate_name' }            = $stored_values{ stored_fp_plate_id };
    $params->{ summary_row_values }{ 'fp_well_assay_complete' }   = $stored_values{ stored_fp_well_assay_complete };
    $params->{ summary_row_values }{ 'fp_well_created_ts' }       = $stored_values{ stored_fp_well_created_ts };
    $params->{ summary_row_values }{ 'fp_well_accepted' }         = $stored_values{ stored_fp_well_accepted }; 
    return;
}

# values specific to SFP wells
sub fetch_values_for_type_SFP {
    my $params = shift;

    if( (not exists $stored_values{ stored_sfp_well_id }) || ($params->{ curr_well }->id != $stored_values{ stored_sfp_well_id }) ) {
	    # different well to previous cycle, so must fetch and store new values
		DEBUG caller()."Fetching new values for SFP well : ".$params->{ curr_well }->id;
		$stored_values{ 'stored_sfp_well_id' }                = $params->{ curr_well }->id; # well id
        $stored_values{ 'stored_sfp_well_name' }              = $params->{ curr_well }->name; # well name e.g. A01 to H12 (or P24 for 384-well plates)
        $stored_values{ 'stored_sfp_plate_id' }               = $params->{ curr_well }->plate->id; # plate id
        $stored_values{ 'stored_sfp_plate_name' }             = $params->{ curr_well }->plate->name; # plate name e.g. MOHSAQ60001_C_1
        $stored_values{ 'stored_sfp_well_created_ts' }        = try{ $params->{ curr_well }->created_at->iso8601 }; # well created timestamp
        $stored_values{ 'stored_sfp_well_assay_complete' }    = try{ $params->{ curr_well }->assay_complete->iso8601 }; # assay complete timestamp
        $stored_values{ 'stored_sfp_well_accepted' }          = $params->{ curr_well }->is_accepted; # well accepted (with override)
    }

    $params->{ summary_row_values }{ 'sfp_well_id' }               = $stored_values{ stored_sfp_well_id };
    $params->{ summary_row_values }{ 'sfp_well_name' }             = $stored_values{ stored_sfp_well_name };
    $params->{ summary_row_values }{ 'sfp_plate_id' }              = $stored_values{ stored_sfp_plate_id };
    $params->{ summary_row_values }{ 'sfp_plate_name' }            = $stored_values{ stored_sfp_plate_id };
    $params->{ summary_row_values }{ 'sfp_well_assay_complete' }   = $stored_values{ stored_sfp_well_assay_complete };
    $params->{ summary_row_values }{ 'sfp_well_created_ts' }       = $stored_values{ stored_sfp_well_created_ts };
    $params->{ summary_row_values }{ 'sfp_well_accepted' }         = $stored_values{ stored_sfp_well_accepted }; 
    return;
}

# well qc sequencing test result, if any
#sub fetch_well_qc_sequencing_result {
#    my $well = shift;
#   my $qc_result = try{ $well->well_qc_sequencing_result->pass };
#    return $qc_result;
#}

# well first cell line name, if any
#sub fetch_well_first_cell_line {
#    my $well = shift;
#    my $cell_line = try { $well->first_cell_line->name };   
#    return $cell_line;
#}

# well second cell line name, if any
#sub fetch_well_second_cell_line {
#    my $well = shift;
#    my $cell_line = try{ $well->second_cell_line->name };
#    return $cell_line;
#}

# BACS ids as a simple combined field, if any
sub fetch_well_bacs_string {

    my $well = shift;

    my $process = $well->process_output_wells->first->process;

	my $return_string;

    if (defined $process) {
        my @bacs_names = uniq( map { $_->bac_clone->name } $process->process_bacs );
        $return_string = join( '_', @bacs_names);
    }

    return $return_string;
}

# gene(s) associated with this well combined as single symbol and id strings
sub fetch_well_gene_symbols_and_ids {
    my $well = shift;

    my @gene_ids = uniq map { $_->gene_id } $well->design->genes;

    # try to fetch gene symbols
    my @gene_symbols;
    try {
        for my $gene_id ( @gene_ids ) {
            my $gene_symbol = $model->retrieve_gene( { search_term => $gene_id,  species => 'Mouse' } )->{gene_symbol};
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

# dna quality for a well, if exists
#sub fetch_well_dna_quality {
#    my $well = shift;
#    return try { $well->well_dna_quality->quality }; # well dna quality e.g. M, L, ML, U
#}

# dna status for a well, if exists
#sub fetch_well_dna_status {
#    my $well = shift;
#    return try { $well->well_dna_status->pass }; 
#}

# recombinase used, if any
#sub fetch_well_process_recombinase {
#    my $well = shift;
#    return join( '_', @{$well->recombinases});
#}

# insert row into database
sub insert_summary_row_via_dbix {
    my $summary_data = shift;

	### $summary_data
	
    my $result = try { $model->schema->resultset('Summary')->create($summary_data) } catch { ERROR "Error inserting well, Exception:".$_};

	return defined $result ? 1 : 0; # if defined return 1 else 0
}

# select the rows for this design well and delete them
sub delete_summary_rows_for_design_well {
    my $well_id = shift;

    my $wells_rs = $model->schema->resultset('Summary')->search({
        design_well_id => $well_id,
    });

    my $number_deletes;

    try { $number_deletes = $wells_rs->delete() };

    return $number_deletes;
}

1;