package LIMS2::Model::Util::CreateMiseqDesign;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ 'generate_miseq_design', 'design_preset_params', 'default_nulls' ]
};

use Path::Class;
use Log::Log4perl qw( :easy );
use LIMS2::Exception;
use List::MoreUtils qw( uniq );
use POSIX qw(strftime);
use JSON;
use Bio::Perl qw( revcom );
use YAML::XS qw( LoadFile );
use Try::Tiny;

use LIMS2::Model::Util::OligoSelection qw(
        pick_miseq_internal_crispr_primers
        pick_miseq_crispr_PCR_primers
);
use LIMS2::Model::Util::Crisprs qw( gene_ids_for_crispr );
use LIMS2::Model::Util::PrimerFinder qw( locate_primers );

sub generate_miseq_design {
    my ($c, $design_params, $crispr_id, $requirements) = @_;

    my $search_range = {
        search      => {
            internal    => $design_params->{miseq}->{search_width} || 170,
            external    => $design_params->{pcr}->{search_width} || 350,
        },
        dead        => {
            internal    => $design_params->{miseq}->{offset_width} || 50,
            external    => $design_params->{pcr}->{offset_width} || 170,
        },
        internal    => $design_params->{miseq}->{increment} || 15,
        external    => $design_params->{pcr}->{increment} || 50,
        melting     => $design_params->{mt},
        gc_content  => $design_params->{gc},
    };

    my ($crispr_data, $internal_crispr_primers, $pcr_crispr_primers) = generate_primers($c, $crispr_id, $search_range, $design_params->{genomic_threshold});

    my $crispr_rs = $c->model('Golgi')->schema->resultset('Crispr')->find({ id => $crispr_id });
    my @gene_ids = genes_for_crisprs($c, $crispr_rs);
    if ($crispr_data->{error}) {
        print $crispr_data->{error};
        return $crispr_data;
    }
    my $crispr_details = $crispr_rs->as_hash;

    my $slice_adaptor = $c->model('Golgi')->ensembl_slice_adaptor('Human');
    my $slice_region = $slice_adaptor->fetch_by_region(
        'chromosome',
        $crispr_data->{'left_crispr'}->{'chr_name'},
        $crispr_data->{'left_crispr'}->{'chr_start'} - 1000,
        $crispr_data->{'left_crispr'}->{'chr_end'} + 1000,
        1,
    );
    my $crispr_loc = index ($slice_region->seq, $crispr_data->{left_crispr}->{seq});

    my ($inf, $inr) = find_appropriate_primers($internal_crispr_primers, 260, 297, $slice_region->seq, $crispr_loc, 'Miseq');
    my ($exf, $exr) = find_appropriate_primers($pcr_crispr_primers, 750, 3000, $slice_region->seq, $crispr_loc, 'PCR');
    if ($inf->{error} || $exf->{error}) {
        my $error = $exf->{error} || $inf->{error};
        return { error => $error };
    }
    my $result = {
        crispr  => $crispr_data->{left_crispr}->{id},
        genomic => $pcr_crispr_primers->{pair_count},
        oligos  => {
            inf => $inf,
            inr => $inr,
            exf => $exf,
            exr => $exr,
        },
    };
    my $hit_data = locate_primers($requirements->{species}, $crispr_details, $result->{oligos}, $design_params->{genomic_threshold});
    my @oligos = format_oligos($hit_data);
    $crispr_details->{primer_loci} = $hit_data;
    my $json_params = package_parameters($c, $design_params, $result, $search_range->{dead}, $crispr_details, $requirements->{name});
    my $design_info = {
        design_parameters   => $json_params,
        created_by          => $requirements->{name},
        species             => $requirements->{species},
        type                => $design_params->{design_type},
        gene_ids            => @gene_ids,
        oligos              => @oligos,
    };

    my $design = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->c_create_design( $design_info );
        }
    );

    my $design_crispr = {
        design => $design,
        crispr => $crispr_id,
    };
    return $design_crispr;
};


sub generate_primers {
    my ($c, $crispr_id, $search_range, $genomic_threshold) = @_;

    my $time = strftime "%S-%M-%H_%d-%m-%Y", localtime;
    my $params = {
        crispr_id           => $crispr_id,
        species             => 'Human',
        repeat_mask         => [''],
        offset              => 20,
        well_id             => 'Miseq_Crispr_' . $crispr_id . '_' . $time,
        genomic_threshold   => $genomic_threshold || 30,
        gc                  => $search_range->{gc_content},
        tm                  => $search_range->{melting},
    };

    local $ENV{'LIMS2_SEQ_SEARCH_FIELD'} = $search_range->{search}->{internal};
    local $ENV{'LIMS2_SEQ_DEAD_FIELD'} = $search_range->{dead}->{internal};
    local $ENV{'LIMS2_PCR_SEARCH_FIELD'} = $search_range->{search}->{external};
    local $ENV{'LIMS2_PCR_DEAD_FIELD'} = $search_range->{dead}->{external};

    $params->{increment} = $search_range->{internal};

    my ($internal_crispr, $internal_crispr_primers) = pick_miseq_internal_crispr_primers($c->model('Golgi'), $params);
    if ($internal_crispr_primers->{error_flag} eq 'fail') {
        $params->{error} = sprintf("Primer generation failed: No adequate Miseq primers found; Search width: %s, Offset width: %s\n",
            $ENV{'LIMS2_SEQ_SEARCH_FIELD'}, $ENV{'LIMS2_SEQ_DEAD_FIELD'});
        return $params;
    }

    $params->{increment} = $search_range->{external};

    my $crispr_seq = {
        chr_region_start    => $internal_crispr->{left_crispr}->{chr_start},
        left_crispr         => { chr_name   => $internal_crispr->{left_crispr}->{chr_name} },
    };
    my $en_strand = {
        1   => 'plus',
        -1  => 'minus',
    };

    $params->{crispr_primers} = {
        crispr_primers  => $internal_crispr_primers,
        crispr_seq      => $crispr_seq,
        strand          => $en_strand->{$internal_crispr->{left_crispr}->{chr_strand}},
    };

    my ($pcr_crispr, $pcr_crispr_primers) = pick_miseq_crispr_PCR_primers($c->model('Golgi'), $params);
    if ($pcr_crispr->{error_flag} eq 'fail') {
        $params->{error} = sprintf("Primer generation failed: No adequate PCR primers found; Search width: %s, Offset width: %s\n",
            $ENV{'LIMS2_PCR_SEARCH_FIELD'}, $ENV{'LIMS2_PCR_DEAD_FIELD'});
        return $params;
    } elsif ($pcr_crispr_primers->{genomic_error_flag} eq 'fail') {
        $params->{error} = sprintf("PCR genomic uniqueness check failed; PCR results - %s; Genomic Threshold: %s\n",
            $pcr_crispr_primers->{genomic_error_flag}, $params->{genomic_threshold});
        return $params;
    }

    return $internal_crispr, $internal_crispr_primers, $pcr_crispr_primers;
}

sub find_appropriate_primers {
    my ($crispr_primers, $target, $max, $region, $crispr, $primer_set) = @_;
    my @primers = keys %{$crispr_primers->{left}};
    @primers = reverse sort @primers;
    my $closest->{record} = 5000;
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
    unless ($closest->{primer}) {
        return { error => "No $primer_set primers found beneath the maximum length: $max" };
    }

    return $crispr_primers->{left}->{'left_' . $closest->{primer}}, $crispr_primers->{right}->{'right_' . $closest->{primer}};
}

sub package_parameters {
    my ($c, $design_params, $result_data, $offset, $crispr_details, $user_name) = @_;
    my $primer_loci = $crispr_details->{primer_loci};
    my $date = strftime "%d-%m-%Y", localtime;
    my $version = $c->model('Golgi')->software_version . '_' . $date;

    my $miseq_pcr_conf = LoadFile($ENV{ 'LIMS2_PRIMER3_MISEQ_PCR_CONFIG' });

    my $design_parameters = {
        design_method       => $design_params->{design_type},
        'command-name'      => $design_params->{design_type} . '-design-location',
        assembly            => $crispr_details->{locus}->{assembly},
        created_by          => $user_name,

        target_start        => $primer_loci->{inf}->{loci}->{chr_end},
        target_end          => $primer_loci->{inr}->{loci}->{chr_start},

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

        primer_min_gc       => $design_params->{gc}->{min} || $miseq_pcr_conf->{primer_min_gc},
        primer_opt_gc_content   => $design_params->{gc}->{opt} ||  $miseq_pcr_conf->{primer_opt_gc_percent},
        primer_max_gc       => $design_params->{gc}->{max} || $miseq_pcr_conf->{primer_max_gc},

        primer_min_tm       => $design_params->{melt}->{min} || $miseq_pcr_conf->{primer_min_tm},
        primer_opt_tm       => $design_params->{melt}->{opt} || $miseq_pcr_conf->{primer_opt_tm},
        primer_max_tm       => $design_params->{melt}->{max} || $miseq_pcr_conf->{primer_max_tm},

        repeat_mask_class   => [],

        software_version    => $version,
    };

    my $json_params = encode_json $design_parameters;

    return $json_params;
}

sub format_oligos {
    my $primers = shift;

    my $orientation = 1;
    if ($primers->{exf}->{loci}->{chr_start} > $primers->{exr}->{loci}->{chr_start}) {
        $orientation = -1;
    }

    my @oligos;
    foreach my $primer (keys %$primers) {
        my $primer_data = $primers->{$primer};

        $primer_data->{loci}->{chr_strand} = $orientation; #Loci strand is misleading, it's orientation of the design, not primer specific.
        $primer_data->{loci}->{assembly} = 'GRCh38';

        my $seq = $primer_data->{seq};
        if ($primer_data->{location}->{_strand} == -1) {
            $seq = revcom($seq)->seq; #Store on forward strand
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

sub primer_orientation_check {
    my ($hit_data, $strand) = @_;

    #Results can come back in the wrong orientation from Oligo Selection.
    #Check and correct
    my $corrections = {
        1   => {
            'exr' => 'exf',
            'inr' => 'inf',
        },
        -1  => {
            'exf' => 'exr',
            'inf' => 'inr',
        },
    };

    foreach my $right_side_primer (keys %{$corrections->{$strand}}) {
        my $left_data = $hit_data->{$corrections->{$strand}->{$right_side_primer}};
        my $right_data = $hit_data->{$right_side_primer};

        if ($left_data->{loci}->{chr_start} > $right_data->{loci}->{chr_start}) {
            $hit_data->{$corrections->{$strand}->{$right_side_primer}} = $right_data;
            $hit_data->{$right_side_primer} = $left_data;
        }
    }

    return $hit_data;
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

sub design_preset_params {
    my ($c, $name) = @_;

    my $preset = $c->model('Golgi')->schema->resultset('MiseqDesignPreset')->find({ name => $name })->as_hash;
    my $miseq = $preset->{primers}->{miseq}->{widths};
    my $pcr = $preset->{primers}->{pcr}->{widths};

    my $primer_params = {
        miseq => {
            search_width => $miseq->{search},
            offset_width => $miseq->{offset},
            increment    => $miseq->{increment},
        },
        pcr => {
            search_width => $pcr->{search},
            offset_width => $pcr->{offset},
            increment    => $pcr->{increment},
        },
        gc => $preset->{gc},
        mt => $preset->{mt},
        genomic_threshold => $preset->{genomic_threshold},
    };

    return $primer_params;
}

sub default_nulls {
    my ($c, $criteria, $search) = @_;

    my $default = $c->model('Golgi')->schema->resultset('MiseqDesignPreset')->find($search)->as_hash;

    $criteria = null_check($criteria, $default, keys %$criteria);

    return $criteria;
}

sub null_check {
    my ($data, $default, @keys) = @_;

    foreach my $key (@keys) {
        if (ref $data->{$key} eq ref {}) {
            $data->{$key} = null_check($data->{$key}, $default->{$key}, keys %{$data->{$key}});
        } else {
            unless ($data->{$key}) {
                $data->{$key} = $default->{$key};
            }
        }
    }

    return $data;
}

1;

__END__
