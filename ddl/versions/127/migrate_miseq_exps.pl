#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
use Text::CSV;

sub read_columns {
    my ( $model, $csv, $fh ) = @_;

    my $overview;
    while ( my $row = $csv->getline($fh)) {
        next if $. < 2;
        my @genes;
        push @genes, $row->[1];
        $overview->{$row->[0]} = {
            nhej    => $row->[6],
            total   => $row->[7],
            genes   => \@genes,
        };
    }

    return $overview;
}

my $model = LIMS2::Model->new({ user => 'tasks' });

my @alleles = $model->schema->resultset('MiseqProjectWellExp')->search({
    miseq_exp_id => { '!=' => undef },
});

say "Found " . scalar(@alleles) . " records";

foreach my $allele (@alleles) {
    my $plate = $allele->plate;
    my $exp = $model->schema->resultset('MiseqExperiment')->find({
        miseq_id    => $plate->{id},
        name        => $allele->miseq_exp_id,
    });
    say "Preparing " . $allele->miseq_exp_id;
    unless ($exp) {
        my $rna_seq = $ENV{LIMS2_RNA_SEQ} || "/warehouse/team229_wh01/lims2_managed_miseq_data/";
        my $base = $rna_seq . $plate->{name} . '/summary.csv';

        my $csv = Text::CSV->new({ binary => 1 }) or die "Can't use CSV: " . Text::CSV->error_diag();
        open my $fh, '<:encoding(UTF-8)', $base or die "Can't open CSV: $!";
        my $ov = read_columns($model, $csv, $fh);
        close $fh;
        my $gene = (split(/_/,$ov->{$allele->miseq_exp_id}->{genes}[0]))[0];
        my $exp_params = {
            miseq_id        => $plate->{id},
            name            => $allele->miseq_exp_id,
            gene            => $gene,
            mutation_reads  => $ov->{$allele->miseq_exp_id}->{nhej},
            total_reads     => $ov->{$allele->miseq_exp_id}->{total},
        };
        $model->schema->txn_do( sub {
            try {
                $model->create_miseq_experiment($exp_params);
                print "Inserted Miseq ID: " . $plate->{id} . " Experiment: " . $allele->miseq_exp_id . "\n";
            }
            catch {
                warn "Could not create record for " . $plate->{id} . ": $_";
                $model->schema->txn_rollback;
            };
        });
        $exp = $model->schema->resultset('MiseqExperiment')->find({
            miseq_id    => $plate->{id},
            name        => $allele->miseq_exp_id,
        });
    } 

    $exp = $exp->as_hash;

    $model->schema->txn_do( sub {
        try {
            $model->update_miseq_well_experiment({
                id              => $allele->id,
                miseq_exp_id    => $exp->{id},
            });
            print "Updated Well_Exp: " . $allele->id . " to experiment ID: " . $exp->{id} . "\n";
        }
        catch {
            warn "Could not update record for well_exp: " . $allele->id . ": $_";
            $model->schema->txn_rollback;
        };
    });
}
