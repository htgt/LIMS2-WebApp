package LIMS2::t::Model::Schema::Result::Well;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Schema::Result::Well;
use LIMS2::Model::DBConnect;
use LIMS2::Model;
use strict;
use LIMS2::Test model => { classname => __PACKAGE__ };

##  critic

=head1 NAME

LIMS2/t/Model/Schema/Result/Well.pm - test class for LIMS2::Model::Schema::Result::Well

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN {

    # compile time requirements
    #{REQUIRE_PARENT}
}

=head2 before

Code to run before every test

=cut

sub before : Test(setup) {

    #diag("running before test");
}

=head2 after

Code to run after every test

=cut

sub after : Test(teardown) {

    #diag("running after test");
}

=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup) {

    #diag("running before all tests");
}

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown : Test(shutdown) {

    #diag("running after all tests");
}

=head2 all_tests

Code to execute all tests

=cut

sub all_tests : Tests {
    my $user          = 'lims2';
    my $connect_entry = 'LIMS2_DB';
    my $rs            = 'Well';
    my %record        = ();

    my $model = model();
    ok( $model, 'Creating model' );

    my $well = $model->retrieve_well( { plate_name => 'CEPD0024_1', well_name => 'F08' } );
    ok( $well, "Retrieving well $well" );

    my $children = $well->get_output_wells_as_string;
    ok( $children, "Retrieving well data $children" );
    is( $children, 'FP4734[F08]', "Checking well child" );
}

## use critic

1;

__END__

