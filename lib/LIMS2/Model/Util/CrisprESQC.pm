package LIMS2::Model::Util::CrisprESQC;

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
use HTGT::QC::Constants qw(%BWA_REF_GENOMES);
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
use Bio::Perl qw( revcom );

with 'MooseX::Log::Log4perl';

const my $DEFAULT_QC_DIR => $ENV{ DEFAULT_CRISPR_ES_QC_DIR } //
                                    '/lustre/scratch125/sciops/team87/lims2_crispr_es_qc';
const my $BWA_MEM_CMD => $ENV{BWA_MEM_CMD} //
                                    '/software/vertres/bin-external/bwa-0.7.5a-r406/bwa';
const my $BLAT_CMD => $ENV{BLAT_CMD} //
                                    '/software/vertres/bin-external/blat';
const my $PSL_TO_SAM_CMD => $ENV{PSL_TO_SAM_CMD} //
                                    '/software/vertres/bin-external/samtools-0.2.0-rc8/bin/psl2sam.pl';

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
);

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

has allele_number => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
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

has two_bit_genome_file => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    lazy_build => 1,
);

sub _build_two_bit_genome_file{
    my ($self) = @_;

    my $dir = dir( $ENV{BLAT_GENOMES_DIR} || '/nfs/team87/blat_genomes' );
    my $file_name = $self->assembly.".2bit";
    my $file = $dir->file( $file_name );
    unless ( -e $file ){
        die "Cannot find two bit genome file $file to use for BLAT alignment";
    }
    return $file;
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

    if($self->allele_number){
        $qc_run_data->{allele_number} = $self->allele_number;
    }

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

has chrom_sizes => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy_build => 1,
    traits  => [ 'Hash' ],
    handles => {
        get_chrom_size => 'get',
    }
);

sub _build_chrom_sizes {
    my ( $self ) = @_;

    my $dir = dir( $ENV{CHROM_SIZES_DIR} || '/nfs/team87/blat_genomes' );
    my $file_name = $self->assembly.".chrom.sizes";

    my $file = $dir->file( $file_name );
    my $fh = $file->openr or die "Could not open chrom sizes file $file_name for reading - $!";

    my $sizes = {};
    my @lines = <$fh>;
    foreach my $line (@lines){
        chomp $line;
        my ($chr,$size) = split "\t", $line;
        $chr =~ s/chr//;
        $sizes->{$chr} = $size;
    }
    return $sizes;
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

    $self->fetch_and_parse_reads;

    $self->log->info ( 'Analysing wells' );

    my @qc_well_data;
    for my $well ( $self->plate->wells->all ) {
        next if $self->well_name && $well->name ne $self->well_name;

        # Retrieve the well ancestor that is specific to the allele we want to QC
        my $allele_well;
        if($self->allele_number){
            if($self->allele_number == 1){
                $allele_well = $well->first_allele;
            }
            elsif($self->allele_number == 2){
                $allele_well = $well->second_allele;
            }
            else{
                die "Sorry, allele number ".$self->allele_number." QC not yet supported";
            }
        }

        my $qc_data = $self->analyse_well( $well, $allele_well );

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
    my ( $self, $well, $allele_well ) = @_;
    $self->log->info( "Analysing well $well" );

    my $work_dir = $self->base_dir->subdir( $well->as_string );
    $work_dir->mkpath;

    $allele_well ||= $well;

    $self->log->info( "Getting design and crispr for well $allele_well");
    my $crispr = $allele_well->crispr_entity;
    my $design = $allele_well->design;

    my ( $analyser, %analysis_data, $well_reads );
    if ( !$crispr ) {
        $self->log->warn( "No crispr found for well " . $well->name );
        $analysis_data{no_crispr} = 1;
    }
    elsif ( $self->well_has_primer_reads( $well->name ) ) {
        $well_reads = $self->get_well_primer_reads( $well->name );

        my $sam_file = $self->align_reads_for_well( $well->name, $crispr, $work_dir );

        $analyser = $self->analyse_well_alignments( $well, $crispr, $sam_file, $work_dir );
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

=head2 align_reads_for_well

Perform alignment against target region using BLAT and prepare output for
further processing by align_and_analyse_well_reads

=cut
sub align_reads_for_well{
    my ($self, $well_name, $crispr, $work_dir) = @_;


    my $read_file = $self->write_well_fa_file( $well_name, $work_dir );

    my $blat_output_pslx_file = $self->run_blat_alignment( $crispr, $read_file, $work_dir);

    my $sam_file = $self->convert_pslx_to_sam($crispr, $well_name, $blat_output_pslx_file, $work_dir );

    return $sam_file;
}

=head write_well_fa_file

  Write .fa file containing reads for this well

=cut
sub write_well_fa_file{
    my ($self,$well_name,$work_dir) = @_;

    my $read_file = $work_dir->file("primer_reads.fa");
    my $reads_fh = $read_file->openw or die $!;
    my $reads_out = Bio::SeqIO->new( -fh => $reads_fh, -format => 'fasta' );

    $self->log->warn( "No forward primer reads for well " . $well_name) unless ($self->primer_reads->{ $well_name }->{forward});
    $reads_out->write_seq( $self->primer_reads->{ $well_name }->{forward} ) unless (! $self->primer_reads->{ $well_name }->{forward});

    $self->log->warn( "No reverse primer reads for well " . $well_name) unless ($self->primer_reads->{ $well_name }->{reverse});
    $reads_out->write_seq( $self->primer_reads->{ $well_name }->{reverse} ) unless (! $self->primer_reads->{ $well_name }->{reverse});

    return $read_file;
}

=head run_blat_alignment

    Run the blat command against the target region

=cut
sub run_blat_alignment{
    my ($self,$crispr, $read_file, $work_dir) = @_;

    my $region_start = $self->_get_region_start($crispr);
    my $region_end = $self->_get_region_end($crispr);

    my $target_region = "chr".$crispr->chr_name.":$region_start-$region_end";

    my $blat_output_pslx_file = $work_dir->file('blat_alignment.pslx')->absolute;
    my $blat_log_file = $work_dir->file( 'blat.log' )->absolute;
    my @blat_cmd = (
        $BLAT_CMD,
        "-out=pslx",
        $self->two_bit_genome_file->stringify.":".$target_region,
        $read_file,
        $blat_output_pslx_file->stringify,
    );

    $self->log->debug("Running blat command: ". join " ", @blat_cmd);
    run( \@blat_cmd,
        '>', $blat_log_file->stringify,
        '2>&1',
    ) or die(
            "Failed to run blat command, see log file: $blat_log_file" );

    return $blat_output_pslx_file;
}

# Methods defining the start and end of the genomic target region
sub _get_region_start{
    my ($self,$crispr) = @_;
    return $crispr->start - 500;
}

sub _get_region_end{
    my ($self,$crispr) = @_;
    return $crispr->end + 500;
}
=head2 convert_pslx_to_sam

=cut
sub convert_pslx_to_sam{
    my ($self, $crispr, $well_name, $blat_output_pslx_file, $work_dir) = @_;

    my @psl_to_sam_cmd = (
        $PSL_TO_SAM_CMD,
        $blat_output_pslx_file->stringify,
    );
    my $sam_file_no_header = $work_dir->file('alignment_no_header.sam')->absolute;
    my $psl_to_sam_log = $work_dir->file('psl_to_sam.log')->absolute;

    run (\@psl_to_sam_cmd,
        '>', $sam_file_no_header->stringify,
        '2>', $psl_to_sam_log->stringify,
    ) or die ("Failed to run psl2sam, see log file: $psl_to_sam_log");

    # Fix SAM file from psl_to_sam so it contains correct info for
    # further processing
    my $sam_file = $self->fix_no_header_sam({
        sam_file     => $sam_file_no_header,
        chr_name     => $crispr->chr_name,
        region_start => $self->_get_region_start($crispr),
        primer_reads => $self->primer_reads->{$well_name},
        work_dir     => $work_dir,
    });

    return $sam_file;
}
=head2 fix_no_header_sam

  sort samfile generated by psl_to_sam
  add header
  adjust coordinates to match reference genome
  add read sequence
  adjust CIGAR string so it reflects complete read sequence

=cut
sub fix_no_header_sam{
    my ( $self, $params ) = @_;

    my $length = $self->get_chrom_size( $params->{chr_name} );

    my @sam_content = $params->{sam_file}->slurp(chomp => 1);
    my @sam_values = map { [ split "\t", $_ ] } @sam_content;
    my $sam_new = $params->{work_dir}->file('alignment.sam');
    my $fh = $sam_new->openw or die "Could not open $sam_new for writing - $!";

    # Write headers
    print $fh "\@HD\tVN:1.3\tSO:coordinate\n";
    print $fh "\@SQ\tSN:".$params->{chr_name}."\tLN:$length\n";


    my $sam_values_unique = {};
    my $best_score_for_read = {};
    foreach my $value_array (@sam_values){
        # Only use the alignment with the highest score for each read
        # Score is in col 12 (index 11), format AS:i:468
        my $read_name = $value_array->[0];
        my $flag = $value_array->[1];

        # But first exclude reads not in the right orientation for the primer
        if($flag == 16){
            my $rev_primer = $self->reverse_primer_name;
            next unless $read_name =~ /$rev_primer/;
        }
        elsif($flag == 0){
            my $fwd_primer = $self->forward_primer_name;
            next unless $read_name =~ /$fwd_primer/;
        }

        my $score_string = $value_array->[11];
        my $score = (split ":", $score_string)[2];
        if(exists $sam_values_unique->{$read_name}){
            my $exisiting_score = $best_score_for_read->{$read_name};
            next unless $score > $exisiting_score;
        }

        # Store the score in case we have multiple alignments for read
        $best_score_for_read->{$read_name} = $score;

        # replace region name with chromosome name
        $value_array->[2] = $params->{chr_name};

        # replace start coord within region with start
        # coord relative to chromosome
        my $start = $value_array->[3];
        $value_array->[3] = $start + $params->{region_start};

        # Add sequence (revcom if FLAG==16)
        my $seq;
        if($value_array->[1] == 16){
            $seq = revcom( $params->{primer_reads}->{'reverse'} )->seq;
        }
        else{
            $seq = $params->{primer_reads}->{'forward'}->seq;
        }
        $value_array->[9] = $seq;

        # Replace H (hard clipping) with S (soft clipping) in
        # CIGAR string so it reflects full length read
        $value_array->[5] =~ tr/H/S/;

        $sam_values_unique->{$read_name} = $value_array;
    }

    # Sort by start coord of alignment
    my @sam_values_sorted = sort { $a->[3] <=> $b->[3] } values %{ $sam_values_unique };
    foreach my $value_array (@sam_values_sorted){
        print $fh join "\t", @{ $value_array };
        print $fh "\n";
    }

    close $fh;
    return $sam_new;
}

=head2 analyse_well_alignments

The analysis of the alignments is done by the HTGT::QC::Util::CrisprDamageVEP
module.

=cut
sub analyse_well_alignments {
    my ( $self, $well, $crispr, $sam_file, $work_dir ) = @_;
    $self->log->debug( "Analysing alignments for well: $well" );

    my %params = (
        species      => $self->species,
        target_start => $crispr->start,
        target_end   => $crispr->end,
        target_chr   => $crispr->chr_name,
        dir          => $work_dir,
        sam_file     => $sam_file,
        target_region_padding => 20,
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


=head2 fetch_and_parse_reads

Fetch the primer reads and store them in primer_reads hash

=cut
sub fetch_and_parse_reads{
    my ( $self ) = @_;
    my $seq_reads = $self->fetch_seq_reads();
    my $query_file = $self->parse_primer_reads( $seq_reads );

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

    # Also might as well store crispr ids here, for createing crispr validation records
    # for qc done on EP_PICK plates
    # In a future we will try to auto call crispr validation
    if ( $crispr ) {
        $analysis_data->{crispr_id}  = $crispr->id;
        if ( $crispr->is_pair ) {
            $analysis_data->{is_pair}    = $crispr->is_pair;
            $analysis_data->{crispr_ids} = [ $crispr->left_crispr_id, $crispr->right_crispr_id ];
        }
        elsif ( $crispr->is_group ) {
            $analysis_data->{is_group}   = $crispr->is_group;
            $analysis_data->{crispr_ids} = [ map { $_->crispr_id } $crispr->crispr_group_crisprs->all ];
        }
        else {
            $analysis_data->{crispr_ids} = [ $crispr->id ];
        }
    }

    $analysis_data->{design_id}  = $design->id if $design;
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

        $analysis_data->{design_strand}         = $design->chr_strand if $design;
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

    my $crispr_ids = exists $analysis_data->{crispr_ids} ? $analysis_data->{crispr_ids} : undef;
    my %qc_data = (
        well_id       => $well->id,
        analysis_data => $analysis_data,
    );

    if ( $crispr ) {
        $qc_data{crispr_start}    = $crispr->start;
        $qc_data{crispr_end}      = $crispr->end;
        $qc_data{crispr_chr_name} = $crispr->chr_name;
        if ( $self->plate->type_id eq 'EP_PICK' && $crispr_ids ) {
            $qc_data{crisprs_to_validate} = $crispr_ids;
        }
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

    if ( $analysis_data->{no_reads} ) {
        $qc_data{crispr_damage_type} = 'no-call';
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
