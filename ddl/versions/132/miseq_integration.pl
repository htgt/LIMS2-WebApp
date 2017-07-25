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
    'file=s' => \my $file,
    'name=s' => \my $miseq,
);

my $model = LIMS2::Model->new({ user => 'tasks' });

my $csv = Text::CSV->new();

my $data;

open my $fh, '<', $file or die "$!"; 
my @cols = @{$csv->getline($fh)};
$csv->column_names(@cols);
while (my $row = $csv->getline($fh)) {
    $data->{well($row->[1])}->{$row->[4]} = well($row->[5]);
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
        plate   => $miseq,
        well    => $well_name,
        created_by  => 'pk8@sanger.ac.uk',
        created_at  => $plate->{date},
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
        type            => 'miseq_no_template',
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
$model->schema->txn_do( sub {
    try {
        my $traditional_plate = $model->create_plate($params);
        say "Inserted Miseq ID: " . $plate->{id} . " Name: " . $plate->{name} . " New Plate id: " . $traditional_plate->id;
    }
    catch {
        warn "Could not create record for " . $plate->{id} . ": $_";
        $model->schema->txn_rollback;
    };
});

1;
