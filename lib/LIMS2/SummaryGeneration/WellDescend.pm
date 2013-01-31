#!/usr/bin/perl

package LIMS2::SummaryGeneration::WellDescend;

use strict;
use List::MoreUtils qw(uniq);

use Devel::Leak;		# TODO: remove before production

# Insert query for summaries table
my $SQL_INSERT_SUMMARY = <<'EOT';
INSERT INTO public.summaries (
	design_gene_id,
	design_gene_symbol,
	design_bacs,
	design_plate_name,
	design_plate_id,
	design_well_name,
	design_well_id,
	design_well_created_ts,
	design_type,
	design_phase,
	design_name,
	design_id,
	design_well_assay_complete,
	design_well_accepted,
	int_plate_name,
	int_plate_id,
	int_well_name,
	int_well_id,
	int_well_created_ts,
	int_qc_seq_pass,
	int_cassette_name,
	int_backbone_name,
	int_well_assay_complete,
	int_well_accepted,
	final_plate_name,
	final_plate_id,
	final_well_name,
	final_well_id,
	final_well_created_ts,
	final_recombinase_id,
	final_qc_seq_pass,
	final_cassette_name,
	final_cassette_cre,
	final_cassette_promoter,
	final_cassette_conditional,
	final_backbone_name,
	final_well_assay_complete,
	final_well_accepted,
	final_pick_plate_name,
	final_pick_plate_id,
	final_pick_well_name,
	final_pick_well_id,
	final_pick_well_created_ts,
	final_pick_recombinase_id,
	final_pick_qc_seq_pass,
	final_pick_cassette_name,
	final_pick_cassette_cre,
	final_pick_cassette_promoter,
	final_pick_cassette_conditional,
	final_pick_backbone_name,
	final_pick_well_assay_complete,
	final_pick_well_accepted,
	dna_plate_name,
	dna_plate_id,
	dna_well_name,
	dna_well_id,
	dna_well_created_ts,
	dna_qc_seq_pass,
	dna_status_pass,
	dna_quality,
	dna_well_assay_complete,
	dna_well_accepted,
	ep_plate_name,
	ep_plate_id,
	ep_well_name,
	ep_well_id,
	ep_well_created_ts,
	ep_first_cell_line_name,
	ep_colonies_picked,
	ep_colonies_total,
	ep_colonies_rem_unstained,
	ep_well_assay_complete,
	ep_well_accepted,
	ep_pick_plate_name,
	ep_pick_plate_id,
	ep_pick_well_name,
	ep_pick_well_id,
	ep_pick_well_created_ts,
	ep_pick_qc_seq_pass,
	ep_pick_well_assay_complete,
	ep_pick_well_accepted,
	sep_plate_name,
	sep_plate_id,
	sep_well_name,
	sep_well_id,
	sep_well_created_ts,
	sep_second_cell_line_name,
	sep_well_assay_complete,
	sep_well_accepted,
	sep_pick_plate_name,
	sep_pick_plate_id,
	sep_pick_well_name,
	sep_pick_well_id,
	sep_pick_well_created_ts,
	sep_pick_qc_seq_pass,
	sep_pick_well_assay_complete,
	sep_pick_well_accepted,
	fp_plate_name,
	fp_plate_id,
	fp_well_name,
	fp_well_id,
	fp_well_created_ts,
	fp_well_assay_complete,
	fp_well_accepted,
	sfp_plate_name,
	sfp_plate_id,
	sfp_well_name,
	sfp_well_id,
	sfp_well_created_ts,
	sfp_well_assay_complete,
	sfp_well_accepted
) VALUES (
	?,?,?,?,?,?,?,?,?,?,?,?,?,?,
	?,?,?,?,?,?,?,?,?,?,
	?,?,?,?,?,?,?,?,?,?,?,?,?,?,
	?,?,?,?,?,?,?,?,?,?,?,?,?,?,
	?,?,?,?,?,?,?,?,?,?,?,
	?,?,?,?,?,?,?,?,?,?,?,?,
	?,?,?,?,?,?,?,?,
	?,?,?,?,?,?,
	?,?,?,?,?,?,?,?,
	?,?,?,?,?,?,?,
	?,?,?,?,?,?,?
)
;
EOT

my $NUMBER_SUMMARIES_FIELDS = 111;			# number of fields in table
my $MODEL;									# model for DB links

# Determine well decendants and write result string
sub well_descendants {
	
	# passed design well ID, output CSV filepath
    my ( $DESIGN_WELL_ID, $CSV_FILEPATH) = @_;
    
    my $well_inserts_succeeded = 0;
    my $well_inserts_failed = 0;
    
    #print "Well ID processing=$DESIGN_WELL_ID\n";
    
    $MODEL = LIMS2::Model->new( user => 'webapp', audit_user => $ENV{USER} );		# for lims2_live_as28 running on local
    my $DESIGN_WELL = $MODEL->retrieve_well( { id => $DESIGN_WELL_ID } );
    
    # returned array contains well list and trails list     
    my @return_array = $DESIGN_WELL->descendants->depth_first_traversal_with_trails($DESIGN_WELL, [], [], [], 0);
    my ( $well_list, $all_trails ) = @return_array;			# return two array refs
    
    # dereference trails array
    my @design_well_trails = @{$all_trails};
    
    $DESIGN_WELL = undef;									# free memory
    $well_list = undef;
    	
    my $trails_index = 0;
    
    while ( $design_well_trails[$trails_index] ) {
		
		#print "Trails index=$trails_index\n";
		
		#my $CURR_TRAIL = $design_well_trails[$trails_index];
		
		my @output;				# output array holding row details
        my %done = ();			# hash keeping track of done plate types
        
        # Loop through the wells in the trail
        #foreach my $curr_well (reverse @{$CURR_TRAIL}){
		foreach my $curr_well (reverse @{$design_well_trails[$trails_index]}){
			
			my $curr_plate_type_id = $curr_well->plate->type->id;
			
			foreach my $type ('DESIGN','INT','FINAL','FINAL_PICK','DNA','EP','EP_PICK','SEP','SEP_PICK','FP','SFP') {
				
                if($curr_plate_type_id eq $type){
					if(!exists $done{$type}){
						
						#print "Processing type = $type\n";

						# NB. unshift adds an element to the beginning of an array
						# i.e. output array is built up BACKWARDS
						
						if($curr_plate_type_id eq 'FINAL'){
						# check whether hierarchy contains a FINAL_PICK plate and fill if not
							if(!exists $done{'FINAL_PICK'}) {
								# 14 final_pick_plate_name,final_pick_plate_id,final_pick_well_name,final_pick_well_id,final_pick_well_created_ts,final_pick_recombinase,final_pick_qc_seq_pass,final_pick_cassette,final_pick_cassette_cre,final_pick_cassette_promoter,final_pick_cassette_conditional,final_pick_backbone,final_pick_well_assay_complete,final_pick_well_accepted
								my @FINPfill = ("") x 14;								
								unshift @output, @FINPfill;
							}
						}
						
						if($curr_plate_type_id eq 'DNA'){
							
							# check whether well hierarchy had an SEP step but not an EP step and fill for EP if not
							#print "DNA check\n";
							if((exists $done{'SEP'}) && (!exists $done{'EP'})){
								#11 ep_plate_name,ep_plate_id,ep_well_name,ep_well_id,ep_well_created_ts,ep_first_cell_line,ep_colonies_picked,ep_colonies_total,ep_colonies_rem_unstained,ep_well_assay_complete,ep_well_accepted,";
								my @EPfill = ("") x 11;								
								unshift @output, @EPfill;
							}
						}						
						
						# Common elements 
						# TODO: except for design plates
						#if($curr_plate_type_id ne 'DESIGN'){
							unshift @output, $curr_well->is_accepted;							# well accepted (with override)
							unshift @output, $curr_well->assay_complete;						# assay complete timestamp
						#}
					
                        if($curr_plate_type_id eq 'DESIGN'){
							
							unshift @output, $curr_well->design->id;							# design DB identifier
							unshift @output, $curr_well->design->name;							# design name
							unshift @output, $curr_well->design->phase;							# e.g. -1,0,1,2
                            unshift @output, $curr_well->design->design_type_id;				# design type, e.g. conditional, deletion, insertion, artificial-intron, intron-replacement, cre-bac
							# ? 
                        }
                        if($curr_plate_type_id eq 'INT'){
                            unshift @output, $curr_well->backbone->name;						# backbone name
                            unshift @output, $curr_well->cassette->name;						# cassette name
                            unshift @output, fetch_well_qc_sequencing_result( $curr_well ); 	# qc sequencing test result
                            # valid primers?	-> qc test result and valid primers are outputs of QC system and should be linked to each well for INT, FINAL, POSTINT, DNA, EP_PICK
        					# ?
                        }
                        if($curr_plate_type_id eq 'FINAL'){
							unshift @output, $curr_well->backbone->name;						# backbone name
							unshift @output, $curr_well->cassette->conditional;					# final_cassette_conditional
							unshift @output, $curr_well->cassette->promoter;					# final_cassette_promoter
							unshift @output, $curr_well->cassette->cre;							# final_cassette_cre							
                            unshift @output, $curr_well->cassette->name;						# cassette name
                            unshift @output, fetch_well_qc_sequencing_result( $curr_well ); 	# qc sequencing test result
                            unshift @output, fetch_well_process_recombinase( $curr_well ); 		# process recombinase
                            # valid primers?
                            # ?
                        }
                        if($curr_plate_type_id eq 'FINAL_PICK'){
							unshift @output, $curr_well->backbone->name;						# backbone name
							unshift @output, $curr_well->cassette->conditional;					# final_cassette_conditional
							unshift @output, $curr_well->cassette->promoter;					# final_cassette_promoter
							unshift @output, $curr_well->cassette->cre;							# final_cassette_cre							
                            unshift @output, $curr_well->cassette->name;						# cassette name
                            unshift @output, fetch_well_qc_sequencing_result( $curr_well ); 	# qc sequencing test result
                            unshift @output, fetch_well_process_recombinase( $curr_well ); 		# process recombinase
                            # valid primers?
                            # ?
                        }
                        if($curr_plate_type_id eq 'DNA'){
							unshift @output, fetch_well_dna_quality( $curr_well );				# well dna quality e.g. M, L, ML, U
							unshift @output, fetch_well_dna_status( $curr_well );				# well dna status e.g. t or f
							unshift @output, fetch_well_qc_sequencing_result( $curr_well );		# qc sequencing test result
                            # valid primers?
                            # ?
                        }
                        if($curr_plate_type_id eq 'EP'){
                            unshift @output, fetch_well_colony_count_remaining_unstained( $curr_well );	# count colonies remaining unstained 
                            unshift @output, fetch_well_colony_count_total( $curr_well );		# count colonies total
                            unshift @output, fetch_well_colony_count_picked( $curr_well );		# count colonies picked
                            unshift @output, fetch_well_first_cell_line( $curr_well );			# first cell line name
                            # ?
                        }
                        if($curr_plate_type_id eq 'EP_PICK'){
							unshift @output, fetch_well_qc_sequencing_result( $curr_well ); 	# qc sequencing test result
                            # valid primers?
                            # ?
                        }
                        
                        # XEP?
                        # process recombinase ? via process output well to process_recombinase table 
                        
                        if($curr_plate_type_id eq 'SEP'){
							unshift @output, fetch_well_second_cell_line( $curr_well );			# second cell line name
                            # colony count or only on EP?
        					# ?
                        }
                        if($curr_plate_type_id eq 'SEP_PICK'){
        					unshift @output, fetch_well_qc_sequencing_result( $curr_well ); 	# qc sequencing test result
                            # valid primers?
                            # ?
                        }
                        if($curr_plate_type_id eq 'FP'){
							# ? All the QC data which isn't available yet
                         	# ?
                        }
                        if($curr_plate_type_id eq 'SFP'){
							# ? All the QC data which isn't available yet
                         	# ?
                        }
                        
                        # common elements                        
                        unshift @output, $curr_well->created_at;								# well created timestamp
                        unshift @output, $curr_well->id;										# well id
                        unshift @output, $curr_well->name;										# well name e.g. A01 to H12 (or P24 for 384-well plates)
                        unshift @output, $curr_well->plate->id;									# plate id
                        unshift @output, $curr_well->plate->name;								# plate name e.g. MOHSAQ60001_C_1
                        
                        if($curr_plate_type_id eq 'DESIGN'){
                   
							unshift @output, fetch_well_bacs_string( $curr_well );				# BACs associated with this design	
							my @genes_array = fetch_well_gene_symbols_and_ids( $curr_well );		
							unshift @output, $genes_array[0]; 									# gene symbols
							unshift @output, $genes_array[1]; 									# gene ids
							@genes_array = undef;
                        }
                        						    
						if($curr_plate_type_id eq 'SFP'){
							# fill FP
							#7 fp_plate_name,fp_plate_id,fp_well_name,fp_well_id,fp_well_created_ts,fp_well_assay_complete,fp_well_accepted
							my @FPfill = ("") x 7;
							unshift @output, @FPfill;
						}						
						if($curr_plate_type_id eq 'FP'){
							# fill SEP_PICK then SEP
							#8 sep_pick_plate_name,sep_pick_plate_id,sep_pick_well_name,sep_pick_well_id,sep_pick_well_created_ts,sep_pick_qc_seq_pass,sep_pick_well_assay_complete,sep_pick_well_accepted
							my @SEPPICKfill = ("") x 8;
							unshift @output, @SEPPICKfill;
							
							#8 sep_plate_name,sep_plate_id,sep_well_name,sep_well_id,sep_well_created_ts,sep_second_cell_line,sep_well_assay_complete,sep_well_accepted
							my @SEPfill = ("") x 8;
							unshift @output, @SEPfill;
							
						}						
						if($curr_plate_type_id eq 'SEP'){
							# fill EP_PICK
							#8 ep_pick_plate_name,ep_pick_plate_id,ep_pick_well_name,ep_pick_well_id,ep_pick_well_created_ts,ep_pick_qc_seq_pass,ep_pick_well_assay_complete,ep_pick_well_accepted
							my @EPPICKfill = ("") x 8;
							unshift @output, @EPPICKfill;
						}						    
						                        
                        # add element in hash to indicate type is done
                        $done{$type} = 1;
                    }
                }
            }
            
            $curr_well = undef;				# memory clear up
            $curr_plate_type_id = undef;
        }
        
        # fill array out to max row size
        my $output_size = @output;
        my $increase_by = ($NUMBER_SUMMARIES_FIELDS-$output_size);
        if ($increase_by > 0) {
			my @outputfill = ("") x $increase_by;
			@output = (@output, @outputfill);
		}
        
        # create log row
        my $logmsg;
        foreach my $x (@output){
			if(!$x){$x = '-'};
			if(\$x == \$output[-1]) {
				$logmsg=$logmsg."$x";
			} else {
				$logmsg=$logmsg."$x,";
			}
		}		
		$logmsg=$logmsg."\n";
		
        # write output to csv log file, with exclusive lock(2)
        {
			open (my $OUTFILE, '>>', $CSV_FILEPATH) or die "Error: Summary data generation - cannot open output file $CSV_FILEPATH for append\nSystem message: $!\n";
			flock($OUTFILE, 2) or die "Error: Summary data generation - failed to lock output file $CSV_FILEPATH for append\nSystem message: $!\n";
			print $OUTFILE $logmsg;
			close $OUTFILE;
		}		
		
		# prepare output for DB write - replace empty strings with undefs in output for DB write
		foreach my $y (@output){
			if(!$y){$y = undef};
			if($y eq '-'){$y = undef};
		}
		
		# insert to DB
		#my $inserts_made = insert_summary_row ( \@output ) or warn "Insert failed for @output\nSystem message: $!\n";
		my $inserts_made = insert_summary_row_via_dbix ( \@output ) or warn "Insert failed for @output\nSystem message: $!\n";
				
		if($inserts_made > 0) {
			$well_inserts_succeeded += 1;
		} else {
			$well_inserts_failed += 1;
		}
		
		@output = undef;
		$design_well_trails[$trails_index] = undef;
		%done = undef;
		
		$trails_index++;
    }
    
    $MODEL = undef;
    $DESIGN_WELL = undef;
    $CSV_FILEPATH = undef;
    @design_well_trails = undef;
    
    #print "well ID : $DESIGN_WELL_ID inserts/fails = $well_inserts_succeeded/$well_inserts_failed\n";
    
    return ($well_inserts_succeeded, $well_inserts_failed);
}

# well qc sequencing test result, if any
sub fetch_well_qc_sequencing_result {
	my $well = $_[0];
	my $qc_result = $well->well_qc_sequencing_result;
	$well = undef;	
	if (defined $qc_result) {
		return $qc_result->pass;
	} else {
		return "";
	}	
}

# well first cell line name, if any
sub fetch_well_first_cell_line {
	my $well = $_[0];
	
	my $cell_line = $well->first_cell_line;	
	$well = undef;	
	if (defined $cell_line) {
		return $cell_line->name;
	} else {
		return "";
	}	
}

# well second cell line name, if any
sub fetch_well_second_cell_line {
	my $well = $_[0];
	
	my $cell_line = $well->second_cell_line;
	$well = undef;	
	if (defined $cell_line) {
		return $cell_line->name;
	} else {
		return "";
	}	
}

# BACS ids as a simple combined field, if any
sub fetch_well_bacs_string {
	
	my ( $well ) = @_;
	
	my $bacs_string = "";
	
	my $process = $well->process_output_wells->first->process;
	if (defined $process) {

		my @bacs_ids = uniq( map { $_->bac_clone_id } $process->process_bacs );
		
		foreach my $bacs_id ( @bacs_ids ) {
			my $bac_rs = $MODEL->schema->resultset('BacClone')->search(
				{ id => $bacs_id }
			);
						
			my $bac = $bac_rs->first;
			my $bac_name = $bac->name;	

			if(\$bacs_id == \$bacs_ids[-1]) {
				$bacs_string=$bacs_string.$bac_name;
			} else {
				$bacs_string=$bacs_string.$bac_name."_";
			}
			
			$bac_rs 	= undef;
			$bac 		= undef;
			$bac_name 	= undef;
		}
		
		@bacs_ids = undef;
	}	
	
	$process = undef;
	
	return $bacs_string;
}

# gene(s) associated with this well combined as single symbol and id strings
sub fetch_well_gene_symbols_and_ids {
	my $well = $_[0];
	
	my @gene_ids = uniq map { $_->gene_id } $well->design->genes;
	
	my $gene_symbols_string = "";
	my $gene_ids_string = "";
		
	# try to fetch gene symbols
	eval{
		my @gene_symbols  = uniq map {
		   $MODEL->retrieve_gene(
			   { species => 'Mouse', search_term => $_ }
		   )->{gene_symbol}
		} @gene_ids;
		
		foreach my $gene_symbol ( @gene_symbols ) {
			if(\$gene_symbol == \$gene_symbols[-1]) {
				$gene_symbols_string=$gene_symbols_string.$gene_symbol;
			} else {
				$gene_symbols_string=$gene_symbols_string.$gene_symbol."_";
			}
		}		
		@gene_symbols = undef;
		
	};
	if ($@){
		# catch failure to identify symbols
		$gene_symbols_string = "";
	}
	
	foreach my $gene_id ( @gene_ids ) {
		if(\$gene_id == \$gene_ids[-1]) {
			$gene_ids_string=$gene_ids_string.$gene_id;
		} else {
			$gene_ids_string=$gene_ids_string.$gene_id."_";
		}
	}
	
	$well = undef;
	@gene_ids = undef;
	
	#my @return_array = ( $gene_symbols_string, $gene_ids_string );
	#return @return_array;
	return ( $gene_symbols_string, $gene_ids_string );
}

# count of colonies picked for a well, if count exists
sub fetch_well_colony_count_picked {
	my $well = shift;
	
	my $colony_count_rs = $well->well_colony_counts( { colony_count_type_id => 'picked_colonies' } );
	if (defined $colony_count_rs->first) {
		my $num_colonies = $colony_count_rs->first->colony_count;
		$colony_count_rs = undef;
		return $num_colonies;
	} else {
		$colony_count_rs = undef;
		return "";
	}
}

# count of colonies total for a well, if count exists
sub fetch_well_colony_count_total {
	my $well = shift;
	
	my $colony_count_rs = $well->well_colony_counts( { colony_count_type_id => 'total_colonies' } );
	if (defined $colony_count_rs->first) {
		my $num_colonies = $colony_count_rs->first->colony_count;
		$colony_count_rs = undef;
		return $num_colonies;
	} else {
		$colony_count_rs = undef;
		return "";
	}
}

# count of colonies remaining unstained for a well, if count exists
sub fetch_well_colony_count_remaining_unstained {
	my $well = shift;
	
	my $colony_count_rs = $well->well_colony_counts( { colony_count_type_id => 'remaining_unstained_colonies' } );
	$well = undef;
	if (defined $colony_count_rs->first) {
		my $num_colonies = $colony_count_rs->first->colony_count;
		$colony_count_rs = undef;
		return $num_colonies;
	} else {
		$colony_count_rs = undef;
		return "";
	}
}

# dna quality for a well, if exists
sub fetch_well_dna_quality {
	my $well = shift;
	
	my $well_dna_quality = $well->well_dna_quality;
	$well = undef;
	if(defined $well_dna_quality) {
		return $well_dna_quality->quality;				# well dna quality e.g. M, L, ML, U
	} else {
		return "";
	}
}
	
# dna status for a well, if exists
sub fetch_well_dna_status {
	my $well = shift;
	
	my $well_dna_status = $well->well_dna_status;
	$well = undef;
	if(defined $well_dna_status) {
		return $well_dna_status->pass;					# well dna pass, t or f
	} else {
		return "";
	}
}

# recombinase used, if any
sub fetch_well_process_recombinase {
	my $well = shift;
	
	my $recombinase_string = "";
	
	# TODO: make more efficient so not copying arrays like this
	my @recombinases = @{$well->recombinases};
	
	foreach my $well_recombinase_id ( @recombinases ) {
		if(\$well_recombinase_id == \$recombinases[-1]) {
			$recombinase_string=$recombinase_string.$well_recombinase_id;
		} else {
			$recombinase_string=$recombinase_string.$well_recombinase_id."_";
		}
	}
	
	@recombinases = undef;
	
	return $recombinase_string;
}

# insert a row into the database via DBI
#sub insert_summary_row {
#	my ( $output ) = @_;
#	
#	return $MODEL->schema->storage->dbh_do(
#	    sub {
#           my ( $storage, $dbh ) = @_;
#          
#            my $insert_handle = $dbh->prepare( $SQL_INSERT_SUMMARY );
#         
#			die "Couldn't prepare insert query; aborting"
#				unless defined $insert_handle;
#
#			$insert_handle->execute(@{$output}) or return 0;
#       }
#    );	
#}

# insert a row into the database via DBIx
sub insert_summary_row_via_dbix {
	my @output = shift;
	
	$MODEL->schema->populate('Summary', [
    [qw/
    design_gene_id
	design_gene_symbol
	design_bacs
	design_plate_name
	design_plate_id
	design_well_name
	design_well_id
	design_well_created_ts
	design_type
	design_phase
	design_name
	design_id
	design_well_assay_complete
	design_well_accepted
	int_plate_name
	int_plate_id
	int_well_name
	int_well_id
	int_well_created_ts
	int_qc_seq_pass
	int_cassette_name
	int_backbone_name
	int_well_assay_complete
	int_well_accepted
	final_plate_name
	final_plate_id
	final_well_name
	final_well_id
	final_well_created_ts
	final_recombinase_id
	final_qc_seq_pass
	final_cassette_name
	final_cassette_cre
	final_cassette_promoter
	final_cassette_conditional
	final_backbone_name
	final_well_assay_complete
	final_well_accepted
	final_pick_plate_name
	final_pick_plate_id
	final_pick_well_name
	final_pick_well_id
	final_pick_well_created_ts
	final_pick_recombinase_id
	final_pick_qc_seq_pass
	final_pick_cassette_name
	final_pick_cassette_cre
	final_pick_cassette_promoter
	final_pick_cassette_conditional
	final_pick_backbone_name
	final_pick_well_assay_complete
	final_pick_well_accepted
	dna_plate_name
	dna_plate_id
	dna_well_name
	dna_well_id
	dna_well_created_ts
	dna_qc_seq_pass
	dna_status_pass
	dna_quality
	dna_well_assay_complete
	dna_well_accepted
	ep_plate_name
	ep_plate_id
	ep_well_name
	ep_well_id
	ep_well_created_ts
	ep_first_cell_line_name
	ep_colonies_picked
	ep_colonies_total
	ep_colonies_rem_unstained
	ep_well_assay_complete
	ep_well_accepted
	ep_pick_plate_name
	ep_pick_plate_id
	ep_pick_well_name
	ep_pick_well_id
	ep_pick_well_created_ts
	ep_pick_qc_seq_pass
	ep_pick_well_assay_complete
	ep_pick_well_accepted
	sep_plate_name
	sep_plate_id
	sep_well_name
	sep_well_id
	sep_well_created_ts
	sep_second_cell_line_name
	sep_well_assay_complete
	sep_well_accepted
	sep_pick_plate_name
	sep_pick_plate_id
	sep_pick_well_name
	sep_pick_well_id
	sep_pick_well_created_ts
	sep_pick_qc_seq_pass
	sep_pick_well_assay_complete
	sep_pick_well_accepted
	fp_plate_name
	fp_plate_id
	fp_well_name
	fp_well_id
	fp_well_created_ts
	fp_well_assay_complete
	fp_well_accepted
	sfp_plate_name
	sfp_plate_id
	sfp_well_name
	sfp_well_id
	sfp_well_created_ts
	sfp_well_assay_complete
	sfp_well_accepted
    /],
    @output,
  ]);
  
  @output = undef;	# free memory
  
  return 1;
}

1;
