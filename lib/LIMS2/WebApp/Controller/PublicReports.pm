package LIMS2::WebApp::Controller::PublicReports;
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

=head2 index

=cut
sub sponsor_report :Path( '/public_reports/sponsor_report' ) {
    my ( $self, $c, $targeting_type ) = @_;

    my $species;

    if ($c->user_exists) {
        $c->request->params->{species} = $c->session->{selected_species};
    }

    if (!$c->request->params->{species}) {
        $c->request->params->{species} = 'Human';
    }

    $species = $c->request->params->{species};
    $c->session->{selected_species} = $species;

    if ( defined $targeting_type ) {
        # show report for the requested targeting type
        $self->_generate_front_page_report ( $c, $targeting_type, $species );
    }
    else {
        # by default show the single_targeted report
        $self->_generate_front_page_report ( $c, 'single_targeted', $species );
    }

    $c->stash(
        template    => 'publicreports/sponsor_report.tt',
    );

    return;
}

sub _generate_front_page_report {
    my ( $self, $c, $targeting_type, $species ) = @_;

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
        'species'        => $species,
        'targeting_type' => $targeting_type,
        'columns'        => $columns,
        'rows'           => $rows,
        'data'           => $data,
    );

    return;
}


sub view : Path( '/public_reports/sponsor_report' ) : Args(3) {
    my ( $self, $c, $targeting_type, $sponsor_id, $stage ) = @_;

    # expecting :
    # targeting type i.e. 'st' or 'dt' for single- or double-targeted
    # sponsor id is the project sponsor e.g. Syboss, Pathogens
    # stage is the level e.g. genes, DNA

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

    my $link = "/public_reports/sponsor_report/$targeting_type/$sponsor_id/$stage";
    my $type;

    if ($disp_stage eq 'Genes') {

        if (! $c->request->params->{type}) {
            $c->request->params->{type} = 'simple';
            return $c->response->redirect( $c->uri_for( "/public_reports/sponsor_report/$targeting_type/$sponsor_id/$stage", { type => 'simple' } ) );
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
            'template'             => 'publicreports/sponsor_sub_report.tt',
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








=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
