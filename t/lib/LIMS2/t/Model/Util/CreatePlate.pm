package LIMS2::t::Model::Util::CreatePlate;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::CreatePlate qw(merge_plate_process_data);

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/CreatePlate.pm - test class for LIMS2::Model::Util::CreatePlate

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

sub all_tests  : Test(3)
{
    note( "Plate Create - merge plate process data" );

    my $well_data = {
        well_name    => 'A01',
        parent_plate => 'MOHFAQ0001_A_2',
        parent_well  => 'A01',
        cassette     => 'test_cassette',
        backbone     => '',
        recombinase  => 'Cre'
    };

    my $plate_data = {
        backbone => 'test_backbone',
        cassette => 'wrong_cassette',
        process_type => '2w_gateway',
    };

    use_ok('LIMS2::Model::Util::CreatePlate', qw( merge_plate_process_data ) );

    ok merge_plate_process_data( $well_data, $plate_data );

    is_deeply $well_data, {
        well_name    => 'A01',
        parent_plate => 'MOHFAQ0001_A_2',
        parent_well  => 'A01',
        cassette     => 'test_cassette',
        backbone     => 'test_backbone',
        process_type => '2w_gateway',
        recombinase  => ['Cre'],
    }, 'well_data array is as expected';

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

