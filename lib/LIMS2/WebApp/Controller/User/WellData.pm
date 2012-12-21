package LIMS2::WebApp::Controller::User::WellData;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::WellData - Catalyst Controller

=head1 DESCRIPTION

Create, update or view specific plates well results.

=head1 METHODS

=cut

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return;
}

sub dna_status_update :Path( '/user/dna_status_update' ) :Args(0) {
    my ( $self, $c ) = @_;

    return unless $c->request->params->{update_dna_status};

    my $plate_name = $c->request->params->{plate_name};
    unless ( $plate_name ) {
        $c->stash->{error_msg} = 'You must specify a plate name';
        return;
    }
    $c->stash->{plate_name} = $plate_name;

    my $dna_status_data = $c->request->upload('datafile');
    unless ( $dna_status_data ) {
        $c->stash->{error_msg} = 'No csv file with dna status data specified';
        return;
    }

    my %params = (
        csv_fh     => $dna_status_data->fh,
        plate_name => $plate_name,
        species    => $c->session->{selected_species},
        user_name  => $c->user->name,
    );

    $c->model('Golgi')->txn_do(
        sub {
            try{
                my $msg = $c->model('Golgi')->update_plate_dna_status( \%params );
                $c->stash->{success_msg} = "Uploaded dna status information onto plate $plate_name:<br>"
                    . join("<br>", @{ $msg  });
                $c->stash->{plate_name} = '';
            }
            catch {
                $c->stash->{error_msg} = 'Error encountered while updating dna status data for plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    return;
}

sub genotyping_qc_data : Path( '/user/genotyping_qc_data') : Args(0){
    my ( $self, $c ) = @_;

    my $plate_name = $c->request->params->{plate_name};
    unless ( $plate_name ) {
        $c->stash->{error_msg} = 'You must specify a plate name';
        return;
    }
    $c->stash->{plate_name} = $plate_name;

    my $model = $c->model('Golgi');

    my $plate = $model->retrieve_plate({ name => $plate_name});

    my @value_names = (
        { title => 'Call', field=>'call'},
        { title => 'Copy Number', field => 'copy_number'},
        { title => 'Range', field => 'copy_number_range'},
        { title => 'Confidence', field => 'confidence' },
    );
    my @assay_types = sort map { $_->id } $model->schema->resultset('GenotypingResultType')->all;

        $c->stash->{assay_types} = \@assay_types;
        $c->stash->{value_names} = \@value_names;

        return;
}

sub update_colony_picks : Path( '/user/update_colony_picks' ) :Args(0) {
    my ( $self, $c ) = @_;
    my $params = $c->request->params;
    my $model =$c->model('Golgi');

    unless (exists $params->{plate_name} && exists $params->{well_name}){
        $c->stash(
            colony_pick_fields => (),
            go => 1,
        );
        return;
    }

    if ($params->{go} eq 2){
        $params->{created_by} = $c->user->name;

        try{
            $c->model('Golgi')->txn_do(
                sub {
                     $model->update_well_colony_picks( $params );
                     $c->stash->{success_msg} = "Successfully added colony picks";
                }
            );
        }
        catch{
            $c->stash->{error_msg} = "$_";
        };
        return;
    }
    my $colony_fields;
    my $plate_name = $params->{plate_name};
    my $well_name = $params->{well_name};

    try{
        $colony_fields = $model->get_well_colony_pick_fields_values($params);
    }
    catch{
        $c->stash(
            colony_pick_fields => (),
            plate_name => $plate_name,
            well_name => $well_name,
            go => 1,
        );
        return;
    };

    $c->stash(
        colony_pick_fields => $colony_fields,
        plate_name => $plate_name,
        well_name => $well_name,
        go => 2,
    );
    return;

}


sub upload_well_colony_picks_file_data  : Path( '/user/upload_well_colony_counts_file_data' ) :Args(0){
    my ( $self, $c ) = @_;


    my $well_colony_picks_data = $c->request->upload('datafile');
    $c->request->params->{created_by} = $c->user->name;

    unless ( $well_colony_picks_data ) {
        $c->flash->{error_msg} = 'No csv file with well colony counts data specified';
        $c->res->redirect( $c->uri_for('/user/update_colony_picks') );
        return;
    }

    $c->assert_user_roles('edit');
    try{
        $c->model('Golgi')->txn_do(
            sub {
                shift->upload_well_colony_picks_file_data( $well_colony_picks_data->fh, $c->request->params );
                 $c->flash->{success_msg} = 'Successfully added well colony counts to wells';
            }
        );
    }
    catch{
        $c->flash->{error_msg} = "$_";
    };

    $c->res->redirect( $c->uri_for('/user/update_colony_picks') );
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
