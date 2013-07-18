package LIMS2::t::Model::Plugin::User;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Plugin::User;

use LIMS2::Test;
use Hash::MoreUtils qw( slice );

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Plugin/User.pm - test class for LIMS2::Model::Plugin::User

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

sub all_tests  : Test(7)
{

    model->txn_do(
	sub {
	    my $model = shift;

	    can_ok $model, 'create_user';

	    ok my $u1 = $model->create_user( { name => 'TEST_foo', password => 'XXX' } ),
		'create a user with no roles';

	    ok my $u2 = $model->create_user( { name => 'TEST_bar', roles => [ 'read', 'edit' ], password => 'YYY' } ),
		'create a user with two roles';

	    can_ok $model, 'disable_user';

	    ok $model->disable_user( { name => $u1->name } );

	    can_ok $model, 'enable_user';

	    ok $model->enable_user( { name => $u1->name } );
	}
    );

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

