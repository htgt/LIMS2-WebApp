package LIMS2::WebApp::Controller::API::Browser;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Browser::VERSION = '0.193';
}
## use critic

use Moose;
use namespace::autoclean;

use LIMS2::Model::Util::GenomeBrowser qw/
    crisprs_for_region
    crisprs_to_gff
    crispr_pairs_for_region
    crispr_pairs_to_gff 
    gibson_designs_for_region
    design_oligos_to_gff
    /;

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

    my $schema = $c->model('Golgi')->schema;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = $c->request->params->{'assembly'} // get_species_default_assembly($schema, $params->{species} ) // 'GRCh37';
    $params->{chromosome_number}= $c->request->params->{'chr'};
    $params->{start_coord}= $c->request->params->{'start'};
    $params->{end_coord}= $c->request->params->{'end'};

    my $crisprs = crisprs_for_region(
         $schema,
         $params,
    );

    my $crispr_gff = crisprs_to_gff( $crisprs, $params );
    $c->response->content_type( 'text/plain' );
    my $body = join "\n", @{$crispr_gff};
    return $c->response->body( $body );
}

sub crispr_pairs :Path('/api/crispr_pairs') :Args(0) :ActionClass('REST') {
}

sub crispr_pairs_GET {
    my ( $self, $c ) = @_;

    my $schema = $c->model('Golgi')->schema;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = $c->request->params->{'assembly'} // get_species_default_assembly($schema, $params->{species} ) // 'GRCh37';
    $params->{chromosome_number}= $c->request->params->{'chr'};
    $params->{start_coord}= $c->request->params->{'start'};
    $params->{end_coord}= $c->request->params->{'end'};


    my $crisprs = crispr_pairs_for_region(
         $schema,
         $params,
    );

    my $crispr_gff = crispr_pairs_to_gff( $crisprs, $params );
    $c->response->content_type( 'text/plain' );
    my $body = join "\n", @{$crispr_gff};
    return $c->response->body( $body );
}

sub get_species_default_assembly {
    my $schema = shift;
    my $species = shift;

    my $assembly_r = $schema->resultset('SpeciesDefaultAssembly')->find( { species_id => $species } );

    return $assembly_r->assembly_id || undef;

}

sub gibson_designs :Path('/api/gibson_designs') :Args(0) :ActionClass('REST') {
}

sub gibson_designs_GET {
    my ( $self, $c ) = @_;

    my $schema = $c->model('Golgi')->schema;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = $c->request->params->{'assembly'} // get_species_default_assembly($schema, $params->{species} ) // 'GRCh37';
    $params->{chromosome_number}= $c->request->params->{'chr'};
    $params->{start_coord}= $c->request->params->{'start'};
    $params->{end_coord}= $c->request->params->{'end'};

    my $crisprs = gibson_designs_for_region (
         $schema,
         $params,
    );

    my $gibson_gff = design_oligos_to_gff( $crisprs, $params );
    $c->response->content_type( 'text/plain' );
    my $body = join "\n", @{$gibson_gff};
    return $c->response->body( $body );
}
1;
