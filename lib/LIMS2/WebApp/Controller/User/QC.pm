package LIMS2::WebApp::Controller::User::QC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::QC::VERSION = '0.494';
}
## use critic


use Moose;
use namespace::autoclean;
use HTTP::Status qw( :constants );
use Scalar::Util qw( blessed );
use LWP::UserAgent;
use JSON qw( encode_json decode_json );
use Try::Tiny;
use Config::Tiny;
use Data::Dumper;
use List::MoreUtils qw( uniq any firstval );
use HTGT::QC::Config;
use HTGT::QC::Run;
use HTGT::QC::Util::ListLatestRuns;
use HTGT::QC::Util::KillQCFarmJobs;
use HTGT::QC::Util::CreateSuggestedQcPlateMap qw( create_suggested_plate_map get_sequencing_project_plate_names get_parsed_reads);
use LIMS2::Util::ESQCUpdateWellAccepted;
use LIMS2::Model::Util::QCPlasmidView qw( add_display_info_to_qc_results );
use IPC::System::Simple qw( capturex );
use Path::Class;
use LIMS2::Model::Util::ImportSequencing qw( get_seq_file_import_date );

use HTGT::QC::Util::SubmitQCFarmJob::Vector;
use HTGT::QC::Util::SubmitQCFarmJob::ESCell;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::UI::QC - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

has qc_config => (
    is      => 'ro',
    isa     => 'HTGT::QC::Config',
    default => sub{ HTGT::QC::Config->new({ is_lims2 => 1 }) },
    lazy    => 1,
);

has latest_run_util => (
    is      => 'ro',
    isa     => 'HTGT::QC::Util::ListLatestRuns',
    lazy_build => 1,
);

sub _build_latest_run_util {
    my $self = shift;
    my $lustre_server = $ENV{ FILE_API_URL }
        or die "FILE_API_URL environment variable not set";

    return HTGT::QC::Util::ListLatestRuns->new( {
        config => $self->qc_config,
        file_api_url => $lustre_server,
    } );
}

## no critic(ProtectPrivateSubs)
sub _list_all_profiles {
    my ( $self, $es_cell ) = @_;

    my @profiles;
    if ( $es_cell ) {
        my $config = $self->qc_config->_config->{profile} || {};

        while ( my ( $profile, $data ) = each %{ $config } ) {
            next unless $data->{vector_stage} eq 'allele';

            push @profiles, $profile;
        }
    }
    else {
        @profiles = sort $self->qc_config->profiles;
    }

    return \@profiles;
}
## use critic

sub index :Path( '/user/qc_runs' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $params = $c->request->params;

    if ( defined $params->{show_all} ) {
        $params = {}; #this will get everything
    }

    #filter isnt in the pspec so remove it to avoid an error
    delete $params->{filter} if defined $params->{filter};

    $params->{species} ||= $c->session->{selected_species};

    my ( $qc_runs, $pager ) = $c->model('Golgi')->retrieve_qc_runs( $params );

    my $pageset = LIMS2::WebApp::Pageset->new(
        {
            total_entries    => $pager->total_entries,
            entries_per_page => $pager->entries_per_page,
            current_page     => $pager->current_page,
            pages_per_set    => 5,
            mode             => 'slide',
            base_uri         => $c->request->uri
        }
    );

    $c->stash(
        qc_runs  => $qc_runs,
        pageset  => $pageset,
        profiles => $c->model('Golgi')->list_profiles,
    );
    return;
}

sub view_qc_run :Path( '/user/view_qc_run' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my ( $qc_run, $results ) = $c->model( 'Golgi' )->qc_run_results(
        { qc_run_id => $c->request->params->{qc_run_id} } );

    #see if its a crispr run or not so we can display the right fields
    my $crispr = HTGT::QC::Config->new->profile( $qc_run->profile )->vector_stage eq "crispr";

    # calculate if the accept ep_pick well button should be shown
    my %es_cell_profiles = map { $_ => 1 } @{ $self->_list_all_profiles( 'es_cell' ) };
    my $show_accept_ep_pick_well_button = 0;
    if (   exists $es_cell_profiles{ $qc_run->profile }
        && $qc_run->qc_template->parent_plate_type eq 'EP_PICK'
        && $qc_run->qc_template->species_id eq 'Mouse' )
    {
        $show_accept_ep_pick_well_button = 1;
    }

    $c->stash(
        qc_run  => $qc_run->as_hash,
        results => $results,
        crispr  => $crispr,
        show_accept_ep_pick_well_button => $show_accept_ep_pick_well_button,
    );
    return;
}

sub delete_qc_run :Path( '/user/delete_qc_run' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    my $params = $c->request->params;

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi')->delete_qc_run( { id => $params->{id} } );
                $c->flash->{success_msg} = 'Deleted QC Run ' . $params->{id};
                $c->res->redirect( $c->uri_for('/user/qc_runs') );
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while deleting QC run: ' . $_;
                $c->model('Golgi')->txn_rollback;
                $c->res->redirect( $c->uri_for('/user/view_qc_run', { id => $params->{id} }) );
            };
        }
    );
    return;
}

sub view_qc_result :Path('/user/view_qc_result') Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );
    my ( $qc, $res ) = $c->model( 'Golgi' )->qc_run_results(
        { qc_run_id => $c->req->params->{qc_run_id} } );
    my ( $qc_seq_well, $seq_reads, $results ) = $c->model('Golgi')->qc_run_seq_well_results(
        {
            qc_run_id  => $c->req->params->{qc_run_id},
            plate_name => $c->req->params->{plate_name},
            well_name  => uc( $c->req->params->{well_name} ),
            with_eng_seq => 1,
        }
    );

    my $qc_run = $c->model('Golgi')->retrieve_qc_run( { id => $c->req->params->{qc_run_id} } );

    # Find template well which is best match to sequencing result
    my $best = $results->[0];

    my $template_well = _find_best_match_template_well($c, $qc_seq_well, $qc_run->qc_template, $best);

    my @genotyping_primers;
    my @crispr_primers;

    if($template_well){
        $c->log->debug("Template well: ".$template_well->name);
        @genotyping_primers = map { $_->genotyping_primer }
                              $template_well->qc_template_well_genotyping_primers->search({ qc_run_id => $qc_run->id });
        @crispr_primers = map { $_->crispr_primer }
                              $template_well->qc_template_well_crispr_primers->search({ qc_run_id => $qc_run->id });
        $c->log->debug("crispr primers: ".Dumper(@crispr_primers));
    }

    my $is_es_qc = grep { $_ eq $qc_run->profile } @{ $self->_list_all_profiles('es_cell') };

    my $error_msg;
    unless($is_es_qc){
        # Create start and end coords for items to be drawn in plasmid view
        # Adds result->{display_alignments} which is an array of read alignments
        # and result->{alignment_targets} which is a hash of target regions by primer
        # A primer read is required to align to the target region in order to pass
        try{
            add_display_info_to_qc_results($results,$c->log,$c->model('Golgi'));
        }
        catch{
            $error_msg = "Failed to generate plasmid view: $_";
        };
    }
    my $species_id = $c->session->{selected_species};
    my $gene = $c->model('Golgi')->find_gene( { search_term => $c->req->params->{gene_symbol}, species => $species_id } );
    $c->stash(
        qc_run      => $qc_run->as_hash,
        qc_seq_well => $qc_seq_well,
        results     => $results,
        seq_reads   => [ sort { $a->primer_name cmp $b->primer_name } @{ $seq_reads } ],
        genotyping_primers => \@genotyping_primers,
        crispr_primers => \@crispr_primers,
        qc_template_well => $template_well,
        error_msg   => $error_msg,
        gene => $gene,
    );

    return;
}

sub _find_best_match_template_well{
    my ($c, $qc_seq_well, $template, $best) = @_;

    my $matching_well;

    if (     (defined $best->{design_id})
         and (defined $best->{expected_design_id})
         and ($best->{design_id} eq $best->{expected_design_id}) ){
        # Best design ID matches expected design ID so
        # matches template well with same location as seq well
        $c->log->debug("Found design_id at expected location on template");
        ($matching_well) = $template->qc_template_wells->search({ name => $qc_seq_well->name });
    }
    elsif( my $design_id = $best->{design_id} ){
        # See if design_id was expected in some other well on the template,
        # and get source for that
        $c->log->debug("Looking for design_id $design_id at different template location");
        my @design_template_wells = grep { $_->as_hash->{eng_seq_params}->{design_id} eq $design_id }
                                  $template->qc_template_wells->all;
        if(@design_template_wells > 1){
            # Narrow down by crispr ID if we can
            if (my $crispr_id = $best->{crispr_id}){
                $c->log->debug("Multiple matches for design_id $design_id, narrowing by crispr_id $crispr_id");
                ($matching_well) = grep { $_->as_hash->{eng_seq_params}->{crispr_id} eq $crispr_id }
                                   @design_template_wells;
            }
            else{
                # Or just return first well found matching design
                $matching_well = $design_template_wells[0];
            }
        }
        else{
            $matching_well = $design_template_wells[0];
        }
    }
    elsif(my $crispr_id = $best->{crispr_id}){
        $c->log->debug("Best result has no design id, looking for crispr_id $crispr_id in template");
        if(     (defined $best->{expected_crispr_id})
            and ($crispr_id = $best->{expected_crispr_id})){
            $c->log->debug("Found crispr_id $crispr_id at expected location on template");
            ($matching_well) = $template->qc_template_wells->search({ name => $qc_seq_well->name });
        }
        else{
            ($matching_well) = grep { $_->as_hash->{eng_seq_params}->{crispr_id} eq $crispr_id }
                               $template->qc_template_wells->all;
        }
    }

    if($best->{crispr_id} or $best->{design_id}){
        die "Could not find template well for result with design "
        .$best->{design_id}." and crispr ".$best->{crispr_id} unless $matching_well;
    }
    return $matching_well;
}

sub qc_seq_reads :Path( '/user/qc_seq_reads' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $format = $c->req->params->{format} || 'fasta';

    my ( $filename, $formatted_seq ) = $c->model('Golgi')->qc_seq_read_sequences(
        {
            qc_run_id  => $c->req->params->{qc_run_id},
            plate_name => $c->req->params->{plate_name},
            well_name  => uc( $c->req->params->{well_name} ),
            format     => $format,
        }
    );

    $c->response->content_type( 'chemical/seq-na-fasta' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
    return;
}

sub qc_eng_seq :Path( '/user/qc_eng_seq' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $format = $c->req->params->{format} || 'genbank';

    my ( $filename, $formatted_seq ) = $c->model('Golgi')->qc_eng_seq_sequence(
        {
            qc_test_result_id => $c->req->params->{qc_test_result_id},
            format => $format
        }
    );

    $c->response->content_type( 'chemical/seq-na-genbank' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
    return;
}

sub view_qc_alignment :Path('/user/view_qc_alignment') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $alignment_data = $c->model('Golgi')->qc_alignment_result(
        { qc_alignment_id => $c->req->params->{qc_alignment_id} }
    );

    $c->stash(
        data       => $alignment_data,
        qc_run_id  => $c->req->params->{qc_run_id},
        plate_name => $c->req->params->{plate_name},
        well_name  => uc( $c->req->params->{well_name} ),
    );
    return;
}

sub submit_new_qc :Path('/user/submit_new_qc') :Args(0) {
	my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    $c->stash->{profiles} = $self->_list_all_profiles;
    $c->stash->{run_type} = 'vector';

    my $requirements = {
    	template_plate      => { validate => 'existing_qc_template_name'},
    	profile             => { validate => 'non_empty_string'},
    	sequencing_project  => { validate => 'non_empty_string'},
    	submit_initial_info => { optional => 0 },
    };

	# Store form values
	$c->stash->{sequencing_project} = [ $c->req->param('sequencing_project') ];
	$c->stash->{template_plate} = $c->req->param('template_plate');
	$c->stash->{profile} = $c->req->param('profile');

	my $run_id;
	if ( $c->req->param( 'submit_initial_info' ) ){
		try{
			# validate input params before doing anything else
			$c->model( 'Golgi' )->check_params( $c->req->params, $requirements );

            # fetch the template type to display to user
            my $template = $c->model('Golgi')->retrieve_qc_template({ name => $c->req->param('template_plate') });

		    my $plate_map = create_suggested_plate_map(
		        $c->stash->{sequencing_project},
	            $c->model( 'Golgi' )->schema,
	            "Plate",
	        );
		    $c->stash->{plate_map} = $plate_map;
		    $c->stash->{plate_map_request} = 1;
		}
		catch{
			$c->stash( error_msg => "QC plate map generation failed with error $_" );
			return;
		};
	}
	elsif ( $c->req->param('launch_qc') ){

        my $plate_map = $self->_build_plate_map( $c );
        my $validated_plate_map = $self->_validate_plate_map( $c, $plate_map, $c->stash->{sequencing_project} );

        unless ( $validated_plate_map ) {
            $c->stash( plate_map => $plate_map );
            $c->stash( plate_map_request => 1 );
            return;
        }

		if ( $run_id = $self->_launch_qc( $c, $validated_plate_map ) ){
			$c->stash->{run_id} = $run_id;
			$c->stash->{success_msg} = "Your QC job has been submitted with ID $run_id. "
			                           ."Go to <a href=\"".$c->uri_for('/user/latest_runs')."\">Latest Runs</a>"
			                           ." to see the progress of your job";
		}
	}
	return;
}

sub submit_es_cell :Path('/user/submit_es_cell') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    #template plate is always EPD plate with a T added to the start
    $c->req->params->{epd_plate} = $self->_clean_input( $c->req->param('epd_plate') );
    my $template_plate = 'T' . $c->req->param('epd_plate');
    $c->req->params->{template_plate} = $template_plate;

    $c->stash->{profiles} = $self->_list_all_profiles( 'es_cell' );
    $c->stash->{run_type} = 'es_cell';

    my $requirements = {
        template_plate      => { validate => 'existing_qc_template_name'},
        profile             => { validate => 'non_empty_string'},
        epd_plate           => { validate => 'non_empty_string'},
        submit_initial_info => { optional => 0 },
    };

    # Store form values
    $c->stash->{epd_plate} = $self->_clean_input( $c->req->param('epd_plate') );
    $c->stash->{profile} = $c->req->param('profile');
    $c->stash->{template_plate} = $c->req->param('template_plate');

    my $run_id;
    if ( $c->req->param( 'submit_initial_info' ) ) {
        try{
            # validate input params before doing anything else
            $c->model( 'Golgi' )->check_params( $c->req->params, $requirements );
            # my $template_check = $c->model( 'Golgi' )->schema->resultset('QcTemplate')->find(
            #     { name => $c->stash->{template_plate} }
            # );
            # if (!$template_check) {
            #     die "Template plate ".$c->stash->{template_plate}." does not exist";
            # }
            $c->stash->{epd_plate_request} = 1;
        }
        catch{
            $c->stash( error_msg => "QC plate map generation failed with error $_" );
            return;
        };
    }
    elsif ( $c->req->param('launch_qc') ){

        if ( $run_id = $self->_launch_es_cell_qc( $c ) ){

            $c->stash->{run_id} = $run_id;
            $c->stash->{success_msg}
                = "Your QC job has been submitted with ID $run_id. "
                . "Go to <a href=\"".$c->uri_for('/user/latest_runs')."\">Latest Runs</a> "
                . "to see the progress of your job";
        }
    }

    return;
}

sub _launch_qc{
    my ($self, $c, $plate_map ) = @_;

    $plate_map ||= {};

    my $params = {
        profile             => $c->stash->{ profile },
        template_plate      => $c->stash->{ template_plate },
        sequencing_projects => $c->stash->{ sequencing_project } ,
        plate_map           => $plate_map,
        created_by          => $c->user->name,
        species             => $c->session->{ selected_species },
        run_type            => $c->stash->{run_type},
    };

    my $run_id = $self->_run_qc($c, $params);

    return $run_id;
}

sub _launch_es_cell_qc{
    my ($self, $c ) = @_;

    my $params = {
        profile             => $c->stash->{ profile },
        template_plate      => $c->stash->{ template_plate },
        sequencing_projects => [ $c->stash->{ epd_plate } ],
        created_by          => $c->user->name,
        species             => $c->session->{ selected_species },
        run_type            => $c->stash->{run_type},
    };

    my $run_id = $self->_run_qc($c, $params);

    return $run_id;
}

sub _run_qc{

    my ($self, $c, $params) = @_;

    my $qc_data = $params;

    if ( $qc_data->{ run_type } eq 'es_cell' ) {
        my $epd_plate_name = shift @{ $qc_data->{ sequencing_projects } };
        $c->log->debug( "Retrieving sequencing projects for epd plate $epd_plate_name" );

        my @all_projects = $self->_get_trace_projects( $epd_plate_name );

        die "Couldn't find any sequencing projects for $epd_plate_name"
            unless @all_projects;

        $c->log->debug( "Found the following sequencing projects: " . join ", ", @all_projects );

        $qc_data->{ sequencing_projects } = \@all_projects;
    }

    my $run_id;
    # Attempt to launch QC job
    try {

        my $config = HTGT::QC::Config->new( { is_lims2 => 1 } );

        my %run_params = (
            config              => $config,
            profile             => $qc_data->{ profile },
            template_plate      => $qc_data->{ template_plate },
            sequencing_projects => $qc_data->{ sequencing_projects },
            run_type            => $qc_data->{ run_type },
            created_by          => $qc_data->{ created_by },
            species             => $qc_data->{ species },
            persist             => 1,
        );

        my %run_types = (
            es_cell   => "ESCell",
            vector    => "Vector",
        );

        die $qc_data->{ run_type } . " is not a valid run type."
            unless exists $run_types{ $qc_data->{ run_type } };

        my $submit_qc_farm_job = "HTGT::QC::Util::SubmitQCFarmJob::" . $run_types{ $qc_data->{ run_type } };

        #add any additional type specific modifications in this if
        if ( $qc_data->{ run_type } eq "vector" ) {
            #only vector needs a plate_map.
            $run_params{ plate_map } = $qc_data->{ plate_map };
        }


        my $run = HTGT::QC::Run->init( %run_params );
        $run_id = $run->id or die "No QC run ID generated"; #this is pretty pointless; we always get one.

        $submit_qc_farm_job->new( { qc_run => $run } )->run_qc_on_farm();

    }
    catch {
        $c->log->warn( $_ );
    };

    return $run_id;
}

sub _get_trace_projects {
    my ( $self, $epd_plate_name ) = @_;
    return @{ HTGT::QC::Util::ListTraceProjects->new()->get_trace_projects( $epd_plate_name ) };
}

sub latest_runs :Path('/user/latest_runs') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    $c->stash( latest => $self->latest_run_util->get_latest_run_data );

    return;
}

sub qc_farm_error_rpt :Path('/user/qc_farm_error_rpt') :Args(1) {
    my ( $self, $c, $params ) = @_;

    $c->assert_user_roles( 'read' );

    my ( $qc_run_id, $last_stage ) = $params =~ /^(.+)___(.+)$/;
    my $config = $self->qc_config;

    # Fetches error file via file server api
    my @error_file_content = $self->latest_run_util->fetch_error_file($qc_run_id, $last_stage);

    $c->stash( run_id => $qc_run_id );
    $c->stash( last_stage => $last_stage );
    $c->stash( error_content => \@error_file_content );

    return;
}

sub kill_farm_jobs :Path('/user/kill_farm_jobs') :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    $c->assert_user_roles( 'edit' );

    my @jobs_killed = $self->_kill_lims2_qc($qc_run_id, $c);

    if ( @jobs_killed ) {
        $c->flash( info_msg => "Killing farm jobs (" . join( ' ', @jobs_killed ) . ") from QC run $qc_run_id" );
    }
    else {
        my $error = $c->stash->{ error_msg } . "<br/>Failed to kill farm jobs."; #dont overwrite other error
        $c->flash( error_msg => $error );
    }

    $c->res->redirect( $c->uri_for('/user/latest_runs') );
    return;
}

sub _kill_lims2_qc{
    my ( $self, $qc_run_id, $c ) = @_;

    my $job_ids = [];

    try{
        my $killer = HTGT::QC::Util::KillQCFarmJobs->new({
            config    => $self->qc_config,
            qc_run_id => $qc_run_id,
        });
        $job_ids = $killer->kill_unfinished_farm_jobs();
    }
    catch{
        $c->log->warn( $_ );
        $c->stash->{error_msg} = $_;
    };

    return @{ $job_ids };
}

sub _build_plate_map {
    my ( $self, $c ) = @_;
    my $params = $c->request->params;
    my $sequencing_projects = $c->request->params->{ 'sequencing_project' };
    $sequencing_projects = [ $sequencing_projects ] unless ref $sequencing_projects;

    my @map_params = grep{ $_ =~ /_map$/ } keys %{ $params };

    my %plate_map;
    foreach my $map_key ( @map_params ) {
        my $map = $self->_clean_input( $params->{$map_key});
        next unless $map;
        my $plate_name = substr( $map_key,0, -4 );

        $plate_map{$plate_name} = $map;
    }

    return \%plate_map;
}

sub _validate_plate_map {
    my ( $self, $c, $plate_map, $sequencing_projects ) = @_;
    my @errors;

    my $seq_project_plate_names = get_sequencing_project_plate_names( $sequencing_projects );

    for my $plate_name ( @{ $seq_project_plate_names } ) {
        unless ( defined $plate_map->{$plate_name} ) {
            push @errors, "$plate_name not defined in plate_map";
        }

        my $canonical_plate_name = $plate_map->{$plate_name};
        unless ( $canonical_plate_name ) {
            push @errors, "$plate_name has no new plate_name mapped to it";
        }
    }

    if ( @errors ) {
        $c->stash( error_msg => join '<br />', @errors );
        return;
    }

    return $plate_map;
}

sub _clean_input {
    my ( $self, $value ) = @_;
    return unless $value;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;

    return $value;
}

sub create_template_plate :Path('/user/create_template_plate') :Args(0){
	my ($self, $c) = @_;

    $c->assert_user_roles( 'edit' );

    # Store form values
    foreach my $param qw(template_plate source_plate cassette backbone phase_matched_cassette){
    	$c->stash->{$param} = $c->req->param($param);
    }
    $c->stash->{recombinase} = [ $c->req->param('recombinase') ];
    my $template_name = $c->req->param('template_plate');

    $self->_populate_create_template_menus($c);

	if ( $c->req->param('create_from_plate')){
		try{
			unless($template_name){
				die "You must provide a name for the template plate";
			}
			unless($c->req->param('source_plate')){
				die "You must provide a source plate";
			}

            my %overrides = map { $_ => $c->req->param($_) }
                            grep { $c->req->param($_) }
                            qw( cassette backbone phase_matched_cassette);
            $overrides{recombinase} = [ $c->req->param('recombinase') ];

            my $template;
            $c->model('Golgi')->txn_do(
			    sub{
			    	$template = $c->model('Golgi')->create_qc_template_from_plate({
				        name => $c->req->param('source_plate'),
				        template_name => $c->req->param('template_plate'),
				        %overrides,
			        });
			    }
            );

			my $view_uri = $c->uri_for("/user/view_template",{ id => $template->id});
			$c->stash->{success_msg} = "Template <a href=\"$view_uri\">$template_name</a> was successfully created";
		}
		catch{
			$c->stash->{error_msg} = "Sorry, template plate creation failed with error: $_" ;
		};
	}
	elsif( $c->req->param('create_from_csv')){
		try{
			unless($template_name){
				die "You must provide a name for the template plate";
			}

			my $well_data = $c->request->upload('datafile');

			unless ($well_data){
				die "You must select a csv file containing the well list";
			}

            my %overrides = map { $_ => $c->req->param($_) }
                            grep { $c->req->param($_) }
                            qw( cassette backbone phase_matched_cassette);
            $overrides{recombinase} = [ $c->req->param('recombinase') ];

			my $template = $c->model('Golgi')->create_qc_template_from_csv({
				template_name => $template_name,
				well_data_fh  => $well_data->fh,
				species       => $c->session->{selected_species},
                %overrides,
			});

			my $view_uri = $c->uri_for("/user/view_template",{ id => $template->id});
			$c->stash->{success_msg} = "Template <a href=\"$view_uri\">$template_name</a> was successfully created";
		}
		catch{
			$c->stash->{error_msg} = "Sorry, template plate creation failed with error: $_" ;
		};
	}

	return;
}

sub _populate_create_template_menus{
	my ($self, $c) = @_;

    my @cassettes = @{ $c->model('Golgi')->eng_seq_builder->list_seqs( type => 'final-cassette') };
    push @cassettes, @{ $c->model('Golgi')->eng_seq_builder->list_seqs( type => 'intermediate-cassette') };

    my $schema = $c->model('Golgi')->schema;

    my (@phase_cassettes, @non_phase_cassettes);

    # Filter cassette list into non-phase matched cassettes, and phase match groups
    foreach my $cass ( @cassettes ) {
    	my $cassette_name = $cass->{name};
    	my $cassette = $schema->resultset('Cassette')->find({ name => $cassette_name});
    	if ($cassette and defined $cassette->phase_match_group){
    		push @phase_cassettes, $cassette->phase_match_group;
    	}
    	else{
    		push @non_phase_cassettes, $cassette_name;
    	}
    }
    $c->stash->{phase_cassettes} = [ "", uniq sort {lc($a) cmp lc($b) } @phase_cassettes ];
    $c->stash->{non_phase_cassettes} = [ "", sort {lc($a) cmp lc($b) } @non_phase_cassettes ];

    # intermediate backbones can be in a final vector, so need a list of all backbone types
    # which eng-seq-builder can not provide using the eng_seq_of_type method
    my @backbones = $schema->resultset('Backbone')->all;
    $c->stash->{backbones} = [ sort { lc($a) cmp lc($b) } map { $_->name } @backbones ];
    unshift @{ $c->stash->{backbones} }, "";

    $c->stash->{recombinases} = [ sort map { $_->id } $c->model('Golgi')->schema->resultset('Recombinase')->all ];

    return;
}

sub create_plates :Path('/user/create_plates') :Args(0){
	my ($self, $c) = @_;

	my $run_id = $c->req->param('qc_run_id');

	# Store params for reload
	$c->stash->{qc_run_id} = $run_id;
	$c->stash->{plate_type} = $c->req->param('plate_type');

	$c->stash->{plate_types}   = [ qw(PREINT INT POSTINT FINAL FINAL_PICK CRISPR_V) ];

	unless ($run_id){
		$c->flash->{error_msg} = "No QC run ID provided to create plates";
		$c->res->redirect( $c->uri_for('/user/qc_runs') );
		return;
	}

    # Store list of plates from existing plate name map
    my $rename_plate = $self->_create_plate_rename_map($c);

    # If plate map is empty get plate names from QC run
    unless(keys %{ $rename_plate || {} }){
        my ( $qc_run, $results ) = $c->model( 'Golgi' )->qc_run_results( { qc_run_id => $run_id } );
		my @plates = uniq map { $_->{plate_name} } @$results;
		$c->stash->{qc_run_plates} = [sort @plates];
    }

	if($c->req->param('create')){
		# Create the plates within transaction so this can be re-run
		# if creation of any individual plate fails
		my @new_plates;

        unless ( $c->req->param('plate_type') ) {
            $c->flash->{error_msg} = "You must specify a plate type";
            return;
        }

        my $plate_from_qc = {
			qc_run_id    => $run_id,
			plate_type   => $c->req->param('plate_type'),
			rename_plate => $rename_plate,
			created_by   => $c->user->name,
			view_uri     => $c->uri_for("/user/view_qc_result"),
		};

		$c->model('Golgi')->txn_do(
		    sub{
		    	try{
		    		# The view_uri is needed to create path to results view
		    		# which is entered in the well_qc_sequencing_result
			        @new_plates = $c->model('Golgi')->create_plates_from_qc($plate_from_qc);
		        }
		        catch{
			        $c->stash->{error_msg} = "Plate creation failed with error: $_";
			        $c->model('Golgi')->txn_rollback;
		        }
		    }
		);
		# Report names of created plates
		if (@new_plates){
		    $c->flash->{success_msg} = "The following plates where created: ".
				                       join ", ", map { $_->name } @new_plates;
		    my $browse_plate_params = {filter => 'Filter',  plate_type => $c->req->param('plate_type')};
            $c->res->redirect( $c->uri_for('/user/browse_plates', $browse_plate_params) );
	    }
	}

	return;
}

sub _create_plate_rename_map{
	my ($self, $c) = @_;

    my $params = $c->request->parameters;
    my %plate_map;

    for my $p ( keys %{$params} ) {
        my ( $plate_name ) = $p =~ /^rename_plate_(.+)$/;
        if ( $plate_name ) {
            my $rename_to = $params->{$p};
            $rename_to =~ s/\s+//;
            $plate_map{$plate_name} = uc( $rename_to );
            # Store mapping for reload
            $c->stash->{$p} = $rename_to;
        }
    }

    # Store plate list for reload
    $c->stash->{qc_run_plates} = [sort keys %plate_map];

    # Check that there are no duplicates in the list of plates we're asked to create
    my @to_create = values %plate_map;
    if ( @to_create != uniq @to_create ) {
        $c->stash->{error_msg} = "Duplicate plate names found";
        $c->detach();
    }

    return \%plate_map;
}

=head2 mark_ep_pick_wells_accepted

Run against standard-es-cell qc, analyses results plus well primer band data
and marks ep_pick wells as accepted if there are enought passing primers.

=cut
sub mark_ep_pick_wells_accepted :Path('/user/mark_ep_pick_wells_accepted') :Args(0) {
	my ($self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
	my $run_id = $c->req->param('qc_run_id');

	unless ($run_id){
		$c->flash->{error_msg} = "No QC run ID provided";
		$c->res->redirect( $c->uri_for('/user/qc_runs') );
		return;
	}

    my ( $updated_wells, $error );
    try {
        my $qc_run = $c->model('Golgi')->retrieve_qc_run( { id => $run_id } );

        my $qc_util = LIMS2::Util::ESQCUpdateWellAccepted->new(
            model       => $c->model('Golgi'),
            qc_run      => $qc_run,
            user        => $c->user->name,
            base_qc_url => $c->uri_for( '/user/view_qc_result' )->as_string,
            commit      => 1,
        );
        ( $updated_wells, $error ) = $qc_util->update_well_accepted();
    }
    catch {
        $c->stash->{error_msg} = "Error updating epd well accepted values: $_";
    };

    if ( $error ) {
		$c->flash->{error_msg} = "Error: $error";
    }
    else {
        $c->flash->{success_msg} = "The following wells were marked as accepted:<br>" .
                                   join("<br>", @{ $updated_wells } );
    }
    $c->res->redirect( $c->uri_for('/user/view_qc_run', { qc_run_id => $run_id } ) );

	return;
}

sub view_traces :Path('/user/qc/view_traces') :Args(0){
    my ($self, $c) = @_;
    $c->assert_user_roles('read');

    # Store form values
    $c->stash->{sequencing_project}     = $c->req->param('sequencing_project');
    $c->stash->{sequencing_sub_project} = $c->req->param('sequencing_sub_project');
    $c->stash->{primer_data} = $c->req->param('primer_data');
    $c->stash->{well_name} = $c->req->param('well_name');
    #Create recently added list
    my $recent = $c->model('Golgi')->schema->resultset('SequencingProject')->search(
        {
            available_results => 'y'
        },
        {
            rows => 20,
            order_by => {-desc => 'created_at'},
        }
    );

    my @results;

    while (my $focus = $recent->next) {
        push(@results, $focus->{_column_data});
    }
    $c->stash->{recent_results} = \@results;
    if($c->req->param('get_reads')){
        unless($ENV{LIMS2_SEQ_FILE_DIR}){
            $c->stash->{error_msg} = "Cannot fetch reads - LIMS2_SEQ_FILE_DIR environment variable not set!";
            return;
        }
        my $project = $c->req->param('sequencing_project');
        my $sub_project = $c->req->param('sequencing_sub_project');
        my $well_name = $c->req->param('well_name');
        my $date = $c->req->param('data_set');
        my $version;
        if ($date ne 'Latest') {
            my $seq_rs = $c->model('Golgi')->schema->resultset('SequencingProject')->find({
                name => $project
            })->backup_directories;
            foreach my $dir (@{$seq_rs}) {
                if ($date eq $dir->{date}) {
                    $version = $dir->{dir};
                    $c->stash->{selected_version} = $dir->{date};
                }
            }
        } else {
            $c->stash->{selected_version} = 'Latest';
        }
        if ($well_name && $well_name ne ' '){
            # Fetch the sequence fasta files for this well from the lims2 managed seq data dir
            # This will not work for older internally sequenced data
            $c->log->debug("Fetching reads for $sub_project well $well_name");
            my $project_dir = file_name($c, $version, $project);

            my $file_prefix = $sub_project.lc($well_name);
            my @well_files = grep { $_->basename =~ /^$file_prefix\..*\.seq$/ } $project_dir->children;

            unless(@well_files){
                $c->stash->{error_msg} = "Could not find any reads for $sub_project well $well_name";
                return;
            }

            my @reads;
            foreach my $file (@well_files){
                my $input = $file->slurp;
                my $seqIO = Bio::SeqIO->new(-string => $input, -format => 'fasta');
                my $seq = $seqIO->next_seq();
                my $read_name = $seq->display_id;
                my ($primer) = ( $read_name =~ /^$file_prefix\.p1k(.*)$/ );

                my $read = {
                    well_name      => uc($well_name),
                    primer         => $primer,
                    plate_name     => $sub_project,
                    seq            => $seq->seq,
                    orig_read_name => $read_name,
                };
                push @reads, $read;
            }
            $c->stash->{reads} = \@reads;

        }
        else{
            # Fetch the sequence fasta and parse it
            my $script_name = 'fetch-seq-reads.sh';
            my $fetch_cmd = File::Which::which( $script_name ) or die "Could not find $script_name";
            my $fasta_input;
            if ($version) {
                $fasta_input = join "", capturex( $fetch_cmd, $project . '/' . $version );
                $c->log->debug("Using version " . $version . " of " . $project);
            } else {
                $fasta_input = join "", capturex( $fetch_cmd, $project);
                $c->log->debug("Using latest version of " . $project);
            }

            my $seqIO = Bio::SeqIO->new(-string => $fasta_input, -format => 'fasta');
            my $seq_by_name = {};
            while (my $seq = $seqIO->next_seq() ){
                $seq_by_name->{ $seq->display_id } = $seq->seq;
            }
            # Parse all read names for the project
            # and store along with read sequence
            my $reads_by_sub;
            foreach my $read ( get_parsed_reads($project) ){
                $read->{seq} = $seq_by_name->{ $read->{orig_read_name} };
                $read->{date} = get_seq_file_import_date( $project, $read->{orig_read_name}, $version);
                $reads_by_sub->{ $read->{plate_name} } ||= [];
                push @{ $reads_by_sub->{ $read->{plate_name} } }, $read;
            }
            $c->stash->{reads} = $reads_by_sub->{ $sub_project };
        }
    }

    return;
}

sub file_name {
    my ($c, $version, $project) = @_;
    my $project_dir;
    if ($version) {
        $project_dir = dir($ENV{LIMS2_SEQ_FILE_DIR}, $project . '/' . $version);
        $c->log->debug("Using version " . $version . " of " . $project);
    }
    else {
        $project_dir = dir($ENV{LIMS2_SEQ_FILE_DIR}, $project);
        $c->log->debug("Using latest version of " . $project);
    }
    unless (-r $project_dir){
        $c->stash->{error_msg} = "Cannot fetch reads as directory $project_dir is not available";
        return;
    }
    return $project_dir;
}

sub download_reads :Path( '/user/download_reads' ) :Args() {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $seq_project = $c->req->param('sequencing_project');

    unless($seq_project){
        $c->stash->{error_msg} = "No sequencing_project specified";
    }

    my $script_name = 'fetch-seq-reads.sh';
    my $fetch_cmd = File::Which::which( $script_name ) or die "Could not find $script_name";
    my $fasta = join "", capturex( $fetch_cmd, $seq_project );

    $c->response->status( 200 );
    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$seq_project.fasta" );
    $c->response->body( $fasta );
    return;
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
