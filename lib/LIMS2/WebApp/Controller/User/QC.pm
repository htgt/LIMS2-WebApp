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

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::UI::QC - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub _list_all_profiles {
    my ( $self, $c ) = @_;

    [ sort HTGT::QC::Config->new->profiles ];
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
    	template_plate     => { validate => 'existing_qc_template_name'},
    	profile            => { validate => 'alphanumeric_string'},
    	sequencing_project => { validate => 'alphanumeric_string'},
    	launch_qc          => { optional => 0 },
    };
    
	# Store form values
	$c->stash->{sequencing_project} = [ $c->req->param('sequencing_project') ];
	$c->stash->{template_plate} = $c->req->param('template_plate');
	$c->stash->{profile} = $c->req->param('profile');
	
	my $run_id;
	if ( $c->req->param('launch_qc') ){
		# validate input params before attempting to run QC
		$c->model('Golgi')->check_params($c->req->params, $requirements);
		if ( $run_id = $self->_launch_qc($c) ){
			$c->stash->{run_id} = $run_id;
			$c->stash->{success_msg} = "Your QC job has been submitted with ID $run_id";
		}
	}
	return;
}

sub _launch_qc{
	my ($self, $c) = @_;
	
    my $ua = LWP::UserAgent->new();
    my $qc_conf = Config::Tiny->new();
    $qc_conf = Config::Tiny->read($ENV{LIMS2_QC_CONFIG});
    
    unless ($qc_conf){
    	die "No QC submission service has been configured. Cannot submit QC job.";
    }

    # FIXME: how is this generated?
    my $plate_map = {};
    
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
        $c->log->debug($response->content);
        $content = decode_json( $response->content );
        
        unless ($response->is_success){
        	die "Request to $uri was not successful. Error message: ".$content->{'error'};
        }
    }
    catch{
    	$c->stash( error_msg => "Sorry, your QC job submission failed with error $_" );
    };
    
    my $run_id = $content->{'qc_run_id'};
    
    return $run_id;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
