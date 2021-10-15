package LIMS2::Model::Util::PrimerFinder;
use strict;
use warnings;
use Bio::SeqIO;
use Carp;
use Data::UUID;
use DesignCreate::Util::BWA;
use IO::String;
use Path::Class;
use WebAppCommon::Util::EnsEMBL;
use WebAppCommon::Util::RemoteFileAccess;
use base qw/Exporter/;
our @EXPORT_OK = qw/locate_primers choose_closest_primer_hit fetch_amplicon_seq loci_builder/;

=head2 choose_closest_primer_hit

Selects the candidate hit from BWA output nearest to a given target.

    my $target = {
        chr_name   => 9,
        chr_start  => 15093500,
    };
    my $hits = $bwa->oligo_hits;
    # the hits object is read from the BWA YAML output, will look like:
    # $hits = {
    #   exf => {
    #       chr => 'X',
    #       start => 47169187,
    #       hit_locations => [
    #           { chr => '9', start => 15093992 },
    #           { chr => '3', start => 130686952 },
    #           ...
    #       ],
    #   },
    #   ...
    # };

    my $best = choose_closest_primer_hit ( $target, $hits );
    # $best = {
    #   chr   => '9',
    #   start => 15093992,
    # };

    # note: chr can also have 'chr' at the start

Note that choose_closest_primer_hit returns the closest hit as output by BWA,
with no attempt to munge the properties into the format expected elsewhere.

If there are no candidate hits on the same chromosome, returns I<undef>.

=cut

sub choose_closest_primer_hit {
    my ( $target, $hits ) = @_;
    my @candidates = ($hits);
    if ( exists $hits->{hit_locations} ) {
        push @candidates, @{ $hits->{hit_locations} };
    }
    @candidates = grep { $_->{chr} =~ /^(?:chr)?$target->{chr_name}/ } @candidates;
    return if not @candidates;
    my $best          = shift @candidates;
    my $best_distance = abs $target->{chr_start} - $best->{start};
    foreach (@candidates) {
        my $distance = abs $target->{chr_start} - $_->{start};
        if ( $distance < $best_distance ) {
            $best          = $_;
            $best_distance = $distance;
        }
    }
    return $best;
}

sub loci_builder {
    my ( $target_loci, $primer, $oligo_hits ) = @_;
    my $oligo_bwa = choose_closest_primer_hit( $target_loci, $oligo_hits );
    if ( not defined $oligo_bwa ) {
        return;
    }
    my $oligo_len = length( $primer->{seq} );
    my $oligo_end = $oligo_bwa->{start} + $oligo_len - 1;  #Store to ensembl -1 convention. 
    my $chr       = $oligo_bwa->{chr};
    $chr =~ s/chr//xms;
    return {
        chr_start => $oligo_bwa->{start},
        chr_name  => $chr,
        chr_end   => $oligo_end,
    };
}

=head2 locate_primers

    Uses BWA to find the locations of a set of primers, based on their sequences
    and the location of a CRISPR that they are near.

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
    
    locate_primers( 'Human', 'GRCh38', $target_crispr, $primers );

    # $primers = {
    #   exf => {
    #       loci     => {
    #           chr_name   => 17,
    #           chr_start  => 58363089,
    #           chr_end    => 58363109,
    #       },
    #       seq => q/TTTGGGCCTCACCTACAGAA/,
    #   },
    #   ...
    # }

=cut

sub locate_primers {
    my ( $species, $target_crispr, $primers, $genomic_threshold ) = @_;
    my $data = shift;
    my $bwa = DesignCreate::Util::BWA->new(
        primers           => $primers,
        species           => $species,
        three_prime_check => 0,
        num_bwa_threads   => 2,
        num_mismatches    => 0,
    );

    if ( $genomic_threshold ) {
        local $ENV{'BWA_GENOMIC_THRESHOLD'} = $genomic_threshold;
    }

    $bwa->generate_sam_file;
    my $oligo_hits = $bwa->oligo_hits;
    foreach my $oligo ( keys %{$oligo_hits} ) {
        my $locus = loci_builder( $target_crispr->{locus},
            $primers->{$oligo}, $oligo_hits->{$oligo}, );
        carp "Could not find $oligo primer for CRISPR "
          . $target_crispr->{wge_crispr_id}
          if not defined $locus;
        $primers->{$oligo}->{loci} = $locus;
    }
    return $primers;
}

sub fetch_amplicon_seq {
    my ( $species, $strand, $primers ) = @_;

    my $ensembl = WebAppCommon::Util::EnsEMBL->new( species => $species );

    my $left_prime = $primers->{inf}->{loci};
    my $right_prime = $primers->{inr}->{loci};
    if ( $strand == -1 ) {
        $left_prime = $primers->{inr}->{loci};
        $right_prime = $primers->{inf}->{loci};
    }
$DB::single=1;
    my $amplicon = $ensembl->slice_adaptor->fetch_by_region(
        'chromosome',
        $left_prime->{chr_name},
        $left_prime->{chr_end},
        $right_prime->{chr_start} + 1,
        $left_prime->{chr_strand},
    );

    return $amplicon->seq;
}

1;
