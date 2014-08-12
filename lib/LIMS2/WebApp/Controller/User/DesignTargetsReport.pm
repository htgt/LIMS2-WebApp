package LIMS2::WebApp::Controller::User::DesignTargetsReport;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::DesignTargetsReport::VERSION = '0.231';
}
## use critic

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::PlateView - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller to display plates in a widget for viewing and editing

=head1 METHODS

=cut

sub view_design_targets :Path( '/user/view_design_targets' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( template => 'user/pool/DesignTargetsLoader.tt');
#    return $c->res->redirect( $c->uri_for('/user/XepAppLoader') );
    return;
}

=head1 AUTHOR

t87-developers

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
