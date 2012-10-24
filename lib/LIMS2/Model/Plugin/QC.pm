package LIMS2::Model::Plugin::QC;

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
);
use LIMS2::Model::Util::QCResults qw(
    retrieve_qc_run_results
    retrieve_qc_run_summary_results
    retrieve_qc_run_seq_well_results
    retrieve_qc_alignment_results
    retrieve_qc_seq_read_sequences
    retrieve_qc_eng_seq_sequence
    build_qc_runs_search_params
);
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use namespace::autoclean;

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
        $qc_template->create_related(
            qc_template_wells => {
                name          => $well_name,
                qc_eng_seq_id => $eng_seq_id,
                source_well_id => $source_for_well{$well_name},
            }
        );
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

    my $search_params = build_qc_template_search_params( $validated_params );

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
        $self->throw( InvalidState => {
              message => 'Template ' . $template->id
                      . ' has been used in one or more QC runs, so cannot be deleted'
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

    my $results = retrieve_qc_run_results($qc_run);

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
    };
}

sub qc_run_seq_well_results {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_qc_run_seq_well_results );
    my $qc_seq_well = $self->retrieve_qc_run_seq_well($validated_params);

    my ( $seq_reads, $results ) = retrieve_qc_run_seq_well_results($qc_seq_well);

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

sub pass_to_boolean {
    my ( $self, $pass_or_fail ) = @_;

    return $pass_or_fail =~ /^pass$/i ? '1' : $pass_or_fail =~ /^fail$/i ? '0' : undef;
}

sub pspec_qc_template_from_csv{
	return{
		template_name => { validate => 'plate_name'},
		species       => { validate => 'existing_species'},
		well_data_fh  => { validate => 'file_handle' },
	};
}

sub create_qc_template_from_csv{
    my ( $self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_qc_template_from_csv );

	my $well_data = parse_csv_file($params->{well_data_fh});

	my $well_hash;

	for my $datum (@{$well_data}){
		my $name = $datum->{well_name};
        $well_hash->{$name}->{well_name} = $datum->{source_well};
        $well_hash->{$name}->{plate_name} = $datum->{source_plate};
        # FIXME: handle optional cassette, backbone, recombinase?
	}

	my $template = $self->create_qc_template_from_wells({
		template_name => $params->{template_name},
		species       => $params->{species},
		wells         => $well_hash,
	});

    return $template;
}

sub pspec_qc_template_from_wells {
    return {
        template_name => { validate => 'plate_name' },
        species       => { validate => 'existing_species' },
        wells         => { validate => 'hashref' },
    };
}

sub create_qc_template_from_wells{
	my ($self, $params) = @_;

	my $validated_params = $self->check_params( $params, $self->pspec_qc_template_from_wells );

	# die if template name already exists
	my $existing = $self->retrieve_qc_templates({ name => $params->{template_name} });
	if (@$existing){
		die "QC template ".$params->{template_name}." already exists. Cannot use this plate name.";
	}

	my $wells;

	for my $name (keys %{ $validated_params->{wells} }){

        my $datum = $validated_params->{wells}->{$name};

		my $well_params = { slice_def( $datum, qw( plate_name well_name well_id ) ) };

		my ($method, $source_well_id, $esb_params) = $self->generate_well_eng_seq_params($well_params);

		$wells->{$name}->{eng_seq_id}     = $esb_params->{display_id};
		$wells->{$name}->{well_name}      = $params->{template_name}."_$name";
		$wells->{$name}->{eng_seq_method} = $method;
		$wells->{$name}->{eng_seq_params} = $esb_params;
		$wells->{$name}->{source_well_id} = $source_well_id;
	}

	my $template = $self->find_or_create_qc_template({
		name    => $params->{template_name},
		species => $params->{species},
		wells   => $wells,
	});

    return $template;
}
1;

__END__
