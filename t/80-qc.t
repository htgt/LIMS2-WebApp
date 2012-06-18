#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use JSON qw( encode_json decode_json );
use HTTP::Request::Common;
use HTTP::Status qw( :constants );

my $mech = mech();

note "Testing creation and retrieval of QC template";

my $template;

{
    my $template_data = test_data( 'qc_template.yaml' );
    my $template_name = $template_data->{name};

    ok my $res = $mech->request( POST '/api/qc_template', 'Content-Type' => 'application/json', Content => encode_json( $template_data ) ), "POST qc_template $template_name";
    ok $res->is_success, '...request should succeed';
    is $res->code, HTTP_CREATED, '...status is created';

    lives_ok {
        $template = decode_json( $res->content )
    } '...decoding JSON lives';

    like $res->header('location'), qr(\Q/api/qc_template?id=$template->{id}\E$), '...location header is correct';
}

note "Testing creation and retrieval of QC run";

my $run_data = test_data( 'qc_run.yaml' );
$run_data->{qc_template_name} = $template->{name};
my $test_results = delete $run_data->{test_results};

{
    ok my $res = $mech->request( POST '/api/qc_run', 'Content-Type' => 'application/json', Content => encode_json( $run_data ) ), "POST qc_run $run_data->{id}";
    ok $res->is_success, '...request should succeed';
    is $res->code, HTTP_CREATED, '..status is created';
    like $res->header('location'), qr(\Q/api/qc_run?id=$run_data->{id}\E$), '...location header is correct';
}

note "Testing creation and retrieval of QC sequencing reads";

{
    my @seq_reads_data = test_data( 'qc_seq_reads.yaml' );

    for my $s ( @seq_reads_data ) {
        ok my $res = $mech->request( POST '/api/qc_seq_read', 'Content-Type' => 'application/json', Content => encode_json( $s ) ), "POST qc_seq_read $s->{id}";
        ok $res->is_success, '...request should succeed';
        is $res->code, HTTP_CREATED, '...status is "created"';
        like $res->header('location'), qr(\Q/api/qc_seq_read?id=$s->{id}\E$), '...location header is correct';
    }
}

# XXX Retrieve QC run not yet implemented
# {
#     my $url = "/api/qc_run?id=$run_data->{id}";
#     ok my $res = $mech->request( GET $url, 'Content-Type' => 'application/json' ), "GET $url";
#     ok $res->is_success, '...request should succeed';
#     is $res->code, HTTP_OK, '...status is ok';
#     my $run;
#     lives_ok {
#         $run = decode_json( $res->content );
#     } '...decoding JSON lives';
#     is $run->{id}, $run_data->{id}, '...run id is correct';
# }

note "Testing creation and retrieval of test results";

for my $test_result ( @{ $test_results } ) {
    # Make sure the eng_seq_id exists in the database
    my $eng_seq_id = model->schema->resultset( 'QcEngSeq' )->search( {}, { order_by => \'RANDOM()', limit => 1 } )->first->id;
    $test_result->{qc_eng_seq_id} = $eng_seq_id;
    for my $alignment ( @{ $test_result->{alignments} } ) {
        $alignment->{qc_eng_seq_id} = $eng_seq_id;
    }
    $test_result->{qc_run_id} = $run_data->{id};
    my $test_result_id;
    {
        ok my $res = $mech->request( POST '/api/qc_test_result', 'Content-Type' => 'application/json', Content => encode_json( $test_result ) ), 'POST /api/qc_test_result';
        ok $res->is_success, '...request should succeed';
        is $res->code, HTTP_CREATED, '...status is created';
        like $res->header('location'), qr(\Q/api/qc_test_result?id=\E\d+$), '...location header is correct';
        ( $test_result_id ) = $res->header('location') =~ m/(\d+)$/;
    }
    {
        my $url = "/api/qc_test_result?id=$test_result_id";
        ok my $res = $mech->request( GET $url, 'Content-Type' => 'application/json' ), "GET $url";
        ok $res->is_success, '...request should succeed';
        is $res->code, HTTP_OK, '...status is ok';
        my $entity;
        lives_ok {
            $entity = decode_json( $res->content );
        } '...decoding JSON lives';
        is $entity->{id}, $test_result_id, '...it has the expected id';
    }
}

done_testing();
