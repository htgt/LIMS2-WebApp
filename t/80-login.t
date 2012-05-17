#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;

my $mech = unauthenticated_mech();

{
    $mech->get_ok( '/login' );
    ok my $res = $mech->submit_form(
        form_name => 'login_form',
        fields    => { username => 'test_user@example.org', password => 'foobar' },
        button    => 'login'
    ), 'Login with invalid password';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/login', '...stays on the login page';
    like $res->content, qr/Incorrect username or password/, '...incorrect username/password error displayed';
}

{
    $mech->get_ok( '/login' );
    ok my $res = $mech->submit_form(
        form_name => 'login_form',
        fields    => { username => 'no_such_user@example.org', password => 'ahdooS1e' },
        button    => 'login'
    ), 'Login with incorrect username';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/login', '...stays on the login page';
    like $res->content, qr/Incorrect username or password/, '...incorrect username/password error displayed';
}

{
    $mech->get_ok( '/login' );
    ok my $res = $mech->submit_form(
        form_name => 'login_form',
        fields    => { username => 'test_user@example.org', password => 'ahdooS1e' },
        button    => 'login'
    ), 'Login with correct username and password';

    ok $res->is_success, '...response is_success';
    like $res->content, qr/Login successful/, '...login successful message is present';
    is $res->base->path, '/', '...redirected to "/"';
}

done_testing;

