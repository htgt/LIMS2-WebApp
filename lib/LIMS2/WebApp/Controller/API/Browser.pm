package LIMS2::WebApp::Controller::API::Browser;
use Moose;
use namespace::autoclean;

use LIMS2::Model::Util::CrisprBrowser qw/ crisprs_for_region_as_arrayref /;

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

$DB::single=1;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = 'GRCh37';
    $params->{chromosome_id}= '22';
    $params->{start_coord}= '1';
    $params->{end_coord}= '100000000';

    my $schema = $c->model('Golgi')->schema;

    my $crisprs = crisprs_for_region_as_arrayref (
         $schema,
         $params,
    );

    return $self->status_ok(
        $c,
        entity =>  $crisprs ,
    );
}

1;
