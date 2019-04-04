package LIMS2::WebApp::Controller::User::EPPipelineIIWellExpansion;
use Moose;
use namespace::autoclean;
use Carp;
use Try::Tiny;
use LIMS2::Model::Util::EPPipelineIIWellExpansion qw(create_well_expansion);
BEGIN { extends 'Catalyst::Controller' }

sub expansion : Path( '/user/epII/expansion' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $parameters = {
        plate_name        => $c->request->param('plate_name'),
        parent_well       => $c->request->param('well_name'),
        child_well_number => $c->request->param('child_well_number'),
        species           => $c->session->{selected_species},
        created_by        => $c->user->name,
    };
    try {
        my $freeze_plates_created = create_well_expansion( $c->model('Golgi'), $parameters );
    $c->stash->{plate_list} = $freeze_plates_created;
    }
    catch {
        $c->stash->{error_msg} = "$_";
    };
    return;
}

__PACKAGE__->meta->make_immutable;

1;

