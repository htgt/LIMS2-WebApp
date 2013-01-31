#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use LIMS2::SummaryGeneration::WellDescend;

use threads;
use threads::shared;
use Thread::Queue;

use Parallel::ForkManager;

my $SINGLE_WELL = 0;
my $NUM_CONC_PROCESSES = 10;					# Number of concurrent processes to create
my $WELL_INSERTS_SUCCEEDED :shared = 0;		# Counter successful DB inserts
my $WELL_INSERTS_FAILED :shared = 0;		# Counter failed DB inserts
my @DESIGN_WELL_IDS;						# Array of design wells
my $DESIGN_WELL_ID = 0;						# Current design well ID

# Check for input of single well ID or for all DESIGN plate wells
my ( $well_id ) = @ARGV;
if (defined $well_id && $well_id > 0) {
	$DESIGN_WELL_ID = $well_id;
	$SINGLE_WELL = 1;
	print "Input well id:$well_id\n";
}

my $start_time=localtime;
print "Start time: $start_time\n";

# check if output file exists, and if so rename it
# TODO: make output file optional, maybe input from command line
my $dir = '/nfs/users/nfs_a/as28/Sandbox/';
my $filename = 'summaries_data.csv';
my $CSV_FILEPATH = $dir.$filename;
if (-e $CSV_FILEPATH) {			
	print "Renaming existing file.\n";
	my $time=localtime;
	my ($day,$month,$date,$tm,$year)=split(/\s+/,$time);
	my $stamp=$year."_".$month."_".$date."_".$tm;
	my $newfilepath = $dir.$stamp."_BAK_".$filename;
	rename $CSV_FILEPATH, $newfilepath or die "Error, can not rename $CSV_FILEPATH as $newfilepath: $!";
} 

#DESIGN		Design Instances
#INT		Intermediate Vectors
#POSTINT	Post-intermediate Vectors
#FINAL		Final Vectors
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
open my $OUTFILE, '>>', $CSV_FILEPATH or die "Error: Summary data generation - Cannot open output file $CSV_FILEPATH for append: $!";
print $OUTFILE $logmsg;
close $OUTFILE;


# connect to database
#my $model = LIMS2::Model->new( user => 'webapp', audit_user => $ENV{USER}.'@sanger.ac.uk' );
my $model = LIMS2::Model->new( user => 'webapp', audit_user => $ENV{USER} );		# for lims2_live_as28 running on local

if($SINGLE_WELL) {
	
	print "Well ID processing=$DESIGN_WELL_ID\n";
	
	# Call method on well
	my ($inserts, $fails) = LIMS2::SummaryGeneration::WellDescend::well_descendants($DESIGN_WELL_ID, $CSV_FILEPATH);
	$WELL_INSERTS_SUCCEEDED += $inserts;
	$WELL_INSERTS_FAILED += $fails;
	
} else {
	# select ALL the DESIGN wells
	my $wells_rs = $model->schema->resultset( 'Well' )->search( 
		{ 
			'plate.type_id'		=> 'DESIGN' 				# where clause, select wells where plates.type_id = 'DESIGN'
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
	#      Process wells
	#------------------------------------------------------------------
	
	# Max processes for parallel download
	my $pm = new Parallel::ForkManager($NUM_CONC_PROCESSES); 

	# Setup a callback for when a child finishes up so we can get its exit code
	$pm->run_on_finish(
		sub { my ($pid, $inserts, $ident) = @_;
			print "Well ID $ident completed with PID $pid and inserts: $inserts\n";
			lock($WELL_INSERTS_SUCCEEDED);
			$WELL_INSERTS_SUCCEEDED += $inserts;
			print "Total inserts: $WELL_INSERTS_SUCCEEDED\n";
		}
	);
	
	$pm->run_on_start(
		sub { my ($pid,$ident) = @_;
			print "Well ID $ident started, pid: $pid\n";
		}
	);
	
	$pm->run_on_wait(
		sub {
			print "Waiting...\n"
		},
		0.5
	);

	foreach my $design_well_id (@DESIGN_WELL_IDS) {
		$pm->start($design_well_id) and next; # do the fork

		my ($inserts, $fails) = LIMS2::SummaryGeneration::WellDescend::well_descendants($design_well_id, $CSV_FILEPATH);
		
		# TODO: May be able to pass counts back via finish callback
		$pm->finish($inserts); # do the exit in the child process
	}
	$pm->wait_all_children;
	
	
}

my $end_time=localtime;
print "Process Completed at $end_time\n";
print "Start time was: $start_time\n";
print "DB Inserts successful: $WELL_INSERTS_SUCCEEDED\n";
print "DB Inserts failed: $WELL_INSERTS_FAILED\n";
