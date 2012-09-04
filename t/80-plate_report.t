#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use File::Temp ':seekable';

my $mech = unauthenticated_mech();

$mech->get_ok( '/login' );
ok $mech->submit_form(
    form_name => 'login_form',
    fields    => { username => 'test_user@example.org', password => 'ahdooS1e' },
    button    => 'login'
), 'Login with correct username and password';

{
    note('Can view plate report');

    $mech->get_ok( '/user/report/sync/DesignPlate?plate_id=939' );
    $mech->content_contains('Design Plate 187');
    $mech->content_contains('Baz2b');
}

done_testing;
