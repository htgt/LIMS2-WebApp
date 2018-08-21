package LIMS2::WebApp::Controller::User::RecombinaseUpload;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::RecombinaseUpload::VERSION = '0.510';
}
## use critic

use Moose;
use namespace::autoclean;
use Try::Tiny;
BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::UI::RecombinaseUpload - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub recombinase_upload :Path( '/user/recombinase_upload' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        process_fields => $c->model('Golgi')->get_process_fields( { process_type => 'recombinase' } )
    );
    return;
}

sub add_recombinase :Path( '/user/add_recombinase' ) :Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->request->params->{plate_name}
        and $c->request->params->{well_name}
        and $c->request->params->{recombinase} )
    {
        $c->flash->{error_msg}
            = 'Data must be specified for all three fields; Plate Name, Well Name and Recombinase';
        $c->res->redirect( $c->uri_for('/user/recombinase_upload') );
        return;
    }

    $c->assert_user_roles('edit');
    try{
        $c->model('Golgi')->txn_do(
            sub { shift->add_recombinase_data( $c->request->params ) }
        );
        $c->flash->{success_msg}
            = 'Add '
            . $c->request->params->{recombinase}
            . ' recombinase for well '
            . $c->request->params->{well_name}
            . ' on plate '
            . $c->request->params->{plate_name};
    }
    catch {
        s/\{.*?\}//;
        $c->flash->{error_msg} = 'Error: ' . $_;
    };
    $c->res->redirect( $c->uri_for('/user/recombinase_upload') );
    return;
}

sub upload_recombinase_file :Path( '/user/upload_recombinase_file' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $recombinase_data = $c->request->upload('datafile');

    unless ( $recombinase_data ) {
        $c->flash->{error_msg} = 'No csv file with recombinase data specified';
        $c->res->redirect( $c->uri_for('/user/recombinase_upload') );
        return;
    }

    $c->assert_user_roles('edit');
    try{
        $c->model('Golgi')->txn_do(
            sub {
                shift->upload_recombinase_file_data( $recombinase_data->fh);
            }
        );
        $c->flash->{success_msg} = 'Successfully added recombinase to wells';
    }
    catch{
        $c->flash->{error_msg} = "$_->message";
    };

    $c->res->redirect( $c->uri_for('/user/recombinase_upload') );
    return;
}

=head1 AUTHOR

Peter Matthews

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
