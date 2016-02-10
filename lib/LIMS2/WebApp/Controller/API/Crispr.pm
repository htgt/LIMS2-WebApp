package LIMS2::WebApp::Controller::API::Crispr;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Crispr::VERSION = '0.374';
}
## use critic

use Moose;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

sub single_crispr : Path( '/api/single_crispr' ) : Args(0) : ActionClass( 'REST' ) {
}

sub single_crispr_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $crispr = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_crispr( { slice_def $c->request->params, qw( id wge_crispr_id ) });
        }
    );

    return $self->status_ok( $c, entity => $crispr );
}

sub single_crispr_POST{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $crispr = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->create_crispr( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/single_crispr', { id => $crispr->id } ),
        entity   => $crispr
    );
}

sub crispr_off_target : Path( '/api/crispr_off_target' ) : Args(0) : ActionClass( 'REST') {
}

sub crispr_off_target_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $crispr = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_crispr_off_target(
                { slice_def $c->request->params, qw( id crispr_id off_target_crispr_id ) } );
        }
    );

    return $self->status_ok( $c, entity => $crispr );
}

sub crispr_off_target_POST{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $ot = $c->model( 'Golgi' )->txn_do(
        sub{
            shift->create_crispr_off_target( $c->request->data );
        }
    );

    return $self->status_ok( $c, entity => $ot );
}

sub crispr_off_target_summary : Path( '/api/crispr_off_target_summary' ) : Args(0) : ActionClass( 'REST') {
}

sub crispr_off_target_summary_POST{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $summary = $c->model( 'Golgi' )->txn_do(
        sub{
            shift->update_crispr_off_target_summary( $c->request->data );
        }
    );

    return $self->status_ok( $c, entity => $summary );
}

sub crispr_pair_off_target_summary : Path( '/api/crispr_pair_off_target_summary' ) : Args(0) : ActionClass( 'REST' ){
}

sub crispr_pair_off_target_summary_POST{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $pair = $c->model('Golgi')->txn_do(
        sub{
            shift->update_crispr_pair_off_target_summary( $c->request->data );
        }
    );

    return $self->status_ok( $c, entity => $pair );
}

sub crispr_pair : Path( '/api/crispr_pair' ) : Args(0) : ActionClass('REST'){
}

sub crispr_pair_GET{
    my ($self, $c) = @_;

    $c->assert_user_roles('read');

    my $pair = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_crispr_pair( { id => $c->request->param( 'id' ) } );
        }
    );

    return $self->status_ok( $c, entity => $pair );
}

sub crispr_pair_POST{
    my ($self, $c) = @_;

    $c->assert_user_roles('edit');

    my $pair = $c->model('Golgi')->txn_do(
        sub{
            shift->update_or_create_crispr_pair( $c->request->data );
        }
    );

    return $self->status_ok( $c, entity => $pair );
}

sub crispr_group : Path( '/api/crispr_group' ) : Args(0) : ActionClass('REST'){
}

sub crispr_group_GET {
    my ($self, $c) = @_;

    $c->assert_user_roles('read');

    my $pair = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_crispr_group( { id => $c->request->param( 'id' ) } );
        }
    );

    return $self->status_ok( $c, entity => $pair );
}

1;
