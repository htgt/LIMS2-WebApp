package LIMS2::t::WebApp::Controller::API::RearrayPIQ;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::API::PlateWell;
use LIMS2::t::WebApp::Controller::API qw( construct_post );

use LIMS2::Test model => { classname => __PACKAGE__ };
use File::Temp ':seekable';
use JSON;
use YAML;
use HTTP::Request;
use Data::Dumper;
use POSIX;

use strict;

## no critic

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
};


my $mech = LIMS2::Test::mech();

sub all_tests  : Test(15)
{
    note ('Testing Create PIQ REST API');
    create_piq_post();

    note ("Testing wells_parent_GET API");
    wells_parent_plate_get();

    note ('Testing sibling_miseq_plate_GET API');
    sibling_miseq_plate_get();
}

sub create_piq_post {
    note ('Test successful run through');

    my $data = {
        name        => 'PIQ_creation_test_success',
        created_by  => 'test_user@example.org',
        species     => 'Human',
        created_at  => strftime("%Y-%m-%dT%H:%M:%S", localtime(time)),
        type        => 'PIQ',
        wells       => {
            A01 => {
                parent_well => 'G01',
                parent_plate => 'Test_Ref_FP',
            },
            B01 => {
                parent_well => 'G02',
                parent_plate => 'Test_Ref_FP',
            },
            C01 => {
                parent_well => 'G03',
                parent_plate => 'Test_Ref_FP',
            },
            D01 => {
                parent_well => 'G04',
                parent_plate => 'Test_Ref_FP',
            },
            E01 => {
                parent_well => 'G05',
                parent_plate => 'Test_Ref_FP',
            },
        },
    };

    my $json_response = _submit_post_query($data);
    is ($json_response->{name}, 'PIQ_creation_test_success', 'New PIQ is created with name "PIQ_creation_test_success"');

    note ('Test incorrect parent plate type');
    
    $data->{name} = 'PIQ_incorrect_parent';
    map { $data->{wells}->{$_}->{parent_plate} = 'Test_Ref_EP' } keys %{ $data->{wells} };
    
    $json_response = _submit_post_query($data);
    like ($json_response->{error}, qr/dist_qc process input well should be type FP/, 'Receive error response - Incorrect parent plate type');

    note ('Out of bounds well names');

    $data->{name} = 'PIQ_out_of_bounds';
    my $count = 0;
    my @well_keys = keys %{ $data->{wells} };
    map { $data->{wells}->{$_}->{parent_plate} = 'Test_Ref_FP' } @well_keys;
    map { $data->{wells}->{$_}->{parent_well} = 'E' . (13 + $count); $count++; } @well_keys;
    
    $json_response = _submit_post_query($data);
    like ($json_response->{error}, qr/Can not find parent well Test_Ref_FP/, 'No parent wells found');

    return;
}

sub _submit_post_query {
    my ($data) = @_;

    my $json_data = encode_json($data);
    my $req = construct_post('/api/create_piq_plate/?relations=' . $json_data);

    ok $mech->request( $req ), 'Query received';
    ok my $json_response = decode_json($mech->content), 'Decode JSON response';

    return $json_response;
}

sub wells_parent_plate_get {
    $mech->get_ok('/api/wells_parent_plate/?plate=Sibling_PIQ', {'content-type' => 'text/plain'} );
    ok my $json = decode_json($mech->content), 'Response is JSON';
    is ($json->{'Parent_FP'}->{type}, 'FP', 'Parent plate is of type FP');
 
    $mech->get('/api/wells_parent_plate/?plate=iDoNotExist', {'content-type' => 'text/plain'} );
    is ($mech->status, '415', "Bad request - plate does not exist");

    $mech->get('/api/wells_parent_plate/?plate=', {'content-type' => 'text/plain'} );
    is ($mech->status, '415', "Bad request - nothing supplied");

    return;
}

sub sibling_miseq_plate_get {
$DB::single=1;
    $mech->get_ok('/api/sibling_miseq_plate/?plate=Sibling_PIQ', {'content-type' => 'application/json'} );
    ok my $json = decode_json($mech->content), 'Response is JSON';
    print Dumper $json;

    return;
}

1;
