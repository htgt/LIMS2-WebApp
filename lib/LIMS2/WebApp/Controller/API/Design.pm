package LIMS2::WebApp::Controller::API::Design;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Design::VERSION = '0.446';
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
            shift->c_retrieve_design( { id => $c->request->param( 'id' ) } );
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
    my $protocol = $c->req->headers->header('X-FORWARDED-PROTO') // '';

    if($protocol eq 'HTTPS'){
        my $base = $c->req->base;
        $base =~ s/^http:/https:/;
        $c->req->base(URI->new($base));
        $c->req->secure(1);
    }
    $c->require_ssl;

    my $design = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->c_create_design( $c->request->data );
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
            shift->list_designs_for_gene( { slice_def $c->request->params, qw( gene_id species type ) } );
        }
    );

    return $c->forward( 'list_designs', [$designs] );
}

sub candidate_designs_for_gene : Path( '/api/candidate_designs_for_gene' ) :Args(0) :ActionClass('REST') {
}

sub candidate_designs_for_gene_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $designs = $c->model('Golgi')->txn_do(
        sub {
            shift->c_list_candidate_designs_for_gene( { slice_def $c->request->params, qw( gene_id species type ) } );
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

sub design_oligo : Path( '/api/design_oligo' ) : Args(0) :ActionClass( 'REST' ) {
}

=head2 GET /api/design_oligo

Retrieve a design oligo.

=cut

sub design_oligo_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $design_oligo = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->c_retrieve_design_oligo( { slice_def $c->request->params, qw( design_id oligo_type ) } );
        }
    );

    return $self->status_ok( $c, entity => $design_oligo );
}

=head2 POST

Create a design oligo.

=cut

sub design_oligo_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $design_oligo = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->c_create_design_oligo( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/design_oligo', { id => $design_oligo->id } ),
        entity => $design_oligo
    );
}

sub design_oligo_locus : Path( '/api/design_oligo_locus' ) : Args(0) :ActionClass( 'REST' ) {
}

=head2 POST

Create a design oligo locus.

=cut

sub design_oligo_locus_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $design_oligo_locus = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->c_create_design_oligo_locus( $c->request->data );
        }
    );

    return $self->status_no_content( $c );
}

sub design_attempt : Path( '/api/design_attempt' ) : Args(0) :ActionClass( 'REST' ) {
}

=head2 GET /api/design_attempt

Retrieve a design attempt by id.

=cut
sub design_attempt_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $design_attempt = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->c_retrieve_design_attempt( { id => $c->request->param( 'id' ) } );
        }
    );

    return $self->status_ok( $c, entity => $design_attempt );
}

=head2 POST

Create a design attempt

=cut
sub design_attempt_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $design_attempt = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->c_create_design_attempt( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/design_attempt', { id => $design_attempt->id } ),
        entity   => $design_attempt,
    );
}

=head2 PUT

Update a design attempt

=cut
sub design_attempt_PUT {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $design_attempt = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->c_update_design_attempt( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/design_attempt', { id => $design_attempt->id } ),
        entity   => $design_attempt,
    );
}

sub design_attempt_status :Path( '/api/design_attempt_status' ) :Args(1) :ActionClass('REST') {
}

sub design_attempt_status_GET {
    my ( $self, $c, $da_id ) = @_;

    $c->assert_user_roles( 'read' );
    my $da = $c->model('Golgi')->c_retrieve_design_attempt( { id => $da_id } );
    my $status = $da->status;
    my $design_links;
    if ( $status eq 'success' ) {
        for my $design_id ( @{ $da->design_ids } ) {
            my $link = $c->uri_for('/user/view_design', { design_id => $design_id } )->as_string;
            $design_links .= '<a href="' . $link . '">'. $design_id .'</a><br>';
        }
    }
    return $self->status_ok( $c, entity => { status => $status, designs => $design_links } );
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
