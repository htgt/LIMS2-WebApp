package LIMS2::WebApp::Controller::User::PlateUpload;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::UI::PlateUpload - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
}

sub plate_upload_step1 :Path( '/user/plate_upload_step1' ) :Args(0) {
    my ( $self, $c ) = @_;

    my @process_types = map{ $_->id } @{ $c->model('Golgi')->list_process_types };

    $c->stash(
        process_types => [ grep{ !/create_di/ } @process_types ],
    );
}

sub plate_upload_step2 :Path( '/user/plate_upload_step2' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $process_type = $c->request->params->{process_type};
    unless ( $process_type ) {
        $c->flash->{error_msg} = 'You must specify a process type';
        return $c->res->redirect('/user/plate_upload_step1');
    }

    $c->stash(
        process_type   => $process_type,
        process_fields => $c->model('Golgi')->get_process_fields( { process_type => $process_type } ),
        plate_types    => $c->model('Golgi')->get_process_plate_types( { process_type => $process_type } ),
    );

    return;
}

sub plate_upload_complete :Path( '/user/plate_upload_complete' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( $c->request->params );
    my $params = $c->request->params;

    my $well_data = $c->request->upload('datafile');
    unless ( $well_data ) {
        $c->stash->{error_msg} = 'No well data';
        $c->go( 'plate_upload_step2' );
    }

    unless ( $params->{plate_name} ) {
        $c->stash->{error_msg} = 'Must specify a plate name';
        $c->go( 'plate_upload_step2' );
    }

    unless ( $params->{plate_type} ) {
        $c->stash->{error_msg} = 'Must specify a plate type';
        $c->go( 'plate_upload_step2' );
    }

    $params->{species} ||= $c->session->{selected_species};
    $params->{created_by} = $c->user->name;

    my $plate_data = $c->model('Golgi')->process_plate_data( $params, $well_data->fh );

    my $plate;
    $c->model('Golgi')->txn_do(
        sub {
            try{
                $plate = $c->model('Golgi')->create_plate( $plate_data );
            }
            catch {
                $c->stash->{error_msg} = 'Error encountered while creating plate: ' . $_;
                $c->go( 'plate_upload_step2' );
                $c->model('Golgi')->txn_rollback;
            };
        }
    );
    #TODO clear stash

    $c->stash->{plate} = $plate;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
