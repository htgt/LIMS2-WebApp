#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use JSON qw( encode_json decode_json );
use HTTP::Request::Common;
use HTTP::Status qw( :constants );

my @seq_reads_data = test_data( 'qc_seq_reads.yaml' );

my $mech = mech();

for my $s ( @seq_reads_data ) {    
    ok my $res = $mech->request( POST '/api/qc_seq_read', 'Content-Type' => 'application/json', Content => encode_json( $s ) ), "POST qc_seq_read $s->{id}";
    ok $res->is_success, '...request should succeed';
    is $res->code, HTTP_CREATED, '...status is "created"';
    like $res->header('location'), qr(\Q/api/qc_seq_read?id=$s->{id}\E$), '...location header is correct';    
}

done_testing();
