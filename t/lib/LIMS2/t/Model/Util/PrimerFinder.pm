package LIMS2::t::Model::Util::PrimerFinder;
use strict;
use warnings;
use base qw/Test::Class/;
use Test::Most;
use LIMS2::Model::Util::PrimerFinder qw/choose_closest_primer_hit loci_builder locate_primers/;

sub _create_hits {
    my $result = { chr => shift, start => shift };
    if(@_){
        my @alternatives = ();
        while(@_){
            push @alternatives, { chr => shift, start => shift };
        }
        $result->{hit_locations} = \@alternatives;
    }
    return $result;
}

sub test_choose_closest_primer_hit : Test(12) {
    my $target = { chr_name => 13, chr_start => 50000 };
    note('first hit is best');
    {
        my $hits = _create_hits( 13 => 51000, X => 80000, 2 => 50000 );
        ok my $best = choose_closest_primer_hit( $target, $hits );
        is($best->{start}, 51000); 
    }
    note('a different hit is best');
    {
        my $hits = _create_hits( X => 51000, 13 => 49000, 2 => 50000 );
        ok my $best = choose_closest_primer_hit( $target, $hits );
        is($best->{start}, 49000);
    }
    note('no additional candidates');
    {
        my $hits = _create_hits( 13 => 50500 );
        ok my $best = choose_closest_primer_hit( $target, $hits );
        is($best->{start}, 50500);
    }
    note('chooses the best candidate on the right chromosome');
    {
        my $hits = _create_hits( 13 => 60000, 2 => 51000, 13 => 20000 );
        ok my $best = choose_closest_primer_hit( $target, $hits );
        is($best->{start}, 60000);
    }
    note('works when chromosome starts with \'chr\'');
    {
        my $hits = _create_hits( chr13 => 60000, chr2 => 51000, chr13 => 20000 );
        ok my $best = choose_closest_primer_hit( $target, $hits );
        is($best->{start}, 60000);
    }
    note('does not work when chromosome starts with \'chrom\'');
    {
        my $hits = _create_hits( chrom13 => 60000, chrom2 => 51000, chrom13 => 20000 );
        ok not choose_closest_primer_hit( $target, $hits );
    }
    note('no appropriate candidates');
    {
        my $hits = _create_hits( 12 => 80000, X => 51000, 2 => 50000 );
        ok not choose_closest_primer_hit( $target, $hits );
    }

}

sub test_loci_builder : Test(2) {
    my $target = { chr_name => 1, chr_start => 12345 };
    my $primer = { seq => 'ATCG' };
    my $hits = _create_hits( 1 => 12300, Y => 12345, 20 => 10000 );
    my $expected = { chr_start => 12300, chr_name => 1, chr_end => 12303 };
    is_deeply( loci_builder($target, $primer, $hits), $expected, 'loci_builder returns correct loci when closest hit first in list' );
    $target = { chr_name => 13, chr_start => 50000 };
    $hits = _create_hits( X => 51000, 13 => 49000, 2 => 50000 );
    $expected = { chr_start => 49000, chr_name => 13, chr_end => 49003 };
    is_deeply( loci_builder($target, $primer, $hits), $expected, 'loci_builder returns correct loci when closest hit second in list' );
}

sub test_locate_primers : Test(1) {
    my $target_crispr = {
        wge_crispr_id => 1149665659,
        locus  => {
            chr_name   => 17,
            chr_start  => 58363337,
        },
    };
    my $primers = {
        exf => { seq => q/TTTGGGCCTCACCTACAGAA/ },
        exr => { seq => q/CTCACCCCTCACACATCTATC/ },
        inf => { seq => q/GGGTAAGCACACTAGACCTC/ },
        inr => { seq => q/TTTATCTTCCTCCATCCAGCC/ }
    };
    my $expected = {
        exf => {
            loci => {
                chr_name => 17,
                chr_start => 58363089,
                chr_end => 58363108,
            },
            seq => q/TTTGGGCCTCACCTACAGAA/,
        },
        exr => {
            loci => {
                chr_name => 17,
                chr_start => 58363667,
                chr_end => 58363687,
            },
            seq => q/CTCACCCCTCACACATCTATC/,
        },
        inf => {
            loci => {
                chr_name => 17,
                chr_start => 58363257,
                chr_end => 58363276,
            },
            seq => q/GGGTAAGCACACTAGACCTC/,
        },
        inr => {
            loci => {
                chr_name => 17,
                chr_start => 58363473,
                chr_end => 58363493,
            },
            seq => q/TTTATCTTCCTCCATCCAGCC/,
        },
    };
    is_deeply(locate_primers('Human', $target_crispr, $primers), $expected, 'locate_primers returns expected data');
}

1;
