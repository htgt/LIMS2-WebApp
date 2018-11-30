package LIMS2::Model::Util::PrimerFinder;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::PrimerFinder::VERSION = '0.516';
}
## use critic

use strict;
use warnings;
use Bio::SeqIO;
use Carp;
use Data::UUID;
use DesignCreate::Util::BWA;
use Path::Class;
use base qw/Exporter/;
our @EXPORT_OK = qw/locate_primers choose_closest_primer_hit/;

sub generate_bwa_query_file {
    my $primers = shift;

    my $root_dir = $ENV{'LIMS2_BWA_OLIGO_DIR'} // '/var/tmp/bwa';
    my $ug = Data::UUID->new();

    my $unique_string = $ug->create_str();
    my $dir_out = dir( $root_dir, '_' . $unique_string );
    mkdir $dir_out->stringify
      or croak 'Could not create directory ' . $dir_out->stringify . ": $!";

    my $fasta_file_name = $dir_out->file('oligos.fasta');
    my $fh              = $fasta_file_name->openw();
    my $seq_out         = Bio::SeqIO->new( -fh => $fh, -format => 'fasta' );

    foreach my $oligo ( sort keys %{$primers} ) {
        my $fasta_seq = Bio::Seq->new(
            -seq => $primers->{$oligo}->{seq},
            -id  => $oligo
        );
        $seq_out->write_seq($fasta_seq);
    }
    return ( $fasta_file_name, $dir_out );
}

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
    #       chr => 'chrX',
    #       start => 47169187,
    #       hit_locations => [
    #           { chr => 'chr9', start => 15093992 },
    #           { chr => 'chr3', start => 130686952 },
    #           ...
    #       ],
    #   },
    #   ...
    # };

    my $best = choose_closest_primer_hit ( $target, $hits );
    # $best = {
    #   chr   => 'chr9',
    #   start => 15093992,
    # };

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
    my $target_chr = 'chr' . $target->{chr_name};
    @candidates = grep { $_->{chr} eq $target_chr } @candidates;
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
    my $oligo_end = $oligo_bwa->{start} + $oligo_len;
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
        wge_id => 1149665659,
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
    my ( $fasta, $dir ) = generate_bwa_query_file($primers);
    my $bwa = DesignCreate::Util::BWA->new(
        query_file        => $fasta,
        work_dir          => $dir,
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
          . $target_crispr->{wge_id}
          if not defined $locus;
        $primers->{$oligo}->{loci} = $locus;
    }
    return $primers;
}

1;
