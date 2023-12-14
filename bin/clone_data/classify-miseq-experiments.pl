#!/usr/bin/env perl

=head

Add the classification for the clones in a miseq-well-experiment.

=cut

use strict;
use warnings;
use feature qw(say);
use Getopt::Long;

use LIMS2::Model;
use LIMS2::Model::Util::Miseq qw/ classify_reads _get_miseq_data_from_well /;

my $fp_plate_name = "";
my $fp_well_name = "";
GetOptions(
    'fp_plate_name=s' => \$fp_plate_name,
    'fp_well_name=s' => \$fp_well_name,
) or die();

my $model = LIMS2::Model->new( user => 'lims2' );

my $fp_well = $model->retrieve_well( { plate_name => $fp_plate_name, well_name => $fp_well_name } );
my $miseq_data = _get_miseq_data_from_well($model, $fp_well);
my $allele_data = $miseq_data->{data}->{allele_data};

my $output = classify_reads($allele_data);
say($output);
