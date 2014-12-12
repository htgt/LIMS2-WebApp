package LIMS2::WebApp::Controller::API::CrisprQc;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::CrisprQc::VERSION = '0.277';
}
## use critic

use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::CrisprQc - Catalyst Controller

=head1 DESCRIPTION

API methods dealing with es cell crispr qc

=cut

sub update_crispr_es_qc_well :Path('/api/update_crispr_es_qc_well') :Args(0) :ActionClass('REST') {
}

sub update_crispr_es_qc_well_POST {
    my ( $self, $c ) = @_;

    try{
        my $qc_well = $c->model('Golgi')->txn_do(
            sub {
                shift->update_crispr_es_qc_well( $c->request->params );
            }
        );
        $self->status_ok( $c, entity => { success => 1 } );
    }
    catch {
        $c->log->error( "Error updating crispr es qc well value: $_" );
        $self->status_bad_request( $c, message => "Error: $_" );
    };

    return
}

sub crispr_es_qc_run : Path( '/api/crispr_es_qc_run' ) : Args(0) :ActionClass( 'REST' ) {
}

=head2 GET /api/crispr_es_qc_run

Retrieve a crispr es qc run by id

=cut

sub crispr_es_qc_run_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $crispr_es_qc_run = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_crispr_es_qc_run( { id => $c->request->param( 'id' ) } );
        }
    );

    return $self->status_ok( $c, entity => $crispr_es_qc_run );
}

=head2 POST

Create a crispr es qc run record

=cut

sub crispr_es_qc_run_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $crispr_es_qc_run = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->create_crispr_es_qc_run( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/crispr_es_qc_run', { id => $crispr_es_qc_run->id } ),
        entity   => $crispr_es_qc_run
    );
}

sub crispr_es_qc_well : Path( '/api/crispr_es_qc_well' ) : Args(0) :ActionClass( 'REST' ) {
}

=head2 GET /api/crispr_es_qc_well

Retrieve a crispr es qc run by id

=cut

sub crispr_es_qc_well_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $crispr_es_qc_well = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_crispr_es_qc_well( { id => $c->request->param( 'id' ) } );
        }
    );

    return $self->status_ok( $c, entity => $crispr_es_qc_well );
}

=head2 POST

Create a crispr es qc well record

=cut

sub crispr_es_qc_well_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $crispr_es_qc_well = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->create_crispr_es_qc_well( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/crispr_es_qc_well', { id => $crispr_es_qc_well->id } ),
        entity   => $crispr_es_qc_well
    );
}

sub validate_crispr_es_qc_run : Path( '/api/validate_crispr_es_qc_run' ) : Args(0) :ActionClass( 'REST' ) {
}

=head2 POST

Validate a crispr es qc run

=cut

sub validate_crispr_es_qc_run_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    try{
        my $crispr_es_qc_run = $c->model('Golgi')->txn_do(
            sub {
                shift->validate_crispr_es_qc_run( $c->request->params );
            }
        );
        $self->status_ok( $c, entity => { success => 1 } );
    }
    catch {
        $c->log->error( "Error validating crispr es qc run : $_" );
        $self->status_bad_request( $c, message => "Error: $_" );
    };

    return
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
