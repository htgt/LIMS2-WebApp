package LIMS2::Model::Util::CrisprESQC;

=head1 NAME

LIMS2::Model::Util::CrisprESQC -

=head1 DESCRIPTION


=cut

use Moose;
use HTGT::QC::Util::CigarParser;
use HTGT::QC::Util::CrisprAlleleDamage;
use WebAppCommon::Util::EnsEMBL;
use LIMS2::Exception;
use Bio::SeqIO;
use Bio::Seq;
use JSON qw( encode_json );
use Try::Tiny;
use MooseX::Types::Path::Class::MoreCoercions qw/AbsDir/;
use File::Which;
use Data::UUID;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
);

has plate => (
    is       => 'ro',
    isa      => 'LIMS2::Model::Schema::Result::Plate',
    required => 1,
);

has well_name => (
    is  => 'ro',
    isa => 'Str',
);

has forward_primer_name => (
    is      => 'ro',
    isa     => 'Str',
    default => 'SF1',
);

has reverse_primer_name => (
    is      => 'ro',
    isa     => 'Str',
    default => 'SR1',
);

has sequencing_project_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has base_dir => (
    is       => 'ro',
    isa      => AbsDir,
    required => 1,
    coerce   => 1,
);

has uuid => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_uuid {
    return Data::UUID->new->create_str;
}

has user => (
    is      => 'ro',
    isa     => 'Str',
    default => 'system',
);

has commit => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has ensembl_util => (
    is         => 'ro',
    isa        => 'WebAppCommon::Util::EnsEMBL',
    lazy_build => 1,
);

sub _build_ensembl_util {
    my $self = shift;

    return WebAppCommon::Util::EnsEMBL->new( species => $self->species );
}

has cigar_parser => (
    is         => 'ro',
    isa        => 'HTGT::QC::Util::CigarParser',
    lazy_build => 1,
);

sub _build_cigar_parser {
    my $self = shift;
    return HTGT::QC::Util::CigarParser->new(
        primers => [ $self->forward_primer_name, $self->reverse_primer_name ] );
}

has primer_reads => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub{ {} },
    traits  => [ 'Hash' ],
    handles => {
        well_has_primer_reads => 'exists',
        get_well_primer_reads => 'get',
    }
);


=head2 analyse_plate

Start crispr es cell qc analysis.

=cut
sub analyse_plate {
    my ( $self ) = @_;
    $self->log->info( 'Running crispr es cell qc on plate: ' . $self->plate->name );

    $self->get_primer_reads();

    my @well_qc_data;
    for my $well ( $self->plate->wells->all ) {
        next if $self->well_name && $well->name ne $self->well_name;
        my $well_analysis_data = $self->analyse_well( $well );
        push @well_qc_data, $well_analysis_data if $well_analysis_data;
    }

    my $qc_run;
    $self->model->txn_do(
        sub{
            try{
                $qc_run = $self->model->create_crispr_es_qc_run(
                    {
                        id                 => $self->uuid,
                        created_by         => $self->user,
                        species            => $self->species,
                        sequencing_project => $self->sequencing_project_name,
                        wells              => \@well_qc_data,
                    }
                );
                $self->log->info('Persisted crispr es qc data');
                unless ( $self->commit ) {
                    $self->log->info('rollback');
                    $self->model->txn_rollback;
                }
            }
            catch {
                $self->log->error("Error persisting crispr es qc: $_" );
                $self->model->txn_rollback;
            };
        }
    );

    return $qc_run;
}

=head2 analyse_well

Analyse a well on the plate.

=cut
sub analyse_well {
    my ( $self, $well ) = @_;
    $self->log->info( "Analysing well $well" );

    my $crispr        = $self->crispr_for_well( $well );
    my $target_slice  = $crispr->target_slice;
    $target_slice     = $target_slice->expand( 200, 200 );
    my $design_strand = $well->design->info->chr_strand;;

    my ( $alignment_data, $well_reads );
    if ( $self->well_has_primer_reads( $well->name ) ) {
        $well_reads = $self->get_well_primer_reads( $well->name );
        $alignment_data = $self->align_well_reads( $well, $target_slice, $well_reads, $design_strand );
    }
    else {
        $self->log->warn("No primer reads for well " . $well->name );
        $alignment_data = { no_reads => 1 };
    }
    return unless $alignment_data;

    my $analysis_json
        = $self->parse_analysis_data( $alignment_data, $crispr, $target_slice, $design_strand );

    return $self->build_qc_data( $well, $analysis_json, $well_reads, $crispr );
}

=head2 align_well_reads

Gather the primer reads and align against the target region the crispr pair
will hit.
The alignment and analysis work is done by the HTGT::QC::Util::CrisprAlleleDamage
module.

=cut
sub align_well_reads {
    my ( $self, $well, $target_slice, $well_reads, $design_strand ) = @_;
    $self->log->debug( "Aligning reads for well: $well" );

    my $target_genomic_region = Bio::Seq->new(
        -display_id => 'target_region_' . $well->name,
        -alphabet   => 'dna',
        -seq        => $target_slice->seq
    );

    # revcomp if design is on -ve strand
    if ( $design_strand == -1 ) {
        $target_genomic_region = $target_genomic_region->revcom;
    }

    my $work_dir = $self->base_dir->subdir( $well->as_string );
    $work_dir->mkpath;

    my %params = (
        genomic_region      => $target_genomic_region,
        forward_primer_name => $self->forward_primer_name,
        reverse_primer_name => $self->reverse_primer_name,
        dir                 => $work_dir,
        cigar_parser        => $self->cigar_parser,
    );
    $params{forward_primer_read} = $well_reads->{forward} if exists $well_reads->{forward};
    $params{reverse_primer_read} = $well_reads->{reverse} if exists $well_reads->{reverse};

    my $alignment_data;
    try{
        my $qc = HTGT::QC::Util::CrisprAlleleDamage->new( %params );
        $alignment_data = $qc->analyse;
    }
    catch {
        $self->log->error("Error running CrisprAlleleDamage alignment and analysis:\n $_");
    };

    return $alignment_data;
}

=head2 crispr_for_well

Return the crispr pair or crispr linked to the well.

=cut
sub crispr_for_well {
    my ( $self, $well ) = @_;

    my ( $left_crispr_well, $right_crispr_well ) = $well->left_and_right_crispr_wells;

    if ( $left_crispr_well && $right_crispr_well ) {
        my $left_crispr  = $left_crispr_well->crispr;
        my $right_crispr = $right_crispr_well->crispr;

        my $crispr_pair = $self->model->schema->resultset('CrisprPair')->find(
            {
                left_crispr_id  => $left_crispr->id,
                right_crispr_id => $right_crispr->id,
            }
        );

        unless ( $crispr_pair ) {
            LIMS2::Exception(
                "Unable to find crispr pair: left crispr $left_crispr, right crispr $right_crispr" );
        }
        $self->log->debug("Crispr pair for well $well: $crispr_pair" );

        return $crispr_pair;
    }
    elsif ( $left_crispr_well ) {
        my $crispr = $left_crispr_well->crispr;
        $self->log->debug("Crispr pair for $well: $crispr" );
        return $crispr;
    }
    else {
        LIMS2::Exception( "Unable to determine crispr pair or crispr for well $well" );
    }

    return;
}

=head2 get_primer_reads

Gather all the reads from a sequencing project, parse the data and put
into a hash, keyed on well names.

=cut
sub get_primer_reads {
    my ( $self ) = @_;

    my $seq_reads = $self->fetch_seq_reads;

    $self->log->debug( 'Parsing sequence read data' );
    my %primer_reads;
    while ( my $bio_seq = $seq_reads->next_seq ) {
        next unless $bio_seq->length;
        ( my $cleaned_seq = $bio_seq->seq ) =~ s/-/N/g;
        $bio_seq->seq( $cleaned_seq );
        my $res = $self->cigar_parser->parse_query_id( $bio_seq->display_name );

        if ( $res->{primer} eq $self->forward_primer_name ) {
            $primer_reads{ $res->{well_name} }{forward} = $bio_seq;
        }
        elsif ( $res->{primer} eq $self->reverse_primer_name ) {
            $primer_reads{ $res->{well_name} }{reverse} = $bio_seq;
        }
        else {
            $self->log->error( "Unknown primer read name $res->{primer} on well $res->{well_name}" );
        }
    }

    $self->primer_reads( \%primer_reads );
    return;
}

=head2 fetch_seq_reads

Fetch the fasta file containing all the primer reads for the sequencing project.

=cut
sub fetch_seq_reads {
    my ( $self  ) = @_;

    my $cmd = which( 'fetch-seq-reads.sh' );
    LIMS2::Exception->throw( 'Unable to find fetsch-seq-reads.sh script' ) unless $cmd;

    $self->log->info(
        "Retrieving reads from trace server for project: " . $self->sequencing_project_name );
    open( my $seq_reads_fh, '-|', $cmd, $self->sequencing_project_name )
        or LIMS2::Exception->throw( "failed to run $cmd for " . $self->sequencing_project_name );

    return Bio::SeqIO->new( -fh => $seq_reads_fh, -format => 'fasta' );
}

=head2 parse_analysis_data

Combine all the qc analysis data we want to store and convert into a json string.

=cut
sub parse_analysis_data {
    my ( $self, $alignment_data, $crispr, $target_slice, $design_strand ) = @_;

    my %parsed_data;
    for my $direction ( qw( forward reverse ) ) {
        if ( exists $alignment_data->{$direction} ) {
            $parsed_data{$direction} = $alignment_data->{$direction};
        }
        else {
            $parsed_data{$direction} = {
                no_alignment => 1,
            };
        }
    }

    if ( $alignment_data->{no_reads} ) {
        $parsed_data{warning} = 'No primer reads found for well' ;
    }

    $parsed_data{target_region_strand}   = $design_strand;
    $parsed_data{target_sequence_start}  = $target_slice->start;
    $parsed_data{target_sequence_end}    = $target_slice->end;
    $parsed_data{crispr_id}              = $crispr->id;
    $parsed_data{target_sequence}        = $target_slice->seq;

    return encode_json( \%parsed_data );
}

=head2 build_qc_data

Build up a hash of qc data for a well that can be perisisted to LIMS2.

=cut
sub build_qc_data {
    my ( $self, $well, $analysis_json, $well_reads, $crispr ) = @_;

    my $start =
    my %qc_data = (
        well_id         => $well->id,
        crispr_start    => $crispr->start,
        crispr_end      => $crispr->end,
        crispr_chr_name => $crispr->chr_name,
        analysis_data   => $analysis_json,
    );

    if ( exists $well_reads->{forward} ) {
        my $bioseq = $well_reads->{forward};
        $qc_data{fwd_read} = '>' . $bioseq->display_id . "\n" . $bioseq->seq;
    }

    if ( exists $well_reads->{reverse} ) {
        my $bioseq = $well_reads->{reverse};
        $qc_data{rev_read} = '>' . $bioseq->display_id . "\n" . $bioseq->seq;
    }

    return \%qc_data;
}

1;

__END__
