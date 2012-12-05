package LIMS2::WebApp::Controller::User::Graph;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Graph::VERSION = '0.034';
}
## use critic

use Moose;
use MooseX::Types::Path::Class;
use Data::UUID;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::Graph - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

has graph_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    default  => sub { Path::Class::dir( '/tmp' ) }
);

has graph_format => (
    is      => 'ro',
    isa     => 'Str',
    default => 'svg'
);

has graph_content_type => (
    is      => 'ro',
    isa     => 'Str',
    default =>  'image/svg+xml'
);

has graph_filename => (
    is      => 'ro',
    isa     => 'Str',
    default => 'graph.svg'
);

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $plate_name  = $c->req->param('plate_name');
    my $well_name   = $c->req->param('well_name');
    my $graph_type  = $c->req->param('graph_type') || 'descendants';

    $c->stash(
        plate_name  => $plate_name,
        well_name   => $well_name,
        graph_type  => $graph_type
    );

    return unless $c->req->param('go');

    if ( ! $plate_name || ! $well_name ) {
        $c->stash( error_msg => 'Please enter a plate name and well name' );
        return;
    }

    if ( $graph_type ne 'ancestors' && $graph_type ne 'descendants' ) {
        $c->stash( error_msg => "Please select 'ancestors' or 'descendants'" );
        return;
    }

    my $well = $c->model('Golgi')->retrieve_well( { plate_name => $plate_name, well_name => $well_name } );
    my $uuid = $self->_write_graph( $c, $well, $graph_type );

    $c->stash( graph_uri => $c->uri_for( "/user/graph/render/$uuid" ) );

    return;
}

sub _write_graph {
    my ( $self, $c, $well, $graph_type ) = @_;

    my $uuid = Data::UUID->new->create_str;
    my $output_dir = $self->graph_dir->subdir( $uuid );
    $output_dir->mkpath;

    my $graph = $well->$graph_type();

    $graph->render( output_file => $output_dir->file( $self->graph_filename )->stringify, format => $self->graph_format );

    return $uuid;
}

sub render :Path( '/user/graph/render' )  :Args(1) {
    my ( $self, $c, $uuid ) = @_;

    my $file = $self->graph_dir->subdir( $uuid )->file( $self->graph_filename );

    my $sb = $file->stat;
    my $fh = $file->openr;

    $c->response->content_type( $self->graph_content_type );
    $c->response->content_length( $sb->size );
    $c->response->body( $fh );

    return;
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
