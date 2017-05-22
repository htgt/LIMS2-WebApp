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

my @plates = $model->schema->resultset('MiseqProjects')->search({
    miseq_exp_id => { '!=' => undef },
});

say "Found " . scalar(@plates) . " MiSEQ projects.\n\n";

$DB::single=1;

foreach my $plate (@plates) {
=head
sub pspec_create_plate {
    return {
        name        => { validate => 'plate_name' },
        species     => { validate => 'existing_species', rename => 'species_id' },
        type        => { validate => 'existing_plate_type', rename => 'type_id' },
        description => { validate => 'non_empty_string', optional => 1 },
        created_by => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        appends    => { optional => 1, validate => 'existing_crispr_plate_appends_type' },
        comments   => { optional => 1 },
        wells      => { optional => 1 },
        is_virtual => { validate => 'boolean', optional => 1 },
        version    => { validate => 'integer', optional => 1, default => undef },
    };
}
=cut
    print "break";
    $model->schema->txn_do( sub {
        try {
            $model->create_plate($exp_params);
            print "Inserted Miseq ID: " . $plate->{id} . " Experiment: " . $allele->miseq_exp_id . "\n";
        }
        catch {
            warn "Could not create record for " . $plate->{id} . ": $_";
            $model->schema->txn_rollback;
        };
    });

















=head
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
=cut
}
