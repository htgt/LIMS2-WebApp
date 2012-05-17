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

        ok my $u1 = $model->create_user( { name => 'TEST_foo' } ),
            'create a user with no roles';

        ok my $u2 = $model->create_user( { name => 'TEST_bar', roles => [ 'read', 'edit' ] } ),
            'create a user with two roles';

        can_ok $model, 'delete_user';
        
        ok $model->delete_user( { slice( $u1->as_hash, 'name' ) } ),
            'delete user 1';

        ok $model->delete_user( { slice( $u2->as_hash, 'name' ) } ),
            'delete_user 2';
    }
);

done_testing;
