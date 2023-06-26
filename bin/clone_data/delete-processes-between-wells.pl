#!/usr/bin/env perl

=head

Delete a process between a PIQ well and a MiSeq well.

=cut

use strict;
use warnings;
use feature qw(say);

use Getopt::Long;

use LIMS2::Model;

my $piq_plate_name = "";
my $piq_well_name = "";
my $miseq_plate_name = "";
my $miseq_well_name= "";
GetOptions(
    'piq_plate_name=s' => \$piq_plate_name,
    'piq_well_name=s' => \$piq_well_name,
    'miseq_plate_name=s' => \$miseq_plate_name,
    'miseq_well_name=s' => \$miseq_well_name,
) or die;

say "Getting model";

my $model = LIMS2::Model->new( user => 'lims2' );

my @processes = $model->get_processes_for_wells({
    input_well => {
        plate_name => $piq_plate_name,
        well_name => $piq_well_name,
    },
    output_well => {
        plate_name => $miseq_plate_name,
        well_name => $miseq_well_name,
    },
});


my $number_of_processes = scalar @processes;

say "Number of processes: $number_of_processes";

die "Expected 1 element but found $number_of_processes" unless $number_of_processes == 1;

$model->delete_process({id => $processes[0]->id});

say "Deleted";
