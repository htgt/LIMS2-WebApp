package LIMS2::WebApp::Controller::API::AssemblyQc;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::AssemblyQc::VERSION = '0.399';
}
## use critic

use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::AssemblyQc - Catalyst Controller

=head1 DESCRIPTION

API methods dealing with assembly well qc

=cut

sub update_assembly_qc_well :Path('/api/update_assembly_qc') :Args(0) :ActionClass('REST') {
}

sub update_assembly_qc_well_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    try{
        my $qc = $c->model('Golgi')->txn_do(
            sub {
                shift->update_assembly_qc_well( $c->request->params );
            }
        );
        my $well = $c->model('Golgi')->retrieve_well({ id => $c->request->param('well_id') });
        my $qc_verified = $well->assembly_well_qc_verified // '';

        $self->status_ok( $c,
            entity => {
                success     => 1,
                qc_verified => "$qc_verified",
                well_name   => $well->name,
            }
        );
    }
    catch {
        $c->log->error( "Error updating assembly qc well value: $_" );
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

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;