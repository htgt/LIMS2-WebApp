package LIMS2::WebApp::Controller::API::Design;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Design::VERSION = '0.003';
}
## use critic

use Moose;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::Design - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub design : Path( '/api/design' ) : Args(0) :ActionClass( 'REST' ) {
}

=head2 GET /api/design

Retrieve a design by id.

=cut

sub design_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $design = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_design( { id => $c->request->param( 'id' ) } );
        }
    );

    return $self->status_ok( $c, entity => $design );
}

=head2 POST

Create a design.

=cut

sub design_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $design = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->create_design( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/design', { id => $design->id } ),
        entity   => $design
    );
}

sub designs_for_gene : Path( '/api/designs_for_gene' ) :Args(0) :ActionClass( 'REST' ) {
}

sub designs_for_gene_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $designs = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->list_designs_for_gene( { slice_def $c->request->params, qw( gene type ) } );
        }
    );

    return $c->forward( 'list_designs', [$designs] );
}

sub candidate_designs_for_mgi_accession : Path( '/api/candidate_designs_for_mgi_accession' ) :Args(0) :ActionClass('REST') {
}

sub candidate_designs_for_mgi_accession_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $designs = $c->model('Golgi')->txn_do(
        sub {
            shift->list_candidate_designs_for_mgi_accession( { slice_def $c->request->params, qw( mgi_accession_id type ) } );
        }
    );

    return $c->forward( 'list_designs', [$designs] );
}

sub list_designs : Private {
    my ( $self, $c, $designs ) = @_;

    my @result;

    for my $d ( @{$designs} ) {
        my $r = $d->as_hash(1);
        $r->{uri} = $c->uri_for( '/api/design', { id => $d->id } )->as_string;
        push @result, $r;
    }

    return $self->status_ok(
        $c,
        entity => \@result
    );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
