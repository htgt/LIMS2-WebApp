package LIMS2::t::Model::Util::PrimerFinder;
use strict;
use warnings;
use base qw/Test::Class/;
use Test::Most;
use LIMS2::Model::Util::PrimerFinder qw/choose_closest_primer_hit/;

sub _create_hits {
    my $result = { chr => 'chr' . shift, start => shift };
    if(@_){
        my @alternatives = ();
        while(@_){
            push @alternatives, { chr => 'chr' . shift, start => shift }; 
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

1;
