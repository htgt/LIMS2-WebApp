package LIMS2::WebApp::Controller::Admin;

use Moose;
use TryCatch;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 auto

Check that the user is has been granted admin privileges; if not,
redirect to the login page.

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    if ( !$c->check_user_roles('admin') ) {
        $c->flash( error_msg => 'Please login as an admin user to proceed' );
        return $c->response->redirect( $c->uri_for( '/login', { goto_on_success => $c->request->uri } ) );
    }

    # Important, otherwise Catalyst jumps straight to end()
    return 1;
}

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    my $users = $c->model('Golgi')->list_users();

    $c->stash( users => [ map { $_->as_hash } @{$users} ] );

    return;
}

=head2 create_user

=cut

sub create_user : Path( '/admin/create_user' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( roles => $c->model('Golgi')->list_roles );

    return unless $c->request->method eq 'POST';

    my $username   = $c->request->param('user_name');
    my @user_roles = $c->request->param('user_roles');

    unless ( $username and @user_roles ) {
        $c->stash(
            user_name    => $username,
            checked_role => { map { $_ => 1 } @user_roles },
            error_msg    => 'Please specify the username and select at least one role for this user'
        );
        return;
    }

    my $model = $c->model('Golgi');

    my $password = $model->pwgen();

    my $user = $model->txn_do(
        sub {
            $model->create_user(
                {   name     => $username,
                    roles    => \@user_roles,
                    password => $password
                }
            );
        }
    );

    $c->flash( success_msg => "Created user $username with password $password" );
    return $c->response->redirect( $c->uri_for('/admin') );
}

=head2 announcements

=cut

sub announcements : Path( '/admin/announcements' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $messages = $c->model('Golgi')->list_messages();

    $c->stash ( messages => [ map { $_->as_hash } @{$messages} ] );

    return unless $c->request->method eq 'POST';

    return $c->response->redirect( $c->uri_for('/admin') );
}

=head2 create_announcement

=cut

sub create_announcement : Path( '/admin/announcements/create_announcement' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        priorities    => $c->model('Golgi')->list_priority(),
    );

    return unless $c->request->method eq 'POST';

    my $message = $c->request->param('message');
    my $expiry_date = $c->request->param('expiry_date');
    my $created_date = DateTime->now(time_zone=>'local');
    my $priority = $c->request->param('priority');
    my $wge = $c->request->param('wge_checkbox');
    my $htgt = $c->request->param('htgt_checkbox');
    my $lims = $c->request->param('lims_checkbox');

    unless ($wge or $htgt or $lims) {
        $c->stash (
            message_field   => $message,
            expiry_date     => $expiry_date,
            priority        => $priority,
            error_msg       => 'Please specify a system for the announcement'
        );
        return;
    }

    my $announcement = $c->model('Golgi')->create_message(
        {
            message         => $message,
            expiry_date     => $expiry_date,
            created_date    => $created_date,
            priority        => $priority,
            wge             => $wge,
            htgt            => $htgt,
            lims            => $lims,
        }

    );

    return;
}

=head2 update_user

=cut

sub update_user : Path( '/admin/update_user' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $user = $self->_retrieve_user_by_id($c);

    $c->stash(
        user         => $user,
        roles        => $c->model('Golgi')->list_roles,
        checked_role => { map { $_->name => 1 } $user->roles }
    );

    return unless $c->request->method eq 'POST';

    if ( $c->request->param('update_roles') ) {
        return $c->forward('update_user_roles');
    }

    if ( $c->request->param('reset_password') ) {
        return $c->forward('reset_user_password');
    }

    $c->stash( error_msg => 'No action selected' );

    return;
}

=head2 update_user_roles

=cut

sub update_user_roles : Private {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    my @roles = $c->request->param('user_roles');

    unless (@roles) {
        $c->stash( error_msg => 'Please select at least one role for the user' );
        return;
    }

    $c->log->info( 'Updating roles for user ' . $user->name );

    $c->model('Golgi')->txn_do(
        sub {
            shift->set_user_roles( { name => $user->name, roles => \@roles } );
        }
    );

    $c->flash( success_msg => 'Updated roles for ' . $user->name );
    return $c->response->redirect( $c->uri_for('/admin') );
}

=head2 reset_user_password

=cut

sub reset_user_password : Private {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    $c->log->info( 'Resetting password for ' . $user->name );

    my $model    = $c->model('Golgi');
    my $password = $model->pwgen;

    $model->txn_do(
        sub {
            $model->set_user_password( { name => $user->name, password => $password } );
        }
    );

    $c->flash( success_msg => 'Reset password for ' . $user->name . ' to ' . $password );
    return $c->response->redirect( $c->uri_for('/admin') );
}

=head2 disable_user

=cut

sub disable_user : Path( '/admin/disable_user' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $user = $self->_retrieve_user_by_id($c);

    $c->model('Golgi')->txn_do(
        sub {
            shift->disable_user( { name => $user->name } );
        }
    );

    $c->stash( success_msg => "Disabled user " . $user->name );
    return $c->go('index');
}

=head2 enable_user

=cut

sub enable_user : Path( '/admin/enable_user' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $user = $self->_retrieve_user_by_id($c);

    $c->model('Golgi')->txn_do(
        sub {
            shift->enable_user( { name => $user->name } );
        }
    );

    $c->stash( success_msg => "Enabled user " . $user->name );
    return $c->go('index');
}

sub _retrieve_user_by_id {
    my ( $self, $c ) = @_;

    my $user_id = $c->request->param('user_id');

    unless ( defined $user_id ) {
        $c->stash( error_msg => "Given no user to act on" );
        $c->go('index');
    }

    my $user = try {
        return $c->model('Golgi')
            ->retrieve( User => { 'me.id' => $user_id }, { prefetch => { user_roles => 'role' } } );
    }
    catch( LIMS2::Exception::NotFound $e) {
        $c->stash( error_msg => "Failed to retrieve user with id $user_id" );
            $c->go('index');
    };

    return $user;
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
