package LIMS2::WebApp::Controller::User::Report;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Report::VERSION = '0.147';
}
## use critic

use Moose;
use LIMS2::Report;
use MooseX::Types::Path::Class;
use LIMS2::WebApp::Pageset;
use Text::CSV;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::Report - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head1 GET /user/report/cache/$REPORT

Retrieve a cached report. Generate the report asynchronously if there is no vaild copy in the cache.

=cut

sub cached_async_report :Path( '/user/report/cache' ) :Args(1) {
    my ( $self, $c, $report ) = @_;

    $c->assert_user_roles( 'read' );

    my $params = $c->request->params;
    $params->{species} ||= $c->session->{selected_species};
    delete $params->{sponsor} if $params->{sponsor} eq 'All';

    my $report_id = LIMS2::Report::cached_report(
        model      => $c->model( 'Golgi' ),
        report     => $report,
        params     => $params,
    );

    $c->stash(
        template    => 'user/report/await_report.tt',
        report_name => $report,
        report_id   => $report_id
    );

    return;
}

=head1 GET /user/report/sync/$REPORT

Synchronously generate the report I<$REPORT>. Forward to an HTML view.

=cut

sub sync_report :Path( '/user/report/sync' ) :Args(1) {
    my ( $self, $c, $report ) = @_;
    $c->assert_user_roles( 'read' );

    my $params = $c->request->params;
    $params->{species} ||= $c->session->{selected_species};

    my $report_id = LIMS2::Report::generate_report(
        model      => $c->model( 'Golgi' ),
        report     => $report,
        params     => $params,
        async      => 0
    );

    if ( not defined $report_id ) {
        $c->flash( error_msg => 'Failed to generate report' );
        return $c->response->redirect( $c->uri_for( '/' ) );
    }

    return $c->forward( 'view_report', [ $report_id ] );
}

=head1 GET /user/report/async/$REPORT

Asynchronously generate the report I<$REPORT>. Delivers a holding page
while the report is generated.

=cut

sub async_report :Path( '/user/report/async' ) :Args(1) {
    my ( $self, $c, $report ) = @_;

    $c->assert_user_roles( 'read' );

    my $params = $c->request->params;
    $params->{species} ||= $c->session->{selected_species};

    my $report_id = LIMS2::Report::generate_report(
        model      => $c->model('Golgi'),
        report     => $report,
        params     => $params,
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

    my ( $report_name, $report_fh ) = LIMS2::Report::read_report_from_disk( $report_id );

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

    my ( $report_name, $report_fh ) = LIMS2::Report::read_report_from_disk( $report_id );

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

    # Check for plate_id and set the is_virtual_plate flag if appropriate 

    my $is_virtual_plate = 0;

    if ( my $plate_id = $c->request->param('plate_id') ) {
        my $plate = $c->model( 'Golgi')->retrieve_plate({ id =>  $plate_id });
        $is_virtual_plate = $plate->is_virtual;
    }

    my @data;
    for ( 1..$pageset->entries_per_page ) {
        my $row = $csv->getline( $report_fh )
            or last;
        push @data, $row;
    }

    $c->stash(
        template        => 'user/report/simple_table.tt',
        report_id       => $report_id,
        title           => $report_name,
        pageset         => $pageset,
        columns         => $columns,
        data            => \@data,
        plate_is_virtual   => $is_virtual_plate,
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

sub select_sponsor :Path( '/user/report/sponsor' ) :Args(1) {
    my ( $self, $c, $report ) = @_;

    $c->stash(
        template    => 'user/report/select_sponsor.tt',
        report_name => $report
    );

    return;
}

sub select_vector_params :Path( '/user/report/vector' ) :Args(1) {
    my ( $self, $c, $report ) = @_;

    my @sponsors = map { $_->id } $c->model('Golgi')->schema->resultset('Sponsor')->all;
    $c->stash(
        template    => 'user/report/select_vector_params.tt',
        report_name => $report,
        sponsors    => [sort @sponsors],
    );

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
