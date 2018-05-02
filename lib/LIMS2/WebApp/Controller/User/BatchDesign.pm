package LIMS2::WebApp::Controller::User::BatchDesign;
use Moose;
use namespace::autoclean;
use Bio::Perl qw/revcom/;
use Carp;
use Data::UUID;
use DesignCreate::Util::BWA;
use JSON;
use List::MoreUtils qw/uniq/;
use Path::Class;
use Readonly;
BEGIN { extends 'Catalyst::Controller' }

Readonly::Scalar my $MAX_INTERNAL_DISTANCE => 300;
Readonly::Scalar my $MAX_EXTERNAL_DISTANCE => 1000;
Readonly::Array my @NUMERIC_COLUMNS        => qw/WGE_ID/;
Readonly::Array my @GENE_COLUMNS           => qw/CRISPR_ID/;
Readonly::Array my @NUCLEOTIDE_COLUMNS     => (
    'CRISPR Sequence',
    'PCR forward',
    'PCR reverse',
    'MiSEQ forward',
    'MiSEQ reverse',
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
    my ( $row, $rule, $columns, $line ) = @_;
    foreach my $column ( @{$columns} ) {
        my $value = $row->{$column};
        if ( not $value =~ $rule ) {
            my $line_text = defined $line ? "on line $line " : q//;
            return
              "'$value' is not a valid value for $column $line_text($rule)";
        }
    }
    return;
}

sub _validate_sequences {
    my $primers = shift;
    foreach my $oligo ( keys %{$primers} ) {
        my $seq = $primers->{$oligo}->{seq};
        if ( not $seq =~ m/^[ACTG]+$/xms ) {
            return "'$seq' is not a valid $oligo primer";
        }
    }
    return;
}

sub _genomic_distance {
    my ( $forward, $reverse ) = @_;
    my $strand = $forward->{loci}->{chr_strand};
    if ( $strand > 0 ) {
        return $reverse->{chr_start} - $forward->{chr_end};
    }
    return $forward->{chr_start} - $reverse->{chr_end};
}

sub _validate_primers {
    my $primers = shift;
    my $chromosomes = uniq map { $_->{loci}->{chr_name} } values %{$primers};
    if ( $chromosomes != 1 ) {
        return 'Oligos have inconsistent chromosomes';
    }
    my $strands = uniq map { $_->{loci}->{chr_strand} } values %{$primers};
    if ( $strands != 1 ) {
        return 'Oligos have inconsistent strands';
    }
    my $distance = _genomic_distance( @{$primers}{qw/inf inr/} );
    if ( $distance > $MAX_INTERNAL_DISTANCE or $distance < 0 ) {
        return "Internal oligos are ${distance}bp apart";
    }
    $distance = _genomic_distance( @{$primers}{qw/exf exr/} );
    if ( $distance > $MAX_EXTERNAL_DISTANCE or $distance < 0 ) {
        return "Internal oligos are ${distance}bp apart";
    }
    return;
}

sub _get_genes {
    my ( $data, $model ) = @_;
    my $search = {
        species     => $data->{species},
        search_term => $data->{symbol},
    };
    my $gene = $model->find_gene($search);
    $data->{gene}     = $gene;
    $data->{gene_ids} = [
        {
            gene_id      => $gene->{gene_id},
            gene_type_id => 'HGNC'
        }
    ];
    return;
}

sub _read_line {
    my $row = shift;
    my ($symbol) = split /_/xms, $row->{CRISPR_ID};
    return {
        wge_id     => $row->{WGE_ID},
        symbol     => $symbol,
        crispr_seq => $row->{'CRISPR Sequence'},
        exf        => $row->{'PCR forward'},
        exr        => $row->{'PCR reverse'},
        inf        => $row->{'MiSEQ forward'},
        inr        => $row->{'MiSEQ reverse'},
    };
}

sub _read_file {
    my ( $c, $fh ) = @_;
    my $csv     = Text::CSV->new;
    my $headers = $csv->getline($fh);
    $csv->column_names( @{$headers} );
    if ( my $error = _validate_columns($headers) ) {
        $c->stash->{error_msg} = $error;
        return;
    }
    my $rownum = 2;
    my @data   = ();
    while ( my $row = $csv->getline_hr($fh) ) {
        if (
            my $error =
            _validate_values( $row, qr/^\d+$ /xms, \@NUMERIC_COLUMNS, $rownum )
            // _validate_values( $row, qr/^\w+/xms, \@GENE_COLUMNS, $rownum )
            // _validate_values(
                $row, qr/^[ACTG]+$ /xms,
                \@NUCLEOTIDE_COLUMNS, $rownum
            )
          )
        {
            $c->stash->{error_msg} = $error;
            return;
        }
        my $line = _read_line($row);
        push @data, $line;
        $rownum++;
    }
    return \@data;
}

sub _extract_data {
    my ( $c, $datafile ) = @_;

    open my $fh, '<:encoding(utf8)', $datafile->tempname or croak;
    my $data = _read_file( $c, $fh );
    close $fh or croak;
    return $data;
}

sub generate_bwa_query_file {
    my $data = shift;

    my $root_dir = $ENV{'LIMS2_BWA_OLIGO_DIR'} // '/var/tmp/bwa';
    my $ug = Data::UUID->new();

    my $unique_string = $ug->create_str();
    my $dir_out = dir( $root_dir, '_' . $unique_string );
    mkdir $dir_out->stringify
      or croak 'Could not create directory ' . $dir_out->stringify . ": $!";

    my $fasta_file_name = $dir_out->file( $data->{wge_id} . '_oligos.fasta' );
    my $fh              = $fasta_file_name->openw();
    my $seq_out         = Bio::SeqIO->new( -fh => $fh, -format => 'fasta' );

    foreach my $oligo ( sort keys %{ $data->{primers} } ) {
        my $fasta_seq = Bio::Seq->new(
            -seq => $data->{primers}->{$oligo}->{seq},
            -id  => $oligo
        );
        $seq_out->write_seq($fasta_seq);
    }
    return ( $fasta_file_name, $dir_out );
}

sub loci_builder {
    my ( $data, $oligo_hits, $oligo, $strand ) = @_;

    my $oligo_bwa = $oligo_hits->{$oligo};
    my $oligo_len = length( $data->{primers}->{$oligo}->{seq} );
    my $oligo_end = $oligo_bwa->{start} + $oligo_len;
    my $chr       = $oligo_bwa->{chr};
    $chr =~ s/chr//xms;
    my $loci = {
        assembly   => $data->{assembly},
        chr_start  => $oligo_bwa->{start},
        chr_name   => $chr,
        chr_end    => $oligo_end,
        chr_strand => $strand,
    };
    $data->{primers}->{$oligo}->{loci} = $loci;

    return $data;
}

sub _build_data {
    my ( $data, $model ) = @_;
    my $crispr_hash =
      $model->schema->resultset('Crispr')
      ->find( { wge_crispr_id => $data->{wge_id} } );

    $data->{assembly} =
      $model->schema->resultset('SpeciesDefaultAssembly')
      ->find( { species_id => $data->{species} } )->assembly_id;

    # if the CRISPRs haven't been imported from WGE yet, do that
    if ( not $crispr_hash ) {
        my @wge_crispr_arr = [ $data->{wge_id} ];
        my @crispr_arr =
          $model->import_wge_crisprs( \@wge_crispr_arr,
            $data->{species}, $data->{assembly} );
        $crispr_hash = $crispr_arr[0]->{db_crispr};
    }
    $crispr_hash         = $crispr_hash->as_hash;
    $data->{lims_crispr} = $crispr_hash->{id};
    $data->{loci}        = {
        assembly   => $data->{assembly},
        chr_start  => $crispr_hash->{locus}->{chr_start},
        chr_end    => $crispr_hash->{locus}->{chr_end},
        chr_name   => $crispr_hash->{locus}->{chr_name},
        chr_strand => $crispr_hash->{locus}->{chr_strand},
    };
    my ( $fasta, $dir ) = generate_bwa_query_file($data);
    my $bwa = DesignCreate::Util::BWA->new(
        query_file        => $fasta,
        work_dir          => $dir,
        species           => $data->{species},
        three_prime_check => 0,
        num_bwa_threads   => 2,
    );

    $bwa->generate_sam_file;
    my $oligo_hits = $bwa->oligo_hits;
    my $strand     = 1;
    if ( $oligo_hits->{exf}->{start} > $oligo_hits->{exr}->{start} ) {
        $strand = -1;
    }
    foreach my $oligo ( keys %{$oligo_hits} ) {
        loci_builder( $data, $oligo_hits, $oligo, $strand );
    }
    return;
}

sub _create_oligos {
    my $data    = shift;
    my $primers = $data->{primers};
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
        push @oligos, $oligo;
    }

    $data->{oligos} = \@oligos;
    return;
}

sub _create_parameters {
    my ( $data, $model ) = @_;
    my $json       = JSON->new->allow_nonref;
    my $parameters = {
        design_method  => 'miseq',
        'command-name' => 'miseq-design-location',
        species        => $data->{species},
        assembly       => $data->{assembly},
        created_by     => $data->{user},
        chr_name       => $data->{gene}->{chromosome},
        chr_strand     => $data->{loci}->{chr_strand},
        target_start   => $data->{loci}->{chr_start},
        target_end     => $data->{loci}->{chr_end},
        target_genes   => [ $data->{gene}->{gene_id} ],

        three_prime_exon         => 'null',
        five_prime_exon          => 'null',
        oligo_three_prime_align  => '0',
        exon_check_flank_length  => '0',
        primer_lowercase_masking => 'null',
        num_genomic_hits         => '1',

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
        software_version  => $model->software_version,
    };
    $data->{design_parameters} = $json->encode($parameters);
    return;
}

sub _clean_data {
    my $data = shift;
    delete $data->{primers};
    delete $data->{gene};
    delete $data->{lims_crispr};
    delete $data->{crispr_seq};
    delete $data->{loci};
    delete $data->{wge_id};
    delete $data->{crispr_id};
    delete $data->{assembly};
    delete $data->{symbol};
    return;
}

sub _create_design {
    my ( $data, $model ) = @_;
    my $design = $model->txn_do(
        sub {
            shift->c_create_design($data);
        }
    );
    return $design->{_column_data};
}

sub _run {
    my ( $data, $model ) = @_;
    if ( my $error =
        _validate_values( $data, qr/^\d+$ /xms, [qw/wge_id/] )
        // _validate_values( $data, qr/^\w+/xms, [qw/symbol/] )
        // _validate_sequences( $data->{primers} ) )
    {
        return { error => $error };
    }
    _get_genes( $data, $model );
    _build_data( $data, $model );
    if ( my $error = _validate_primers( $data->{primers} ) ) {
        return { error => $error };
    }
    _create_parameters( $data, $model );
    _create_oligos( $data, $model );
    _clean_data($data);
    return _create_design( $data, $model );
}

sub miseq_create : Path('/user/batchdesign/miseq_create' ) : Args(0) {
    my ( $self, $c ) = @_;
    my $data = {
        wge_id     => $c->request->param('wge_id'),
        symbol     => $c->request->param('symbol'),
        crispr_seq => $c->request->param('crispr_seq'),
        primers    => {
            exf => { seq => $c->request->param('exf') },
            exr => { seq => $c->request->param('exr') },
            inf => { seq => $c->request->param('inf') },
            inr => { seq => $c->request->param('inr') },
        },
        type       => 'miseq',
        species    => $c->session->{selected_species},
        created_by => $c->user->name
    };
    $c->stash->{json_data} = _run( $data, $c->model('Golgi') );
    $c->forward('View::JSON');
    return;
}

sub miseq_submit : Path('/user/batchdesign/miseq_submit' ) : Args(0) {
    my ( $self, $c ) = @_;
    my $datafile = $c->request->upload('datafile');

    if ( not defined $datafile ) {
        $c->stash->{error_msg} =
          'You must upload a CSV containing design information';
        return;
    }
    my $designs = _extract_data( $c, $datafile );
    $c->stash->{designs} = $designs;
    return;
}

__PACKAGE__->meta->make_immutable;

1;
