#!/usr/bin/env perl

=head

Add the classification for the clones in a miseq-well-experiment.

=cut

use strict;
use warnings;
use feature qw(say);
use Getopt::Long;
use Log::Log4perl qw( :easy );
use List::Util qw( any );

use LIMS2::Model;
use LIMS2::Model::Util::Miseq qw/ classify_reads _get_miseq_data_from_well _get_crispr_from_well /;

say("Running the perl script");

my $model = LIMS2::Model->new( user => 'lims2' );

my @classifications = ("WT", "K/O Het", "K/O Hom", "K/O Hom Compound", "K/O Hemizygous");

foreach my $line ( <STDIN> ) {
    chomp( $line );
    my ($fp_plate_name, $fp_well_name) = split(',', $line);
    DEBUG("Classifying for ${fp_plate_name}_${fp_well_name}");

    my $fp_well = $model->retrieve_well( { plate_name => $fp_plate_name, well_name => $fp_well_name } );
    my $miseq_data = _get_miseq_data_from_well($model, $fp_well);
    my $allele_data = $miseq_data->{data}->{allele_data};
    my $indel_data = $miseq_data->{data}->{indel_data};
    my $crispr_data = _get_crispr_from_well($fp_well);
    my $chromosome_name = $crispr_data->{locus}->{chr_name};

    # The function `classify_reads` only return one of `@classifications` or else undef. Thus
    # elements that have wrongly been classified as one of these clasifications, but aren't won't
    # be corrected. We fix this by 're-setting' all of clones which have one of these
    # classifications before re-classisfying.
    my $old_classification = $miseq_data->{data}->{classification};
    DEBUG("Old classification: $old_classification");
    if (any { $old_classification eq $_ } @classifications) {
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
 
        DEBUG("Miseq well experiment ID: " . $miseq_well_experiment->id);
        $model->update_miseq_well_experiment({
           id =>  $miseq_well_experiment->id,
           classification => "Not Called",
        });
    }

    my $classification = classify_reads($allele_data, $indel_data, $chromosome_name);

    DEBUG(defined($classification) ? "New classification: $classification" : "New classification: undef");

    if (defined $classification) {
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
 
        DEBUG("Miseq well experiment ID: " . $miseq_well_experiment->id);
 
        $model->update_miseq_well_experiment({
           id =>  $miseq_well_experiment->id,
           classification => $classification,
        });
    }
}
