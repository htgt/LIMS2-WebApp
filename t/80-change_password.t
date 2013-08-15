#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

my $mech = mech();

{
    note( "Don't specify new password" );
    $mech->get_ok( '/user/change_password' );
    $mech->title_is('Change Password');
    ok my $res = $mech->submit_form(
        form_id => 'change_password',
        fields  => {
            new_password         => '',
            new_password_confirm => ''
        },
        button => 'change_password_submit'
    ), 'submit form with no new password value';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/change_password', '...stays on the same page';
    like $res->content, qr/You must specify a new password/, '... no new password specified';
}

{
    note( "Don't specify new password confirm field" );
    $mech->get_ok( '/user/change_password' );
    $mech->title_is('Change Password');
    ok my $res = $mech->submit_form(
        form_id => 'change_password',
        fields  => {
            new_password         => 'new_pass',
            new_password_confirm => ''
        },
        button => 'change_password_submit'
    ), 'submit form with no new password confirm value';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/change_password', '...stays on the same page';
    like $res->content, qr/You must fill in password confirm box as well/, '... no new password confirm specified';
}

{
    note( "New password and Password confirm values do not match" );
    $mech->get_ok( '/user/change_password' );
    $mech->title_is('Change Password');
    ok my $res = $mech->submit_form(
        form_id => 'change_password',
        fields  => {
            new_password         => 'new_pass',
            new_password_confirm => 'foo_bar'
        },
        button => 'change_password_submit'
    ), 'submit form with non';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/change_password', '...stays on the same page';
    like $res->content, qr/new password and password confirm values do not match/, '... password and password confirm values do not match';
}

{
    note( "Invalid password" );
    $mech->get_ok( '/user/change_password' );
    $mech->title_is('Change Password');
    ok my $res = $mech->submit_form(
        form_id => 'change_password',
        fields  => {
            new_password         => 'pass',
            new_password_confirm => 'pass'
        },
        button => 'change_password_submit'
    ), 'submit form with invalid password';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/change_password', '...stays on the same page';
    like $res->content, qr/new_password, is invalid: password_string/, '... invalid password message';
}

{
    note( "Change password successful" );
    $mech->get_ok( '/user/change_password' );
    $mech->title_is('Change Password');
    ok my $res = $mech->submit_form(
        form_id => 'change_password',
        fields  => {
            new_password         => 'new_pass',
            new_password_confirm => 'new_pass'
        },
        button => 'change_password_submit'
    ), 'submit form with non';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/', '...moves to root page';
    like $res->content, qr/Password successfully changed for: test_user/, '... password and password confirm values do not match';
}

{
    my $new_mech = unauthenticated_mech();
    $new_mech->get_ok( '/login' );
    ok $new_mech->submit_form(
        form_name => 'login_form',
        fields    => { username => 'test_user@example.org', password => 'new_pass' },
        button    => 'login'
    ), 'Login with changed password';
}

{
    note( "Change password back" );
    $mech->get_ok( '/user/change_password' );
    $mech->title_is('Change Password');
    ok my $res = $mech->submit_form(
        form_id => 'change_password',
        fields  => {
            new_password         => 'ahdooS1e',
            new_password_confirm => 'ahdooS1e'
        },
        button => 'change_password_submit'
    ), 'submit form with non';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/', '...moves to root page';
    like $res->content, qr/Password successfully changed for: test_user/, '... password and password confirm values do not match';
}

done_testing;

