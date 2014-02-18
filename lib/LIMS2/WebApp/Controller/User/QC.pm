package LIMS2::WebApp::Controller::User::QC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::QC::VERSION = '0.160';
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
use List::MoreUtils qw( uniq );
use HTGT::QC::Config;
use HTGT::QC::Util::ListLatestRuns;
use HTGT::QC::Util::KillQCFarmJobs;
use HTGT::QC::Util::CreateSuggestedQcPlateMap qw( create_suggested_plate_map get_sequencing_project_plate_names );
use LIMS2::Model::Util::CreateQC qw( htgt_api_call );

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

    my $crispr = 0;
    if ($results->[0]->{crispr_id}) {
        $crispr = 1;
    }

    $c->stash(
        qc_run  => $qc_run->as_hash,
        results => $results,
        crispr  => $crispr
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
	my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

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

sub _launch_qc{
    my ($self, $c, $plate_map ) = @_;

    $plate_map ||= {};

    my $params = {
        profile             => $c->stash->{ profile },
        template_plate      => $c->stash->{ template_plate },
        sequencing_projects => $c->stash->{ sequencing_project },
        plate_map           => $plate_map,
        created_by          => $c->user->name,
        species             => $c->session->{ selected_species },
    };

    my $content = htgt_api_call( $c, $params, 'submit_uri' );

    return $content->{ qc_run_id };
}

sub latest_runs :Path('/user/latest_runs') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $llr = HTGT::QC::Util::ListLatestRuns->new( { config => $self->qc_config } );

    $c->stash( latest => $llr->get_latest_run_data );

    return;
}

sub qc_farm_error_rpt :Path('/user/qc_farm_error_rpt') :Args(1) {
    my ( $self, $c, $params ) = @_;

    $c->assert_user_roles( 'read' );

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

    $c->assert_user_roles( 'edit' );

    my $content = htgt_api_call( $c, { qc_run_id => $qc_run_id }, 'kill_uri' );

    if ( $content ) {
        my @jobs_killed = @{ $content->{ job_ids } };
        $c->stash( info_msg => "Killing farm jobs (" . join( ' ', @jobs_killed ) . ") from QC run $qc_run_id" );
    }
    else {
        my $error = $c->stash->{ error_msg } . "<br/>Failed to kill farm jobs."; #dont overwrite other error
        $c->stash( error_msg => $error );
    }

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

			my $template = $c->model('Golgi')->create_qc_template_from_csv({
				template_name => $template_name,
				well_data_fh  => $well_data->fh,
				species       => $c->session->{selected_species},
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

	$c->stash->{plate_types}   = [ qw(INT POSTINT FINAL FINAL_PICK CRISPR_V) ];

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

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
