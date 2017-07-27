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
    $exp->{$row->[6]} = {
        exp     => $row->[0],
        gene    => $row->[3],
    };
}
close $fh;

my @well_names;
foreach my $number (1..12) {
    foreach my $letter ( qw(A B C D E F G H) ) {
		my $well = sprintf("%s%02d",$letter,$number);
		push (@well_names, $well);
	}
}

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

my $miseq_plate = {
    plate_id    => $traditional_plate->as_hash->{id},
    is_384      => $plate->{is_384},
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

while (my $rs = $miseq_exp_rs->next->as_hash) {
    my $params = {
        id              => $rs->{id},
        miseq_id        => $new_miseq->{id},
        name            => $exp->{$rs->name}->{exp},
        gene            => $exp->{$rs->name}->{gene},
    };


}
1;
