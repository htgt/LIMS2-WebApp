#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use LIMS2::SummaryGeneration::SummariesWellDescend;
use Parallel::ForkManager;                  # Running multiple processes
use Try::Tiny;                              # Exception handling
use Const::Fast;                            # Constant variables
use Getopt::Long;                           # Command line options
use Log::Log4perl ':easy';                  # DEBUG to INFO to WARN to ERROR to LOGDIE
use Perl6::Slurp;
use Time::HiRes;
use List::MoreUtils qw(uniq any);
use Data::Dumper;

#------------------------------------------------------------------
#  Variables
#------------------------------------------------------------------
const my $DEFAULT_NUM_CONC_PROCS => 10;     # Default number of concurrent processes
my $num_concurrent_processes;               # Number of concurrent processes to create
my $processes_succeeded = 0;                # Successful design well sub-processes
my $processes_failed = 0;                   # Failed design well sub-processes
my @design_well_ids;                        # Array of design wells
my $design_well_id = 0;                     # Current design well ID
my $loglevel = $INFO;                       # Logging level
my $design_well_list_file;

#------------------------------------------------------------------
#  Check for input of single well ID or if we are processing all wells
#------------------------------------------------------------------

GetOptions(
#    'help'             => sub { pod2usage( -verbose => 1 ) },
#    'man'              => sub { pod2usage( -verbose => 2 ) },
    'debug'            => sub { $loglevel = $DEBUG },
    'well_id=i'        => \$design_well_id,
    'well_id_list=s'   => \$design_well_list_file,
    'num_processes=i'  => \$num_concurrent_processes,
);

# initialise logging
Log::Log4perl->easy_init( { level => $loglevel, layout => '%d [%P] %p %m (%R)%n' } );

$num_concurrent_processes //= $DEFAULT_NUM_CONC_PROCS; # if not defined populate with default

my $model = LIMS2::Model->new( user => 'lims2' );
my $start_time=localtime;
my $all_wells = 0;

#------------------------------------------------------------------
#  Process wells
#------------------------------------------------------------------

if($design_well_id) {

    #------------------------------------------------------------------
    #  Process a single DESIGN well
    #------------------------------------------------------------------

    # set concurrent processes to zero to prevent forking
    $num_concurrent_processes = 0;

    # push design well id into array for processing
    push @design_well_ids, $design_well_id;

}
elsif ( $design_well_list_file ) {
    push @design_well_ids, slurp $design_well_list_file, { chomp => 1 };
} else {
    #------------------------------------------------------------------
    #  Select ALL the DESIGN wells
    #------------------------------------------------------------------
    $all_wells = 1;

    # select well row objects into an array
    my $well_rows_rs = $model->schema->resultset( 'Well' )->search(
        {
            'plate.type_id'     => 'DESIGN'             # where clause, select wells where plates.type_id = 'DESIGN'
        },
        {
            join                => 'plate',             # prefetch to speed up query
            order_by            => 'me.id',
            columns             => [ 'id' ],
        }
    );

   # select ids out of well row objects into well ids array
   @design_well_ids = $well_rows_rs->get_column( 'id' )->all;
}

# Pre-compute the descendant paths for all relevant design wells in batch
INFO "Pre-computing descendant paths for design wells";
my $paths_table = $model->create_well_descendant_paths_temp_table(\@design_well_ids);
INFO "Descendant paths table created";

INFO "LIMS2 Summary data generation: ".scalar(@design_well_ids)." design well id(s) identified at : ".localtime;

#------------------------------------------------------------------
#  Process wells to fetch summary data use multiple FORKS
#------------------------------------------------------------------

my $stop_run = 0;
my $design_well_index = 0;
my $design_wells_total = scalar(@design_well_ids);

# Max processes for parallel download
my $pm = Parallel::ForkManager->new($num_concurrent_processes);

# Setup a callback for when a child finishes up so we can get its exit code
$pm->run_on_finish(
    sub { my ($pid, $exit_code, $ident) = @_;
        {
            if($exit_code == 0) {
                $processes_succeeded++;
                DEBUG "LIMS2 Summary data generation: Well ID $ident : OK   : Exit code = $exit_code Total process successes/fails $processes_succeeded/$processes_failed\n";
            } else {
                $processes_failed++;
                $stop_run = 1;
                ERROR "LIMS2 Summary data generation: Well ID $ident : FAIL : Exit code = $exit_code Total process successes/fails $processes_succeeded/$processes_failed\n";
            }
        }
    }
);

$pm->run_on_start(
    sub { my ($pid,$ident) = @_;
		++$design_well_index;
        DEBUG "LIMS2 Summary data generation: Well ID $ident : Started...";
    }
);

#$pm->run_on_wait(
#   sub {
#       print "Waiting...\n"
#   },
#   0.5
#);

# Create forks for each DESIGN well, ForkManager handles pool of forks for us
foreach my $design_well_id (@design_well_ids) {

    # exit loop if flag set
    last if $stop_run;

    # Code between pm start and finish runs in forked process
    $pm->start($design_well_id) and next; # create the fork and call the callback

    DEBUG "Fetching descendant paths from temp table";
    my $sql_result =  $model->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( "SELECT * FROM $paths_table where well_id=$design_well_id" );
         $sth->execute();
         $sth->fetchall_arrayref();
    });
    # sql_result is an array of arrays of [well_id, [path array] ]
    # we just want to store the path arrays
    my @path_list = map { $_->[1] } @{$sql_result} ;
    my $paths = { $design_well_id => \@path_list };
    DEBUG "got descendant paths for design well $design_well_id";

    # ISSUE: what about wells no longer existing, summary data would remain. Possible solution:
    # Insert design well ids into an emptied table 'summary_wells' first then and run
    # "delete from summaries where design_well_id not in(select design_well_id from summary_wells)"
    # summary_wells could even contain a processed_ts, insert_count and fail_count columns
    # Alternate solution, add insert_ts column into table so can delete old rows as part of job.

    # run the summary data generation for one design well per process
    my $well_ancestors = undef; # ISSUE: have not found a quick way to retrieve precomputed ancestors from any store
    my $results = LIMS2::SummaryGeneration::SummariesWellDescend::generate_summary_rows_for_design_well($design_well_id,$model,$paths, $well_ancestors);

	my $exit_code = $results->{exit_code};

	DEBUG "LIMS2 Summary data generation: Well ID $design_well_id : Index $design_well_index of $design_wells_total : EC=$exit_code";
	if($exit_code == 0) {
		DEBUG "LIMS2 Summary data generation: Well ID $design_well_id : Deletes/Inserts/Fails = ".$results->{count_deletes}."/".$results->{count_inserts}."/".$results->{count_fails};
	} else {
        DEBUG "LIMS2 Summary data generation: Well ID $design_well_id : Error message = ".$results->{error_msg};
	}

    $pm->finish($exit_code);    # close the fork and call the callback method

}

$pm->wait_all_children;

INFO  "LIMS2 Summary data generation: Processes successful/failed : $processes_succeeded/$processes_failed";
ERROR "LIMS2 Summary data generation: Processes FAILED : $processes_failed" if $processes_failed > 0;
ERROR "LIMS2 Summary data generation: ERROR: Run was ABORTED before completion!" if $stop_run;

#------------------------------------------------------------------
#  End and print out totals
#------------------------------------------------------------------
if($paths_table){
    $model->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( "DROP TABLE IF EXISTS $paths_table" );
         $sth->execute();
        }
    );
    DEBUG "Paths table $paths_table dropped";
}

my $end_time=localtime;
INFO "LIMS2 Summary data generation: Start time was       : $start_time";
INFO "LIMS2 Summary data generation: Process completed at : $end_time";
