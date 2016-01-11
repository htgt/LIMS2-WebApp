package LIMS2::WebApp::Controller::User::PlateEdit;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::PlateEdit::VERSION = '0.360';
}
## use critic

use Moose;
use namespace::autoclean;
use Try::Tiny;
use JSON;
use LIMS2::Model::Util::BarcodeActions qw(upload_plate_scan);


BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::PlateEdit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub begin :Private {
    my ( $self, $c ) = @_;

    unless ( $c->request->params->{id} ) {
        $c->flash->{error_msg} = 'No plate_id specified';
        $c->res->redirect( $c->uri_for('/user/browse_plates') );
        return;
    }

    $c->assert_user_roles( 'edit' );
    return;
}

sub delete_plate :Path( '/user/delete_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi')->delete_plate( { id => $params->{id} } );
                $c->flash->{success_msg} = 'Deleted plate ' . $params->{name};
                $c->res->redirect( $c->uri_for('/user/browse_plates') );
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while deleting plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
                $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
            };
        }
    );
    return;
}

sub rename_plate :Path( '/user/rename_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    unless ( $params->{new_name} ) {
        $c->flash->{error_msg} = 'You must specify a new plate name';
        $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
        return;
    }

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi')->rename_plate(
                    {   id       => $params->{id},
                        new_name => $params->{new_name}
                    }
                );

                $c->flash->{success_msg} = 'Renamed plate from ' . $params->{name}
                                         . ' to ' . $params->{new_name};
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while renaming plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
    return;
}

sub flag_virtual_plate :Path( '/user/flag_virtual_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    $c->model('Golgi')->txn_do(
        sub {
            try{
                my $plate = $c->model('Golgi')->retrieve_plate(
                    {   id       => $params->{id}, }
                );
                $plate->update( { is_virtual => 1 } );

                $c->flash->{success_msg} = 'Plate ' . $plate->name . ' status changed to virtual ';
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while setting virtual flag to true on plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
    return;
}

sub unflag_virtual_plate :Path( '/user/unflag_virtual_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    $c->model('Golgi')->txn_do(
        sub {
            try{
                my $plate = $c->model('Golgi')->retrieve_plate(
                    {   id       => $params->{id}, }
                );
                $plate->update( { is_virtual => 0 } );

                $c->flash->{success_msg} = 'Plate ' . $plate->name . ' status changed to not virtual ';
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while setting virtual flag to false on plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
    return;
}

sub add_comment_plate :Path( '/user/add_comment_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $timestamp = scalar localtime;
    my $user = $c->user->id;
    my $params = $c->request->params;

    unless ( $params->{comment} ) {
         $c->flash->{error_msg} = "Comments can't be empty";
         $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
         return;
    }

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi')->schema->resultset('PlateComment')->create(
                    {
                         plate_id      => $params->{id},
                         comment_text  => $params->{comment},
                         created_by_id => $user,
                         created_at    => $timestamp,
                    });

                $c->flash->{success_msg} = 'Comment created for plate ' . $params->{name};
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while creating comment: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
    return;
}

sub delete_comment_plate :Path( '/user/delete_comment_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi')->schema->resultset('PlateComment')->find(
                    {
                         id    => $params->{comment_id}
                    })->delete;

                $c->flash->{success_msg} = 'Comment deleted for plate ' . $params->{name};
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while deleting comment: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
    return;
}

sub update_plate_barcode :Path( '/user/update_plate_barcode' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    unless ( $params->{new_plate_barcode} ) {
        $c->flash->{error_msg} = 'You must specify a new plate barcode';
        $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
        return;
    }

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi')->set_plate_barcode(
                    {   id                => $params->{id},
                        new_plate_barcode => $params->{new_plate_barcode}
                    }
                );

                if ( $params->{curr_barcode} ) {
                    $c->flash->{success_msg} = 'Updated plate barcode from ' . $params->{curr_barcode}
                                         . ' to ' . $params->{new_plate_barcode};
                }
                else {
                    $c->flash->{success_msg} = 'Set plate barcode to ' . $params->{new_plate_barcode};
                }
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while updating plate barcode: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    $c->res->redirect( $c->uri_for('/user/view_plate', { id => $params->{id} }) );
    return;
}

sub update_plate_well_barcodes :Path( '/user/update_plate_well_barcodes' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;
    my $csv_barcodes_data_file = $c->request->upload('wellbarcodesfile');

    unless ( $csv_barcodes_data_file ) {
        $c->flash->{ 'error_msg' } = 'You must select a barcode csv file to upload';
        $c->res->redirect( $c->uri_for('/user/view_plate', { 'id' => $params->{ 'id' } }) );
        return;
    }

    my $list_messages = [];
    my $plate;
    my $plate_name;

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $plate = $c->model('Golgi')->retrieve_plate({ id => $params->{ 'id' } });
                $plate_name = $plate->name;
                my $upload_params = {
                    existing_plate_name => $plate->name,
                    species             => $c->session->{selected_species},
                    user                => $c->user->name,
                    csv_fh              => $csv_barcodes_data_file->fh,
                };
                ($plate, $list_messages) = upload_plate_scan($c->model('Golgi'), $upload_params);
            }
            catch {
                $c->flash->{ 'error_msg' } = 'Error encountered while updating plate tube barcodes: ' . $_;
                $c->log->debug('rolling back barcode upload actions');
                $c->model('Golgi')->txn_rollback;
                $c->res->redirect( $c->uri_for('/user/view_plate', { 'id' => $params->{ 'id' } }) );
            };
        }
    );

    # encode messages as json string to send to well results view
    my $json_text = encode_json( $list_messages );

    # find plate by name rather than ID so we get current version
    my $updated_plate = $c->model('Golgi')->retrieve_plate( { name => $plate_name } );

    $c->stash(
        template            => 'user/browseplates/view_well_barcode_results.tt',
        plate               => $updated_plate,
        well_results_list   => $json_text,
        username            => $c->user->name,
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
