package LIMS2::WebApp::Controller::Root;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::Root::VERSION = '0.422';
}
## use critic

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

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $feed = $c->model('Golgi')->schema->resultset('Message')->search({
        lims => 1,
        expiry_date => { '>=', \'now()' }
    },
    {
        order_by => { -desc => 'created_date' }
    });
    my @messages;
    my @high_prior;
    while (my $status = $feed->next){
        my $message = $status->as_hash;
        if ($message->{priority} eq 'high'){
            push @high_prior, $message;
        } else {
            push @messages, $message;
        }
    }
    $c->stash(
        high => \@high_prior,
        normal => \@messages,
    );
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
