package LIMS2::Model::Plugin::QC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::QC::VERSION = '0.411';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use LIMS2::Model::Util::CreateQC qw(
    create_or_retrieve_eng_seq
    find_qc_template_with_layout
    build_qc_template_search_params
    create_qc_run_seq_proj
    create_qc_test_result_alignment
    get_qc_run_seq_well_from_alignments
    link_primers_to_qc_run_template
);

use LIMS2::Model::Util::QCResults qw(
    retrieve_qc_run_results
    retrieve_qc_run_results_fast
    retrieve_qc_run_summary_results
    retrieve_qc_run_seq_well_results
    retrieve_qc_alignment_results
    retrieve_qc_seq_read_sequences
    retrieve_qc_eng_seq_sequence
    retrieve_qc_eng_seq_bioseq
    build_qc_runs_search_params
    infer_qc_process_type
);
use LIMS2::Model::Util::QCTemplates qw( create_qc_template_from_wells );
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use LIMS2::Model::Util qw( sanitize_like_expr );
use List::MoreUtils qw( uniq );
use Log::Log4perl qw( :easy );
use HTGT::QC::Config;
use namespace::autoclean;
use Try::Tiny;


requires qw( schema check_params throw );


sub pspec_find_or_create_qc_template {
    return {
        name       => { validate => 'plate_name' },
        species    => { validate => 'existing_species', rename => 'species_id' },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        wells      => { validate => 'hashref' }
    };
}

sub find_or_create_qc_template {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_find_or_create_qc_template );

    # Build a new data structure mapping each well to a qc_eng_seq.id and source well id
    my %template_layout;
    my %source_for_well;
    while ( my ( $well_name, $well_params ) = each %{ $validated_params->{wells} } ) {
        next unless defined $well_params and keys %{$well_params};
        $template_layout{$well_name} = create_or_retrieve_eng_seq( $self, $well_params )->id;
        $source_for_well{$well_name} = $well_params->{source_well_id};
    }

    # If a template already exists with this name and layout, return it
    my $existing_template
        = find_qc_template_with_layout( $self, @{$validated_params}{'species_id','name'}, \%template_layout );
    if ($existing_template) {
        $self->log->debug( 'Returning matching template with id ' . $existing_template->id );
        return $existing_template;
    }

    # Otherwise, create a new template
    my $qc_template = $self->schema->resultset('QcTemplate')
        ->create( { slice_def $validated_params, qw( name species_id created_at ) } );
    $self->log->debug(
        'created qc template plate ' . $qc_template->name . ' with id ' . $qc_template->id );
    while ( my ( $well_name, $eng_seq_id ) = each %template_layout ) {

        # Store the overrides that were specified for this template
        my %well_overrides = slice_def ($validated_params->{wells}->{$well_name},
                                        qw( cassette backbone recombinase ) );

        my $template_well = $qc_template->create_related(
                qc_template_wells => {
                name          => $well_name,
                qc_eng_seq_id => $eng_seq_id,
                source_well_id => $source_for_well{$well_name},
            }
        );

        if(my $cassette_name = $well_overrides{'cassette'}){
            my $cassette = $self->schema->resultset('Cassette')->find({ name => $cassette_name })
            or die "Cassette $cassette_name not found";
            $template_well->create_related(
                qc_template_well_cassette => {
                    cassette_id => $cassette->id,
                }
            );
        }

        if(my $backbone_name = $well_overrides{'backbone'}){
            my $backbone = $self->schema->resultset('Backbone')->find({ name => $backbone_name })
            or die "Backbone $backbone_name not found";
            $template_well->create_related(
                qc_template_well_backbone => {
                    backbone_id => $backbone->id,
                }
            );
        }

        if(my $recom_list = $well_overrides{'recombinase'}){
            foreach my $recom (@$recom_list){
                $self->schema->resultset('Recombinase')->find({ id => $recom })
                or die "Recombinase $recom not found";
                $template_well->create_related(
                    qc_template_well_recombinases => {
                        recombinase_id => $recom,
                    }
                );
            }
        }
    }

    return $qc_template;
}

sub pspec_retrieve_qc_templates {
    return {
        id      => { validate => 'integer',          optional => 1 },
        species => { validate => 'existing_species', optional => 1 },
        name    => { validate => 'non_empty_string', optional => 1 },
        latest  => { validate => 'boolean',          default  => 1 },
        created_before =>
            { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    };
}

sub retrieve_qc_templates {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_templates );

    my $search_params = build_qc_template_search_params( $validated_params, $self->schema );

    my @templates = $self->schema->resultset('QcTemplate')
        ->search( $search_params, { prefetch => { qc_template_wells => 'qc_eng_seq' } } );

    return \@templates;
}

# Retrieve single QC template by ID
sub pspec_retrieve_qc_template {
    return {
        id      => { validate => 'integer', optional => 1 },
        name    => { validate => 'existing_qc_template_name', optional => 1},
        REQUIRE_SOME => { name_or_id => [ 1, qw( name id ) ] }
    };
}

sub retrieve_qc_template {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_template );

    my %search;
    if ($validated_params->{name}){
        $search{'me.name'} = $validated_params->{name};
    }
    if ($validated_params->{id}){
        $search{'me.id'} = $validated_params->{id};
    }

    my $template = $self->retrieve(
        'QcTemplate' => \%search,
        { prefetch => 'qc_template_wells' }
    );

    return $template;
}

sub pspec_retrieve_qc_template_well {
    return {
        id      => { validate => 'integer' },
    };
}

sub retrieve_qc_template_well {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_template_well );

    my $template_well = $self->retrieve(
        'QcTemplateWell' => { 'me.id' => $validated_params->{id} },
        { prefetch => 'qc_eng_seq' }
    );

    return $template_well;
}

sub pspec_delete_qc_template {
    return {
        id => { validate => 'integer' },
        delete_runs => { validate => 'boolean', default => 0 },
    };
}

sub delete_qc_template {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_delete_qc_template );

    my $template = $self->retrieve(
        'QcTemplate' => { 'me.id' => $validated_params->{id} },
        { prefetch => 'qc_template_wells' }
    );

    if ( my @runs = $template->qc_runs ) {
        if ($validated_params->{delete_runs}){
            foreach my $run (@runs){
                $self->delete_qc_run({ id => $run->id });
            }
        }
        else{
            $self->throw( InvalidState => {
                message => 'Template ' . $template->id
                      . ' has been used in one or more QC runs, so cannot be deleted'
                }
            );
        }
    }

    for my $well ( $template->qc_template_wells ) {
        $well->delete_related('qc_template_well_cassette');
        $well->delete_related('qc_template_well_backbone');
        $well->delete_related('qc_template_well_recombinases');
        $well->delete;
    }

    $template->delete;

    return 1;
}

sub pspec_find_or_create_qc_seq_read {
    return {
        id                => { validate => 'qc_seq_read_id' },
        species           => { validate => 'existing_species', rename => 'species_id' },
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

    my $seq_proj = $self->schema->resultset('QcSeqProject')
        ->find_or_create( { id => $validated_params->{qc_seq_project_id}, species_id => $validated_params->{species_id} } );

    my $qc_seq_read = $self->schema->resultset('QcSeqRead')->find_or_create(
        +{  slice_def( $validated_params, qw( id description primer_name seq length ) ),
            qc_seq_project_id => $seq_proj->id
        }
    );

    my $qc_run_seq_well = $self->schema->resultset('QcRunSeqWell')->find_or_create(
        {   qc_run_id  => $validated_params->{qc_run_id},
            plate_name => $validated_params->{plate_name},
            well_name  => $validated_params->{well_name}
        },
        { key => 'qc_run_seq_wells_qc_run_id_plate_name_well_name_key' }
    );

    $self->schema->resultset('QcRunSeqWellQcSeqRead')->create(
        {   qc_run_seq_well_id => $qc_run_seq_well->id,
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

    my $qc_run_seq_well
        = get_qc_run_seq_well_from_alignments( $self, $validated_params->{qc_run_id},
        $validated_params->{alignments} );

    my $qc_test_result = $self->schema->resultset('QcTestResult')->create(
        {   qc_run_id          => $validated_params->{qc_run_id},
            qc_run_seq_well_id => $qc_run_seq_well->id,
            qc_eng_seq_id      => $validated_params->{qc_eng_seq_id},
            score              => $validated_params->{score},
            pass               => $validated_params->{pass} || 0
        }
    );

    for my $alignment ( @{ $validated_params->{alignments} } ) {
        create_qc_test_result_alignment( $self, $alignment, $qc_test_result );
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

sub pspec_create_qc_run {
    return {
        id         => { validate => 'uuid' },
        species    => { validate => 'existing_species', rename => 'species_id' },
        created_at => { validate => 'date_time', post_filter => 'parse_date_time', optional => 1 },
        created_by => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        profile                => { validate => 'non_empty_string' },
        software_version       => { validate => 'software_version' },
        qc_template_id         => { validate => 'existing_qc_template_id', optional => 1 },
        qc_template_name       => { validate => 'existing_qc_template_name', optional => 1 },
        qc_sequencing_projects => { validate => 'non_empty_string' }
        ,    # Data::FormValidator will call this for each element of the array ref
        REQUIRE_SOME => { qc_template_id_or_name => [ 1, qw( qc_template_id qc_template_name ) ] }
    };
}

sub create_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_qc_run );

    if ( !defined $validated_params->{qc_template_id} ) {
        my $template = $self->retrieve_qc_templates(
            { name => $validated_params->{qc_template_name}, latest => 1 } )->[0];
        $validated_params->{qc_template_id} = $template->id;
    }

    my $qc_run = $self->schema->resultset('QcRun')->create(
        {   slice_def(
                $validated_params,
                qw( id created_at created_by_id profile qc_template_id software_version )
            )
        }
    );

    for my $seq_proj_id ( @{ $validated_params->{qc_sequencing_projects} } ) {
        my $qc_run_seq_proj = create_qc_run_seq_proj(
            $self, $qc_run,
            {
                species_id        => $validated_params->{species_id},
                qc_seq_project_id => $seq_proj_id
            },
        );
    }

    link_primers_to_qc_run_template($qc_run);

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
        species            => { validate => 'existing_species', rename => 'species_id' },
        sequencing_project => { validate => 'existing_qc_seq_project_id', optional => 1 },
        template_plate     => { validate => 'existing_qc_template_name',  optional => 1 },
        profile            => { validate => 'non_empty_string',           optional => 1 },
        page               => { validate => 'integer', default => 1 },
    };
}

sub retrieve_qc_runs {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_runs );

    my $search_params = build_qc_runs_search_params($validated_params);

    my $qc_runs = $self->schema->resultset('QcRun')->search(
        $search_params,
        {   join     => [ 'qc_template',  { 'qc_run_seq_projects' => 'qc_seq_project' } ],
            order_by => { -desc => 'created_at' },
            distinct => 1,
            page     => $validated_params->{page},
            rows     => 15,
        }
    );

    my @qc_runs_data;
    while ( my $qc_run = $qc_runs->next ) {
        my $qc_run_data = $qc_run->as_hash;
        $qc_run_data->{expected_designs} = $qc_run->count_designs;
        $qc_run_data->{observed_designs} = $qc_run->count_observed_designs;
        $qc_run_data->{valid_designs}    = $qc_run->count_valid_designs;
        push @qc_runs_data, $qc_run_data;
    }

    return(  \@qc_runs_data, $qc_runs->pager );
}

sub list_profiles {
    my ($self) = @_;

    my @profiles = $self->schema->resultset('QcRun')->search(
        {},
        {   columns  => ['profile'],
            distinct => 1,
            order_by => ['profile']
        }
    )->all;

    return [ map { $_->profile } @profiles ];
}

sub pspec_retrieve_qc_run {
    return { id => { validate => 'uuid' }, };
}

sub retrieve_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_run );
    my $qc_run = $self->retrieve( 'QcRun' => $validated_params );

    return $qc_run;
}

sub delete_qc_run {
    my ( $self, $params ) = @_;

    # This will validate params
    my $qc_run = $self->retrieve_qc_run($params);

    #delete any alignments (and subsequent regions) linked to this qc run.
    for my $alignment ( $qc_run->search_related('qc_alignments') ) {
        $alignment->delete_related('qc_alignment_regions');
    }
    $qc_run->delete_related('qc_alignments');

    #delete any alignments (and subsequent regions) linked to this qc run.
    for my $alignment ( $qc_run->search_related('qc_alignments') ) {
        $alignment->delete_related('qc_alignment_regions');
    }
    $qc_run->delete_related('qc_alignments');

    $qc_run->delete_related('qc_run_seq_projects');

    foreach my $well ($qc_run->search_related('qc_run_seq_wells')){
        $well->delete_related('qc_run_seq_well_qc_seq_reads');
        $well->delete_related('qc_test_results');
    }

    $qc_run->delete_related('qc_run_seq_wells');

    $qc_run->delete;

    return 1;
}

sub pspec_retrieve_qc_run_seq_well {
    return {
        qc_run_id  => { validate => 'uuid' },
        plate_name => { validate => 'plate_name' },
        well_name  => { validate => 'well_name' },
    };
}

sub retrieve_qc_run_seq_well {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_run_seq_well );

    my $qc_seq_well = $self->retrieve(
        'QcRunSeqWell' => {
            'qc_run.id'     => $validated_params->{qc_run_id},
            'me.plate_name' => $validated_params->{plate_name},
            'me.well_name'  => $validated_params->{well_name},

        },
        { join => 'qc_run' }
    );

    return $qc_seq_well;
}

sub pspec_qc_run_results {
    return { qc_run_id => { validate => 'uuid' }, };
}

sub qc_run_results {
    my ( $self, $params ) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_qc_run_results );

    my $qc_run = $self->retrieve( 'QcRun' => { id => $validated_params->{qc_run_id} } );
    my $crispr_run = HTGT::QC::Config->new->profile( $qc_run->profile )->vector_stage eq "crispr";

    my $results = retrieve_qc_run_results_fast($qc_run, $self, $crispr_run);

    return ( $qc_run, $results );
}

sub pspec_qc_run_summary_results {
    return { qc_run_id => { validate => 'uuid' }, };
}

sub qc_run_summary_results {
    my ( $self, $params ) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_qc_run_summary_results );

    my $qc_run = $self->retrieve( 'QcRun' => { id => $validated_params->{qc_run_id} } );

    return retrieve_qc_run_summary_results($qc_run);
}

sub pspec_qc_run_seq_well_results {
    return {
        qc_run_id  => { validate => 'uuid' },
        plate_name => { validate => 'plate_name' },
        well_name  => { validate => 'well_name' },
        with_eng_seq => { validate => 'boolean', default => 0 },
    };
}

sub qc_run_seq_well_results {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_qc_run_seq_well_results );

    my $with_eng_seq = delete $validated_params->{with_eng_seq};

    my $qc_seq_well = $self->retrieve_qc_run_seq_well($validated_params);

    my ( $seq_reads, $results ) = retrieve_qc_run_seq_well_results($params->{qc_run_id}, $qc_seq_well);

    if($with_eng_seq == 1){
        foreach my $result(@$results){
            my $eng_seq = $self->qc_eng_seq_bioseq({
                            qc_test_result_id => $result->{qc_test_result_id}
                        });
            $result->{eng_seq} = $eng_seq;
        }
    }

    return ( $qc_seq_well, $seq_reads, $results );
}

sub pspec_qc_alignment_result {
    return { qc_alignment_id => { validate => 'integer' }, };
}

sub qc_alignment_result {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_qc_alignment_result );

    my $qc_alignment
        = $self->retrieve( 'QcAlignment' => { 'me.id' => $validated_params->{qc_alignment_id} }, );

    return retrieve_qc_alignment_results( $self->eng_seq_builder, $qc_alignment );
}

sub pspec_qc_seq_read_sequences {
    return {
        qc_run_id  => { validate => 'uuid' },
        plate_name => { validate => 'plate_name' },
        well_name  => { validate => 'well_name' },
        format     => { validate => 'non_empty_string' },
    };
}

sub qc_seq_read_sequences {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_qc_seq_read_sequences );

    my $qc_seq_well = $self->retrieve_qc_run_seq_well(
        { slice_def( $validated_params, qw( plate_name well_name qc_run_id ) ) } );

    return retrieve_qc_seq_read_sequences( $qc_seq_well, $validated_params->{format} );
}

sub pspec_qc_eng_seq_sequence {
    return {
        format            => { validate => 'non_empty_string' },
        qc_test_result_id => { validate => 'integer' },
    };
}

sub qc_eng_seq_sequence {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_qc_eng_seq_sequence );

    my $qc_test_result
        = $self->retrieve( 'QcTestResult' => { id => $validated_params->{qc_test_result_id} }, );

    return retrieve_qc_eng_seq_sequence( $self->eng_seq_builder, $qc_test_result,
        $validated_params->{format} );
}

sub pspec_qc_eng_seq_bioseq {
    return {
        qc_test_result_id => { validate => 'integer' },
    };
}

sub qc_eng_seq_bioseq{
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_qc_eng_seq_bioseq );

    my $qc_test_result
        = $self->retrieve( 'QcTestResult' => { id => $validated_params->{qc_test_result_id} }, );

    return retrieve_qc_eng_seq_bioseq( $self->eng_seq_builder, $qc_test_result );
}

sub pass_to_boolean {
    my ( $self, $pass_or_fail ) = @_;

    return $pass_or_fail =~ /^pass$/i ? '1' : $pass_or_fail =~ /^fail$/i ? '0' : undef;
}

sub pspec_qc_template_from_plate{
    return{
        name                   => { validate => 'existing_plate_name', optional => 1},
        id                     => { validate => 'integer', optional => 1},
        species                => { validate => 'existing_species', optional => 1},
        template_name          => { validate => 'plate_name'},
        cassette               => { validate => 'existing_cassette', optional => 1},
        backbone               => { validate => 'existing_backbone', optional => 1},
        recombinase            => { validate => 'existing_recombinase', optional => 1},
        phase_matched_cassette => { optional => 1 },
    };
}

sub create_qc_template_from_plate {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_qc_template_from_plate );
    $self->log->info( 'Creating qc template plate: ' . $validated_params->{template_name} );

    my $plate = $self->retrieve_plate( { slice_def( $validated_params, qw( name id species ) ) } );

    my $well_hash;

    foreach my $well ($plate->wells->all){
        my $name = $well->name;
        $well_hash->{$name}->{well_id} = $well->id;
        foreach my $override ( qw(cassette recombinase backbone phase_matched_cassette)) {
            $well_hash->{$name}->{$override} = $validated_params->{$override}
                if exists $validated_params->{$override};
        }
    }

    my $template = create_qc_template_from_wells(
        $self,
        {   template_name => $validated_params->{template_name},
            species       => $plate->species_id,
            wells         => $well_hash,
        }
    );

    return $template;
}

sub pspec_qc_template_from_csv{
    return{
        template_name          => { validate => 'plate_name'},
        species                => { validate => 'existing_species'},
        well_data_fh           => { validate => 'file_handle' },
        cassette               => { validate => 'existing_cassette', optional => 1},
        backbone               => { validate => 'existing_backbone', optional => 1},
        recombinase            => { validate => 'existing_recombinase', optional => 1},
        phase_matched_cassette => { optional => 1 },
    };
}

sub create_qc_template_from_csv{
    my ( $self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_qc_template_from_csv );

    my $well_data = parse_csv_file($params->{well_data_fh});

    my $well_hash;

    for my $datum (@{$well_data}){
        # We uppercase all well and source well names so that csv
        # input values are case insensitive
        my $name = uc( $datum->{well_name} );
        $well_hash->{$name}->{well_name} = uc( $datum->{source_well} );
        $well_hash->{$name}->{plate_name} = $datum->{source_plate};

        if ($datum->{cassette}) {
            $well_hash->{$name}->{cassette} = $datum->{cassette};
        } elsif ($params->{cassette}) {
            $well_hash->{$name}->{cassette} = $params->{cassette};
        }

        if ($datum->{backbone}) {
            $well_hash->{$name}->{backbone} = $datum->{backbone};
        } elsif ($params->{backbone}) {
            $well_hash->{$name}->{backbone} = $params->{backbone};
        }

        if ($datum->{phase_matched_cassette}) {
            $well_hash->{$name}->{phase_matched_cassette} = $datum->{phase_matched_cassette};
        } elsif ($params->{phase_matched_cassette}) {
            $well_hash->{$name}->{phase_matched_cassette} = $params->{phase_matched_cassette};
        }

        if ($datum->{recombinase}){
            my @recombinases = split ",", $datum->{recombinase};
            s/\s*//g foreach @recombinases;
            $well_hash->{$name}->{recombinase} = \@recombinases;
        } elsif ($params->{recombinase}) {
            $well_hash->{$name}->{recombinase} = $params->{recombinase};
        }
    }

    my $template = create_qc_template_from_wells(
        $self,
        {   template_name => $validated_params->{template_name},
            species       => $validated_params->{species},
            wells         => $well_hash,
        }
    );

    return $template;
}

sub pspec_list_templates {
    return {
        species       => { validate => 'existing_species' },
        template_name => { validate => 'non_empty_string', optional => 1 },
        page          => { validate => 'integer', optional => 1, default => 1 },
        pagesize      => { validate => 'integer', optional => 1, default => 15 }
    };
}

sub list_templates {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_list_templates );

    my %search = ( 'me.species_id' => $validated_params->{species} );

    if ( $validated_params->{template_name} ) {
        $search{'me.name'}
            = { -like => '%' . sanitize_like_expr( $validated_params->{template_name} ) . '%' };
    }

    my $resultset = $self->schema->resultset('QcTemplate')->search(
        \%search,
        {
            order_by => { -desc => 'created_at' },
            page     => $validated_params->{page},
            rows     => $validated_params->{pagesize}
        }
    );

    return ( [ $resultset->all ], $resultset->pager );
}

# acs 11/03/13 - added optional process type for use with type FINAL_PICK
sub pspec_create_plates_from_qc{
    return {
        qc_run_id    => { validate => 'uuid' },
        plate_type   => { validate => 'existing_plate_type'   },
        created_by   => { validate => 'existing_user' },
        rename_plate => { validate => 'hashref', optional => 1 },
        view_uri     => { validate => 'absolute_url' },
    };
}

sub create_plates_from_qc{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_plates_from_qc);

    my ($qc_run, $results) = $self->qc_run_results({ qc_run_id => $validated_params->{qc_run_id}});
    my @created_plates;

    # Get list of all sequencing plate names
    my @plates = uniq map { $_->{plate_name} } @$results;

    foreach my $plate (@plates){
        # Get results for this plate only, store by well
        my %results_by_well;
        for my $r ( @$results ) {
            next unless $r->{plate_name} eq $plate;
            push @{ $results_by_well{ uc( substr( $r->{well_name}, -3 ) ) } }, $r;
        }

        my $old_name = $plate;
        my $new_name;
        my $rename = $validated_params->{rename_plate};
        $new_name = ($rename and $rename->{$old_name}) ? $rename->{$old_name}
                                                       : $old_name;

        my $plate_from_qc = {
            plate_name      => $new_name,
            orig_name       => $old_name,
            results_by_well => \%results_by_well,
            plate_type      => $validated_params->{plate_type},
            qc_template_id  => $qc_run->qc_template->id,
            created_by      => $validated_params->{created_by},
            view_uri        => $validated_params->{view_uri},
            qc_run_id       => $validated_params->{qc_run_id},
        };

        my $plate = $self->create_plate_from_qc($plate_from_qc,);

        push @created_plates, $plate;
    }
    return @created_plates;
}

# acs 11/03/13 - added optional process type for use with type FINAL_PICK
sub pspec_create_plate_from_qc{
    return {
        plate_name   => { validate => 'non_empty_string' },
        orig_name    => { validate => 'non_empty_string' },
        plate_type   => { validate => 'existing_plate_type'   },
        results_by_well => { validate => 'hashref' },
        qc_template_id  => { validate => 'integer' },
        created_by   => { validate => 'existing_user'},
        view_uri     => { validate => 'absolute_url'},
        qc_run_id    => { validate => 'uuid'},
    };
}

sub create_plate_from_qc{
    my ($self, $params) = @_;

    DEBUG "Creating plate ".$params->{plate_name};

    my $validated_params = $self->check_params( $params, $self->pspec_create_plate_from_qc );

    my $template = $self->retrieve_qc_template({ id => $validated_params->{qc_template_id}});
    my $results_by_well = $validated_params->{results_by_well};



    my @new_wells;

    while (my ($well, $results) = each %$results_by_well) {
        my $best = $results->[0];
        my $name = '';
        if (defined $best->{design_id}) {
            $name = 'design_id';
        } elsif (defined $best->{crispr_id}) {
            $name = 'crispr_id';
        }

        if( $name ){
            my $id = $best->{$name};
            DEBUG "Found $name $id for well $well";
            my $template_well;

            if ( (defined $best->{'expected_'.$name}) and ($id eq $best->{'expected_'.$name}) ){
                # Fetch source well from template well with same location
                DEBUG "Found $name $id at expected location on template";
                ($template_well) = $template->qc_template_wells->search({ name => $well });
            }
            else{
                # See if design_id was expected in some other well on the template,
                # and get source for that
                DEBUG "Looking for $name $id at different template location";
                ($template_well) = grep { $_->as_hash->{eng_seq_params}->{$name} eq $id }
                                      $template->qc_template_wells->all;
                die "Could not find template well for $name $id" unless $template_well;
            }
            my $source_well = $template_well->source_well
                or die "No source well linked to template well ".$template_well->id;

            # Store new well params
            my %well_params = (
                well_name => $well,
                parent_plate => $source_well->plate->name,
                parent_well  => $source_well->name,
                accepted     => $best->{pass},
            );

            # Identify reagent overrides from QC wells
            if ( my $cassette = $template_well->qc_template_well_cassette){
                $well_params{cassette} = $cassette->cassette->name;
            }

            if ( my $backbone = $template_well->qc_template_well_backbone){
                $well_params{backbone} = $backbone->backbone->name;
            }

            if ( my @recombinases = $template_well->qc_template_well_recombinases->all ){
                $well_params{recombinase} = [ map { $_->recombinase_id } @recombinases ];
            }

            $well_params{process_type} = infer_qc_process_type(
                \%well_params,
                $validated_params->{plate_type},
                $source_well->plate_type,
            );

            push @new_wells, \%well_params;
        }
        else{
            # Decided not to create empty wells
            # If we created empty wells they would either need dummy input process,
            # or we would have to remove the constraint that wells have input process
            DEBUG "No design or crispr for well $well";
        }
    }

    my $plate = $self->create_plate({
        name    => $validated_params->{plate_name},
        species => $template->species->id,
        type    => $validated_params->{plate_type},
        wells   => \@new_wells,
        created_by => $validated_params->{created_by},
    });

    $self->_add_well_qc_sequencing_results({
        plate           => $plate,
        orig_name       => $validated_params->{orig_name},
        results_by_well => $results_by_well,
        view_uri        => $validated_params->{view_uri},
        qc_run_id       => $validated_params->{qc_run_id},
    });

    return $plate;
}

sub pspec_add_well_qc_sequencing_results{
    return{
        plate   => { },
        orig_name       => { validate => 'non_empty_string' },
        results_by_well => { validate => 'hashref' },
        view_uri        => { validate => 'absolute_url' },
        qc_run_id       => { validate => 'uuid' },
    };
}

sub _add_well_qc_sequencing_results{
    my ($self, $params) = @_;

    my $v_params = $self->check_params($params, $self->pspec_add_well_qc_sequencing_results);

    my $plate = $v_params->{plate};

    foreach my $well ($plate->wells->all){
        my $results = $v_params->{results_by_well}->{$well->name};
        my $best = $results->[0];

        my $view_params = {
            well_name  => lc($well->name),
            plate_name => $v_params->{orig_name},
            qc_run_id  => $v_params->{qc_run_id},
        };

        my $url = URI->new($v_params->{view_uri});
        $url->query_form($view_params);

        my $qc_result = {
            well_id         => $well->id,
            valid_primers   => join( q{,}, @{ $best->{valid_primers} } ),
            mixed_reads     => @{ $results } > 1 ? 1 : 0,
            pass            => $best->{pass} ? 1 : 0,
            test_result_url => $url->as_string,
            created_by      => $plate->created_by->name,
        };
        $self->create_well_qc_sequencing_result($qc_result);
    }
    return;
}

sub pspec_create_sequencing_project{
    return {
        name            => { validate => 'non_empty_string' },
        template        => { validate => 'existing_qc_template_id', rename => 'qc_template_id', optional => 1},
        user_id         => { validate => 'existing_user_id', rename => 'created_by_id' },
        sub_projects    => { validate => 'integer' },
        qc              => { validate => 'boolean', optional => 1},
        is_384          => { validate => 'boolean', optional => 1},
        created_at      => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        primers         => { optional => 1 },
        qc_type         => { optional => 1 },
    };
}

sub create_sequencing_project {
    my ($self, $params) = @_;
    DEBUG "Creating sequencing project ".$params->{name};
    try {
        if($params->{qc}){
            unless ($params->{qc_type} eq 'Crispr') {
                my $template_id = $self->retrieve_qc_template({ name => $params->{template} })->{_column_data}->{id};
                $params->{template} = $template_id;
            }
        }
    } catch {
        $self->throw( InvalidState => {
            message => 'QC template: ' . $params->{template}
                  . ' does not exist'
            }
        );
        return;
    };

    my $validated_params = $self->check_params( $params, $self->pspec_create_sequencing_project);

    #Create if the project name already exists
    if ( $self->schema->resultset('SequencingProject')->find({ name => $validated_params->{name} }) ) {
        $self->throw( InvalidState => {
            message => 'Sequencing project name: ' . $validated_params->{name}
                  . ' already exists'
            }
        );
        return;
    }

    # Otherwise, create a new project
    my $seq_project = $self->schema->resultset('SequencingProject')->create( { slice_def $validated_params, qw( name created_by_id created_at sub_projects qc is_384) } );
    $self->log->debug('created sequencing project ' . $seq_project->name . ' with id ' . $seq_project->id );

    if ($validated_params->{primers}){
        my @primers = @{$validated_params->{primers}};
        foreach my $primer (@primers){
            my $check_primer = $self->schema->resultset('SequencingPrimerType')->find({ id => $primer },{ distinct => 1 });

            if($check_primer) {
                create_sequencing_relations($self, $primer, $seq_project, 'sequencing_project_primers', 'primer_id');
            }
            else {
                $self->throw( InvalidState => {
                    message => 'Primer : ' . $primer
                        . ' was not found in the sequencing primer types table.'
                    }
                );
            }
        }
    }
    if ($validated_params->{qc_template_id}){
        create_sequencing_relations($self, $validated_params->{qc_template_id}, $seq_project, 'sequencing_project_templates', 'qc_template_id');
    }
    return;
 }

 sub create_sequencing_relations {
    my ($self, $data, $seq_proj, $table, $column) = @_;
    my $seq_relation;
    try{
        $seq_relation = $seq_proj->create_related(
                $table => {
                $column         => $data,
                seq_project_id  => $seq_proj->{_column_data}->{id},
            }
        );
    } catch {
        $self->throw( InvalidState => {
            message => 'Could not create relation in ' . $table . ' table for id: '. $seq_proj->{_column_data}->{id}
            }
        );

    };

    if( $seq_relation->{_column_data} ) {
        $self->log->debug('created sequencing relation. table: ' . $table . ' id: ' . $seq_relation->{_column_data}->{seq_project_id} . ' foreign key: ' . $data );
    }
    return;
 }

sub pspec_update_sequencing_project{
    return {
        id          => { validate => 'integer', optional =>  1},
        name        => { validate => 'non_empty_string', optional => 1},
        abandoned   => { validate => 'boolean', optional => 1},
        available_results => { validate => 'boolean', optional => 1},
        results_imported_date => { validate => 'date_time', post_filter => 'parse_date_time', optional => 1 },
        REQUIRE_SOME => { name_or_id => [ 1, qw( name id ) ] },
    };
}

 sub update_sequencing_project {
    my ($self, $params) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_update_sequencing_project );

    my $seq_proj = $self->retrieve_sequencing_project( { slice_def( $validated_params, qw( name id ) ) });

    my $update_params = { slice_def( $validated_params, qw( abandoned available_results results_imported_date ) ) };
    $seq_proj->update( $update_params );

    return;
}

sub pspec_retrieve_sequencing_project{
    return {
        id          => { validate => 'integer', optional =>  1},
        name        => { validate => 'non_empty_string', optional => 1},
        REQUIRE_SOME => { name_or_id => [ 1, qw( name id ) ] },
    }
}

sub retrieve_sequencing_project{
    my ($self, $params) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_sequencing_project );

    my $project_params = { slice_def( $validated_params, qw( name id ) ) };
    return $self->retrieve( SequencingProject => $project_params );
}

sub pspec_create_sequencing_project_backup{
    return {
        seq_project_id  => { validate => 'integer'},
        directory       => { validate => 'non_empty_string'},
        creation_date   => { validate => 'psql_date'},
    }
}


sub create_sequencing_project_backup{
    my ($self, $params, $name) = @_;
    my $seq_rs = $self->schema->resultset('SequencingProject')->find({
        name => $name
    });
    if ($seq_rs) {
        $params->{seq_project_id} = $seq_rs->as_hash->{id};
        my $validated_params = $self->check_params( $params, $self->pspec_create_sequencing_project_backup );

        #    my $seq_project_backup = $seq_rs->create_related(
            #SequencingProjectBackup => {
                #directory       => $validated_params->{directory},
            #creation_date   => $validated_params->{creation_date},
            #});
        my $seq_project_backup = $self->schema->resultset('SequencingProjectBackup')->create( { slice_def $validated_params, qw( seq_project_id directory creation_date ) } );

        $self->log->debug('created sequencing project backup ' . $seq_project_backup->directory . ' with id ' . $seq_project_backup->id );
    } else {
        $self->log->debug("$name not found in Sequencing Projects");
    }
    return;
}
1;

__END__
