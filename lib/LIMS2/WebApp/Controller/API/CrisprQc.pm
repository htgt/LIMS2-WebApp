package LIMS2::WebApp::Controller::API::CrisprQc;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::CrisprQc - Catalyst Controller

=head1 DESCRIPTION

API methods dealing with es cell crispr qc

=cut

sub update_well_accepted :Path('/api/update_well_accepted') :Args(0) :ActionClass('REST') {
}

sub update_well_accepted_POST {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    my $qc_well = $c->model('Golgi')->schema->resultset('CrisprEsQcWell')->find(
        {
            id => $params->{id},
        },
        { prefetch => 'well' }
    );

    #TODO: validate params

    #set both the qc well and the actual well to accepted
    try {
        $c->model('Golgi')->txn_do(
            sub {
                $qc_well->update( { accepted => $params->{accepted} } );
                $qc_well->well->update( { accepted => $params->{accepted} } );
            }
        );
        $self->status_ok( $c, entity => { success => 1 } );
    }
    catch {
        $self->status_bad_request( $c, message => "Error: $_" );
        $c->log->error( "Error updating crispr es qc well accepted flag: $_" );
    };

    return;
}

sub update_well_crispr_damage :Path('/api/update_well_crispr_damage') :Args(0) :ActionClass('REST') {
}

sub update_well_crispr_damage_POST {
    my ( $self, $c ) = @_;

    try{
        my $qc_well = $c->model('Golgi')->txn_do(
            sub {
                shift->update_crispr_well_damage( $c->request->params );
            }
        );
        $self->status_ok( $c, entity => { success => 1 } );
    }
    catch {
        $c->log->error( "Error updating crispr well damage value: $_" );
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

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
