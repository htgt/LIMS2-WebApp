package LIMS2::Model::Util::CrisprESQC;

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

has base_dir => (
    is       => 'ro',
    isa      => AbsDir,
    required => 1,
    coerce   => 1,
);

has commit => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

=head2 analyse_plate

desc

=cut
use Smart::Comments;
sub analyse_plate {
    my ( $self ) = @_;
    $self->log->info( 'Running crispr es cell qc on plate: ' . $self->plate->name );
    
    $self->get_primer_reads();

    my @well_qc_data;
    for my $well ( $self->plate->wells->all ) {
        next if $self->well_name && $well->name ne $self->well_name;
        push @well_qc_data, $self->analyse_well( $well );
    }

    ### @well_qc_data
    if ( $self->commit ) {
        # TODO commit run though model 
    }

    return;
}

=head2 analyse_well

desc

=cut
sub analyse_well {
    my ( $self, $well ) = @_;
    
    my $crispr_pair  = $self->crispr_for_well( $well );
    my $target_slice = $crispr_pair->target_slice;
    $target_slice    = $target_slice->expand( 200, 200 );

    my ( $alignment_data, $well_reads );
    if ( $self->well_has_primer_reads( $well->name ) ) {
        $well_reads = $self->get_well_primer_reads( $well->name );
        $alignment_data = $self->align_well_reads( $well, $target_slice, $well_reads );
    }
    else {
        $self->log->warning("No primer reads for well " . $well->name );
        $alignment_data = { no_reads => 1 };
    }

    my $analysis_json
        = $self->parse_analysis_data( $alignment_data, $crispr_pair, $target_slice );

    return $self->build_qc_data( $well, $analysis_json, $well_reads, $crispr_pair );
}

=head2 align_well_reads

desc

=cut
sub align_well_reads {
    my ( $self, $well, $target_slice, $well_reads ) = @_;
    $self->log->debug( "Aligning reads for well: $well" );

    my $target_genomic_region = Bio::Seq->new(
        -display_id => 'target_region_' . $well->name,
        -alphabet   => 'dna',
        -seq        => $target_slice->seq
    );

    my $design = $well->design;
    # revcomp if design is on -ve strand 
    if ( $design->info->chr_strand == -1 ) {
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

    my $qc = HTGT::QC::Util::CrisprAlleleDamage->new( %params );

    return $qc->analyse;
}

=head2 crispr_for_well

desc

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
    else {
        # TODO: we may do qc on single crisprs, must deal with that here
        LIMS2::Exception( "Unable to determine crispr pair for well $well" );
    }

    return;
}

=head2 get_primer_reads

desc

=cut
sub get_primer_reads {
    my ( $self ) = @_;
    
    my $seq_reads = $self->fetch_seq_reads;

    $self->log->debug( 'Parsing sequence read data' );
    my %primer_reads;
    while ( my $seq = $seq_reads->next_seq ) {
        next unless $seq->length;
        my $res = $self->cigar_parser->parse_query_id( $seq->display_name );

        if ( $res->{primer} eq $self->forward_primer_name ) {
            $primer_reads{ $res->{well_name} }{forward} = $seq;
        }
        elsif ( $res->{primer} eq $self->reverse_primer_name ) {
            $primer_reads{ $res->{well_name} }{reverse} = $seq;
        }
        else {
            $self->log->error( "Unknown primer read name $res->{primer} on well $res->{well_name}" );
        }
    }

    $self->primer_reads( \%primer_reads );
    return;
}

=head2 fetch_seq_reads

desc

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

desc

=cut
sub parse_analysis_data {
    my ( $self, $alignment_data, $crispr_pair, $target_slice ) = @_;

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

    # TODO what to write if no reads

    $parsed_data{target_sequence_start}  = $target_slice->start;
    $parsed_data{target_sequence_end}    = $target_slice->end;
    $parsed_data{crispr_pair_id}         = $crispr_pair->id;
    
    return encode_json( \%parsed_data );
}

=head2 build_qc_data

desc

=cut
sub build_qc_data {
    my ( $self, $well, $analysis_json, $well_reads, $crispr_pair ) = @_;

    my %qc_data = (
        well_id       => $well->id,
        crispr_start  => $crispr_pair->left_crispr_locus->chr_start,
        crispr_end    => $crispr_pair->right_crispr_locus->chr_end,
        crispr_chr_id => $crispr_pair->right_crispr_locus->chr_id,
        analysis_data => $analysis_json,
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
