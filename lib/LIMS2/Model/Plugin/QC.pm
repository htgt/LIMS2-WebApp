package LIMS2::Model::Plugin::QC;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use List::MoreUtils qw( uniq );
use Scalar::Util qw( blessed );
use JSON ();
use Data::Compare qw( Compare );
use LIMS2::Model::Util::QC qw( retrieve_qc_run_results retrieve_qc_run_summary_results );
use namespace::autoclean;

use Const::Fast;
use Bio::SeqIO;

requires qw( schema check_params throw );

sub _encode_eng_seq_params {
    my ( $self, $eng_seq_params ) = @_;
    return JSON->new->utf8->canonical->encode($eng_seq_params);
}

sub _create_or_retrieve_eng_seq {
    my ( $self, $params ) = @_;

    return $self->schema->resultset('QcEngSeq')->find_or_create(
        {   method => $params->{eng_seq_method},
            params => $self->_encode_eng_seq_params( $params->{eng_seq_params} )
        },
        { key => 'qc_eng_seqs_method_params_key' }
    );
}

sub _qc_template_has_identical_layout {
    my ( $self, $template, $wanted_layout ) = @_;

    my %template_layout = map { $_->name => $_->qc_eng_seq_id } $template->qc_template_wells;

    return Compare( \%template_layout, $wanted_layout );
}

sub _find_qc_template_with_layout {
    my ( $self, $template_name, $template_layout ) = @_;

    my $template_rs = $self->schema->resultset('QcTemplate')
        ->search( { 'me.name' => $template_name }, { prefetch => { qc_template_wells => 'qc_eng_seq' } } );

    while ( my $template = $template_rs->next ) {
        if ( $self->_qc_template_has_identical_layout( $template, $template_layout ) ) {
            $self->log->debug("Found existing template with identical layout");
            return $template;
        }
    }

    return;
}

sub pspec_find_or_create_qc_template {
    return {
        name       => { validate => 'plate_name' },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        wells      => { validate => 'hashref' }
    };
}

sub find_or_create_qc_template {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_find_or_create_qc_template );

    # Build a new data structure mapping each well to a qc_eng_seq.id
    my %template_layout;
    while ( my ( $well_name, $well_params ) = each %{ $validated_params->{wells} } ) {
        next unless defined $well_params and keys %{$well_params};
        $template_layout{$well_name} = $self->_create_or_retrieve_eng_seq($well_params)->id;
    }

    # If a template already exists with this name and layout, return it
    my $existing_template = $self->_find_qc_template_with_layout( $validated_params->{name}, \%template_layout );
    if ($existing_template) {
        $self->log->debug( 'Returning matching template with id ' . $existing_template->id );
        return $existing_template;
    }

    # Otherwise, create a new template
    my $qc_template
        = $self->schema->resultset('QcTemplate')->create( { slice_def $validated_params, qw( name created_at ) } );
    $self->log->debug( 'created qc template plate ' . $qc_template->name . ' with id ' . $qc_template->id );
    while ( my ( $well_name, $eng_seq_id ) = each %template_layout ) {
        $qc_template->create_related(
            qc_template_wells => {
                name          => $well_name,
                qc_eng_seq_id => $eng_seq_id
            }
        );
    }

    return $qc_template;
}

sub _build_qc_template_search_params {
    my ( $self, $params ) = @_;

    if ( defined $params->{id} ) {
        return { 'me.id' => $params->{id} };
    }

    my %search;

    if ( $params->{name} ) {
        $search{'me.name'} = $params->{name};
    }

    if ( $params->{created_before} ) {
        $search{'me.created_at'} = { '<=', $params->{created_before} };
    }

    if ( $params->{latest} ) {
        if ( $params->{created_before} ) {
            $search{'me.created_at'} = {
                '=' => \[
                    '( select max(created_at) from qc_templates where name = me.name and created_at <= ? )',
                    [ created_at => $params->{created_before} ]
                ]
            };
        }
        else {
            $search{'me.created_at'}
                = { '=' => \['( select max(created_at) from qc_templates where name = me.name )'] };
        }
    }

    return \%search;
}

sub pspec_retrieve_qc_templates {
    return {
        id             => { validate => 'integer',          optional => 1 },
        name           => { validate => 'non_empty_string', optional => 1 },
        latest         => { validate => 'boolean',          default  => 1 },
        created_before => { validate => 'date_time',        optional => 1, post_filter => 'parse_date_time' }
    };
}

sub retrieve_qc_templates {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_templates );

    my $search_params = $self->_build_qc_template_search_params($validated_params);

    my @templates = $self->schema->resultset('QcTemplate')
        ->search( $search_params, { prefetch => { qc_template_wells => 'qc_eng_seq' } } );

    return \@templates;
}

sub pspec_delete_qc_template {
    return { id => { validate => 'integer' } };
}

sub delete_qc_template {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_delete_qc_template );

    my $template = $self->retrieve(
        'QcTemplate' => { 'me.id' => $validated_params->{id} },
        { prefetch => 'qc_template_wells' }
    );

    if ( $template->qc_runs_rs->count > 0 ) {
        $self->throw(
            InvalidState => {
                message => 'Template ' . $template->id . ' has been used in one or more QC runs, so cannot be deleted'
            }
        );
    }

    for my $well ( $template->qc_template_wells ) {
        $well->delete;
    }

    $template->delete;

    return 1;
}

sub pspec_find_or_create_qc_seq_read {
    return {
        id                => { validate => 'qc_seq_read_id' },
        qc_run_id         => { validate => 'existing_qc_run_id' },
        plate_name        => { validate => 'plate_name' },
        well_name         => { validate => 'well_name' },
        primer_name       => { validate => 'non_empty_string' },
        qc_seq_project_id => { validate => 'non_empty_string' },
        seq               => { validate => 'dna_seq' },
        description       => { validate => 'non_empty_string', optional => 1 },
        length            => { validate => 'integer' }
    };
}

sub find_or_create_qc_seq_read {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_find_or_create_qc_seq_read );

    my $seq_proj
        = $self->schema->resultset('QcSeqProject')->find_or_create( { id => $validated_params->{qc_seq_project_id} } );

    my $qc_seq_read = $self->schema->resultset('QcSeqRead')->find_or_create(
        +{  slice_def( $validated_params, qw( id description primer_name seq length ) ),
            qc_seq_project_id => $seq_proj->id
        }
    );

    my $qc_run_seq_well = $self->schema->resultset( 'QcRunSeqWell' )->find_or_create(
        {
            qc_run_id  => $validated_params->{qc_run_id},
            plate_name => $validated_params->{plate_name},
            well_name  => $validated_params->{well_name}
        },
        {
            key => 'qc_run_seq_wells_qc_run_id_plate_name_well_name_key'
        }
    );

    $self->schema->resultset( 'QcRunSeqWellQcSeqRead' )->create(
        {
            qc_run_seq_well_id => $qc_run_seq_well->id,
            qc_seq_read_id     => $qc_seq_read->id
        }
    );

    return $qc_seq_read;
}

sub pspec_retrieve_qc_seq_read {
    return { id => { validate => 'qc_seq_read_id' } };
}

sub retrieve_qc_seq_read {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_seq_read );

    return $self->retrieve( QcSeqRead => $validated_params );
}

sub pspec__create_qc_test_result_alignment_region {
    return {
        name        => { validate => 'non_empty_string' },
        length      => { validate => 'integer' },
        match_count => { validate => 'integer' },
        query_str   => { validate => 'qc_alignment_seq' },
        target_str  => { validate => 'qc_alignment_seq' },
        match_str   => { validate => 'qc_match_str', trim => 0 },
        pass        => { validate => 'boolean' }
    };
}

sub _create_qc_test_result_alignment_region {
    my ( $self, $params, $alignment ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec__create_qc_test_result_alignment_region );

    return $alignment->create_related( qc_alignment_regions => $validated_params );
}

sub pspec__create_qc_test_result_alignment {
    return {
        qc_seq_read_id    => { validate => 'existing_qc_seq_read_id' },
        qc_eng_seq_id     => { validate => 'existing_qc_eng_seq_id' },
        primer_name       => { validate => 'non_empty_string' },
        query_start       => { validate => 'integer' },
        query_end         => { validate => 'integer' },
        query_strand      => { validate => 'strand' },
        target_start      => { validate => 'integer' },
        target_end        => { validate => 'integer' },
        target_strand     => { validate => 'strand' },
        score             => { validate => 'integer' },
        pass              => { validate => 'boolean' },
        features          => { optional => 1 },
        cigar             => { validate => 'cigar_string' },
        op_str            => { validate => 'op_str' },
        alignment_regions => { optional => 1 }
    };
}

sub _create_qc_test_result_alignment {
    my ( $self, $params, $qc_test_result ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec__create_qc_test_result_alignment );

    $validated_params->{features} ||= '';

    my $alignment = $self->schema->resultset('QcAlignment')->create(
        {   slice(
                $validated_params, qw( qc_seq_read_id qc_eng_seq_id primer_name
                    query_start query_end query_strand
                    target_start target_end target_strand
                    score pass features cigar op_str )
            )
        }
    );

    for my $region ( @{ $validated_params->{alignment_regions} || [] } ) {
        $self->_create_qc_test_result_alignment_region( $region, $alignment );
    }

    return $alignment;
}

sub _get_qc_run_seq_well_from_alignments {
    my ( $self, $qc_run_id, $alignments ) = @_;

    my @qc_seq_read_ids = uniq map { $_->{qc_seq_read_id} } @{$alignments};

    my @wells = $self->schema->resultset( 'QcRunSeqWell' )->search(
        {
            'me.qc_run_id'                                => $qc_run_id,
            'qc_run_seq_well_qc_seq_reads.qc_seq_read_id' => { -in => \@qc_seq_read_ids }
        },
        {
            join     => 'qc_run_seq_well_qc_seq_reads',
            columns  => [ 'me.id' ],
            distinct => 1
        }
    );

    $self->throw( Validation =>
            { message => 'Alignments must belong to exactly one well', params => { alignments => $alignments } } )
        unless @wells == 1;

    return shift @wells;
}

sub pspec_create_qc_test_result {
    return {
        qc_run_id     => { validate => 'existing_qc_run_id' },
        qc_eng_seq_id => { validate => 'existing_qc_eng_seq_id' },
        pass          => { validate => 'boolean' },
        score         => { validate => 'integer' },
        alignments    => {}
    };
}

sub create_qc_test_result {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_qc_test_result );

    my $qc_run_seq_well = $self->_get_qc_run_seq_well_from_alignments( $validated_params->{qc_run_id}, $validated_params->{alignments} );

    my $qc_test_result = $self->schema->resultset('QcTestResult')->create(
        {   qc_run_id              => $validated_params->{qc_run_id},
            qc_run_seq_well_id     => $qc_run_seq_well->id,
            qc_eng_seq_id          => $validated_params->{qc_eng_seq_id},
            score                  => $validated_params->{score},
            pass                   => $validated_params->{pass} || 0
        }
    );

    for my $alignment ( @{ $validated_params->{alignments} } ) {
        $self->_create_qc_test_result_alignment( $alignment, $qc_test_result );
    }

    return $qc_test_result;
}

sub pspec_retrieve_qc_test_result {
    return { id => { validate => 'integer' } };
}

sub retrieve_qc_test_result {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_test_result );

    my $test_result = $self->retrieve( 'QcTestResult', { id => $validated_params->{id} } );

    return $test_result;
}

sub pspec__create_qc_run_seq_proj {
    return { qc_seq_project_id => { validate => 'non_empty_string' } };
}

sub _create_qc_run_seq_proj {
    my ( $self, $params, $qc_run ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec__create_qc_run_seq_proj );

    $self->schema->resultset( 'QcSeqProject' )->find_or_create( { id => $validated_params->{qc_seq_project_id} } );

    return $qc_run->create_related(
        qc_run_seq_projects => { qc_seq_project_id => $validated_params->{qc_seq_project_id} }
    );
}

sub pspec_create_qc_run {
    return {
        id               => { validate => 'uuid' },
        created_at       => { validate => 'date_time', post_filter => 'parse_date_time', optional => 1 },
        created_by       => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        profile          => { validate => 'non_empty_string' },
        software_version => { validate => 'software_version' },
        qc_template_id         => { validate => 'existing_qc_template_id',   optional => 1 },
        qc_template_name       => { validate => 'existing_qc_template_name', optional => 1 },
        qc_sequencing_projects => { validate => 'non_empty_string' },    # Data::FormValidator will call this for each element of the array ref
        REQUIRE_SOME => { qc_template_id_or_name => [ 1, qw( qc_template_id qc_template_name ) ] }
    };
}

sub create_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_qc_run );

    if ( !defined $validated_params->{qc_template_id} ) {
        my $template = $self->retrieve_qc_templates(
            { qc_template_name => $validated_params->{qc_template_name}, latest => 1 }
        )->[0];
        $validated_params->{qc_template_id} = $template->id;
    }

    my $qc_run = $self->schema->resultset('QcRun')->create(
        { slice_def( $validated_params, qw( id created_at created_by_id profile qc_template_id software_version ) ) }
    );

    for my $seq_proj_id ( @{ $validated_params->{qc_sequencing_projects} } ) {
        $self->_create_qc_run_seq_proj( { qc_seq_project_id => $seq_proj_id }, $qc_run );
    }

    return $qc_run;
}

sub pspec_update_qc_run {
    return {
        id              => { validate => 'uuid' },
        upload_complete => { validate => 'boolean' }
    };
}

sub update_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_qc_run );

    my $qc_run = $self->retrieve( QcRun => { id => $validated_params->{id} } );

    $qc_run->update( { upload_complete => $validated_params->{upload_complete} } );

    return $qc_run;
}

sub pspec_retrieve_qc_runs {
    return {
        sequencing_project => { validate => 'existing_qc_seq_project_id', optional => 1 },
        template_plate     => { validate => 'existing_qc_template_name', optional => 1 },
        profile            => { validate => 'non_empty_string', optional => 1 },
    };
}

sub retrieve_qc_runs {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_runs );

    my $search_params = $self->_build_qc_runs_search_params( $validated_params );

    my @qc_runs = $self->schema->resultset('QcRun')->search(
        $search_params,
        {
            join     => [ qw( qc_template qc_run_seq_projects ) ],
            order_by => { -desc => 'created_at' },
            distinct => 1,
        }
    );

    my @qc_runs_data;
    foreach my $qc_run ( @qc_runs ) {
        my $qc_run_data = $qc_run->as_hash;
        $qc_run_data->{expected_designs} = $qc_run->count_designs;
        $qc_run_data->{observed_designs} = $qc_run->count_observed_designs;
        $qc_run_data->{valid_designs} = $qc_run->count_valid_designs;
        push @qc_runs_data, $qc_run_data;
    }

    return \@qc_runs_data;
}

sub list_profiles {
    my ( $self ) = @_;

    my @profiles = $self->schema->resultset( 'QcRun' )->search(
        {},
        {
            columns  => [ 'profile' ],
            distinct => 1,
            order_by => [ 'profile' ]
        }
    )->all;

    return [ map $_->profile, @profiles ];
}

sub _build_qc_runs_search_params {
    my ( $self, $params ) = @_;

    my %search = ( 'me.upload_complete' => 't' );

    unless ( $params->{show_all} ) {
        if ( $params->{sequencing_project} ) {
            $search{ 'qc_run_seq_projects.qc_seq_project_id' } = $params->{sequencing_project};
        }
        if ( $params->{template_plate} ) {
            $search{ 'qc_template.name' } = $params->{template_plate};
        }
        if ( $params->{profile} and $params->{profile} ne '-' ) {
            $search{ 'me.profile' } = $params->{profile};
        }
    }

    return \%search;
}

sub pspec_retrieve_qc_seq_well {
    return {
        qc_run_id  => { validate => 'integer' },
        plate_name => { validate => 'plate_name' },
        well_name  => { validate => 'well_name' },
    };
}

sub retrieve_qc_seq_well {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_seq_well );

    return $self->retrieve( 'QcRunSeqWell' =>
        {
            'qc_run.id'     => $validated_params->{qc_run_id},
            'me.plate_name' => $validated_params->{plate_name},
            'me.well_name'  => $validated_params->{well_name},

        },
        {
            join => 'qc_run'
        }
    );
}

sub pspec_retrieve_qc_run {
    return {
        id => { validate => 'integer' },
    };
}

sub retrieve_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_run );
    my $qc_run = $self->retrieve( 'QcRun' => $validated_params );

    return $qc_run;
}

sub qc_run_results {
    my ( $self, $qc_run ) = @_;
    #TODO add check I have a valid qc_run object here?

    return retrieve_qc_run_results( $qc_run );
}

sub qc_run_summary_results {
    my ( $self, $qc_run ) = @_;
    #TODO add check I have a valid qc_run object here?

    return retrieve_qc_run_summary_results( $qc_run );
}

sub qc_run_seq_well_result {
    my ( $self, $seq_well ) = @_;
    #TODO check for seq_well

    my @seq_reads = $seq_well->qc_seq_reads;

    unless ( @seq_reads ) {
        $self->throw( Validation => {
                'No sequence reads for qc seq well ' . $seq_well->plate_name . $seq_well->well_name } );
    }

    my @qc_alignments = map { $_->qc_alignments } @seq_reads;

    my @qc_results;
    for my $test_result ( $seq_well->qc_test_results ) {
        my %result;
        $result{design_id} = $test_result->qc_eng_seq->design_id;
        $result{score} = $test_result->score;
        $result{pass} = $test_result->pass;
        $result{qc_test_result_id} = $test_result->id;
        $result{alignments} = [ grep{ $_->qc_eng_seq_id == $test_result->qc_eng_seq->id  } @qc_alignments ];
        push @qc_results, \%result;
    }

    return( \@seq_reads, \@qc_results );
}

use HTGT::QC::Util::Alignment qw( alignment_match );
use HTGT::QC::Util::CigarParser;
sub qc_alignment_result {
    my ( $self, $params ) = @_;

    my $test_result = $self->schema->resultset( 'QcTestResult' )->find(
        {
            id => $params->{qc_test_result_id}
        }
    );

    unless ( $test_result ) {
        $self->throw( NotFound => { entity_class => 'QcTestResult', search_params => {} } );
    }

    my $alignment = $self->schema->resultset( 'QcAlignment' )->search_rs(
        {
            qc_eng_seq_id  => $test_result->qc_eng_seq_id,
            qc_seq_read_id => $params->{qc_seq_read_id}
        }
    )->first;

    unless ( $alignment ) {
        $self->throw( NotFound => { entity_class => 'QcAlignment', search_params => {} } );
    }

    my $qc_eng_seq = $test_result->qc_eng_seq->as_hash;
    my $eng_seq_method= $qc_eng_seq->{eng_seq_method};
    my $target = $self->eng_seq_builder->$eng_seq_method( $qc_eng_seq->{eng_seq_params} );
    my $query  = $alignment->qc_seq_read->bio_seq;
    my $cigar  = HTGT::QC::Util::CigarParser->new(strict_mode => 0)->parse_cigar( $alignment->cigar );

    my $match = alignment_match( $query, $target, $cigar, $cigar->{target_start}, $cigar->{target_end} );

    my $target_strand = $alignment->target_strand == 1 ? '+' : '-';

    my $alignment_str = HTGT::QC::Util::Alignment::format_alignment(
        %{$match},
        target_id  => "Target ($target_strand)",
        query_id   => 'Sequence Read',
        line_len   => 72,
        header_len => 12
    );

    return {
         target        => $target->display_id,
         query         => $query->display_id,
         alignment_str => $alignment_str,
         alignment     => $alignment,
         test_result   => $test_result
    };
}

sub retrieve_qc_seq_read_sequences {
    my ( $self, $seq_well, $format ) = @_;
    #TODO add validtion checks

    my @seq_reads = $seq_well->qc_seq_reads;
    unless ( @seq_reads ) {
        $self->throw( Validation => {
                'No sequence reads for qc seq well ' . $seq_well->plate_name . $seq_well->well_name } );
    }

    my $params = $self->_validated_download_seq_params( $format );

    my $filename = 'seq_reads_' . $seq_well->plate_name . $seq_well->well_name . $params->{suffix};

    my $formatted_seq;
    my $seq_io = Bio::SeqIO->new( -fh => IO::String->new( $formatted_seq ), -format => $params->{format} );

    for my $seq_read ( @seq_reads ) {
        $seq_io->write_seq( $seq_read->bio_seq );
    }

    return ( $filename, $formatted_seq );
}

sub retrieve_qc_eng_seq {
    my ( $self, $qc_test_result_id, $format ) = @_;
    #TODO add validtion checks

    my $qc_test_result = $self->retrieve(
        'QcTestResult' => { id => $qc_test_result_id },
    );
    my $qc_eng_seq_params = $qc_test_result->qc_eng_seq->as_hash;
    my $eng_seq_method= $qc_eng_seq_params->{eng_seq_method};
    my $qc_eng_seq = $self->eng_seq_builder->$eng_seq_method( $qc_eng_seq_params->{eng_seq_params} );

    my $params = $self->_validated_download_seq_params( $format );

    my $filename = $qc_eng_seq->display_id . $params->{suffix};

    my $formatted_seq;
    Bio::SeqIO->new(
        -fh => IO::String->new( $formatted_seq ),
        -format => $params->{format}
    )->write_seq( $qc_eng_seq );

    return ( $filename, $formatted_seq );
}

sub _validated_download_seq_params {
    my ( $self, $format ) = @_;

    my %params = (
        format => 'genbank',
    );

    const my %SUFFIX_FOR => ( genbank => '.gbk', fasta => '.fasta' );

    if ( $format ) {
        $format =~ s/^\s+//;
        $format =~ s/\s+$//;
        $format = lc( $format );
        if ( $SUFFIX_FOR{$format} ) {
            $params{format} = $format;
        }
    }

    $params{suffix} = $SUFFIX_FOR{ $params{format} };

    return \%params;
}

1;

__END__
