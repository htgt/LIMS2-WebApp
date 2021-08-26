package LIMS2::t::Model::Util::PrimerFinder;
use strict;
use warnings;
use base qw/Test::Class/;
use Test::Most;
use LIMS2::Model::Util::PrimerFinder qw/choose_closest_primer_hit loci_builder/;

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

sub test_choose_closest_primer_hit : Test(9) {
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
    is_deeply( loci_builder($target, $primer, $hits), $expected, 'loci_builder returns correct loci' );
    $target = { chr_name => 13, chr_start => 50000 };
    $hits = _create_hits( X => 51000, 13 => 49000, 2 => 50000 );
    $expected = { chr_start => 49000, chr_name => 13, chr_end => 49003 };
    is_deeply( loci_builder($target, $primer, $hits), $expected, 'loci_builder returns correct loci' );
}

1;
