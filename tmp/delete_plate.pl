#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use Getopt::Long;
use Try::Tiny;

my $model = LIMS2::Model->new( user => 'webapp', audit_user => $ENV{USER}.'@sanger.ac.uk' );

GetOptions(
    'plate_name=s' => \my $plate_name,
    'commit'       => \my $commit,
);

die "must specify plate name" unless $plate_name;

$model->txn_do(
    sub {
        try{
            $model->delete_plate( { name => $plate_name } );
            print "deleted plate $plate_name";
            unless ( $commit ) {
                print "\nnon-commit mode, rollback";
                $model->txn_rollback;
            }
        }
        catch {
            print "delete plate failed: $_";
            $model->txn_rollback;
        };
    }
);
