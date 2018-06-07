package LIMS2::WebApp::Controller::API::Browser;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Browser::VERSION = '0.506';
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
    generic_designs_for_region
    generic_design_oligos_to_gff
    primers_for_crispr_pair
    crispr_primers_to_gff
    unique_crispr_data
    unique_crispr_data_to_gff
    crispr_groups_for_region
    crispr_groups_to_gff
    design_params_to_gff
    single_experiment_gff
/;
use JSON;
use WebAppCommon::Design::DesignParameters qw( c_get_design_region_coords );

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

    my $model = $c->model('Golgi');
    my $schema = $model->schema;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = $c->request->params->{'assembly'} // $model->get_species_default_assembly( $params->{species} ) // 'GRCh37';
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

    my $model = $c->model('Golgi');
    my $schema = $model->schema;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = $c->request->params->{'assembly'} // $model->get_species_default_assembly( $params->{species} ) // 'GRCh37';
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

sub crispr_groups :Path('/api/crispr_groups') :Args(0) :ActionClass('REST') {
}

sub crispr_groups_GET {
    my ( $self, $c ) = @_;

    my $model = $c->model('Golgi');
    my $schema = $model->schema;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = $c->request->params->{'assembly'} // $model->get_species_default_assembly( $params->{species} ) // 'GRCh37';
    $params->{chromosome_number}= $c->request->params->{'chr'};
    $params->{start_coord}= $c->request->params->{'start'};
    $params->{end_coord}= $c->request->params->{'end'};


    my $crisprs = crispr_groups_for_region(
         $schema,
         $params,
    );

    my $crispr_gff = crispr_groups_to_gff( $crisprs, $params );
    $c->response->content_type( 'text/plain' );
    my $body = join "\n", @{$crispr_gff};
    return $c->response->body( $body );
}


sub gibson_designs :Path('/api/gibson_designs') :Args(0) :ActionClass('REST') {
}

sub gibson_designs_GET {
    my ( $self, $c ) = @_;

    my $model = $c->model('Golgi');
    my $schema = $model->schema;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = $c->request->params->{'assembly'} // $model->get_species_default_assembly( $params->{species} ) // 'GRCh37';
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

sub generic_designs :Path('/api/generic_designs') :Args(0) :ActionClass('REST') {
}

sub generic_designs_GET {
    my ( $self, $c ) = @_;

    my $model = $c->model('Golgi');
    my $schema = $model->schema;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = $c->request->params->{'assembly'} // $model->get_species_default_assembly( $params->{species} ) // 'GRCh37';
    $params->{chromosome_number}= $c->request->params->{'chr'};
    $params->{start_coord}= $c->request->params->{'start'};
    $params->{end_coord}= $c->request->params->{'end'};

    my $crisprs = generic_designs_for_region (
         $schema,
         $params,
    );

    my $generic_designs_gff = generic_design_oligos_to_gff( $crisprs, $params );
    $c->response->content_type( 'text/plain' );
    my $body = join "\n", @{$generic_designs_gff};
    return $c->response->body( $body );
}

# Methods for crispr primers

sub crispr_primers :Path('/api/crispr_primers') :Args(0) :ActionClass('REST') {
}

sub crispr_primers_GET {
    my ( $self, $c ) = @_;

    my $schema = $c->model('Golgi')->schema;

    my $crispr_primers = primers_for_crispr_pair (
         $schema,
         $c->request->params,
    );

    my $crispr_primer_gff = crispr_primers_to_gff( $crispr_primers, $c->request->params );
    $c->response->content_type( 'text/plain' );
    my $body = join "\n", @{$crispr_primer_gff};
    return $c->response->body( $body );
}

sub crispr_genotyping_primers :Path('/api/crispr_genotyping_primers') :Args(0) :ActionClass('REST') {
}

=head crispr_genotyping_primers

Return all genotyping primers for this region

=cut

sub crispr_genotyping_primers_GET {
    my ( $self, $c ) = @_;

    my $model = $c->model('Golgi');
    my $schema = $model->schema;

    my $params = ();
    $params->{species} = $c->session->{'selected_species'} // 'Human';
    $params->{assembly_id} = $c->request->params->{'assembly'} // $model->get_species_default_assembly( $params->{species} ) // 'GRCh37';
    $params->{chromosome_number}= $c->request->params->{'chr'};
    $params->{start_coord}= $c->request->params->{'start'};
    $params->{end_coord}= $c->request->params->{'end'};

    my $crispr_genotyping_primers = crispr_genotyping_primers (
         $schema,
         $params,
    );

    my $crispr_genotyping_primers_gff = crispr_genotyping_primers( $crispr_genotyping_primers, $c->request->params );
    $c->response->content_type( 'text/plain' );
    my $body = join "\n", @{$crispr_genotyping_primers_gff};
    return $c->response->body( $body );
}

=head unique_crispr
Given:

    a crispr_id_type (crispr_pair_id or crispr_id - this is the column to lookup)
    a crispr_type_id (crispr_pair_id or crispr_id)
returns:
    a response body that is a GFF/GTF format file intended for Genoverse rendering
=cut

sub unique_crispr :Path('/api/unique_crispr') :Args(0) :ActionClass('REST') {
}

sub unique_crispr_GET {
    my ( $self, $c ) = @_;

    my $schema = $c->model('Golgi')->schema;
    my $crispr_data = unique_crispr_data (
         $schema,
         $c->request->params,
    );

    my $unique_crispr_data_gff = unique_crispr_data_to_gff( $crispr_data, $c->request->params );
    $c->response->content_type( 'text/plain' );
    my $body = join "\n", @{$unique_crispr_data_gff};
    return $c->response->body( $body );
}

sub single_experiment_track :Path('/api/single_experiment_track') :Args(0) :ActionClass('REST'){
}

sub single_experiment_track_GET{
    my ($self, $c) = @_;

    $c->log->debug('getting experiment');
    my $experiment = $c->model('Golgi')->schema->resultset('Experiment')->find({ id => $c->req->param('id') });
    $c->log->debug('got experiment');
    my $experiment_gff = single_experiment_gff($experiment);
    $c->response->content_type('text/plain');
    my $body  = join "\n", @{ $experiment_gff };
    return $c->response->body( $body );
}

=head design_region_coords
Given: target_start, target_end, chr, assembly, design_type, list of specified region lengths and offsets
Returns GFF containing coords of regions to search in for design oligo generation
=cut

sub design_region_coords :Path('/api/design_region_coords') :Args(0) :ActionClass('REST') {
}

sub design_region_coords_GET{
    my ( $self, $c ) = @_;
    my $region_coords = c_get_design_region_coords($c->req->params);
    my $general_params = {
        chr_name    => $c->req->param('chr'),
        design_type => $c->req->param('design_type'),
    };

    my $params_gff = design_params_to_gff($region_coords, $general_params);
    $c->response->content_type('text/plain');
    my $body = join "\n", @{$params_gff};
    return $c->response->body( $body );
}

1;
