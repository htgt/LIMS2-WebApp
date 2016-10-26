package LIMS2::WebApp::Controller::User::BrowsePlates;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::BrowsePlates::VERSION = '0.428';
}
## use critic

use Moose;
use LIMS2::WebApp::Pageset;
use LIMS2::ReportGenerator::Plate;
use LIMS2::Model::Constants qw( %ADDITIONAL_PLATE_REPORTS );
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::BrowsePlates - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path( '/user/browse_plates' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    if ( $params->{show_all} ) {
        delete @{$params}{ qw( show_all plate_type plate_name ) };
    }

    if ( $params->{plate_type} and $params->{plate_type} eq '-' ) {
        delete $params->{plate_type};
    }

    my ( $plates, $pager ) = $c->model('Golgi')->list_plates(
        {
            plate_name => $params->{plate_name},
            plate_type => $params->{plate_type},
            species    => $params->{species} || $c->session->{selected_species},
            page       => $params->{page},
            pagesize   => $params->{pagesize},
        }
    );

    my $pageset = LIMS2::WebApp::Pageset->new(
        {
            total_entries    => $pager->total_entries,
            entries_per_page => $pager->entries_per_page,
            current_page     => $pager->current_page,
            pages_per_set    => 5,
            mode             => 'slide',
            base_uri         => $c->uri_for( '/user/browse_plates', $params )
        }
    );

    $c->stash(
        plate_types         => [ map { $_->id } @{ $c->model('Golgi')->list_plate_types } ],
        selected_plate_type => $params->{plate_type},
        plate_name          => $params->{plate_name},
        plates              => $plates,
        pageset             => $pageset
    );

    return;
}

sub view :Path( '/user/view_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    # prefetch wells->process_input_wells so we can do the has_child_wells check on plates ( for plate delete button condition )
    my $plate = $c->model('Golgi')->retrieve_plate( $c->request->params,
        { prefetch => { 'wells' => 'process_input_wells' } } );
    my $report_class = LIMS2::ReportGenerator::Plate->report_class_for( $plate->type_id );
    $report_class =~ s/^.*\:\://;
    $c->log->debug( "Report class: $report_class" );

    my $additional_plate_reports = $self->get_additional_plate_reports( $c, $plate );
    my $dna_template;
    if ($plate->as_hash->{type} eq 'INT') {
        $dna_template = get_template($c, $plate);
    }
    if ($plate->as_hash->{type} eq 'FINAL_PICK') {
        my $focus = $plate;
        while ($focus->type_id ne 'INT') {
            my @parents = @{$focus->parent_names};
            $focus = $c->model('Golgi')->retrieve_plate({ name => $parents[0]->{name} });
        }
        $dna_template = get_template($c, $focus);
    }
    $c->stash(
        plate                    => $plate,
        well_report_uri          => $c->uri_for( "/user/report/sync/$report_class", { plate_id => $plate->id } ),
        grid_report_uri          => $c->uri_for( "/user/report/sync/grid/$report_class", { plate_id => $plate->id } ),
        additional_plate_reports => $additional_plate_reports,
        username                 => $c->user->name,
        dna_template             => $dna_template,
    );

    return;
}

sub get_template {
    my ( $c, $focus) = @_;
    my $dna_template;
    my $plate_process = $c->model('Golgi')->schema->resultset('PlateProcess')->search(
        {},
        {
            bind => [ $focus->id, $focus->id ],
        }
    );

    while (my $process = $plate_process->next) {
        $process = $process->as_hash;
        if ($process->{dna_template}) {
            $dna_template = $process->{dna_template};
        }
    }

    return $dna_template;
}
sub get_additional_plate_reports : Private {
    my ( $self, $c, $plate ) = @_;

    return unless exists $ADDITIONAL_PLATE_REPORTS{ $plate->type_id };

    my @additional_reports;
    for my $report ( @{ $ADDITIONAL_PLATE_REPORTS{ $plate->type_id } } ) {
        my $url = $c->uri_for(
            '/user/report/' . $report->{method} . '/' . $report->{class},
            { plate_id => $plate->id, plate_name => $plate->name }
        );
        push @additional_reports, { report_url => $url, name => $report->{name} };
    }

    return \@additional_reports;
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
