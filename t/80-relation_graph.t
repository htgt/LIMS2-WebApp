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
    note( "Test well relations" );

    $mech->get_ok( '/user/graph' );
    ok my $res = $mech->submit_form(
        form_number => '1',
        fields  => { plate_name => 'SEP0006', well_name => 'A01', graph_type => 'descendants' },
        button => 'go',
    ), 'submit well relation graph request';
    $mech->content_contains("<object", 'result page contains image object');
    my ($image_uri) = ( $mech->content =~ /<object data=\"([^\"]*)\"/);
    ok $image_uri, 'image uri found';
    $mech->get_ok($image_uri, 'image exists');
    $mech->content_contains('MOHSAQ0001_A_2_B04','graph contains well MOHSAQ0001_A_2_B04');  
}

{
    note( "Test plate relations" );

    $mech->get_ok( '/user/graph' );
    ok my $res = $mech->submit_form(
        form_number => '2',
        fields  => { pr_plate_name => 'SEP0006', pr_graph_type => 'descendants' },
        button => 'go',
    ), 'submit plate relation graph request';
    $mech->content_contains("<object", 'result page contains image object');
    my ($image_uri) = ( $mech->content =~ /<object data=\"([^\"]*)\"/);
    ok $image_uri, 'image uri found';
    $mech->get_ok($image_uri, 'image exists');
    $mech->content_contains('SEPD0006_1','graph contains plate SEPD0006_1');       
}

done_testing;
