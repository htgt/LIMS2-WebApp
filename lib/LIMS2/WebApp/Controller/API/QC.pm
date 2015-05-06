package LIMS2::WebApp::Controller::API::QC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::QC::VERSION = '0.312';
}
## use critic

use Moose;
use namespace::autoclean;

BEGIN { extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::QC - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub qc_template : Path( '/api/qc_template' ) : Args(0) : ActionClass( 'REST' ) {
}

=head2 GET /api/qc_template

Retrieve qc template(s). If no parameters are given, returns a list of available templates.

=head3 Parameters

=over 4

=item C<id>

The template id

=item C<name>

The template name

Note: this is ignored if C<id> is specified.

=item latest

Boolean. By default, the latest version of a template with the
specified name is returned. If C<latest=0> is specified, all versions of
the template are returned.

Note: this is ignored if C<id> is specified.

=item C<created_before>

Timestamp - used to retrieve an earlier version of a template.

Note: this is ignored if C<id> is specified.

=back

=cut

sub qc_template_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $templates = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_qc_templates( $c->request->params );
        }
    );

    my $entity;

    if ( @{$templates} > 1 ) {
        $entity = [
            map {
                +{  id   => $_->{id},
                    name => $_->{name},
                    url  => $c->uri_for( '/api/qc/template', { id => $_->{id} } )
                    }
                } @{$templates}
        ];
    }
    else {
        $entity = $templates;
    }

    return $self->status_ok( $c, entity => $entity );
}

=head2 POST /api/qc_template

If a template exists with the specified name and layout, return the
existing template. Otherwise, creates and returns a new template.

=cut

sub qc_template_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $qc_template = $c->model('Golgi')->txn_do(
        sub {
            shift->find_or_create_qc_template( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/qc_template', { id => $qc_template->id } ),
        entity   => $qc_template
    );
}

sub qc_seq_read : Path( '/api/qc_seq_read' ) : Args(0) : ActionClass( 'REST' ) {
}

=head2 GET /api/qc_seq_read

Retrieve a QC sequencing read.

=head3 Parameters

=over 4

=item id

The QC seq read id

=back

=cut

sub qc_seq_read_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $qc_seq_read = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_qc_seq_read( $c->request->params );
        }
    );

    return $self->status_ok( $c, entity => $qc_seq_read );
}

=head2 POST /api/qc_seq_read

Create a QC sequencing read.

=cut

sub qc_seq_read_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $qc_seq_read = $c->model('Golgi')->txn_do(
        sub {
            shift->find_or_create_qc_seq_read( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/qc_seq_read', { id => $qc_seq_read->id } ),
        entity   => $qc_seq_read
    );
}

sub qc_run : Path( '/api/qc_run' ) : Args(0) : ActionClass( 'REST' ) {
}

sub qc_run_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    die "Not implemented";
}

=head2 POST /api/qc_run

Create a QC run.

=cut

sub qc_run_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $qc_run = $c->model('Golgi')->txn_do(
        sub {
            shift->create_qc_run( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/qc_run', { id => $qc_run->id } ),
        entity   => {}
    );
}

=head2 POST /api/qc_run

Update a QC run. Currently only update of C<upload_complete> is supported.

=head3 Parameters

=over 4

=item id

The QC run id

=back

=cut

sub qc_run_PUT {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $data = $c->request->data;
    $data->{id} = $c->request->param('id');

    my $qc_run = $c->model('Golgi')->txn_do(
        sub {
            shift->update_qc_run($data);
        }
    );

    return $self->status_ok( $c, entity => $qc_run );
}

sub qc_test_result : Path( '/api/qc_test_result' ) : Args(0) : ActionClass('REST') {
}

=head2 POST /api/qc_test_result

Create a QC test result

=cut

sub qc_test_result_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $test_result = $c->model('Golgi')->txn_do(
        sub {
            shift->create_qc_test_result( $c->request->data );
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/qc_test_result', { id => $test_result->id } ),
        entity   => {}
    );
}

=head2 GET /api/qc_test_result

Retrieve a QC test result

=head3 Parameters

=over 4

=item id

The QC test result id.

=back

=cut

sub qc_test_result_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $res = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_qc_test_result( $c->request->params );
        }
    );

    return $self->status_ok( $c, entity => $res );
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
