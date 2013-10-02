package LIMS2::WebApp::Controller::API::DesignTargets;
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



    use Smart::Comments;
    my ( $self, $c ) = @_;

    ## $self
    $c->assert_user_roles('read');


    my $model = $c->model('Golgi')->schema;


    # my $species = shift;
    ## $species

    my (@dt_data) = get_design_targets_data(
        $model,
        $c->session->{selected_species}
    );

    # my @plate_well_data = $model->get_design_targets_data(
    #     $plate_name,
    #     $c->session->{selected_species}
    # );
    ## @dt_data


    return $self->status_ok( $c, entity => \@dt_data );


}

sub design_targets :Path('/api/design_targets') :ActionClass('REST') {
}


1;