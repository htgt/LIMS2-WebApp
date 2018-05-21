package LIMS2::WebApp::Controller::User::BatchDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::BatchDesign::VERSION = '0.501';
}
## use critic

use Moose;
use namespace::autoclean;
use Bio::Perl qw/revcom/;
use Carp;
use JSON;
use LIMS2::Model::Util::PrimerFinder qw/locate_primers/;
use List::MoreUtils qw/uniq/;
use Readonly;
use Text::CSV;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

Readonly::Scalar my $MAX_INTERNAL_DISTANCE => 1000;
Readonly::Scalar my $MAX_EXTERNAL_DISTANCE => 3000;
Readonly::Hash my %RULES                   => (
    NUMERIC  => qr/^\d+$ /xms,
    GENE     => qr/^\w+ /xms,
    SEQUENCE => qr/^[ACTG]+$ /xms,
);
Readonly::Hash my %COLUMNS => (
    NUMERIC  => [qw/WGE_ID/],
    GENE     => [qw/CRISPR_ID/],
    SEQUENCE => [
        'CRISPR Sequence',
        'PCR forward',
        'PCR reverse',
        'MiSEQ forward',
        'MiSEQ reverse',
    ],
);
Readonly::Array my @REQUIRED_COLUMNS => @{ $COLUMNS{NUMERIC} },
  @{ $COLUMNS{GENE} }, @{ $COLUMNS{SEQUENCE} };

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
        return 'Missing required columns: ' . join ', ', @missing;
    }
    return;
}

sub _validate_values {
    my ( $row, $rule, $columns, $line ) = @_;
    foreach my $column ( @{$columns} ) {
        my $value = $row->{$column};
        if ( not $value =~ $RULES{$rule} ) {
            my $line_text = defined $line ? " on line $line" : q//;
            return "'$value' is not a valid value for $column$line_text";
        }
    }
    return;
}

sub _validate_sequences {
    my $primers = shift;
    foreach my $oligo ( keys %{$primers} ) {
        my $seq = $primers->{$oligo}->{seq};
        if ( not $seq =~ $RULES{SEQUENCE} ) {
            return "'$seq' is not a valid $oligo primer";
        }
    }
    return;
}

sub _genomic_distance {
    my ( $forward, $reverse ) = @_;
    my $strand = $forward->{loci}->{chr_strand};
    if ( $strand > 0 ) {
        return $reverse->{loci}->{chr_start} - $forward->{loci}->{chr_end};
    }
    return $forward->{loci}->{chr_start} - $reverse->{loci}->{chr_end};
}

sub _validate_primers {
    my $primers_ref = shift;
    my %primers     = %{$primers_ref};
    my $chromosomes = uniq map { $_->{loci}->{chr_name} } values %primers;
    if ( $chromosomes != 1 ) {
        return 'Oligos have inconsistent chromosomes';
    }
    my $strands = uniq map { $_->{loci}->{chr_strand} } values %primers;
    if ( $strands != 1 ) {
        return 'Oligos have inconsistent strands';
    }
    my $distance = _genomic_distance( @primers{qw/inf inr/} );
    if ( $distance > $MAX_INTERNAL_DISTANCE or $distance < 0 ) {
        return "Internal oligos are ${distance}bp apart";
    }
    $distance = _genomic_distance( @primers{qw/exf exr/} );
    if ( $distance > $MAX_EXTERNAL_DISTANCE or $distance < 0 ) {
        return "External oligos are ${distance}bp apart";
    }
    return;
}

sub _read_line {
    my $row = shift;
    my ($symbol) = $row->{CRISPR_ID} =~ m/^(\w+)/xms;
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
        if ( my $error =
            _validate_values( $row, 'NUMERIC', $COLUMNS{NUMERIC}, $rownum )
            // _validate_values( $row, 'GENE',     $COLUMNS{GENE},     $rownum )
            // _validate_values( $row, 'SEQUENCE', $COLUMNS{SEQUENCE}, $rownum )
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

sub _import_crispr {
    my ( $model, $wge_id, $species, $assembly ) = @_;
    my $crispr_hash =
      $model->schema->resultset('Crispr')->find( { wge_crispr_id => $wge_id } );

    # if the CRISPRs haven't been imported from WGE yet, do that
    if ( not $crispr_hash ) {
        my ($crispr) =
          $model->import_wge_crisprs( [$wge_id], $species, $assembly );
        $crispr_hash = $crispr->{db_crispr};
    }
    $crispr_hash = $crispr_hash->as_hash;
    return {
        wge_id => $wge_id,
        id     => $crispr_hash->{id},
        locus  => $crispr_hash->{locus}
    };
}

sub _create_oligos {
    my $primers = shift;
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
    return \@oligos;
}

sub _create_parameters {
    my %args = @_;
    my $json       = JSON->new->allow_nonref;
    my $parameters = {
        design_method  => 'miseq',
        'command-name' => 'miseq-design-location',
        species        => 'Human',
        assembly       => 'GRCh38',
        created_by     => 'system',
        target_genes   => [],

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
        %args,
    };
    return $json->encode($parameters);
}

sub _choose_strand {
    my ( $forward, $reverse ) = @_;
    return ( $forward->{loci}->{chr_start} > $reverse->{loci}->{chr_start} )
      ? -1
      : 1;
}

sub _set_locus_props {
    my ( $loci, %props ) = @_;
    foreach my $oligo ( keys %{$loci} ) {
        while ( my ( $k, $v ) = each %props ) {
            $loci->{$oligo}->{loci}->{$k} = $v;
        }
    }
    return $loci;
}

sub _build_design {
    my ( $request, $model ) = @_;
    if ( my $error =
        _validate_values( $request, 'NUMERIC', [qw/wge_id/] )
        // _validate_values( $request, 'GENE', [qw/symbol/] )
        // _validate_sequences( $request->{primers} ) )
    {
        return { error => $error };
    }
    my $response = {};
    my $data     = {
        species    => $request->{species},
        created_by => $request->{user},
        type       => 'miseq',
    };
    try {
        my $gene = $model->find_gene(
            {
                species     => $request->{species},
                search_term => $request->{symbol}
            }
        );
        $data->{gene_ids} = [
            {
                gene_id      => $gene->{gene_id},
                gene_type_id => 'HGNC'
            }
        ];
        my $assembly =
          $model->schema->resultset('SpeciesDefaultAssembly')
          ->find( { species_id => $request->{species} } )->assembly_id;
        my $crispr =
          _import_crispr( $model, $request->{wge_id}, $request->{species},
            $assembly );
        $response->{crispr} = $crispr->{id};
        my $primers = $request->{primers};
        locate_primers( $request->{species}, $crispr, $primers );
        my $strand = _choose_strand( @{$primers}{qw/exf exr/} );
        _set_locus_props(
            $primers,
            assembly   => $assembly,
            chr_strand => $strand
        );
        $data->{design_parameters} = _create_parameters(
            target_genes     => [ $gene->{gene_id} ],
            species          => $request->{species},
            assembly         => $assembly,
            created_by       => $request->{user},
            software_version => $model->software_version,
            chr_name         => $crispr->{locus}->{chr_name},
            chr_strand       => $crispr->{locus}->{chr_strand},
            target_start     => $crispr->{locus}->{chr_start},
            target_end       => $crispr->{locus}->{chr_end},
        );

        if ( my $error = _validate_primers($primers) ) {
            $response->{error} = $error;
        }
        else {
            $response->{locations} = {
                crispr => format_location( $crispr->{locus} ),
                exf    => format_location( $primers->{exf}->{loci} ),
                exr    => format_location( $primers->{exr}->{loci} ),
                inf    => format_location( $primers->{inf}->{loci} ),
                inr    => format_location( $primers->{inr}->{loci} ),
            };
            $data->{oligos} = _create_oligos($primers);
            my $design = $model->txn_do(
                sub {
                    $model->c_create_design($data);
                }
            );
            $response->{design} = $design->{_column_data};
        }
    }
    catch {
        $response->{error} = $_;
    };
    return $response;
}

sub format_location {
    my $loci = shift;
    my ( $chr, $start, $end ) =
      ( $loci->{chr_name}, $loci->{chr_start}, $loci->{chr_end} );
    return "$chr:$start-$end";
}

sub miseq_example : Path( '/user/batchdesign/miseq_example' ) : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->status( 200 );
    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => 'attachment; filename=example.csv' );
    my $csv = Text::CSV->new( { binary => 1, sep_char => q/,/, eol => "\n" } );
    my $output;
    open my $fh, '>', \$output or croak 'Could not create example file';
    $csv->print( $fh, \@REQUIRED_COLUMNS );
    $csv->print( $fh, [qw/1174490822 ADNP_2 AGGATCGGTTCCCTTGCTTC TTTAACTGGCCCGATGAGAG ATGCCCGAGAAGAGAGTAGT CCTGGCCTACAGATTTGACT CCCTTGATGCTAATTGCTCC/] );
    $csv->print( $fh, [qw/904034556 AHDC1_3 TGCCCCACACCGGTCGGAGA AGGCTCGTAGAGGGGATG GTGCAGCTCTCCTGACTAC GATGTCAATCAGCTGCACCA TTGCCAAGGGGGACGAC/] );
    close $fh or croak 'Could not close example file';
    $c->response->body( $output );
    return;
}

sub miseq_create : Path('/user/batchdesign/miseq_create' ) : Args(0) {
    my ( $self, $c ) = @_;
    my $request = {
        context    => $c,
        wge_id     => $c->request->param('wge_id'),
        symbol     => $c->request->param('symbol'),
        crispr_seq => $c->request->param('crispr_seq'),
        primers    => {
            exf => { seq => $c->request->param('exf') },
            exr => { seq => $c->request->param('exr') },
            inf => { seq => $c->request->param('inf') },
            inr => { seq => $c->request->param('inr') },
        },
        species => $c->session->{selected_species},
        user    => $c->user->name
    };
    my $model = $c->model('Golgi');
    $c->stash->{json_data} = _build_design( $request, $model );
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
