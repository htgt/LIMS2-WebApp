package LIMS2::WebApp::Controller::PublicReports;
use Moose;
use LIMS2::Report;
use Try::Tiny;
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

=head2 well_genotyping_info

Page to choose the desired well, no arguments

=cut
sub well_genotyping_info_search :Path( '/public_reports/well_genotyping_info_search' ) :Args(0) {
    my ( $self, $c ) = @_;

    return;
}

=head2 well_genotyping_info

Page to display chosen well, takes a well id (later a barcode) or a plate/well combo

=cut
sub well_genotyping_info :Path( '/public_reports/well_genotyping_info' ) :Args() {
    my ( $self, $c, @args ) = @_;

    if ( @args == 1 ) {
        my $barcode = shift @args;

        $self->_stash_well_genotyping_info( $c, { barcode => $barcode } );
    }
    elsif ( @args == 2 ) {
        my ( $plate_name, $well_name ) = @args;

        $self->_stash_well_genotyping_info(
            $c, { plate_name => $plate_name, well_name => $well_name }
        );
    }
    else {
        $c->stash( error_msg => "Invalid number of arguments" );
    }

    return;
}

sub _stash_well_genotyping_info {
    my ( $self, $c, $search ) = @_;

    #well_id will become barcode
    my $well = $c->model('Golgi')->retrieve_well( $search );

    unless ( $well ) {
        $c->stash( error_msg => "Well doesn't exist" );
        return;
    }

    try {
        #needs to be given a method for finding genes
        my $data = $well->genotyping_info( sub { $c->model('Golgi')->find_genes( @_ ); } );
        $c->stash( data => $data );
    }
    catch {
        #get string representation if its a lims2::exception
        $c->stash( error_msg => ref $_ && $_->can('as_string') ? $_->as_string : $_ );
    };

    return;
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
