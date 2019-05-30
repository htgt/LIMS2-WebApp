#! /usr/bin/perl

use strict;
use warnings;

use LIMS2::Model;
use Try::Tiny;
use Getopt::Long;
use Data::Dumper;
use Moose;
use Text::CSV;
use POSIX qw(strftime);
use feature qw(say);
use List::MoreUtils qw(uniq);

my $lims2_model = LIMS2::Model->new( user => 'lims2' );
my $miseq_experiments_rs = $lims2_model->schema->resultset('MiseqExperiment')->search({ experiment_id => undef });
say $miseq_experiments_rs->count;

my @nm_exps;
my $tristans = {
    ARID1A_1 => 2031,
    KMT2A_1 => 2356,
    KDM5B_1 => 2425,
    KDM5B_2 => 2426,
    BCL11A_1 => 2364,
    BCL11A_2 => 2365,
    SETD1A_1 => 2374,
    SETD1B_2 => 2368,
    ASXL3_2 => 2369,
    KMT2B_1 => 2371,
    KMT2B_2 => 2372,
    KPTN_1 => 2367,
    DDX3X_2 => 2361,
    KMT2C_1 => 2430,
    ARID1B_1 => 2427,
    ARID1B_2 => 2428,
    KMT2E_1 => 2370,
    SETD2_1 => 2107,
};

while (my $exp_rs = $miseq_experiments_rs->next) {
    my $exp = $exp_rs->as_hash;
    my $ignore = 0;
    if ( my ($trivial) = $exp->{name} =~ /([A-Z][A-Z0-9]+\_\d)/) {
        my $update;
        my $lims_exp = $lims2_model->schema->resultset('Experiment')->find({ assigned_trivial => $trivial });
        if ($lims_exp) {
            $lims_exp = $lims_exp->as_hash;
            $update->{experiment_id} = $lims_exp->{id};
        } else {
            if (my $tri = $tristans->{$trivial}) {
                $update->{experiment_id} = $tri;
            }
        }
        if ($update) {
            $update->{id} = $exp->{id};
            print Dumper $update;
            $lims2_model->update_miseq_experiment($update);
            $ignore = 1;
        } 
    }

    if ( my ($plate_name, $trivial) = $exp->{name} =~ /^([A-Z0-9]+)\_?.*\_([A-Z0-9]+\_\d)$/) {
        my $update;
        unless ($exp->{parent_plate_id}) {
            my $plate = $lims2_model->schema->resultset('Plate')->find({ name => $plate_name });
            if ($plate) {
                $plate = $plate->as_hash;
                $update->{parent_plate_id} = $plate->{id};
            }
        }

        my $lims_exp = $lims2_model->schema->resultset('Experiment')->find({ assigned_trivial => $trivial });
        if ($lims_exp) {
            $lims_exp = $lims_exp->as_hash;
            $update->{experiment_id} = $lims_exp->{id};
        } else {
            if (my $tri = $tristans->{$trivial}) {
                $update->{experiment_id} = $tri;
            }
        }
        if ($update) {
            $update->{id} = $exp->{id};
            print Dumper $update;
            $lims2_model->update_miseq_experiment($update);
            $ignore = 1;
        } else {
            push (@nm_exps, $exp->{name});
        }
    }
    if ($ignore == 0) {
        my $mwe = $lims2_model->schema->resultset('MiseqWellExperiment')->search({ miseq_exp_id => $exp->{id} })->first;
        unless ($mwe) {
            next;
        }
        my @parents = $mwe->well->parent_plates;

        foreach my $par (@parents) {
            unless (ref $par eq 'HASH') {
                next;
            }
            my $par_well = $par->{well};
            my $par_well_hash = $par_well->as_hash;
            if ($exp->{name} =~ /$par_well_hash->{plate_name}/i && $par_well_hash->{plate_name} ne '') {
                say "~~~~~~~~~~~~~~~~";
                print Dumper {
                    miseq_exp => $exp->{name},
                    plate => $par_well_hash->{plate_name},
                    well => $par_well_hash->{well_name},
                    miseq_exp_id => $exp->{id}
                };
            }
        }
    }


}
$miseq_experiments_rs = $lims2_model->schema->resultset('MiseqExperiment')->search({ experiment_id => undef });
say $miseq_experiments_rs->count;
print Dumper @nm_exps;

1;
