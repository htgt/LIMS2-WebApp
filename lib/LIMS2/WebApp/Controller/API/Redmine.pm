package LIMS2::WebApp::Controller::API::Redmine;
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

    my $issues = $redmine->get_issues({},{ 'Project ID' => $id } );
    $c->log->debug(Dumper $issues);

    return $self->status_ok( $c, entity => $issues );
}

1;