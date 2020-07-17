package LIMS2::t::WebApp::Controller::API::PointMutation;
use base qw(Test::Class);
use Test::More;
use strict;
use warnings FATAL => 'all';
use LIMS2::WebApp::Controller::API::PointMutation;

sub test_modify_data : Test(3) {
    my @result =
      LIMS2::WebApp::Controller::API::PointMutation::modify_data( 0, 300,
        'L14', ( 'header', 'row1', 'row2' ) );
    my @expected = ( 'Well_Name,header', 'L14,row1', 'L14,row2' );
    is_deeply( \@result, \@expected,
        'modify_data returns correctly modified data with no well offset' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::modify_data( 1, 300,
        'L14', ( 'header', 'row1', 'row2' ) );
    @expected = ( 'Well_Name,Quadrant,header', 'D02,4,row1', 'D02,4,row2' );
    is_deeply( \@result, \@expected,
        'modify_data returns correctly modified data with well offset' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::modify_data( 1, 0, '',
        ( 'header', 'data' ) );
    @expected = ( 'Well_Name,Quadrant,header', ',0,data' );
    is_deeply( \@result, \@expected,
'modify_data returns expected data with missing well name and out of range index'
    );
}

sub test_offset_well : Test(6) {
    my @result = LIMS2::WebApp::Controller::API::PointMutation::offset_well(1);
    my @expected = ( 'A01', 1 );
    is_deeply( \@result, \@expected,
        'offset_well returns correct well name and quadrant for index 1' );
    @result   = LIMS2::WebApp::Controller::API::PointMutation::offset_well(150);
    @expected = ( 'F07', 2 );
    is_deeply( \@result, \@expected,
        'offset_well returns correct well name and quadrant for index 150' );
    @result   = LIMS2::WebApp::Controller::API::PointMutation::offset_well(288);
    @expected = ( 'H12', 3 );
    is_deeply( \@result, \@expected,
        'offset_well returns correct well name and quadrant for index 288' );
    @result   = LIMS2::WebApp::Controller::API::PointMutation::offset_well(289);
    @expected = ( 'A01', 4 );
    is_deeply( \@result, \@expected,
        'offset_well returns correct well name and quadrant for index 289' );
    @result   = LIMS2::WebApp::Controller::API::PointMutation::offset_well(0);
    @expected = ( '', 0 );
    is_deeply( \@result, \@expected,
        'offset_well returns empty string and 0 for out of range index' );
    @result   = LIMS2::WebApp::Controller::API::PointMutation::offset_well(500);
    @expected = ( '', 0 );
    is_deeply( \@result, \@expected,
        'offset_well returns empty string and 0 for out of range index' );
    return;
}

sub test_add_column : Test(3) {
    my @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_column( 'Quadrant', 1,
        ( 'header1,header2', 'data1,data2', 'data3,data4' ) );
    my @expected =
      ( 'Quadrant,header1,header2', ( '1,data1,data2', '1,data3,data4' ) );
    is_deeply( \@result, \@expected,
        'add_column returns expected data with quadrant column' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_column( 'Experiment',
        'exp', ( 'header1,header2', 'data1,data2', 'data3,data4' ) );
    @expected =
      ( 'Experiment,header1,header2',
        ( 'exp,data1,data2', 'exp,data3,data4' ) );
    is_deeply( \@result, \@expected,
        'add_column returns expected data with experiment column' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_column( 'Well_Name',
        '', ( 'header', 'data' ) );
    @expected = ( 'Well_Name,header', (',data') );
    is_deeply( \@result, \@expected,
        'add_column returns expected data with missing well name' );
    return;
}

sub test_add_item_to_data : Test(2) {
    my @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_item_to_data( 1,
        ( 'data1,data2', 'data3,data4' ) );
    my @expected = ( '1,data1,data2', '1,data3,data4' );
    is_deeply( \@result, \@expected, 'add_item_to_data adds number to data' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_item_to_data( 'A01',
        ( 'data1,data2', 'data3,data4' ) );
    @expected = ( 'A01,data1,data2', 'A01,data3,data4' );
    is_deeply( \@result, \@expected, 'add_item_to_data adds string to data' );
    return;
}

1;
