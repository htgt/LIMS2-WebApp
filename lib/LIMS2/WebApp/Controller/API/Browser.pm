package LIMS2::WebApp::Controller::API::Browser;
use Moose;
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::Browser - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller. Implements the REST client interface for genome browser
chunked data calls.

=head1 METHODS

=cut

sub crispr :Path('/api/crispr') :Args(0) :ActionClass('REST') {
}

sub crispr_GET {
    my ( $self, $c ) = @_;

    #TODO
    return $self->status_ok( $c, entity => #TODO );
}

