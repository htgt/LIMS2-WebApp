package LIMS2::WebApp::Controller::User::Report;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Report::VERSION = '0.006';
}
## use critic

use Moose;
use LIMS2::Report;
use MooseX::Types::Path::Class;
use LIMS2::WebApp::Pageset;
use Text::CSV;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

has report_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1
);

=head1 NAME

LIMS2::WebApp::Controller::User::Report - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head1 GET /user/report/sync/$REPORT

Synchronously generate the report I<$REPORT>. Forward to an HTML view.

=cut

sub sync_report :Path( '/user/report/sync' ) :Args(1) {
    my ( $self, $c, $report ) = @_;

    $c->assert_user_roles( 'read' );

    my $report_id = LIMS2::Report::generate_report(
        model      => $c->model( 'Golgi' ),
        report     => $report,
        params     => $c->request->params,
        output_dir => $self->report_dir,
        async      => 0
    );

    return $c->forward( 'view_report', [ $report_id ] );
}

=head1 GET /user/report/async/$REPORT

Asynchronously generate the report I<$REPORT>. Delivers a holding page
while the report is generated.

=cut

sub async_report :Path( '/user/report/async' ) :Args(1) {
    my ( $self, $c, $report ) = @_;

    $c->assert_user_roles( 'read' );

    my $report_id = LIMS2::Report::generate_report(
        model      => $c->model('Golgi'),
        report     => $report,
        params     => $c->request->params,
        output_dir => $self->report_dir,
        async      => 1
    );

    $c->stash(
        template    => 'user/report/await_report.tt',
        report_name => $report,
        report_id   => $report_id
    );

    return;
}

=head1 GET /user/report/download/$REPORT_ID

Read report I<$REPORT_ID> from disk and deliver CSV file to browser.

=cut

sub download_report :Path( '/user/report/download' ) :Args(1) {
    my ( $self, $c, $report_id ) = @_;

    $c->assert_user_roles( 'read' );

    my ( $report_name, $report_fh ) = $self->_read_report_from_disk( $report_id );

    $c->response->status( 200 );
    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$report_name.csv" );
    $c->response->body( $report_fh );
    return;
}

=head1 GET /user/report/view/$REPORT_ID

Read report I<$REPORT_ID> from disk and deliver as paged HTML table.

=cut

sub view_report :Path( '/user/report/view' ) :Args(1) {
    my ( $self, $c, $report_id ) = @_;

    $c->assert_user_roles( 'read' );

    my ( $report_name, $report_fh ) = $self->_read_report_from_disk( $report_id );

    my $pageset = LIMS2::WebApp::Pageset->new(
        {
            total_entries    => $self->_count_rows( $report_fh ),
            entries_per_page => 30,
            current_page     => $c->request->param('page') || 1,
            pages_per_set    => 5,
            mode             => 'slide',
            base_uri         => $c->request->uri
        }
    );

    my $csv     = Text::CSV->new;
    my $columns = $csv->getline( $report_fh );

    my $skip = $pageset->entries_per_page * ( $pageset->current_page - 1 );
    for ( 1..$skip ) {
        $report_fh->getline;
    }

    my @data;
    for ( 1..$pageset->entries_per_page ) {
        my $row = $csv->getline( $report_fh )
            or last;
        push @data, $row;
    }

    $c->stash(
        template  => 'user/report/simple_table.tt',
        report_id => $report_id,
        title     => $report_name,
        pageset   => $pageset,
        columns   => $columns,
        data      => \@data,
    );
    return;
}

sub _count_rows {
    my ( $self, $fh ) = @_;

    my $count = 0;
    while ( $fh->getline ) {
        $count++;
    }

    $fh->seek(0,0);

    return $count - 1;
}

sub _read_report_from_disk {
    my ( $self, $report_id ) = @_;

    my $dir = $self->report_dir->subdir( $report_id );

    my $report_fh   = $dir->file( 'report.csv' )->openr;
    my $report_name = $dir->file( 'name' )->slurp;

    return ( $report_name, $report_fh );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
