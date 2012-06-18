#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use Hash::MoreUtils qw( slice );

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

done_testing;
