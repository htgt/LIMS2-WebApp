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

sub show_genotyping_qc_data :Path('/user/show_genotyping_qc_data') :Args(0){
	my ($self, $c) = @_;

    $c->stash->{plate_name} = $c->request->params->{plate_name};

    return;
}

sub genotyping_qc_data : Path( '/user/genotyping_qc_data') : Args(0){
	my ( $self, $c ) = @_;

    my $plate_name = $c->request->params->{plate_name};
    unless ( $plate_name ) {
        $c->flash->{error_msg} = 'You must specify a plate name';
        return $c->res->redirect('/user/show_genotyping_qc_data');
    }

    $c->stash->{plate_name} = $plate_name;

    my $model = $c->model('Golgi');
    my $plate;

    try{
    	$plate = $model->retrieve_plate({ name => $plate_name });
    }
    catch{
        $c->flash->{error_msg} = "Plate $plate_name not found";
        return $c->res->redirect('/user/show_genotyping_qc_data');
    };

    return unless $plate;

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

sub upload_genotyping_qc : Path( '/user/upload_genotyping_qc') : Args(0){
	my ($self, $c) = @_;

	unless ($c->request->params->{submit_genotyping_qc}){
		return;
	}

    my $genotyping_data = $c->request->upload('datafile');
    unless ( $genotyping_data ) {
        $c->stash->{error_msg} = 'No csv file with genotyping QC data specified';
        return;
    }

    $c->model('Golgi')->txn_do(
        sub {
            try{
                my $msg = $c->model('Golgi')->update_genotyping_qc_data({
                    csv_fh => $genotyping_data->fh,
                    created_by => $c->user->name,
                });
                $c->stash->{success_msg} = "Uploaded genotpying QC results<br>"
                    . join("<br>", @{ $msg  });
            }
            catch {
                $c->stash->{error_msg} = "Error encountered while uploading genotyping QC results: $_";
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
