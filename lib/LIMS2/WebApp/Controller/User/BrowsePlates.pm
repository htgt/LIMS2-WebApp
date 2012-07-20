package LIMS2::WebApp::Controller::User::BrowsePlates;
use Moose;
use LIMS2::WebApp::Pageset;
use LIMS2::Exception::Implementation;
use Module::Pluggable::Object;
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
            pagesize   => $params->{pagesize}
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

    my $plate = $c->model('Golgi')->retrieve_plate( $c->request->params );

    my $report_class = $self->_report_class_for( $c, $plate );
    $c->log->debug( "Report class: $report_class" );

    $c->stash(
        plate           => $plate,
        well_report_uri => $c->uri_for( "/user/report/sync/$report_class", { plate_id => $plate->id } )
    );

    return;
}

sub _report_plugins {
    return grep { $_->meta->does_role( 'LIMS2::Role::PlateReportGenerator' ) }
        Module::Pluggable::Object->new( search_path => [ 'LIMS2::Report' ], require => 1 )->plugins;
}

## no critic(RequireFinalReturn)
sub _report_class_for {
    my ( $self, $c, $plate ) = @_;

    my $plate_type = $plate->type_id;

    for my $plugin ( $self->_report_plugins ) {
        if ( $plugin->plate_type eq $plate_type ) {
            $c->log->debug( "Plugin class: $plugin" );
            $plugin =~ s/^.*\:\://;
            return $plugin;
        }
    }

    LIMS2::Exception::Implementation->throw( "No report class implemented for plate type $plate_type" );
}
## use critic

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
