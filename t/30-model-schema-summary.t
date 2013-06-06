#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;

{
	note ("Testing satisfies cassette function");

	my $summary = model->schema->resultset('Summary')->new({
		final_pick_well_id              => 1,
		final_pick_cassette_conditional => 1,
		final_pick_cassette_promoter    => 1,
		final_pick_cassette_cre         => 0,
		final_pick_recombinase_id       => 'Cre'
	});
	
	my $cassettes = model->schema->resultset('CassetteFunction');
	
	ok $summary->satisfies_cassette_function( $cassettes->find('reporter_only') ), "...is reporter_only";
	ok $summary->satisfies_cassette_function( $cassettes->find('reporter_only_promoter') ), "...is reporter_only_promoter";
	ok !$summary->satisfies_cassette_function( $cassettes->find('ko_first') ), "...is not ko_first";
	
	$summary->final_pick_recombinase_id(undef);
	
	ok $summary->satisfies_cassette_function( $cassettes->find('ko_first') ), "...is ko_first";
	ok $summary->satisfies_cassette_function( $cassettes->find('ko_first_promoter') ), "...is ko_first_promoter";
    ok !$summary->satisfies_cassette_function( $cassettes->find('ko_first_promoterless') ), "...is not ko_first_promoterless";
    ok !$summary->satisfies_cassette_function( $cassettes->find('reporter_only') ), "...is not reporter_only";
    
    $summary->final_pick_cassette_cre(1);
    
    ok $summary->satisfies_cassette_function( $cassettes->find('cre_knock_in') ), "..is cre_knock_in";
}
done_testing();
