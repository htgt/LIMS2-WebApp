package LIMS2::WebApp::Controller::User::PlateUpload;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::PlateUpload::VERSION = '0.396';
}
## use critic

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
    return;
}

sub plate_upload_step1 :Path( '/user/plate_upload_step1' ) :Args(0) {
    my ( $self, $c ) = @_;

    my @process_types = map { $_->id } @{ $c->model('Golgi')->list_process_types };

    $c->stash(
        process_types => [ grep{ !/create_di|legacy_gateway|create_crispr/ } @process_types ],
        plate_help  => $c->model('Golgi')->plate_help_info,
    );
    return;
}

sub plate_upload_step2 :Path( '/user/plate_upload_step2' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $process_type = $c->request->params->{process_type};
    unless ( $process_type ) {
        $c->flash->{error_msg} = 'You must specify a process type';
        return $c->res->redirect('/user/plate_upload_step1');
    }
    my $cell_lines = $c->model('Golgi')->schema->resultset('DnaTemplate')->search();
    my @lines;
    while (my $line = $cell_lines->next){
        push(@lines, $line->as_string);
    }
    $c->stash(
        process_type   => $process_type,
        process_fields => $c->model('Golgi')->get_process_fields( { process_type => $process_type } ),
        plate_types    => $c->model('Golgi')->get_process_plate_types( { process_type => $process_type } ),
        plate_help     => $c->model('Golgi')->plate_help_info,
        cell_lines     => \@lines,
        dna_template   => $c->request->params->{source_dna},
    );

    my $step = $c->request->params->{plate_upload_step};
    return if !$step  || $step != 2;

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
    if ( $params->{plate_type} eq 'INT' && $params->{source_dna} eq '' ) {
        $c->stash->{error_msg} = 'Must specify a DNA template for INT vectors';
        return;
    }

    my $comment;
    if ( $params->{process_type} eq 'int_recom' ) {
        unless ( $params->{planned_wells} ) {
            $c->stash->{error_msg} = 'Must specify the number of planned post-gateway wells';
            return;
        }
        $comment = {
             comment_text  => $params->{planned_wells} .' post-gateway wells planned for wells on plate '. $params->{plate_name},
             created_by_id => $c->user->id,
             created_at    => scalar localtime,
        }
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
            if ( $comment ) {
                $comment->{plate_id} = $plate->id;
                $c->model('Golgi')->schema->resultset('PlateComment')->create( $comment );
            }
        }
    );

    return $plate ? $plate : undef;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
