package LIMS2::WebApp::Controller::PublicReports::API;
use Moose;
use LIMS2::Report;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::PublicReports::API- Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller - API for public reports, check if a report being generated is ready.

=cut

sub report_ready :Path( '/public_reports/ready' ) :Args(1) :ActionClass('REST') {
}

sub report_ready_GET {
    my ( $self, $c, $report_id ) = @_;

    my $status = LIMS2::Report::get_report_status( $report_id );
    return $self->status_ok( $c, entity => { status => $status } );
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
