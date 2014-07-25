package LIMS2::WebApp::Controller::User::SummaryReports;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::SummaryReports::VERSION = '0.224';
}
## use critic

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::SummaryReports - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub view : Path( '/user/view_summary_report' ) : Args(3) {
    my ( $self, $c, $targeting_type, $sponsor_id, $stage ) = @_;

    # expecting :
    # targeting type i.e. 'st' or 'dt' for single- or double-targeted
    # sponsor id is the project sponsor e.g. Syboss, Pathogens
    # stage is the level e.g. Targeted genes, DNA

    $c->assert_user_roles( 'read' );

    # depending on combination of targeting type and stage fetch details

    my $species = $c->session->{selected_species};


    # Call ReportForSponsors plugin to generate report
    my $sponsor_report = LIMS2::Model::Util::ReportForSponsors->new( { 'species' => $species, 'model' => $c->model( 'Golgi' ), 'targeting_type' => $targeting_type, } );

    my $report_params = $sponsor_report->generate_sub_report($sponsor_id, $stage);

    # Fetch details from returned report parameters
    my $report_id        = $report_params->{ 'report_id' };
    my $disp_target_type = $report_params->{ 'disp_target_type' };
    my $disp_stage       = $report_params->{ 'disp_stage' };
    my $columns          = $report_params->{ 'columns' };
    my $display_columns  = $report_params->{ 'display_columns' };
    my $data             = $report_params->{ 'data' };

    my $link = "/user/view_summary_report/$targeting_type/$sponsor_id/$stage";
    my $type;

    if ($disp_stage eq 'Targeted genes') {

        if (! $c->request->params->{type}) {
            $c->request->params->{type} = 'simple';
            return $c->response->redirect( $c->uri_for( "/user/view_summary_report/$targeting_type/$sponsor_id/$stage", { type => 'simple' } ) );
        }

        $type = $c->request->params->{type};

        if ($type eq 'simple') {

            foreach my $column ( @{$data} ) {
                while ( my ($key, $value) = each %{$column} ) {
                    if (${$column}{$key} eq '0') {
                        ${$column}{$key} = '';
                    }
                    else {
                        ${$column}{$key} = '✔'
                        unless ($key eq 'gene_id' || $key eq 'gene_symbol');
                    }
                }
            }
        }
    };

    # csv download
    if ($c->request->params->{csv}) {
        $c->response->status( 200 );
        $c->response->content_type( 'text/csv' );
        $c->response->header( 'Content-Disposition' => 'attachment; filename=report.csv');

        my $body = join(',', map { $_ } @{$display_columns}) . "\n";
        foreach my $column ( @{$data} ) {
            $body .= join(',', map { $column->{$_} } @{$columns}) . "\n";
            $body =~ s/✔/1/g;
        }

        $c->response->body( $body );

    } else {

    # Store report values in stash for display onscreen
        $c->stash(
            'report_id'            => $report_id,
            'disp_target_type'     => $disp_target_type,
            'disp_stage'           => $disp_stage,
            'sponsor_id'           => $sponsor_id,
            'columns'              => $columns,
            'display_columns'      => $display_columns,
            'data'                 => $data,
            'link'                 => $link,
            'type'                 => $type,
        );

    }

    return;
}

=head1 AUTHOR

Andrew Sparkes

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
