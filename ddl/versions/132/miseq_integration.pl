#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
use Text::CSV;
use Getopt::Long;

sub migrate_wells {
    my ( $model, $plate, @wells ) = @_;

    foreach my $well (@wells) {
        my $params = {
            plate_name      => $plate->name,
            well_name       => $well->name,
            process_data    =>
            created_by      => 'pk8@sanger.ac.uk',
            created_at      => $plate->creation_date,
        };
    }

}

GetOptions(
    'file' => \my $project,
);

my $model = LIMS2::Model->new({ user => 'tasks' });

my @plates = $model->schema->resultset('MiseqProject')->search({
    name => { '!=' => undef },
});

say "Found " . scalar(@plates) . " MiSEQ projects.";

say "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

$DB::single=1;

my $csv = Text::CSV->new();

my $data;

my @cols = @{$csv->getline($file)};
$csv->column_names(@cols);
while (my $row = $csv->getline($file)) {
    $data->{$row->{parent_plate}}->{$row->{well_name}} = {
        parent_well => $row->{parent_well},
        process     => $row->{process},
    };
}
use Data::Dumper;
print Dumper $data;

foreach my $plate (@plates) {
    my $params = {
        name        => $plate->name,
        species     => 'Human',
        type        => 'MISEQ',
        created_by  => 'pk8@sanger.ac.uk',
        created_at  => $plate->creation_date,
        wells       => @wells,
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
}
