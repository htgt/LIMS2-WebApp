package LIMS2::WebApp::Controller::API::Report;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Report::VERSION = '0.006';
}
## use critic

use Moose;
use MooseX::Types::Path::Class;
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

has report_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1
);

=head1 NAME

LIMS2::WebApp::Controller::API::Report - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub report_ready :Path( '/api/report/ready' ) :Args(1) :ActionClass('REST') {
}

sub report_ready_GET {
    my ( $self, $c, $report_id ) = @_;

    $c->assert_user_roles( 'read' );

    my $work_dir = $self->report_dir->subdir( $report_id );

    unless ( $work_dir->stat and -d _ ) {
        return $self->status_ok( $c, entity => { status => 'NOT_FOUND' } );
    }

    if ( $work_dir->file( 'done' )->stat ) {
        return $self->status_ok( $c, entity => { status => 'DONE' } );
    }

    if ( $work_dir->file( 'failed' )->stat ) {
        return $self->status_ok( $c, entity => { status => 'FAILED' } );
    }

    return $self->status_ok( $c, entity => { status => 'PENDING' } );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
