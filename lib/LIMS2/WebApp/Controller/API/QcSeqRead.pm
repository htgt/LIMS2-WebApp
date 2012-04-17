package LIMS2::WebApp::Controller::API::QcSeqRead;
use Moose;
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::QcSeqRead - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub qc_seq_reads :Path( '/api/qc_seq_reads' ) :Args(0) :ActionClass('REST') { }

=head2 GET /api/qc_seq_reads

Retrieve list of QcSeqReads

=cut

sub qc_seq_reads_GET {
    my ( $self, $c ) = @_;

    my $qc_seq_reads = $c->model('Golgi')->retrieve_list(
        QcSeqRead => { }, { columns => [ qw( id ) ] } );


    $self->status_ok(
        $c,
        entity => { map { $_->id => $c->uri_for( '/api/qc_seq_read/'
                        . $_->id )->as_string } @{ $qc_seq_reads } },
    );
}

=head2 POST /api/qc_seq_reads

Create a QcSeqRead

=cut

sub qc_seq_reads_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    my $qc_seq_read = $c->model( 'Golgi' )->create_qc_seq_read( $c->request->data );

    $self->status_created(
        $c,
        location => $c->uri_for( '/api/qc_seq_read/', $qc_seq_read->id ),
        entity   => $qc_seq_read,
    );
}

sub qc_seq_read :Path( '/api/qc_seq_read' ) :Args(1) :ActionClass( 'REST' ) { }

=head2 GET /api/qc_seq_read

Retrieve a specific QcSeqRead, by qc_seq_read_id

=cut

sub qc_seq_read_GET {
    my ( $self, $c, $qc_seq_read_id ) = @_;

    $c->assert_user_roles( 'read' );

    my $qc_seq_read = $c->model('Golgi')->retrieve( QcSeqRead => { id => $qc_seq_read_id });

    return $self->status_ok(
        $c,
        entity => $qc_seq_read,
    );
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
