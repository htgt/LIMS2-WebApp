package LIMS2::t::WebApp::Controller::API::PointMutation;
use base qw(Test::Class);
use Test::More;
use strict;
use warnings FATAL => 'all';
use LIMS2::WebApp::Controller::API::PointMutation;

sub test_modify_data : Test(4) {
    my @result = LIMS2::WebApp::Controller::API::PointMutation::modify_data(
        0, 300, 'L14',
        (
            'Aligned_Sequence,Reference_Sequence,Phred_Quality',
            'ATCG,ATCG,****', 'GCTA,GCTA,!!!!'
        )
    );
    my @expected = (
        'Well_Name,Aligned_Sequence,Reference_Sequence,Phred_Quality',
        'L14,ATCG,ATCG,****', 'L14,GCTA,GCTA,!!!!'
    );
    is_deeply( \@result, \@expected,
        'modify_data returns correctly modified data with no well offset' );
    @result = LIMS2::WebApp::Controller::API::PointMutation::modify_data(
        1, 300, 'L14',
        (
            'Aligned_Sequence,Reference_Sequence,Phred_Quality',
            'ATCG,ATCG,****', 'GCTA,GCTA,!!!!'
        )
    );
    @expected = (
        'Well_Name,Quadrant,Aligned_Sequence,Reference_Sequence,Phred_Quality',
        'D02,4,ATCG,ATCG,****', 'D02,4,GCTA,GCTA,!!!!'
    );
    is_deeply( \@result, \@expected,
        'modify_data returns correctly modified data with well offset' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::modify_data( 0, 300,
        'L14', ( 'header', 'data' ) );
    @expected = (
        'Well_Name,Aligned_Sequence,Reference_Sequence,Phred_Quality,header',
        'L14,,,,data'
    );
    is_deeply( \@result, \@expected,
        'modify_data returns expected data when headers missing' );
    @result = LIMS2::WebApp::Controller::API::PointMutation::modify_data(
        1, 0, '',
        (
            'Aligned_Sequence,Reference_Sequence,Phred_Quality',
            'ATCG,ATCG,****'
        )
    );
    @expected = (
        'Well_Name,Quadrant,Aligned_Sequence,Reference_Sequence,Phred_Quality',
        ',0,ATCG,ATCG,****'
    );
    is_deeply( \@result, \@expected,
'modify_data returns expected data with missing well name and out of range index'
    );
    return;
}

sub test_validate_columns : Test(3) {
    my @result =
      LIMS2::WebApp::Controller::API::PointMutation::validate_columns(
        'Aligned_Sequence,Reference_Sequence,Phred_Quality',
        ( 'ATCG,ATCG,****', 'GCTA,GCTA,!!!!' ) );
    my @expected = (
        'Aligned_Sequence,Reference_Sequence,Phred_Quality',
        'ATCG,ATCG,****', 'GCTA,GCTA,!!!!'
    );
    is_deeply( \@result, \@expected,
        'validate_columns returns data as before when all columns present' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::validate_columns(
        'Aligned_Sequence,Reference_Sequence',
        ( 'ATCG,ATCG', 'GCTA,GCTA' ) );
    @expected = (
        'Aligned_Sequence,Reference_Sequence,Phred_Quality',
        'ATCG,ATCG,', 'GCTA,GCTA,'
    );
    is_deeply( \@result, \@expected,
        'validate_columns returns data with missing column filled in' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::validate_columns( 'header',
        ( 'data1', 'data2' ) );
    @expected = (
        'Aligned_Sequence,Reference_Sequence,Phred_Quality,header',
        ',,,data1', ',,,data2'
    );
    is_deeply( \@result, \@expected,
        'validate_columns returns data with all missing columns filled in' );
    return;
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
      LIMS2::WebApp::Controller::API::PointMutation::add_column( 'new_header',
        'new_data', 0, ( 'header1,header2', 'data1,data2', 'data3,data4' ) );
    my @expected = (
        'new_header,header1,header2',
        ( 'new_data,data1,data2', 'new_data,data3,data4' )
    );
    is_deeply( \@result, \@expected,
        'add_column returns expected data with added column at start' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_column( 'new_header',
        'new_data', 2, ( 'header1,header2', 'data1,data2', 'data3,data4' ) );
    @expected = (
        'header1,header2,new_header',
        ( 'data1,data2,new_data', 'data3,data4,new_data' )
    );
    is_deeply( \@result, \@expected,
        'add_column returns expected data with added column at end' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_column( 'new_header',
        'new_data', 1, ( 'header1,header2', 'data1,data2', 'data3,data4' ) );
    @expected = (
        'header1,new_header,header2',
        ( 'data1,new_data,data2', 'data3,new_data,data4' )
    );
    is_deeply( \@result, \@expected,
        'add_column returns expected data with added column in middle' );
    return;
}

sub test_add_item_to_data : Test(3) {
    my @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_item_to_data(
        'new_data', 0, ( 'data1,data2', 'data3,data4' ) );
    my @expected = ( 'new_data,data1,data2', 'new_data,data3,data4' );
    is_deeply( \@result, \@expected,
        'add_item_to_data adds data at start of row' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_item_to_data(
        'new_data', 1, ( 'data1,data2', 'data3,data4' ) );
    @expected = ( 'data1,new_data,data2', 'data3,new_data,data4' );
    is_deeply( \@result, \@expected,
        'add_item_to_data adds data in middle of row' );
    @result =
      LIMS2::WebApp::Controller::API::PointMutation::add_item_to_data(
        'new_data', 2, ( 'data1,data2', 'data3,data4' ) );
    @expected = ( 'data1,data2,new_data', 'data3,data4,new_data' );
    is_deeply( \@result, \@expected,
        'add_item_to_data adds data at end of row' );
    return;
}

1;
