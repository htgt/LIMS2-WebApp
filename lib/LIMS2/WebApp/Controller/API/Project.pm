package LIMS2::WebApp::Controller::API::Project;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Project::VERSION = '0.247';
}
## use critic

use Moose;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

sub project : Path( '/api/project' ) : Args(0) : ActionClass( 'REST' ) {
}

sub project_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_project_by_id( { id => $c->request->param( 'id' ) } );
        }
    );

    return $self->status_ok( $c, entity => $project->as_hash );
}

sub project_toggle : Path( '/api/project_toggle' ) : Args(0) : ActionClass( 'REST' ) {
}

sub project_toggle_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->toggle_concluded_flag( { id => $c->request->param( 'id' ) } );
        }
    );

    return $self->status_ok( $c, entity => $project->as_hash );
}


1;
