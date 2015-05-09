package LIMS2::WebApp::Controller::API::DesignTargets;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::DesignTargets::VERSION = '0.313';
}
## use critic

use Moose;
use LIMS2::Model::Util::DesignTargets qw( get_design_targets_data );
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::DesignTargets - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub design_targets_list :Path('/api/design_targets') :Args(0) :ActionClass('REST'){
}

sub design_targets_list_GET {


    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $model = $c->model('Golgi')->schema;

    my @dt_data = get_design_targets_data(
        $model,
        $c->session->{selected_species}
    );

    return $self->status_ok( $c, entity => \@dt_data );

}

sub design_targets :Path('/api/design_targets') :ActionClass('REST') {
}

1;
