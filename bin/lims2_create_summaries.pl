#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use LIMS2::SummaryGeneration::SummariesWellDescend;
use POSIX;									# for timestamp for files
use Parallel::ForkManager;					# for running multiple processes
use Try::Tiny;								# Exception handling

#------------------------------------------------------------------
#  Variables
#------------------------------------------------------------------

my $SINGLE_WELL = 0;						# Flag if processing a single well or all
my $NUM_CONCURRENT_PROCESSES = 10;			# Number of concurrent processes to create
my $PROCESSES_SUCCEEDED = 0;				# Successful design well sub-processes
my $PROCESSES_FAILED = 0;					# Failed design well sub-processes
my @DESIGN_WELL_IDS;						# Array of design wells
my $DESIGN_WELL_ID = 0;						# Current design well ID

#------------------------------------------------------------------
#  Check for input of single well ID or if we are processing all wells
#------------------------------------------------------------------

my ( $well_id ) = @ARGV;

if (defined $well_id && $well_id > 0) {

	$DESIGN_WELL_ID = $well_id;
	$SINGLE_WELL = 1;

	print "Input well id:$well_id\n";

}

my $start_time=localtime;
print "Start time: $start_time\n";

#------------------------------------------------------------------
#  Generate output log filename and write header row
#------------------------------------------------------------------
#my $DIR = '/nfs/users/nfs_a/as28/Sandbox/';
#my $FILENAME = 'summaries.csv';
#my $DATETIME = strftime("%Y-%m-%d_%H-%M-%S", localtime);
#my $LOG_FILEPATH = $DIR.$DATETIME."_BAK_".$FILENAME;
#if (-e $LOG_FILEPATH) {
#	die "Error, filepath $LOG_FILEPATH already exists\n";
#}

#DESIGN		Design Instances
#INT		Intermediate Vectors
#POSTINT	Post-intermediate Vectors
#FINAL		Final Vectors
#FINAL_PICK	Final final Vectors
#CREBAC		Cre/BAC Vectors
#DNA		DNA QC
#EP			Electroporation
#EP_PICK	ES Cells
#XEP		Electroporation With Recombinase Applied
#XEP_PICK	ES Cells With Recombinase Applied
#XEP_POOL	ES Cells Backup Vial
#SEP		Second Allele Electroporation
#SEP_PICK	Second Allele ES Cells
#SEP_POOL	Second Allele Backup Vial
#FP			Freezer Plates
#SFP		Second Allele Freezer Plates

my $logmsg;
# DESIGN = 14 fields
$logmsg = $logmsg."design_gene_id,design_gene_symbol,design_bacs,design_plate_name,design_plate_id,design_well_name,design_well_id,design_well_created_ts,design_type,design_phase,design_name,design_id,design_well_assay_complete,design_well_accepted,";

# INT = 10 fields
$logmsg = $logmsg."int_plate_name,int_plate_id,int_well_name,int_well_id,int_well_created_ts,int_qc_seq_pass,int_cassette,int_backbone,int_well_assay_complete,int_well_accepted,";

# FINAL = 14 fields
$logmsg = $logmsg."final_plate_name,final_plate_id,final_well_name,final_well_id,final_well_created_ts,final_recombinase,final_qc_seq_pass,final_cassette,final_cassette_cre,final_cassette_promoter,final_cassette_conditional,final_backbone,final_well_assay_complete,final_well_accepted,";

# FINAL_PICK = 14 fields
$logmsg = $logmsg."final_pick_plate_name,final_pick_plate_id,final_pick_well_name,final_pick_well_id,final_pick_well_created_ts,final_pick_recombinase,final_pick_qc_seq_pass,final_pick_cassette,final_pick_cassette_cre,final_pick_cassette_promoter,final_pick_cassette_conditional,final_pick_backbone,final_pick_well_assay_complete,final_pick_well_accepted,";

#DNA = 10 fields
$logmsg = $logmsg."dna_plate_name,dna_plate_id,dna_well_name,dna_well_id,dna_well_created_ts,dna_qc_seq_pass,dna_status_pass,dna_quality,dna_well_assay_complete,dna_well_accepted,";

#EP = 11 fields
$logmsg = $logmsg."ep_plate_name,ep_plate_id,ep_well_name,ep_well_id,ep_well_created_ts,ep_first_cell_line,ep_colonies_picked,ep_colonies_total,ep_colonies_rem_unstained,ep_well_assay_complete,ep_well_accepted,";

#EP_PICK = 8 fields
$logmsg = $logmsg."ep_pick_plate_name,ep_pick_plate_id,ep_pick_well_name,ep_pick_well_id,ep_pick_well_created_ts,ep_pick_qc_seq_pass,ep_pick_well_assay_complete,ep_pick_well_accepted,";

#SEP = 8 fields
$logmsg = $logmsg."sep_plate_name,sep_plate_id,sep_well_name,sep_well_id,sep_well_created_ts,sep_second_cell_line,sep_well_assay_complete,sep_well_accepted,";

#SEP_PICK = 8 fields
$logmsg = $logmsg."sep_pick_plate_name,sep_pick_plate_id,sep_pick_well_name,sep_pick_well_id,sep_pick_well_created_ts,sep_pick_qc_seq_pass,sep_pick_well_assay_complete,sep_pick_well_accepted,";

#FP = 7 fields
$logmsg = $logmsg."fp_plate_name,fp_plate_id,fp_well_name,fp_well_id,fp_well_created_ts,fp_well_assay_complete,fp_well_accepted";

#SFP = 7 fields
$logmsg = $logmsg."sfp_plate_name,sfp_plate_id,sfp_well_name,sfp_well_id,sfp_well_created_ts,sfp_well_assay_complete,sfp_well_accepted,";
# Total fields = 94
$logmsg = $logmsg."\n";
#open my $OUTFILE, '>>', $LOG_FILEPATH or die "Error: Summary data generation - Cannot open output file $LOG_FILEPATH for append: $!";
#print $OUTFILE $logmsg;
#close $OUTFILE;

#------------------------------------------------------------------
#  Process wells
#------------------------------------------------------------------
if($SINGLE_WELL) {
	
	print "Well ID $DESIGN_WELL_ID : started...\n";
	
	#------------------------------------------------------------------
	#  Process a single DESIGN well
	#------------------------------------------------------------------
	#my $exit_code = LIMS2::SummaryGeneration::SummariesWellDescend::well_descendants($DESIGN_WELL_ID, $LOG_FILEPATH);
	my $exit_code = LIMS2::SummaryGeneration::SummariesWellDescend::well_descendants($DESIGN_WELL_ID);
	
	if (defined $exit_code && $exit_code) {
		print "Well ID $DESIGN_WELL_ID : DB inserts successful\n";
	} else {
		print "Well ID $DESIGN_WELL_ID : DB inserts failed\n";
	}
		
} else {
	#------------------------------------------------------------------
	#  Select ALL the DESIGN wells
	#------------------------------------------------------------------
	
	#my $model = LIMS2::Model->new( user => 'webapp', audit_user => $ENV{USER}.'@sanger.ac.uk' );
	my $model = LIMS2::Model->new( user => 'webapp', audit_user => $ENV{USER} );		# for lims2_live_as28 running on local

	my $wells_rs = $model->schema->resultset( 'Well' )->search( 
		{ 
			'plate.type_id'		=> 'DESIGN' 			# where clause, select wells where plates.type_id = 'DESIGN'
		}, 
		{ 		
			prefetch			=> 'plate', 			# prefetch to speed up query
			order_by			=> 'me.id'
		}
	);

	# create well ids array
	@DESIGN_WELL_IDS = ();
	my $wells_count = 0;
	
	while ( my $design_well = $wells_rs->next ) {		
		# transfer each of the well ids into the main well ids array
		push @DESIGN_WELL_IDS, $design_well->id;
		$design_well = undef;
		$wells_count++;
	}
	
	$wells_rs = undef;			# free up memory
	
	my $wells_selected_time=localtime;
	print "$wells_count wells identified at : $wells_selected_time\n";
	
	#------------------------------------------------------------------
	#  Process wells to fetch summary data use multiple FORKS
	#------------------------------------------------------------------
	
	my $STOP_RUN = 0;
	
	# Max processes for parallel download
	my $pm = new Parallel::ForkManager($NUM_CONCURRENT_PROCESSES);

	# Setup a callback for when a child finishes up so we can get its exit code
	$pm->run_on_finish(
		sub { my ($pid, $exit_code, $ident) = @_;
			{
				if($exit_code == 0) {
					$PROCESSES_SUCCEEDED++;
					print "Well ID $ident : OK   : Exit code = $exit_code Total process successes/fails $PROCESSES_SUCCEEDED/$PROCESSES_FAILED\n";
				} else {
					$PROCESSES_FAILED++;
					$STOP_RUN = 1;
					print "Well ID $ident : FAIL : Exit code = $exit_code Total process successes/fails $PROCESSES_SUCCEEDED/$PROCESSES_FAILED\n";
				}				
			}
		}
	);
	
	$pm->run_on_start(
		sub { my ($pid,$ident) = @_;
			print "Well ID $ident : Started...\n";
		}
	);
	
	#$pm->run_on_wait(
	#	sub {
	#		print "Waiting...\n"
	#	},
	#	0.5
	#);

	# Create forks for each DESIGN well, ForkManager handles pool of forks for us
	my $design_well_index = 0;
	foreach my $design_well_id (@DESIGN_WELL_IDS) {
						
		# exit loop if flag set
		last if $STOP_RUN;
		
		# stagger the startup of the processes
		sleep(1) if ++$design_well_index < 10;
		
		# Code between pm start and finish runs in forked process
		$pm->start($design_well_id) and next; # create the fork and call the callback

		# ISSUE: what about wells no longer existing, summary data would remain. Possible solution:
		# Insert design well ids into an emptied table 'summary_wells' first then and run 
		# "delete from summaries where design_well_id not in(select design_well_id from summary_wells)"
		# summary_wells could even contain a processed_ts, insert_count and fail_count columns

		# run the summary data generation for one design well per process
		#my $exit_code = LIMS2::SummaryGeneration::SummariesWellDescend::well_descendants($design_well_id, $LOG_FILEPATH);
		my $exit_code;
		
		my $return_code = LIMS2::SummaryGeneration::SummariesWellDescend::well_descendants($design_well_id);
		
		if(defined $return_code && $return_code == 0) {
			$exit_code = 0;
		} else {
			$exit_code = 1;
		} 
		
		print "Well ID $design_well_id : Index $design_well_index of $wells_count : RC=$return_code,EC=$exit_code\n";
		
		## when on next
    	on_scope_exit {
			$pm->finish($exit_code);	# close the fork and call the callback method
		}
	}
	
	$pm->wait_all_children;
	
	print "Processes successful : $PROCESSES_SUCCEEDED\n";
	print "Processes failed     : $PROCESSES_FAILED\n";
	if($STOP_RUN) {
		print "ERROR: Run was ABORTED!\n";
	}
}

#------------------------------------------------------------------
#  End and print out totals
#------------------------------------------------------------------
	
my $end_time=localtime;
print "Start time was       : $start_time\n";
print "Process completed at : $end_time\n";

