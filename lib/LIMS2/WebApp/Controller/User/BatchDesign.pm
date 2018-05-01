package LIMS2::WebApp::Controller::User::BatchDesign;
use Moose;
use namespace::autoclean;
use Bio::Perl qw/revcom/;
use Data::UUID;
use DesignCreate::Util::BWA;
use JSON;
use Path::Class;
use Readonly;
BEGIN { extends 'Catalyst::Controller' }

Readonly::Array my @NUMERIC_COLUMNS    => qw/Experiment WGE_ID/;
Readonly::Array my @GENE_COLUMNS       => qw/CRISPR_ID/;
Readonly::Array my @NUCLEOTIDE_COLUMNS => (
    'CRISPR Sequence',
    'PCR forward',
    'PCR reverse',
    'MiSEQ forward',
    'MiSEQ reverse'
);
Readonly::Array my @REQUIRED_COLUMNS => @NUMERIC_COLUMNS,
  @GENE_COLUMNS,
  @NUCLEOTIDE_COLUMNS;

sub _validate_columns {
    my $header_ref = shift;
    my %headers    = map { $_ => 1 } @{$header_ref};
    my @missing    = ();
    foreach my $column (@REQUIRED_COLUMNS) {
        if ( not exists $headers{$column} ) {
            push @missing, $column;
        }
    }
    if (@missing) {
        return 'Missing required columnns: ' . join ', ', @missing;
    }
    return;
}

sub _validate_values {
    my ( $line, $row, $rule, @columns ) = @_;
    foreach my $column (@columns) {
        my $value = $row->{$column};
        if ( not $value =~ $rule ) {
            return
              "'$value' is not a valid value for $column on line $line ($rule)";
        }
    }
    return;
}

sub _get_gene {
    my ( $cache, $crispr_id ) = @_;
    my ($symbol) = split /_/, $crispr_id;
    if ( not exists $cache->{$symbol} ) {
        my $search = {
            species     => $cache->{species},
            search_term => $symbol,
        };
        $cache->{$symbol} = $cache->{golgi}->find_gene($search);
    }
    return $cache->{$symbol};
}

sub _get_genes {
    my ( $cache, $data ) = @_;
    foreach my $exp (keys %{$data}){
        my $gene = _get_gene($cache, $data->{$exp}->{crispr_id});
        $data->{$exp}->{gene} = $gene;
        $data->{$exp}->{gene_ids} = [
            {
                gene_id      => $gene->{gene_id},
                gene_type_id => 'HGNC'
            }
        ];
    }
    return;
}

sub _read_line {
    my ($cache, $row) = @_;
    return {
        wge_id     => $row->{WGE_ID},
        crispr_id  => $row->{CRISPR_ID},
        crispr_seq => $row->{'CRISPR Sequence'},
        name       => $row->{Experiment},
        type       => 'miseq',
        species    => $cache->{species},
        created_by => $cache->{user},
        primers    => {
            exf => { seq => $row->{'PCR forward'} },
            exr => { seq => $row->{'PCR reverse'} },
            inf => { seq => $row->{'MiSEQ forward'} },
            inr => { seq => $row->{'MiSEQ reverse'} },
        },
    };
}

sub _read_file {
    my ($c, $cache, $fh) = @_; 
    my $csv  = Text::CSV->new;
    my $headers = $csv->getline($fh);
    $csv->column_names( @{$headers} );
    if ( my $error = _validate_columns($headers) ) {
        $c->stash->{error_msg} = $error;
        return;
    }
    my $line = 2;
    my %data = ();
    while ( my $row = $csv->getline_hr($fh) ) {
        if ( my $error =
            _validate_values( $line, $row, qr/^\d+$/, @NUMERIC_COLUMNS )
            // _validate_values( $line, $row, qr/^\w+/, @GENE_COLUMNS )
            // _validate_values( $line, $row, qr/^[ACTG]+$/,
                @NUCLEOTIDE_COLUMNS ) )
        {
            $c->stash->{error_msg} = $error;
            return;
        }
        my $contents = _read_line($cache, $row);
        $data{$contents->{name}} = $contents;
        $line++;
    }
    return \%data;
}

sub _extract_data {
    my ( $c, $cache, $datafile ) = @_;

    open my $fh, '<:encoding(utf8)', $datafile->tempname or die;
    my $data = _read_file($c, $cache, $fh);
    close $fh;
    return $data;
}

sub generate_bwa_query_file {
    my ( $exp, $crispr, $data ) = @_;

    my $root_dir = $ENV{'LIMS2_BWA_OLIGO_DIR'} // '/var/tmp/bwa';
    my $ug = Data::UUID->new();

    my $unique_string = $ug->create_str();
    my $dir_out = dir( $root_dir, '_' . $exp . '_' . $unique_string );
    mkdir $dir_out->stringify
      or die 'Could not create directory ' . $dir_out->stringify . ": $!";

    my $fasta_file_name =
      $dir_out->file( $exp . '_' . $crispr . '_oligos.fasta' );
    my $fh = $fasta_file_name->openw();
    my $seq_out = Bio::SeqIO->new( -fh => $fh, -format => 'fasta' );

    foreach my $oligo ( sort keys %{ $data->{$exp}->{primers} } ) {
        my $fasta_seq = Bio::Seq->new(
            -seq => $data->{$exp}->{primers}->{$oligo}->{'seq'},
            -id  => $oligo
        );
        $seq_out->write_seq($fasta_seq);
    }
    return ( $fasta_file_name, $dir_out );
}

sub loci_builder {
    my ( $oligo_hits, $exp, $oligo, $data, $strand, $cache ) = @_;

    my $oligo_bwa = $oligo_hits->{$oligo};
    my $oligo_len = length( $data->{$exp}->{primers}->{$oligo}->{seq} );
    my $oligo_end = $oligo_bwa->{start} + $oligo_len;
    my $chr       = $oligo_bwa->{chr};
    $chr =~ s/chr//;
    my $loci = {
        assembly   => $cache->{assembly},
        chr_start  => $oligo_bwa->{start},
        chr_name   => $chr,
        chr_end    => $oligo_end,
        chr_strand => $strand,
    };
    $data->{$exp}->{primers}->{$oligo}->{loci} = $loci;

    return $data;
}

sub _build_data {
    my ( $cache, $data ) = @_;
    foreach my $exp ( keys %{$data} ) {
        my $crispr_hash =
          $cache->{golgi}->schema->resultset('Crispr')
          ->find( { wge_crispr_id => $data->{$exp}->{wge_id} } );

        # if the CRISPRs haven't been imported from WGE yet, do that
        unless ($crispr_hash) {
            my @wge_crispr_arr = [ $data->{$exp}->{wge_id} ];
            my @crispr_arr =
              $cache->{golgi}
              ->import_wge_crisprs( \@wge_crispr_arr, $cache->{species},
                $cache->{assembly} );
            $crispr_hash = $crispr_arr[0]->{db_crispr};
        }
        $crispr_hash                 = $crispr_hash->as_hash;
        $data->{$exp}->{lims_crispr} = $crispr_hash->{id};
        $data->{$exp}->{loci}        = {
            assembly   => $cache->{assembly},
            chr_start  => $crispr_hash->{locus}->{chr_start},
            chr_end    => $crispr_hash->{locus}->{chr_end},
            chr_name   => $crispr_hash->{locus}->{chr_name},
            chr_strand => $crispr_hash->{locus}->{chr_strand},
        };
        my ( $fasta, $dir ) =
          generate_bwa_query_file( $exp, $data->{$exp}->{wge_id}, $data );
        my $bwa = DesignCreate::Util::BWA->new(
            query_file        => $fasta,
            work_dir          => $dir,
            species           => $cache->{species},
            three_prime_check => 0,
            num_bwa_threads   => 2,
        );

        $bwa->generate_sam_file;
        my $oligo_hits = $bwa->oligo_hits;
        my $strand     = 1;
        if ( $oligo_hits->{exf}->{start} > $oligo_hits->{exr}->{start} ) {
            $strand = -1;
        }
        foreach my $oligo ( keys %$oligo_hits ) {
            loci_builder( $oligo_hits, $exp, $oligo, $data, $strand, $cache );
        }
    }
    return;
}

sub _create_oligos {
    my $data = shift;
    foreach my $exp ( keys %{$data} ) {
        my $primers = $data->{$exp}->{primers};
        my @oligos;
        my $rev_oligo = {
            1 => {
                inf => 1,
                inr => -1,
                exf => 1,
                exr => -1,
            },
            -1 => {
                inf => -1,
                inr => 1,
                exf => -1,
                exr => 1,
            },
        };
        foreach my $primer ( keys %{$primers} ) {
            my $primer_data = $primers->{$primer};
            my $seq         = $primer_data->{seq};
            if (
                $rev_oligo->{ $primer_data->{loci}->{chr_strand} }->{$primer} ==
                -1 )
            {
                $seq = revcom($seq)->seq;
            }
            my $oligo = {
                loci => [ $primer_data->{loci} ],
                seq  => uc $seq,
                type => uc $primer,
            };
            push( @oligos, $oligo );
        }

        $data->{$exp}->{oligos} = \@oligos;
    }
    return;
}

sub _create_parameters {
    my ( $cache, $data ) = @_;
    my $json = JSON->new->allow_nonref;
    foreach my $exp ( keys %{$data} ) {
        my $parameters = {
            design_method  => 'miseq',
            'command-name' => 'miseq-design-location',
            species        => $cache->{species},
            assembly       => $cache->{assembly},
            created_by     => $cache->{user},
            chr_name       => $data->{$exp}->{gene}->{chromosome},
            chr_strand     => $data->{$exp}->{loci}->{chr_strand},
            target_start   => $data->{$exp}->{loci}->{chr_start},
            target_end     => $data->{$exp}->{loci}->{chr_end},
            target_genes   => [ $data->{$exp}->{gene}->{gene_id} ],

            three_prime_exon         => 'null',
            five_prime_exon          => 'null',
            oligo_three_prime_align  => '0',
            exon_check_flank_length  => '0',
            primer_lowercase_masking => 'null',
            num_genomic_hits         => "1",

            region_length_3F => '20',
            region_length_3R => '20',
            region_length_5F => '20',
            region_length_5R => '20',

            region_offset_3F => 80,
            region_offset_3R => 80,
            region_offset_5F => 300,
            region_offset_5R => 300,

            primer_min_size       => '18',
            primer_min_gc         => '40',
            primer_opt_gc_content => '50',
            primer_opt_size       => '20',
            primer_max_size       => '22',
            primer_max_gc         => '60',

            primer_min_tm => '57',
            primer_opt_tm => '60',
            primer_max_tm => '63',

            repeat_mask_class => [],

            'ensembl-version' => 'X',
            software_version  => $cache->{golgi}->software_version,
        };
        $data->{$exp}->{design_parameters} = $json->encode($parameters);
    }
    return;
}

sub _clean_data {
    my $data = shift;
    foreach my $exp ( keys %{$data} ) {
        delete $data->{$exp}->{primers};
        delete $data->{$exp}->{gene};
        delete $data->{$exp}->{lims_crispr};
        delete $data->{$exp}->{crispr_seq};
        delete $data->{$exp}->{loci};
        delete $data->{$exp}->{wge_id};
        delete $data->{$exp}->{crispr_id};
    }
    return;
}

sub _create_designs {
    my ( $cache, $data ) = @_;
    my @designs = ();
    foreach my $exp ( keys %{$data} ) {
        my $design = $cache->{golgi}->txn_do(
            sub {
                shift->c_create_design( $data->{$exp} );
            }
        );
        push @designs, $design->{_column_data};
    }
    return @designs;
}

sub miseq_create : Path('/user/batchdesign/miseq_create' ) : Args(0)
{
    my ( $self, $c ) = @_;
    my $datafile = $c->request->upload('datafile');

    my $cache = {
        user    => $c->user->name,
        golgi   => $c->model('Golgi'),
        species => $c->session->{selected_species},
    };

    $cache->{assembly} =
      $c->model('Golgi')->schema->resultset('SpeciesDefaultAssembly')
      ->find( { species_id => $cache->{species} } )->assembly_id;
    if (not defined $datafile){
        $c->stash->{error_msg} = 'You must upload a CSV containing design information';
        return;
    }
    my $data = _extract_data( $c, $cache, $datafile );
    _get_genes ( $cache, $data );
    _build_data( $cache, $data );
    _create_parameters( $cache, $data );
    _create_oligos($data);
    _clean_data($data);
    my @designs = _create_designs( $cache, $data );
    $c->stash->{designs}     = \@designs;
    $c->stash->{success_msg} = 'Successfully batch imported some miseq designs';
    return;
}

__PACKAGE__->meta->make_immutable;

1;
