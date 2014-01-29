package LIMS2::WebApp::Controller::PublicReports;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::PublicReports::VERSION = '0.150';
}
## use critic

use Moose;
use LIMS2::Report;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::PublicReports - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for reports that a un-authenticated user can access.

=cut

=head2 index

List of public reports

=cut
sub index : Path( '/public_reports' ) : Args(0) {
    my ( $self, $c ) = @_;

    return;
}

=head2 cre_knockin_project_status

Report listing the status of cre knockin projects.

=cut
sub cre_knockin_project_status : Path( '/public_reports/cre_knockin_project_status' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $report_id = LIMS2::Report::cached_report(
        model  => $c->model( 'Golgi' ),
        report => 'LegacyCreKnockInProjects',
        params => {},
    );

    $c->stash(
        template    => 'publicreports/await_report.tt',
        report_name => 'Cre_KnockIn_Project_Status',
        report_id   => $report_id
    );

    return;
}

=head2 download_report

Downloads a csv report of a given report_id

=cut
sub download_report :Path( '/public_reports/download' ) :Args(1) {
    my ( $self, $c, $report_id ) = @_;

    my ( $report_name, $report_fh ) = LIMS2::Report::read_report_from_disk( $report_id );

    $c->response->status( 200 );
    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$report_name.csv" );
    $c->response->body( $report_fh );
    return;
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
