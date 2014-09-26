package LIMS2::WebApp::Controller::User::PlateEdit;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::PlateEdit::VERSION = '0.248';
}
## use critic

use Moose;
use namespace::autoclean;
use Try::Tiny;
use JSON;

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

    my $csv_barcodes_data = $self->parse_plate_well_barcodes_csv_file( $c, $csv_barcodes_data_file->fh );

    unless ( $csv_barcodes_data && keys %$csv_barcodes_data > 0 ) {
        $c->flash->{ 'error_msg' } = 'Error encountered while parsing plate well barcodes file, no data found in file';
    }

    my @list_messages = ();

    $c->model('Golgi')->txn_do(
        sub {
            try{
                my $plate = $c->model('Golgi')->retrieve_plate(
                    { 'id' => $params->{ 'id' } },
                    { 'prefetch' => { 'wells' => 'well_barcode' } }
                );

                my $wells_list = {};
                for my $well ( $plate->wells ) {
                    $wells_list->{ $well->name } = $well;
                }

                my @ordered_well_keys = sort keys %$wells_list;

                # check each well on the plate in alphabetic order
                for my $ordered_well_key ( @ordered_well_keys ) {
                    my $ordered_well = $wells_list->{ $ordered_well_key };

                    # all well names should have a barcode in the list
                    unless ( exists $csv_barcodes_data->{ $ordered_well->name } ) {
                        push ( @list_messages, {
                            'well_name' => $ordered_well->name,
                            'error' => 1,
                            'message' => 'A barcode is missing from the uploaded file for this tube and needs to be included.'
                        } );
                        next;
                    }

                    # check for unsuccessful scan text
                    if ( $csv_barcodes_data->{ $ordered_well->name } eq 'No Read' ) {
                        push ( @list_messages, {
                            'well_name' => $ordered_well->name,
                            'error' => 1,
                            'message' => 'Expected a tube in this location but the barcode scanner failed to read one, please re-scan the tube rack.'
                        } );
                        next;
                    }

                    # check whether the well already has a barcode
                    if ( $ordered_well->well_barcode ) {
                        # check if the barcode has changed
                        if ( $ordered_well->well_barcode->barcode eq $csv_barcodes_data->{ $ordered_well->name } ) {
                            # barcode unchanged
                            push ( @list_messages, {
                                'well_name' => $ordered_well->name,
                                'error' => 0,
                                'message' => 'This tube barcode was already set <' . $ordered_well->well_barcode->barcode . '>, so no update was needed.'
                            } );
                        } else {
                            # barcode differs
                            # TODO: need to eventually allow for movements of wells/tubes
                            push ( @list_messages, {
                                'well_name' => $ordered_well->name,
                                'error' => 1,
                                'message' => 'A barcode is already recorded for this tube location <' . $ordered_well->well_barcode->barcode . '>, which does not match the uploaded barcode <' . $csv_barcodes_data->{ $ordered_well->name } . '>.'
                            } );
                        }
                    } else {
                        # no barcode set for this well yet, set it
                        $ordered_well->create_related( 'well_barcode', { 'barcode' => $csv_barcodes_data->{ $ordered_well->name } } );

                        push ( @list_messages, {
                            'well_name' => $ordered_well->name,
                            'error' => 0,
                            'message' => 'This tube barcode will be set to the uploaded value <' . $csv_barcodes_data->{ $ordered_well->name } . '>.'
                        } );
                    }
                }

                # check here to see if we have scanned more barcodes than there are tubes in the rack
                # this is Ok, lab may leave whole 96 tubes rather than risk compromising sterility
                # by moving some in or out
                my @ordered_barcode_keys = sort keys %$csv_barcodes_data;

                for my $ordered_barcode_key ( @ordered_barcode_keys ) {

                    next if $csv_barcodes_data->{ $ordered_barcode_key } eq 'No Read';

                    unless ( exists $wells_list->{ $ordered_barcode_key } ) {
                        push ( @list_messages, {
                            'well_name' => $ordered_barcode_key,
                            'error' => 2,
                            'message' => 'A barcode <' . $csv_barcodes_data->{ $ordered_barcode_key } . '> has been scanned for a location where no tube was present, ignoring.'
                        } );
                        next;
                    }
                }
            }
            catch {
                $c->flash->{ 'error_msg' } = 'Error encountered while updating plate tube barcodes: ' . $_;
                $c->model('Golgi')->txn_rollback;
                $c->res->redirect( $c->uri_for('/user/view_plate', { 'id' => $params->{ 'id' } }) );
            };
        }
    );

    # encode messages as json string to send to well results view
    my $json_text = encode_json( \@list_messages );

    my $plate = $c->model('Golgi')->retrieve_plate( { id => $params->{ 'id' } } );

    $c->stash(
        template            => 'user/browseplates/view_well_barcode_results.tt',
        plate               => $plate,
        well_results_list   => $json_text,
        username            => $c->user->name,
    );

    return;
}

sub parse_plate_well_barcodes_csv_file {
    my ( $self, $c, $fh ) = @_;

    my $csv_data = {};

    try {
        my $csv = Text::CSV_XS->new( { blank_is_undef => 1, allow_whitespace => 1 } );

        while ( my $line = $csv->getline( $fh )) {
            my @fields = split "," , $line;
            my $curr_well = $line->[0];
            my $curr_barcode = $line->[1];
            $csv_data->{ $curr_well } = $curr_barcode;
        }
    }
    catch{
        $c->flash->{error_msg} = 'Error encountered while parsing plate well barcodes file: ' . $_;
        return;
    };

    unless ( keys %$csv_data > 0 ) {
        $c->flash->{error_msg} = 'Error encountered while parsing plate well barcodes file, no data found in file';
        return;
    }

    return $csv_data;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
