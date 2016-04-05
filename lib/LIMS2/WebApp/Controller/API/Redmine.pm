package LIMS2::WebApp::Controller::API::Redmine;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Redmine::VERSION = '0.391';
}
## use critic

use Moose;
use LIMS2::Model::Util::RedmineAPI;
use Data::Dumper;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

my $redmine = LIMS2::Model::Util::RedmineAPI->new_with_config();

sub redmine_issues : Path( '/api/redmine_issues' ) : Args(0) : ActionClass( 'REST' ) {
}

sub redmine_issues_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $id = $c->request->param( 'project_id' );

    return $self->status_bad_request( $c, message => "Error: no project_id specified" ) unless $id;

    my $search_params = {
        'Project ID' => $id,
    };

    if(my $exp_id = $c->request->param('experiment_id')){
        $search_params->{'Current Experiment ID'} = $exp_id;
    }

    # First arg to get issues is hash of standard redmine filter params
    # Second arg is hash of custom field name to values
    my $issues = $redmine->get_issues({},$search_params);

    return $self->status_ok( $c, entity => $issues );
}

sub redmine_issue : Path( '/api/redmine_issue' ) : Args(0) : ActionClass( 'REST' ) {
}

sub redmine_issue_POST{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $params = $c->req->params;

    # Add name of the redmine tracker for issues
    # Do this in the controller rather than config so that we can
    # have other controllers to create redmine entries for other trackers
    $params->{tracker_name} = 'Issue';

    # Add some text to say who created the ticket
    $params->{description} = "Issue created by LIMS2 user ".$c->user->name;

    my $issue = $redmine->create_issue($c->model('Golgi'), $params);

    return $self->status_bad_request( $c, message => "Issue creation failed" ) unless $issue;

    return $self->status_created($c, entity => $issue, location => $issue->{url} );
}
1;