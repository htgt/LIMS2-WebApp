#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
use Text::CSV;

sub migrate_wells {
    my ( $model, $plate, @wells ) = @_;

    foreach my $well (@wells) {
$DB::single=1;
        print $well;
=head 
    return {
        plate_name   => { validate => 'existing_plate_name' },
        well_name    => { validate => 'well_name', rename => 'name' },
        accepted     => { validate => 'boolean', optional => 1 },
        process_data => { validate => 'hashref' },
        created_by => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    };
=cut
        my $params = {
            plate_name      => $plate->name,
            well_name       => $well->name,
            process_data    =>
            created_by      => 'pk8@sanger.ac.uk',
            created_at      => $plate->creation_date,
        };
    }

}

my $model = LIMS2::Model->new({ user => 'tasks' });

my @plates = $model->schema->resultset('MiseqProject')->search({
    name => { '!=' => undef },
});

say "Found " . scalar(@plates) . " MiSEQ projects.";

say "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

$DB::single=1;

foreach my $plate (@plates) {
    my $params = {
        name        => $plate->name,
        species     => 'Human',
        type        => 'MISEQ',
        created_by  => 'pk8@sanger.ac.uk',
        created_at  => $plate->creation_date,
    };
    
    $model->schema->txn_do( sub {
        try {
            my $traditional_plate = $model->create_plate($params);
            say "Inserted Miseq ID: " . $plate->id . " Name: " . $plate->name . " New Plate id: " . $traditional_plate->id;
        }
        catch {
            warn "Could not create record for " . $plate->id . ": $_";
            $model->schema->txn_rollback;
        };
    });
$DB::single=1;
    my @wells = $model->schema->resultset('MiseqProjectWell')->search({
        miseq_plate_id => $plate->id,
    });

    migrate_wells($model, $plate, @wells);













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