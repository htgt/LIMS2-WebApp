#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
use Text::CSV;
use Getopt::Long;

sub well {
    my $name = shift;

    my $letter = substr($name, 0, 1);
    my $val = sprintf("%02d", substr($name, 1));
    
    return $letter . $val;
}

sub well_builder {
    my ($mod, @well_names) = @_;
    foreach my $number (1..12) {
        my $well_num = $number + $mod->{mod};
        foreach my $letter ( @{$mod->{letters}} ) {
            my $well = sprintf("%s%02d", $letter, $well_num);
            push (@well_names, $well);
        }
    }
    return @well_names;
}

GetOptions(
    'file=s'    => \my $file,
    'name=s'    => \my $miseq,
    'process=s' => \my $pro_type,
);

my $model = LIMS2::Model->new({ user => 'tasks' });

my $csv = Text::CSV->new();

my $data;
my $exps;

open my $fh, '<', $file or die "$!"; 
my @cols = @{$csv->getline($fh)};
$csv->column_names(@cols);
while (my $row = $csv->getline($fh)) {
    $data->{well($row->[1])}->{$row->[4]} = well($row->[5]);
    $exps->{$row->[6]} = {
        exp     => $row->[0],
        gene    => $row->[3],
    };
}
close $fh;

my @well_names;
my $quads = {
    '0' => {
        mod     => 0,
        letters => ['A','B','C','D','E','F','G','H'],
    },
    '1' => {
        mod     => 12,
        letters => ['A','B','C','D','E','F','G','H'],
    },
    '2' => {
        mod     => 0,
        letters => ['I','J','K','L','M','N','O','P'], 
    },
    '3' => {
        mod     => 12,
        letters => ['I','J','K','L','M','N','O','P'], 
    }
};
for (my $ind = 0; $ind < 4; $ind++) {
    @well_names = well_builder($quads->{$ind}, @well_names);
}
$DB::single=1;
my $plate = $model->schema->resultset('MiseqProject')->find({ name => $miseq })->as_hash;

my @wells = map { $_->as_hash } $model->schema->resultset('MiseqProjectWell')->search({
    miseq_plate_id => $plate->{id},
});

my @well_data;
foreach my $well (@wells) {
    my $well_name = $well_names[$well->{illumina_index} - 1];
    
    my $well_params = {
        plate_name      => $miseq,
        well_name       => $well_name,
        created_by      => 'pk8@sanger.ac.uk',
        created_at      => $plate->{date},
        process_type    => $pro_type,
    };

    my $parent_data = $data->{$well_name};
    my @inherit_wells;
    foreach my $fp (keys %{$parent_data}) {
        my $parent = {
            plate_name  => $fp,
            well_name   => $parent_data->{$fp},
        };
        push (@inherit_wells, $parent);
    }
    my $process = {
        type            => $pro_type,
        input_wells     => \@inherit_wells,
        output_wells    => [{ plate_name => $plate->{name}, well_name => $well_name }],
    };

    $well_params->{process_data} = $process;

    push (@well_data, $well_params);
}

my $params = {
    name        => $miseq,
    species     => 'Human',
    type        => 'MISEQ',
    created_by  => 'pk8@sanger.ac.uk',
    created_at  => $plate->{date},
    wells       => \@well_data,
};
$DB::single=1;
my $traditional_plate;
$model->schema->txn_do( sub {
    try {
        $traditional_plate = $model->create_plate($params);
        say "LIMS2: Inserted Miseq ID: " . $plate->{id} . " Name: " . $plate->{name} . " New Plate id: " . $traditional_plate->id;
    }
    catch {
        warn "Could not create record for " . $plate->{id} . ": $_";
        $model->schema->txn_rollback;
    };
});

$DB::single=1;
my $lims_plate = $traditional_plate->as_hash;
my $miseq_plate = {
    plate_id    => $lims_plate->{id},
    is_384      => $plate->{384},
};

if ($plate->{run_id}) {
    $miseq_plate->{run_id} = $plate->{run_id};
}
my $new_miseq;
$model->schema->txn_do( sub {
    try {
        $new_miseq = $model->create_miseq_plate($miseq_plate);
        say "Miseq: Inserted Miseq ID: " . $plate->{id} . " Name: " . $plate->{name} . " New Miseq Plate id: " . $new_miseq->id;
    }
    catch {
        warn "Could not create miseq record for " . $plate->{id} . ": $_";
        $model->schema->txn_rollback;
    };
});

my $miseq_exp_rs = $model->schema->resultset('MiseqExperiment')->search({ old_miseq_id => $plate->{id} });
my @exp_ids;
while (my $rs = $miseq_exp_rs->next) {
    if ($rs->as_hash) {
        $rs = $rs->as_hash;
        my $params = {
            id              => $rs->{id},
            miseq_id        => $new_miseq->id,
            name            => $exps->{$rs->{name}}->{exp},
            gene            => $exps->{$rs->{name}}->{gene},
            mutation_reads  => $rs->{nhej_count},
            total_reads     => $rs->{read_count},
        };

        print Dumper $params;

        $model->update_miseq_experiment($params);

        push (@exp_ids, $rs->{id});
    }
}
$DB::single=1;
foreach my $exp_id (@exp_ids) {
    my $wells_rs = $model->schema->resultset('MiseqProjectWellExp')->search({ miseq_exp_id => $exp_id });
    while (my $well_rs = $wells_rs->next) {
        my $well_exp = $well_rs->as_hash;

        my $index = $well_rs->index;
        my $well = $model->schema->resultset('Well')->find({ 
            plate_id    => $lims_plate->{id},
            name        => $well_names[$index - 1],
        });

        my $params = {
            well_id         => $well->id,
            miseq_exp_id    => $exp_id,
            classification  => $well_exp->{classification},
            frameshifted    => $well_exp->{frameshifted},
            status          => 'Plated',
        };

        $model->schema->txn_do( sub {
            try {
                my $new_well_exp = $model->create_miseq_well_experiment($params);
                say "Miseq: Inserted Plate ID: " . $lims_plate->{id} . " Well: " . $well->id . " New Miseq well exp";
            }
            catch {
                warn "Could not create miseq well record for " . $well->id . ": $_";
                $model->schema->txn_rollback;
            };
        });
    }
}
1;
