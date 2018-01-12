package LIMS2::Model::Util::CreateMiseqDesign;

use strict;
use warnings FATAL => 'all';

use Moose;

use namespace::autoclean;
use Path::Class;
use Sub::Exporter -setup => {
    exports => [
        qw(
              create_miseq_design
          )
    ],
};

use List::MoreUtils qw( uniq );
use POSIX qw(strftime);
use JSON;
use Bio::Perl qw( revcom );
use YAML::XS qw( LoadFile );

use LIMS2::Model::Util::OligoSelection qw(
        pick_crispr_primers
        pick_single_crispr_primers
        pick_miseq_internal_crispr_primers
        pick_miseq_crispr_PCR_primers
        oligo_for_single_crispr
        pick_crispr_PCR_primers
);
use LIMS2::Model::Util::Crisprs qw( gene_ids_for_crispr ); 

sub create_miseq_design {
    my ($c, $design, @crisprs) = @_;
    
    my $search_range = {
        search    => {
            internal    => 170,
            external    => 350,
        },
        dead    => {
            internal    => 50,
            external    => 170,
        },
    };
    
    my @results;
    foreach my $crispr_id (@crisprs) {
        my ($internal_crispr_primers, $pcr_crispr_primers) = generate_primers($c, $crispr_id, $search_range);

        my $slice_adaptor = $c->model('Golgi')->ensembl_slice_adaptor('Human');
        my $slice_region = $slice_adaptor->fetch_by_region(
            'chromosome',
            $internal_crispr->{'left_crispr'}->{'chr_name'},
            $internal_crispr->{'left_crispr'}->{'chr_start'} - 1000,
            $internal_crispr->{'left_crispr'}->{'chr_end'} + 1000,
            1,
        );
        my $crispr_loc = index ($slice_region->seq, $internal_crispr->{left_crispr}->{seq});
        my ($inf, $inr) = find_appropriate_primers($internal_crispr_primers, 260, 297, $slice_region->seq, $crispr_loc);
        my ($exf, $exr) = find_appropriate_primers($pcr_crispr_primers, 750, 3000, $slice_region->seq);
$DB::single=1;
        my $result = {
            crispr  => $internal_crispr->{left_crispr}->{id},
            genomic => $pcr_crispr_primers->{pair_count},
            oligos  => {
                inf => $inf,
                inr => $inr,
                exf => $exf,
                exr => $exr,
            },
        };
        push @results, $result;
        package_parameters($c, $design, $result, $search_range->{dead});
        my $crispr_rs = $c->model('Golgi')->schema->resultset('Crispr')->find({ id => $result_data->{crispr} });
        my $crispr_details = $crispr_rs->as_hash;

        my $design_json = {
            design_parameters   => $json_params,
            created_by          => $c->user->name,
            species             => $c->session->{selected_species},
            type                => $design_params->{design_type},
            gene_ids            => \@gene_ids,
            oligos              => $oligos,
        };
        
        my $design = $c->model( 'Golgi' )->txn_do(
            sub {
                shift->c_create_design( $design_json );
            }
        );



    }
    return @results;
};

sub generate_primers {
    my ($c, $crispr_id, $search_range) = @_;

    my $params = {
        crispr_id => $crispr_id,
        species => 'Human',
        repeat_mask => [''],
        offset => 20,
        increment => 15,
        well_id => 'Miseq_Crispr_' . $crispr_id,
    };

    $ENV{'LIMS2_SEQ_SEARCH_FIELD'} = $search_range->{search}->{internal};
    $ENV{'LIMS2_SEQ_DEAD_FIELD'} = $search_range->{dead}->{internal};

    my ($internal_crispr, $internal_crispr_primers) = pick_miseq_internal_crispr_primers($c->model('Golgi'), $params);

    $ENV{'LIMS2_PCR_SEARCH_FIELD'} = $search_range->{search}->{external};
    $ENV{'LIMS2_PCR_DEAD_FIELD'} = $search_range->{dead}->{external};
    $params->{increment} = 50;

    my $crispr_seq = {
        chr_region_start    => $internal_crispr->{left_crispr}->{chr_start},
        left_crispr         => { chr_name   => $internal_crispr->{left_crispr}->{chr_name} },
    };
    my $en_strand = {
        1   => 'plus',
        -1  => 'minus',
    };
$DB::single=1;
    if ($internal_crispr_primers->{error_flag} eq 'fail' ) {
        print "Primer generation failed: Internal primers - " . $internal_crispr_primers->{error_flag} . "; Crispr:" . $crispr_id . "\n";
        exit;
    }
    $params->{crispr_primers} = { 
        crispr_primers  => $internal_crispr_primers,
        crispr_seq      => $crispr_seq,
        strand          => $en_strand->{$internal_crispr->{left_crispr}->{chr_strand}},
    };

    my ($pcr_crispr, $pcr_crispr_primers) = pick_miseq_crispr_PCR_primers($c->model('Golgi'), $params);

    $DB::single=1;
    if ($pcr_crispr_primers->{error_flag} eq 'fail') {
        print "Primer generation failed: PCR results - " . $pcr_crispr_primers->{error_flag} . "; Crispr " . $crispr_id . "\n";
        exit;
    } elsif ($pcr_crispr_primers->{genomic_error_flag} eq 'fail') {
        print "PCR genomic check failed; PCR results - " . $pcr_crispr_primers->{genomic_error_flag} . "; Crispr " . $crispr_id . "\n";
        exit;
    }

    return $internal_crispr_primers, $pcr_crispr_primers;
}

sub find_appropriate_primers {
    my ($crispr_primers, $target, $max, $region, $crispr) = @_;

    #print Dumper $crispr_primers;
    my @primers = keys %{$crispr_primers->{left}};
    my $closest->{record} = 5000;
    my @test;
    foreach my $prime (@primers) {
        my $int = (split /_/, $prime)[1];
        my $left_location_details = $crispr_primers->{left}->{'left_' . $int}->{location};
        my $right_location_details = $crispr_primers->{right}->{'right_' . $int}->{location};
        my $range = $right_location_details->{_start} - $left_location_details->{_end};
        my $start_coord = index ($region, $crispr_primers->{left}->{'left_' . $int}->{seq});
        my $end_coord = index ($region, revcom($crispr_primers->{right}->{'right_' . $int}->{seq})->seq);
        my $primer_diff = abs (($end_coord - 1022) - (1000 - $start_coord));

        my $primer_range = {
            name    => '_' . $int,
            start   => $left_location_details->{_end},
            end     => $right_location_details->{_start},
            lseq    => $crispr_primers->{left}->{'left_' . $int}->{seq},
            rseq    => $crispr_primers->{right}->{'right_' . $int}->{seq},
            range   => $range,
            diff    => $primer_diff,
        };

        push @test, $primer_range;
        if ($range < $max) {
            my $amplicon_score = ($target - $range) + $primer_diff;
            if ($amplicon_score < $closest->{record}) {
                $closest = {
                    record  => $amplicon_score,
                    primer  => $int,
                };
            }
        }
    }

    return $crispr_primers->{left}->{'left_' . $closest->{primer}}, $crispr_primers->{right}->{'right_' . $closest->{primer}};
}

sub package_parameters {
    my ($c, $design_params, $result_data, $offset) = @_;

    my $date = strftime "%d-%m-%Y", localtime;
    my $version = $c->model('Golgi')->software_version . '_' . $date;
    
    my $miseq_pcr_conf = LoadFile($ENV{ 'LIMS2_PRIMER3_PCR_CRISPR_PRIMER_CONFIG' });
    my $miseq_internal_conf = LoadFile($ENV{ 'LIMS2_PRIMER3_CRISPR_SEQUENCING_PRIMER_CONFIG' });

    my $design_parameters = {
        design_method       => $design_params->{design_type},
        'command-name'      => $design_params->{design_type} . '-design-location',
        assembly            => $crispr_details->{locus}->{assembly},
        created_by          => $c->user->name,

        three_prime_exon    => 'null',
        five_prime_exon     => 'null',
        oligo_three_prime_align => '0',
        exon_check_flank_length =>  '0',
        primer_lowercase_masking    => $miseq_pcr_conf->{primer_lowercase_masking},
        num_genomic_hits            => $result_data->{genomic},

        region_length_3F    => '20',
        region_length_3R    => '20',
        region_length_5F    => '20',
        region_length_5R    => '20',

        region_offset_3F    => $offset->{internal},
        region_offset_3R    => $offset->{internal},
        region_offset_5F    => $offset->{external},
        region_offset_5R    => $offset->{external},

        primer_min_size     => $miseq_pcr_conf->{primer_min_size},
        primer_opt_size     => $miseq_pcr_conf->{primer_opt_size},
        primer_max_size     => $miseq_pcr_conf->{primer_max_size},

        primer_min_gc       => $miseq_pcr_conf->{primer_min_gc},
        primer_opt_gc_content   => $miseq_pcr_conf->{primer_opt_gc_percent},
        primer_max_gc       => $miseq_pcr_conf->{primer_max_gc},
           
        primer_min_tm       => $miseq_pcr_conf->{primer_min_tm},
        primer_opt_tm       => $miseq_pcr_conf->{primer_opt_tm},
        primer_max_tm       => $miseq_pcr_conf->{primer_max_tm},

        repeat_mask_class   => [],
            
        software_version    => $version,
    };

    my $json_params = encode_json $design_parameters;

    return $json_params;
}

sub format_oligos {
    my $primers = shift;

    my @oligos;
    my $rev_oligo = {
        1   => {
            inf => 1,
            inr => -1,
            exf => 1,
            exr => -1,
        },
        -1  => {
            inf => -1,
            inr => 1,
            exf => -1,
            exr => 1,
        }
    };
    foreach my $primer (keys %$primers) {
        my $primer_data = $primers->{$primer};
        my $seq = $primer_data->{seq};
        if ($rev_oligo->{ $primer_data->{loci}->{chr_strand} }->{$primer} == -1) {
            $seq = revcom($seq)->seq;
        }
        my $oligo = {
            loci    => [ $primer_data->{loci} ],
            seq     => uc $seq,
            type    => uc $primer,
        };
        push(@oligos, $oligo);
    }

    return \@oligos;
}

sub loci_builder {
    my ($oligo_hits, $oligo, $data, $strand) = @_;

    my $oligo_bwa = $oligo_hits->{$oligo};
    my $oligo_len = length($data->{$oligo}->{seq});
    my $oligo_end = $oligo_bwa->{start} + $oligo_len;
    my $chr = $oligo_bwa->{chr};
    $chr =~ s/chr//;
    my $loci = {
        assembly    => 'GRCh38',
        chr_start   => $oligo_bwa->{start},
        chr_name    => $chr,
        chr_end     => $oligo_end,
        chr_strand  => $strand,
    };
    $data->{$oligo}->{loci} = $loci;

    return $data;
}

sub generate_bwa_query_file {
    my ($crispr, $data) = @_;

    my $root_dir = $ENV{ 'LIMS2_BWA_OLIGO_DIR' } // '/var/tmp/bwa';
    use Data::UUID;
    my $ug = Data::UUID->new();

    my $unique_string = $ug->create_str();
    my $dir_out = dir( $root_dir, '_' . $crispr . '_' .  $unique_string );
    mkdir $dir_out->stringify  or die 'Could not create directory ' . $dir_out->stringify . ": $!";

    my $fasta_file_name = $dir_out->file(  $crispr . '_oligos.fasta');
    my $fh = $fasta_file_name->openw();
    my $seq_out = Bio::SeqIO->new( -fh => $fh, -format => 'fasta' );

    foreach my $oligo ( sort keys %$data ) {
        my $fasta_seq = Bio::Seq->new( -seq => $data->{$oligo}->{'seq'}, -id => $oligo );
        $seq_out->write_seq( $fasta_seq );
    }

    return ($fasta_file_name, $dir_out);
}

sub bwa_oligo_loci { 
    my ($crispr_details, $result_data) = @_;

    my $hit_data;
    my ($fasta, $dir) = generate_bwa_query_file($crispr_details->{wge_crispr_id}, $result_data->{oligos});
    my $bwa = DesignCreate::Util::BWA->new(
            query_file        => $fasta,
            work_dir          => $dir,
            species           => 'Human',
            three_prime_check => 0,
            num_bwa_threads   => 2,
    );

    $bwa->generate_sam_file;
    my $oligo_hits = $bwa->oligo_hits;
    my $strand = 1;
    if ($oligo_hits->{exf}->{start} > $oligo_hits->{exr}->{start}) {
        $strand = -1;
    }
    foreach my $oligo (keys %$oligo_hits) {
        $hit_data = loci_builder($oligo_hits, $oligo, $result_data->{oligos}, $strand);
    }

    my $oligos = format_oligos($hit_data);

    return $design;
}

sub genes_for_crisprs {
    my ($c, $crispr_rs) = @_;

    my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); };

    my @gene_ids;
    my @hgnc_ids = uniq @{ gene_ids_for_crispr( $gene_finder, $crispr_rs, $c->model('Golgi') ) };

    foreach my $hgnc_id (@hgnc_ids) {
        my $gene_spec = {
            gene_id => $hgnc_id,
            gene_type_id => 'HGNC',
        };
        push @gene_ids, $gene_spec;
    }

    return \@gene_ids;
}

__PACKAGE__->meta->make_immutable;

1;

__END__