#!/usr/bin/env perl

=head

Adds mapping (i.e. process) between a PIQ well and a Miseq wells.

=cut

use strict;
use warnings;

use Getopt::Long;

use LIMS2::Model;
use LIMS2::Model::Util::WellName qw/ convert_numeric_well_names_to_alphanumeric /;


my $piq_plate_name = "";
my $piq_well_name = "";
my $miseq_plate_name = "";
my $miseq_well_number = "";
GetOptions(
    'piq_plate_name=s' => \$piq_plate_name,
    'piq_well_name=s' => \$piq_well_name,
    'miseq_plate_name=s' => \$miseq_plate_name,
    'miseq_well_number=i' => \$miseq_well_number,
) or die;

my $model = LIMS2::Model->new( user => 'lims2' );

my $process_data = {
    "type" => "miseq_no_template",
    "input_wells" => [
        {
            "plate_name" => $piq_plate_name,
            "well_name" => $piq_well_name
        },
    ],
    "output_wells" => [
        {
            "plate_name" => $miseq_plate_name,
            "well_name" => convert_numeric_well_names_to_alphanumeric($miseq_well_number)
        },
    ],
};

$model->create_process($process_data);
