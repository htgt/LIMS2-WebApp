package LIMS2::WebApp::Controller::User::QC;
use Moose;
use namespace::autoclean;
use HTTP::Status qw( :constants );
use Scalar::Util qw( blessed );
use LWP::UserAgent;
use JSON qw( encode_json decode_json );
use Try::Tiny;
use Config::Tiny;
use Data::Dumper;
use HTGT::QC::Config;
use HTGT::QC::Util::ListLatestRuns;
use HTGT::QC::Util::KillQCFarmJobs;
use HTGT::QC::Util::CreateSuggestedQcPlateMap qw( create_suggested_plate_map get_sequencing_project_plate_names );

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

sub _list_all_profiles {
    my ( $self, $c ) = @_;

    return [ sort $self->qc_config->profiles ];
}

sub index :Path( '/user/qc_runs' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $params = $c->request->params;
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

    $c->stash(
        qc_run  => $qc_run->as_hash,
        results => $results,
    );
    return;
}

sub view_qc_result :Path('/user/view_qc_result') Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my ( $qc_seq_well, $seq_reads, $results ) = $c->model('Golgi')->qc_run_seq_well_results(
        {
            qc_run_id  => $c->req->params->{qc_run_id},
            plate_name => $c->req->params->{plate_name},
            well_name  => uc( $c->req->params->{well_name} ),
        }
    );

    my $qc_run = $c->model('Golgi')->retrieve_qc_run( { id => $c->req->params->{qc_run_id} } );

    $c->stash(
        qc_run      => $qc_run->as_hash,
        qc_seq_well => $qc_seq_well,
        results     => $results,
        seq_reads   => [ sort { $a->primer_name cmp $b->primer_name } @{ $seq_reads } ]
    );
    return;
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
	my ($self, $c) = @_;

    $c->stash->{profiles} = $self->_list_all_profiles;

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
	if ( $c->req->param('submit_initial_info')){
		try{
			# validate input params before doing anything else
			$c->model('Golgi')->check_params($c->req->params, $requirements);

		    my $plate_map = create_suggested_plate_map(
		        $c->stash->{sequencing_project},
	            $c->model('Golgi')->schema,
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

		if ( $run_id = $self->_launch_qc($c, $validated_plate_map) ){
			$c->stash->{run_id} = $run_id;
			$c->stash->{success_msg} = "Your QC job has been submitted with ID $run_id. "
			                           ."Go to <a href=\"".$c->uri_for('/user/latest_runs')."\">Latest Runs</a>"
			                           ." to see the progress of your job";
		}
	}
	return;
}

sub _launch_qc{
	my ($self, $c, $plate_map) = @_;

    my $ua = LWP::UserAgent->new();
    my $qc_conf = Config::Tiny->new();
    $qc_conf = Config::Tiny->read($ENV{LIMS2_QC_CONFIG});

    unless ($qc_conf){
    	die "No QC submission service has been configured. Cannot submit QC job.";
    }

    $plate_map ||= {};

    my $params = {
	    profile             => $c->stash->{profile},
	    template_plate      => $c->stash->{template_plate},
	    sequencing_projects => $c->stash->{sequencing_project},
	    plate_map           => $plate_map,
	    username            => $qc_conf->{_}->{username},
	    password            => $qc_conf->{_}->{password},
	    created_by          => $c->user->name,
	    species             => $c->session->{selected_species},
    };

    my $uri = $qc_conf->{_}->{submit_uri};

    my $content;

    try{
        my $req = HTTP::Request->new(POST => $uri);
        $req->content_type('application/json');
        $req->content( encode_json( $params ) );

        my $response = $ua->request($req);

        unless ($response->is_success){
        	die "Request to $uri was not successful. Response: ".$response->status_line;
        }

        $content = decode_json( $response->content );
    }
    catch{
    	$c->stash( error_msg => "Sorry, your QC job submission failed with error $_" );
    };

    my $run_id = $content->{'qc_run_id'};

    return $run_id;
}

sub latest_runs :Path('/user/latest_runs') :Args(0) {
    my ( $self, $c ) = @_;

    my $llr = HTGT::QC::Util::ListLatestRuns->new( { config => $self->qc_config } );

    $c->stash( latest => $llr->get_latest_run_data );

    return;
}

sub qc_farm_error_rpt :Path('/user/qc_farm_error_rpt') :Args(1) {
    my ( $self, $c, $params ) = @_;

    my ( $qc_run_id, $last_stage ) = $params =~ /^(.+)___(.+)$/;
    my $config = $self->qc_config;

    my $error_file = $config->basedir->subdir( $qc_run_id )->subdir( 'error' )->file( $last_stage . '.err' );
    my @error_file_content = $error_file->slurp( chomp => 1 );

    $c->stash( run_id => $qc_run_id );
    $c->stash( last_stage => $last_stage );
    $c->stash( error_content => \@error_file_content );

    return;
}

sub kill_farm_jobs :Path('/user/kill_farm_jobs') :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my $kill_jobs = HTGT::QC::Util::KillQCFarmJobs->new(
        {
            qc_run_id => $qc_run_id,
            config    => $self->qc_config,
        } );

    my $jobs_killed = $kill_jobs->kill_unfinished_farm_jobs();
    $c->stash( info_msg => 'Killing farm jobs (' . join( ' ', @{$jobs_killed} ) . ') from QC run '.$qc_run_id );
    $c->go( 'latest_runs' );

    return;
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

    my $template_name = $c->req->param('template_plate');

	# Store form values
	$c->stash->{template_plate} = $template_name;
	$c->stash->{source_plate} = $c->req->param('source_plate');

	if ( $c->req->param('create_from_plate')){
		try{
			unless($template_name){
				die "You must provide a name for the template plate";
			}
			unless($c->req->param('source_plate')){
				die "You must provide a source plate";
			}

			my $template = $c->model('Golgi')->create_qc_template_from_plate({
				name => $c->req->param('source_plate'),
				template_name => $c->req->param('template_plate'),
			});
			$c->stash->{success_msg} = "Template $template_name was successfully created";
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

			$c->model('Golgi')->create_qc_template_from_csv({
				template_name => $template_name,
				well_data_fh  => $well_data->fh,
				species       => $c->session->{selected_species},
			});

			$c->stash->{success_msg} = "Template $template_name was successfully created";
		}
		catch{
			$c->stash->{error_msg} = "Sorry, template plate creation failed with error: $_" ;
		};
	}

	return;
}
=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
