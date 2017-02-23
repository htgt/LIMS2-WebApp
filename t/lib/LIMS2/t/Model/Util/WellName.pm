package LIMS2::t::Model::Util::WellName;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::WellName qw/
	generate_96_well_annotations
/;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/WellName.pm - test class for LIMS2::Model::Util::WellName

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
};

=head2 before

Code to run before every test

=cut

sub before : Test(setup)
{
    #diag("running before test");
};

=head2 after

Code to run after every test

=cut

sub after  : Test(teardown)
{
    #diag("running after test");
};


=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup)
{
    #diag("running before all tests");
};

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown  : Test(shutdown)
{
    #diag("running after all tests");
};

=head2 all_tests

Code to execute all tests

=cut

sub all_tests  : Tests
{
    ok(1, "Test of LIMS2::Model::Util::WellName");

    my %expected_data =
    (
        1 => 'A01',
        2 => 'A02',
        3 => 'A03',
        4 => 'A04',
        5 => 'A05',
        6 => 'A06',
        7 => 'A07',
        8 => 'A08',
        9 => 'A09',
        10 => 'A10',
        11 => 'A11',
        12 => 'A12',
        13 => 'B01',
        14 => 'B02',
        15 => 'B03',
        16 => 'B04',
        17 => 'B05',
        18 => 'B06',
        19 => 'B07',
        20 => 'B08',
        21 => 'B09',
        22 => 'B10',
        23 => 'B11',
        24 => 'B12',
        25 => 'C01',
        26 => 'C02',
        27 => 'C03',
        28 => 'C04',
        29 => 'C05',
        30 => 'C06',
        31 => 'C07',
        32 => 'C08',
        33 => 'C09',
        34 => 'C10',
        35 => 'C11',
        36 => 'C12',
        37 => 'D01',
        38 => 'D02',
        39 => 'D03',
        40 => 'D04',
        41 => 'D05',
        42 => 'D06',
        43 => 'D07',
        44 => 'D08',
        45 => 'D09',
        46 => 'D10',
        47 => 'D11',
        48 => 'D12',
        49 => 'E01',
        50 => 'E02',
        51 => 'E03',
        52 => 'E04',
        53 => 'E05',
        54 => 'E06',
        55 => 'E07',
        56 => 'E08',
        57 => 'E09',
        58 => 'E10',
        59 => 'E11',
        60 => 'E12',
        61 => 'F01',
        62 => 'F02',
        63 => 'F03',
        64 => 'F04',
        65 => 'F05',
        66 => 'F06',
        67 => 'F07',
        68 => 'F08',
        69 => 'F09',
        70 => 'F10',
        71 => 'F11',
        72 => 'F12',
        73 => 'G01',
        74 => 'G02',
        75 => 'G03',
        76 => 'G04',
        77 => 'G05',
        78 => 'G06',
        79 => 'G07',
        80 => 'G08',
        81 => 'G09',
        82 => 'G10',
        83 => 'G11',
        84 => 'G12',
        85 => 'H01',
        86 => 'H02',
        87 => 'H03',
        88 => 'H04',
        89 => 'H05',
        90 => 'H06',
        91 => 'H07',
        92 => 'H08',
        93 => 'H09',
        94 => 'H10',
        95 => 'H11',
        96 => 'H12'
    );

    my $wells = &generate_96_well_annotations;
    foreach (my $count=0; $count <10; $count++)
    {
        my $rand_int = int(rand(120));
        my $well;
        $well = $wells->{$rand_int};
        if (defined $well && $well eq $expected_data{$rand_int})
        {
            ok (1, "Test ok - $rand_int corresponds to $well\n");
        } elsif (defined $well && $well ne $expected_data{$rand_int})
        {
            ok (0, "Test error - Incorrect well $well for index $rand_int\n");
        } else {
            ok (1, "Test ok - No value for $rand_int\n");
        }
    }
}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

