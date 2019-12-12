package LIMS2::WebApp::Controller::API::Project;
use Moose;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;
use Data::Dumper;
use JSON;

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

sub project_recovery_class : Path( '/api/project_recovery_class' ) : Args(0) : ActionClass( 'REST' ) {
}

sub project_recovery_class_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_project_by_id( { id => $c->request->param( 'id' ) } );
        }
    );

    if($c->request->param('recovery_class') eq '-'){
        # Unset recovery class if user has selected '-' from drop-down
        $project->update({ recovery_class_id => undef });
    }
    else{
        my $recovery_class = $c->model('Golgi')->txn_do(
            sub {
                shift->retrieve_recovery_class({ name => $c->request->param( 'recovery_class' ) } );
            }
        );
        $project->update( { recovery_class_id => $recovery_class->id } );
    }

    return $self->status_ok( $c, entity => $project->as_hash );
}

sub project_recovery_comment : Path( '/api/project_recovery_comment' ) : Args(0) : ActionClass( 'REST' ) {
}

sub project_recovery_comment_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_project_by_id( { id => $c->request->param( 'id' ) } );
        }
    );
    my $new_comment = $c->request->param( 'recovery_comment' );
    # Grid submits 'null' as text string if comment is deleted
    if($new_comment eq 'null'){
        $new_comment = undef;
    }

    $project->update( { recovery_comment => $new_comment } );

    return $self->status_ok( $c, entity => $project->as_hash );
}


sub project_priority : Path( '/api/project_priority' ) : Args(0) : ActionClass( 'REST' ) {
}

sub project_priority_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $project_sponsor = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_project_sponsor( {
                project_id => $c->request->param( 'id' ),
                sponsor_id => $c->request->param( 'sponsor_id' ),
                });
        }
    );

    my $priority = $c->request->param( 'priority' );
    if($priority eq '-'){
        $project_sponsor->update( { priority => undef });
    }
    else{
        $project_sponsor->update( { priority =>  $priority } );
    }

    return $self->status_ok( $c, entity => $project_sponsor->project->as_hash );
}

sub cell_line : Path( '/api/cell_line' ) : Args(0) : ActionClass( 'REST' ) {
}

sub cell_line_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $result;
    my $cell_line = $c->request->param('name');

    my $cell_rs = $c->model('Golgi')->schema->resultset('CellLine')->find({ 'name' => $cell_line });

    if ($cell_rs) {
        $result = $cell_rs->tracking;
    }

    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($result);

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );
}


1;
