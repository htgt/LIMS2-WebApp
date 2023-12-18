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

my $classification = classify_reads($allele_data);

say ("Classification: $classification");

my @miseq_well_experiments = $model->schema->resultset('MiseqWellExperiment')->search(
    {
        'miseq_exp.name' => $miseq_data->{data}->{experiment_name},
        'well.name' => $miseq_data->{data}->{miseq_well},
        'plate.name' => $miseq_data->{data}->{miseq_plate},
    },
    {prefetch => ['miseq_exp', 'well', { well => 'plate'}]},
);
if (scalar(@miseq_well_experiments) != 1) {die "There can only be one..."};
my $miseq_well_experiment = $miseq_well_experiments[0];

say("Miseq well experiment ID: " . $miseq_well_experiment->id);

$model->update_miseq_well_experiment({
   id =>  $miseq_well_experiment->id,
   classification => $classification,
});
