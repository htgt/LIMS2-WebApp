package LIMS2::Model::Util::CrisprESQC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CrisprESQC::VERSION = '0.308';
}
## use critic


=head1 NAME

LIMS2::Model::Util::CrisprESQC - Run crispr es cell qc

=head1 DESCRIPTION

Run QC to determine damaged cause to second allele by the crispr.
Align reads from primer pair flanking the crispr target region against the reference genome.
Analyse alignments to check for any damage.

Produce variant call files as well as output from Ensembl variant effect predictor software.

=cut

use Moose;
use HTGT::QC::Util::CigarParser;
use HTGT::QC::Util::CrisprDamageVEP;
use LIMS2::Exception;
use Bio::SeqIO;
use Bio::Seq;
use JSON qw( encode_json );
use YAML::Any qw( DumpFile );
use Try::Tiny;
use Path::Class;
use MooseX::Types::Path::Class::MoreCoercions qw/AbsDir/;
use File::Which;
use Data::UUID;
use Const::Fast;
use Data::Dumper;
use IPC::Run 'run';
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

const my $DEFAULT_QC_DIR => $ENV{ DEFAULT_CRISPR_ES_QC_DIR } //
                                    '/lustre/scratch109/sanger/team87/lims2_crispr_es_qc';
const my $BWA_MEM_CMD => $ENV{BWA_MEM_CMD}
    // '/software/vertres/bin-external/bwa-0.7.5a-r406/bwa';
const my %BWA_REF_GENOMES => (
    human => '/lustre/scratch109/blastdb/Users/team87/Human/bwa/Homo_sapiens.GRCh38.dna.primary_assembly.clean_chr_names.fa',
    mouse => '/lustre/scratch109/blastdb/Users/team87/Mouse/bwa/Mus_musculus.GRCm38.toplevel.clean_chr_names.fa',
    #human => '/lustre/scratch110/sanger/sp12/temp_ref_files/Human/bwa/Homo_sapiens.GRCh38.dna.primary_assembly.clean_chr_names.fa',
    #mouse => '/lustre/scratch110/sanger/sp12/temp_ref_files/Mouse/bwa/Mus_musculus.GRCm38.toplevel.clean_chr_names.fa',
);

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
);

# EP_PICK or PIQ plate name
has plate_name => (
    is  => 'ro',
    isa => 'Str',
);

has plate => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::Plate',
    lazy_build => 1,
);

sub _build_plate {
    my $self = shift;

    LIMS2::Exception->throw( 'Must specify plate_name attribute if not sending in a plate object' )
        unless $self->plate_name;

    # fetch the qc plate
    my $plate = $self->model->retrieve_plate( { name => $self->plate_name } );


    return $plate;
}

# set if you only want to analyse one well on the plate
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

has sub_seq_project => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has sequencing_fasta => (
    is     => 'ro',
    isa    => 'Path::Class::File',
    coerce => 1,
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has assembly => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_assembly {
    my $self = shift;

    return $self->model->get_species_default_assembly( $self->species );
}

#if specified manually no dir will be built
has base_dir => (
    is         => 'ro',
    isa        => AbsDir,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_base_dir {
    my ( $self ) = @_;

    my $dir = dir( $DEFAULT_QC_DIR )->subdir( $self->uuid );
    $dir->mkpath;

    return $dir;
}

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

has cigar_parser => (
    is         => 'ro',
    isa        => 'HTGT::QC::Util::CigarParser',
    lazy_build => 1,
);

sub _build_cigar_parser {
    my $self = shift;

    #strict matches any primer name
    return HTGT::QC::Util::CigarParser->new(
        strict_mode  => 0,
        #primers => [ $self->forward_primer_name, $self->reverse_primer_name ]
    );
}

has sam_header => (
    is  => 'rw',
    isa => 'Str',
);

has sam_for_well => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub{ {} },
    traits  => [ 'Hash' ],
    handles => {
        well_has_read_alignments => 'exists',
        get_well_read_alignments => 'get',
    }
);

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

has qc_run => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::CrisprEsQcRuns',
    lazy_build => 1
);

=head2 _build_qc_run

Create a crispr es qc run with no attached wells

=cut
sub _build_qc_run {
    my ( $self ) = @_;

    $self->log->debug( 'Creating Crispr ES QC run with id ' . $self->uuid );

    my $qc_run_data = {
        id                 => $self->uuid,
        created_by         => $self->user,
        species            => $self->species,
        sequencing_project => $self->sequencing_project_name,
        sub_project        => $self->sub_seq_project,
    };

    my $qc_run;
    $self->model->txn_do(
        sub {
            try {
                $qc_run = $self->model->create_crispr_es_qc_run( $qc_run_data );
                $self->log->info('Persisted crispr es qc run data');

                unless ( $self->commit ) {
                    $self->log->info('rollback');
                    $self->model->txn_rollback;
                }
            }
            catch {
                $self->log->error( "Error persisting crispr es qc: $_" );
                $self->model->txn_rollback;

                #re-throw error so it goes to webapp
                LIMS2::Exception->throw( $_ );
            };
        }
    );

    #write the run data to disk
    my $qc_run_data_file = $self->base_dir->file( 'qc_run_data.yaml' );
    $qc_run_data_file->touch;
    $qc_run_data->{plate} = $self->plate->name;
    DumpFile( $qc_run_data_file, $qc_run_data );

    return $qc_run;
}

=head2 analyse_plate

Start crispr es cell qc analysis.

=cut
sub analyse_plate {
    my ( $self ) = @_;

    # check plate is or right type
    my $plate = $self->plate;

    #initialise lazy build
    $self->qc_run;

    $self->log->info( 'Running crispr es cell qc on plate: ' . $self->plate->name );

    $self->align_primer_reads;

    $self->log->info ( 'Analysing wells' );

    my @qc_well_data;
    for my $well ( $self->plate->wells->all ) {
        next if $self->well_name && $well->name ne $self->well_name;

        my $qc_data = $self->analyse_well( $well );

        #make analysis_data a json string
        if ( $qc_data ) {
            $qc_data->{analysis_data} = encode_json( $qc_data->{analysis_data} );
            push @qc_well_data, $qc_data;
        }
    }

    $self->log->info( 'Well analysis complete, persisting ' . scalar( @qc_well_data ) . " wells" );

    $self->persist_wells( \@qc_well_data );

    return;
}

=head2 persist_wells

Persist all the crispr_es_qc_well data in one go.

=cut
sub persist_wells {
    my ( $self, $qc_wells ) = @_;

    $self->model->txn_do(
        sub {
            try {
                for my $qc_well ( @{ $qc_wells } ) {
                    $self->model->create_crispr_es_qc_well( $qc_well );
                }

                $self->log->info('Persisted crispr es qc well data');
                unless ( $self->commit ) {
                    $self->log->info('rollback');
                    $self->model->txn_rollback;
                }
            }
            catch {
                $self->log->error("Error persisting crispr es qc: $_" );
                $self->model->txn_rollback;

                #re-throw error so it goes to webapp
                LIMS2::Exception->throw( $_ );
            };
        }
    );

    return;
}

=head2 analyse_well

Analyse a well on the plate.

=cut
sub analyse_well {
    my ( $self, $well ) = @_;
    $self->log->info( "Analysing well $well" );

    my $work_dir = $self->base_dir->subdir( $well->as_string );
    $work_dir->mkpath;

    my $crispr = $well->crispr_entity;
    my $design = $well->design;

    my ( $analyser, %analysis_data, $well_reads );
    if ( !$crispr ) {
        $self->log->warn( "No crispr found for well " . $well->name );
        $analysis_data{no_crispr} = 1;
    }
    elsif ( $self->well_has_primer_reads( $well->name ) ) {
        $well_reads = $self->get_well_primer_reads( $well->name );

        unless ( $self->well_has_read_alignments( $well->name ) ) {
            $self->log->warn( "No alignments for reads from well: " . $well->name );
            $analysis_data{no_read_alignments} = 1;
        }

        my $sam_file = $self->build_sam_file_for_well( $well->name, $work_dir );
        $analyser = $self->align_and_analyse_well_reads( $well, $crispr, $sam_file, $work_dir, $design );
    }
    else {
        $self->log->warn( "No primer reads for well " . $well->name );
        $analysis_data{no_reads} = 1;
    }

    $self->parse_analysis_data( $analyser, $crispr, $design, \%analysis_data );
    my $qc_data = $self->build_qc_data( $well, $analyser, \%analysis_data, $well_reads, $crispr );
    $qc_data->{crispr_es_qc_run_id} = $self->qc_run->id;
    $qc_data->{species}             = $self->species;

    my $qc_data_file = $work_dir->file( 'qc_data.yaml' );
    $qc_data_file->touch;
    DumpFile( $qc_data_file, $qc_data );

    return $qc_data;
}

=head2 align_and_analyse_well_reads

Gather the primer reads and align against the target region the crispr entity
will hit.
The alignment and analysis work is done by the HTGT::QC::Util::CrisprDamageVEP
module.

=cut
sub align_and_analyse_well_reads {
    my ( $self, $well, $crispr, $sam_file, $work_dir, $design ) = @_;
    $self->log->debug( "Aligning reads for well: $well" );

    my %params = (
        species      => $self->species,
        target_start => $crispr->start,
        target_end   => $crispr->end,
        target_chr   => $crispr->chr_name,
        dir          => $work_dir,
        sam_file     => $sam_file,
    );

    my $crispr_damage_analyser;
    try{
        $crispr_damage_analyser = HTGT::QC::Util::CrisprDamageVEP->new( %params );
        $crispr_damage_analyser->analyse;
    }
    catch {
        $self->log->error("Error running CrisprDamageVEP alignment and analysis:\n $_");
    };

    return $crispr_damage_analyser;
}

=head2 align_primer_reads

Align the primer reads against the reference genome.
Store data in a hash keyed against well names for easy access.

=cut
sub align_primer_reads {
    my ( $self ) = @_;

    my $seq_reads = $self->fetch_seq_reads();
    my $query_file = $self->parse_primer_reads( $seq_reads );
    my $sam_file = $self->bwa_mem( $query_file );
    $self->parse_sam_file( $sam_file );

    return;
}

=head2 parse_primer_reads

Parse the primer reads fasta file, store reads in hash against well name
and primer type.

=cut
sub parse_primer_reads {
    my ( $self, $seq_reads ) = @_;

    $self->log->debug( 'Parsing sequence read data' );
    my $query_file    = $self->base_dir->file('parsed_primer_reads.fa')->absolute;
    my $query_fh      = $query_file->openw;
    my $query_seq_out = Bio::SeqIO->new( -fh => $query_fh, -format => 'fasta' );

    my %primer_reads;
    while ( my $bio_seq = $seq_reads->next_seq ) {
        next unless $bio_seq->length;

        ( my $cleaned_seq = $bio_seq->seq ) =~ s/-/N/g;
        $bio_seq->seq( $cleaned_seq );
        my $res = $self->cigar_parser->parse_query_id( $bio_seq->display_name );

        if ( defined $self->sub_seq_project ) {
            if ( $res->{plate_name} ne $self->sub_seq_project ) {
                $self->log->debug(
                    $res->{plate_name} . " differs from " . $self->sub_seq_project . ", skipping" );
                next;
            }
        }

        if ( $res->{primer} eq $self->forward_primer_name ) {
            $primer_reads{ $res->{well_name} }{forward} = $bio_seq;
            $query_seq_out->write_seq( $bio_seq );
        }
        elsif ( $res->{primer} eq $self->reverse_primer_name ) {
            $primer_reads{ $res->{well_name} }{reverse} = $bio_seq;
            $query_seq_out->write_seq( $bio_seq );
        }
        else {
            $self->log->error( "Unknown primer read name $res->{primer} on well $res->{well_name}" );
        }
    }

    $self->primer_reads( \%primer_reads );

    return $query_file;
}

=head2 bwa_mem

Run bwa mem to align all the primer reads, return the output sam file.

=cut
sub bwa_mem {
    my ( $self, $query_file ) = @_;

    $self->log->info( "Running bwa mem to align reads, may take a while..." );
    my @mem_command = (
        $BWA_MEM_CMD,
        'mem',                                    # align command
        '-O', 2,                                  # reduce gap open penalty ( default 6 )
        $BWA_REF_GENOMES{ lc( $self->species ) }, # target genome file, indexed for bwa
        $query_file->stringify,                   # query file with read sequences
    );

    $self->log->debug( "BWA mem command: " . join( ' ', @mem_command ) );
    my $bwa_output_sam_file = $self->base_dir->file('read_alignment.sam')->absolute;
    my $bwa_mem_log_file = $self->base_dir->file( 'bwa_mem.log' )->absolute;
    run( \@mem_command,
        '>', $bwa_output_sam_file->stringify,
        '2>', $bwa_mem_log_file->stringify
    ) or die(
            "Failed to run bwa mem command, see log file: $bwa_mem_log_file" );

    return $bwa_output_sam_file;
}

=head2 parse_sam_file

Once we have aligned all the reads parse the resultant sam file
and store alignment details in hash, keyed against well names.

=cut
sub parse_sam_file {
    my ( $self, $sam_file ) = @_;

    my @sam_file = $sam_file->slurp( chomp => 1 );
    my @header = grep { /^@/ } @sam_file;
    $self->sam_header( join("\n", @header) );

    my %sam_for_well;
    my @sam_lines = grep { !/^@/ } @sam_file;
    for my $sam_line ( @sam_lines ) {
        my ( $id ) = split(/\t/, $sam_line);
        my $res = $self->cigar_parser->parse_query_id( $id );
        push @{ $sam_for_well{ $res->{well_name} } }, $sam_line;
    }
    $self->sam_for_well( \%sam_for_well );

    return;
}

=head2 build_sam_file_for_well

Build a sam file with its primer read alignment details for a given well.

=cut
sub build_sam_file_for_well {
    my ( $self, $well_name, $dir ) = @_;

    my $sam_lines = $self->get_well_read_alignments( $well_name );

    my $sam_file = $dir->file('alignment.sam')->absolute;
    my $sam_fh   = $sam_file->openw;
    print $sam_fh $self->sam_header;
    print $sam_fh "\n". $_ for @{ $sam_lines };

    return $sam_file;
}

=head2 fetch_seq_reads

Fetch the fasta file containing all the primer reads for the sequencing project.

=cut
sub fetch_seq_reads {
    my ( $self  ) = @_;

    if ( $self->sequencing_fasta ) {
        return Bio::SeqIO->new( -fh => $self->sequencing_fasta->openr, -format => 'fasta' );
    }

    my $cmd = which( 'fetch-seq-reads.sh' );
    LIMS2::Exception->throw( 'Unable to find fetch-seq-reads.sh script' ) unless $cmd;

    $self->log->info(
        "Retrieving reads from trace server for project: " . $self->sequencing_project_name );
    ## no critic(RequireBriefOpen)
    open( my $seq_reads_fh, '-|', $cmd, $self->sequencing_project_name )
        or LIMS2::Exception->throw( "failed to run $cmd for " . $self->sequencing_project_name );

    return Bio::SeqIO->new( -fh => $seq_reads_fh, -format => 'fasta' );
    ## use critic
}

=head2 parse_analysis_data

Combine all the qc analysis data we want to store and return it in a hash.

=cut
sub parse_analysis_data {
    my ( $self, $analyser, $crispr, $design, $analysis_data ) = @_;

    $analysis_data->{crispr_id}  = $crispr->id if $crispr;
    $analysis_data->{design_id}  = $design->id;
    $analysis_data->{is_pair}    = $crispr->is_pair if $crispr;
    $analysis_data->{is_group}   = $crispr->is_group if $crispr;
    $analysis_data->{assembly}   = $self->assembly;

    return unless $analyser;

    $analysis_data->{vep_output} = $analyser->vep_file->slurp if $analyser->vep_file;
    $analysis_data->{ref_aa_seq} = $analyser->ref_aa_file->slurp if $analyser->ref_aa_file;
    $analysis_data->{mut_aa_seq} = $analyser->mut_aa_file->slurp if $analyser->mut_aa_file;
    $analysis_data->{non_merged_vcf} = $analyser->non_merged_vcf_file->slurp if $analyser->non_merged_vcf_file;

    if ( $analyser->num_target_region_alignments == 0 ) {
        $analysis_data->{ 'forward_no_alignment' } = 1;
        $analysis_data->{ 'reverse_no_alignment' } = 1;
        return;
    }

    if ( $analyser->pileup_parser ) {
        my $seqs = $analyser->pileup_parser->seqs;
        for my $seq_type ( qw( ref forward reverse ) ) {
            if ( exists $seqs->{ $seq_type } ) {
                $analysis_data->{ $seq_type . '_sequence'} = $seqs->{$seq_type}
            }
            else {
                $analysis_data->{ $seq_type . '_no_alignment' } = 1;
            }
        }

        $analysis_data->{design_strand}         = $design->chr_strand;
        $analysis_data->{target_sequence_start} = $analyser->pileup_parser->genome_start;
        $analysis_data->{target_sequence_end}   = $analyser->pileup_parser->genome_end;
        $analysis_data->{insertions}            = $analyser->pileup_parser->insertions;
        $analysis_data->{deletions}             = $analyser->pileup_parser->deletions;
    }

    return;
}

=head2 build_qc_data

Build up a hash of qc data for a well that can be perisisted to LIMS2.
Note that the analysis_data value is a hash-ref at the moment, it will
be converted to json just before we persist the data.

=cut
sub build_qc_data {
    my ( $self, $well, $analyser, $analysis_data, $well_reads, $crispr ) = @_;

    my %qc_data = (
        well_id       => $well->id,
        analysis_data => $analysis_data,
    );

    if ( $crispr ) {
        $qc_data{crispr_start}    = $crispr->start;
        $qc_data{crispr_end}      = $crispr->end;
        $qc_data{crispr_chr_name} = $crispr->chr_name;
    }

    if ( $analyser ) {
        $qc_data{vcf_file} = $analyser->vcf_file_target_region->slurp if $analyser->vcf_file_target_region;
        $qc_data{variant_size} = $analyser->variant_size if $analyser->variant_size;
        if ( $analyser->variant_type ) {
            $qc_data{crispr_damage_type} = $analyser->variant_type;
            # if a variant type other can no-call has been made then mark well accepted
            $qc_data{accepted} = 1 if $analyser->variant_type ne 'no-call';
        }
    }

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
