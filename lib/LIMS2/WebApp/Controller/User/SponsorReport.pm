package LIMS2::WebApp::Controller::User::SponsorReport;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::SponsorReport::VERSION = '0.203';
}
## use critic

use Moose;
use LIMS2::Model::Util::ReportForSponsors;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::SponsorReport - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut
sub index :Path( '/user/sponsor_report' ) {
    my ( $self, $c, $targeting_type ) = @_;

    if ( defined $targeting_type ) {
        # show report for the requested targeting type
        $self->_generate_front_page_report ( $c, $targeting_type );
    }
    else {
        # by default show the single_targeted report
        $self->_generate_front_page_report ( $c, 'single_targeted' );
    }

    return;
}

sub _generate_front_page_report {
    my ( $self, $c, $targeting_type ) = @_;

    $c->assert_user_roles( 'read' );

    my $species = $c->session->{selected_species};

    # Call ReportForSponsors plugin to generate report
    my $sponsor_report = LIMS2::Model::Util::ReportForSponsors->new( { 'species' => $species, 'model' => $c->model( 'Golgi' ), 'targeting_type' => $targeting_type, } );

    my $report_params = $sponsor_report->generate_top_level_report_for_sponsors( );

    # Fetch details from returned report parameters
    my $report_id   = $report_params->{ report_id };
    my $title       = $report_params->{ title };
    my $columns     = $report_params->{ columns };
    my $rows        = $report_params->{ rows };
    my $data        = $report_params->{ data };

    # Store report values in stash for display onscreen
    $c->stash(
        'report_id'      => $report_id,
        'title'          => $title,
        'targeting_type' => $targeting_type,
        'columns'        => $columns,
        'rows'           => $rows,
        'data'           => $data,
    );

    return;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
