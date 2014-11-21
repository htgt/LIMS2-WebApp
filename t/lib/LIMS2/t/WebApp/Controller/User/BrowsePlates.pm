package LIMS2::t::WebApp::Controller::User::BrowsePlates;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/BrowsePlates.pm - test class for LIMS2::WebApp::Controller::User::BrowsePlates

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($FATAL);
}

sub all_tests : Test(3) {
    my $mech = mech();

    note('Can view plate report');

    $mech->get_ok('/user/report/sync/DesignPlate?plate_id=939');
    $mech->content_contains('Design Plate 187');
    $mech->content_contains('Baz2b');

}

## use critic

1;

__END__

