#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use YAML::Any;
use LIMS2::Model;
use Crypt::SaltedHash;

my %seen;

my @data = YAML::Any::LoadFile( shift @ARGV );

my $model = LIMS2::Model->new( user => 'webapp', audit_user => $ENV{USER}.'@sanger.ac.uk' );

$model->txn_do(
    sub {
        for my $d ( @data ) {
            my $user_name = lc( $d->{map_to} || $d->{user_name} );
            next if $seen{ $user_name }++;
            next if $model->schema->resultset( 'User' )->find( { name => $user_name } );
            my $csh = Crypt::SaltedHash->new( algorithm => "SHA-1" );
            $csh->add( $model->pwgen(30) );
            $model->schema->resultset( 'User' )->create(
                {
                    name     => $user_name,
                    password => $csh->generate,
                    active   => 0
                }
            );
        }
    }
);
              
            
