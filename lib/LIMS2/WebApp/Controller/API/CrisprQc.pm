package LIMS2::WebApp::Controller::API::CrisprQc;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::CrisprQc::VERSION = '0.266';
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

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
