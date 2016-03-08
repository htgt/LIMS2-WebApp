#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use WebAppCommon::Util::FarmJobRunner;

my $farm = WebAppCommon::Util::FarmJobRunner->new({ bsub_wrapper => "/nfs/team87/farm3_lims2_vms/conf/run_in_farm3_lims2_af11"});

my $num_processes = 32;
my $cmd = [
	"lims2_create_summaries.pl",
	"--num_processes $num_processes"
];

my $success = $farm->submit_and_wait({
    cmd      => $cmd,
    out_file => "/lustre/scratch109/sanger/team87/summaries/summary_generation.out",
    err_file => "/lustre/scratch109/sanger/team87/summaries/summary_generation.err",
    processors => $num_processes,
    timeout  => 3600,
    interval => 60,
    queue    => 'normal',
});

if($success){
	if(ref($success) eq 'ARRAY'){
		print join " ", @$success
	}
	print STDERR "Summary generation on farm has completed\n";
}
else{
	die "Summary generation on farm has failed\n";
}