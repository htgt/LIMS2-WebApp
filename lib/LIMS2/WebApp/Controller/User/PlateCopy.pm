package LIMS2::WebApp::Controller::User::PlateCopy;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::UI::PlateCopy - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return;
}

sub plate_from_copy :Path( '/user/plate_from_copy' ) :Args(0) {
    my ( $self, $c ) = @_;
$DB::single=1;

    $c->stash(
        plate_help  => $c->model('Golgi')->plate_help_info,
    );
    return;
}


sub plate_from_copy_process :Path( '/user/plate_from_copy_process' ) :Args(0) {
    my ( $self, $c ) = @_;
$DB::single=1;

    my $from_plate_name = $c->request->params->{from_plate_name};
    my $to_plate_name = $c->request->params->{new_plate_name};
    if ( !$from_plate_name or !$to_plate_name ){
        $c->flash->{'error_msg'} = 'Specify both "from" plate name and "to" plate name';
        return $c->res->redirect('/usr/plate_from_copy');
    }
}

=head
    my @process_types = map{ $_->id } @{ $c->model('Golgi')->list_process_types };
sub plate_upload_step2 :Path( '/user/plate_upload_step2' ) :Args(0) {
    my ( $self, $c ) = @_;
$DB::single=1;

    my $process_type = $c->request->params->{process_type};
    unless ( $process_type ) {
        $c->flash->{error_msg} = 'You must specify a process type';
        return $c->res->redirect('/user/plate_upload_step1');
    }

    $c->stash(
        process_type   => $process_type,
        process_fields => $c->model('Golgi')->get_process_fields( { process_type => $process_type } ),
        plate_types    => $c->model('Golgi')->get_process_plate_types( { process_type => $process_type } ),
        plate_help     => $c->model('Golgi')->plate_help_info,
    );

    my $step = $c->request->params->{plate_upload_step};
    
    return if !$step  || $step != 2; # Render the step 2 form

    my $plate = $self->process_plate_upload_form( $c );
    return unless $plate;

    $c->flash->{success_msg} = 'Created new plate ' . $plate->name;
    $c->res->redirect( $c->uri_for('/user/view_plate', { 'id' => $plate->id }) );
    return;
}

sub process_plate_upload_form :Private {
    my ( $self, $c ) = @_;
    $c->stash( $c->request->params );
    my $params = $c->request->params;

    my $well_data = $c->request->upload('datafile');
    unless ( $well_data ) {
        $c->stash->{error_msg} = 'No csv file with well data specified';
        return;
    }

    unless ( $params->{plate_name} ) {
        $c->stash->{error_msg} = 'Must specify a plate name';
        return;
    }

    unless ( $params->{plate_type} ) {
        $c->stash->{error_msg} = 'Must specify a plate type';
        return;
    }

    $params->{species} ||= $c->session->{selected_species};
    $params->{created_by} = $c->user->name;

    my $plate;
    $c->model('Golgi')->txn_do(
        sub {
            try{
                $plate = $c->model('Golgi')->create_plate_csv_upload( $params, $well_data->fh );
            }
            catch {
                $c->stash->{error_msg} = 'Error encountered while creating plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    return $plate ? $plate : undef;
}
=cut

=head1 AUTHOR

David Parry-Smith

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
