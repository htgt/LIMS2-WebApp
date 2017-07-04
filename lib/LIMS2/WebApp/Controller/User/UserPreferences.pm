package LIMS2::WebApp::Controller::User::UserPreferences;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::UserPreferences::VERSION = '0.464';
}
## use critic

use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::UserPreferences - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub change_password :Path( '/user/change_password' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    return unless $params->{change_password};

    unless ( $params->{new_password} ) {
        $c->stash->{error_msg} = 'You must specify a new password';
        return;
    }

    unless ( $params->{new_password_confirm} ) {
        $c->stash->{error_msg} = 'You must fill in password confirm box as well';
        return;
    }

    unless ( $params->{new_password_confirm} eq $params->{new_password} ) {
        $c->stash->{error_msg} = 'new password and password confirm values do not match';
        return;
    }

    $c->model('Golgi')->txn_do(
        sub {
            try{
                my $user = $c->model('Golgi')->change_user_password(
                    {   id                   => $c->user->id,
                        new_password         => $params->{new_password},
                        new_password_confirm => $params->{new_password_confirm}
                    }
                );

                $c->flash->{success_msg} = 'Password successfully changed for: ' . $user->name ;
                $c->res->redirect( $c->uri_for('/') );
            }
            catch {
                $c->stash->{error_msg} = 'Error encountered while changing password : ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    return;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
