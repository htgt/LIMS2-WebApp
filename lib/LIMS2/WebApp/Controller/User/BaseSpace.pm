package LIMS2::WebApp::Controller::User::BaseSpace;
use Data::Dumper;
use Moose;
use namespace::autoclean;
use LIMS2::Model::Util::BaseSpace;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

sub samples : Path('/user/basespace/samples') : Args(0) {
    my ( $self, $c ) = @_;
    my $bs = LIMS2::Model::Util::BaseSpace->new;
    my $project_id = $c->request->param('project');
    try {
        die { Message => 'You must specify a project' } if not $project_id;
        my $project = $bs->project($project_id);
        $c->stash->{json_data} = [ map { $_->sample_id } $project->samples ]; 
    }
    catch {
        $c->stash->{json_data} = $_;
    };
    $c->forward('View::JSON');
    return;

}

sub projects : Path('/user/basespace/projects') : Args(0) {
    my ( $self, $c ) = @_;
    my $bs = LIMS2::Model::Util::BaseSpace->new;
    try {
        $c->stash->{json_data} = { map { $_->{Id} => $_->{Name} } $bs->projects };
    }
    catch {
        $c->stash->{json_data} = $_;
    };
    $c->forward('View::JSON');
    return;
}

__PACKAGE__->meta->make_immutable;

1;

