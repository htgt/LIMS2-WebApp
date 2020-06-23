package LIMS2::t::WebApp::Controller::API::PointMutation;
use base qw(Test::Class);
use Test::More;
use strict;
use warnings FATAL => 'all';
use LIMS2::WebApp::Controller::API::PointMutation;

sub test_add_well_name_col : Test(2) {
    my @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_well_name_col( 'A01',
        ( 'header1,header2', 'data1,data2', 'data3,data4' ) );
    my @expected =
      ( 'Well_Name,header1,header2', ( 'A01,data1,data2', 'A01,data3,data4' ) );
    is_deeply( \@result, \@expected,
        'add_well_name_col returns data with well name' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_well_name_col( '',
        ( 'header', 'data' ) );
    @expected = ( 'Well_Name,header', (',data') );
    is_deeply( \@result, \@expected,
        'add_well_name_col returns expected data with missing well name' );
    return;
}

# more tests to come

1;
