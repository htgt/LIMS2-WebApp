package LIMS2::WebApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=head1 NAME

LIMS2::WebApp::Controller::Root - Root Controller for LIMS2::WebApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 auto

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    if ( ! $c->session->{selected_species} ) {
        if ( $c->user ) {
            my $prefs = $c->model('Golgi')->retrieve_user_preferences( { id => $c->user->id } );
            $c->session->{selected_species} = $prefs->default_species_id;
        }
        else {
            $c->session->{selected_species} = 'Mouse';
        }        
    }

    if ( ! $c->session->{species} ) {
        $c->session->{species} = $c->model('Golgi')->list_species;        
    }

    return 1;
}

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    return $c->go( 'User', 'index' );
}

=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
    return;
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
