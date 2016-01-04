package LIMS2::WebApp::Controller::User::WellData;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::WellData::VERSION = '0.358';
}
## use critic

use Moose;
use namespace::autoclean;
use Try::Tiny;
use LIMS2::Model::Util::DataUpload qw(spreadsheet_to_csv);
use LIMS2::Report qw(get_raw_spreadsheet);

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

sub pcr_status_update :Path( '/user/pcr_status_update' ) :Args(0) {
    my ( $self, $c ) = @_;

    return unless $c->request->params->{update_pcr_status};

    my $plate_name = $c->request->params->{plate_name};
    unless ( $plate_name ) {
        $c->stash->{error_msg} = 'You must specify a plate name';
        return;
    }
    $c->stash->{plate_name} = $plate_name;

    my $pcr_status_data = $c->request->upload('datafile');
    unless ( $pcr_status_data ) {
        $c->stash->{error_msg} = 'No csv file with pcr status data specified';
        return;
    }

    my %params = (
        csv_fh     => $pcr_status_data->fh,
        plate_name => $plate_name,
        species    => $c->session->{selected_species},
        user_name  => $c->user->name,
    );

    $c->model('Golgi')->txn_do(
        sub {
            try{
                my $msg = $c->model('Golgi')->update_plate_pcr_status( \%params );
                $c->stash->{success_msg} = "Uploaded pcr status information onto plate $plate_name:<br>"
                    . join("<br>", @{ $msg  });
                $c->stash->{plate_name} = '';
            }
            catch {
                $c->stash->{error_msg} = 'Error encountered while updating pcr status data for plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    return;
}

## Can be used to upload egel_pass or quality values to well_dna_quality table
sub dna_quality_update :Path( '/user/dna_quality_update' ) :Args(0) {
    my ( $self, $c ) = @_;

    return unless $c->request->params->{update_dna_quality};

    my $plate_name = $c->request->params->{plate_name};
    unless ( $plate_name ) {
        $c->stash->{error_msg} = 'You must specify a plate name';
        return;
    }
    $c->stash->{plate_name} = $plate_name;

    my $dna_status_data = $c->request->upload('datafile');
    unless ( $dna_status_data ) {
        $c->stash->{error_msg} = 'No csv file with dna quality data specified';
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
                my $msg = $c->model('Golgi')->update_plate_dna_quality( \%params );
                $c->stash->{success_msg} = "Uploaded dna quality information onto plate $plate_name:<br>"
                    . join("<br>", @{ $msg  });
                $c->stash->{plate_name} = '';
            }
            catch {
                $c->stash->{error_msg} = 'Error encountered while updating dna quality data for plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    return;
}

sub dna_concentration_upload :Path( '/user/dna_concentration_upload' ) :Args(0) {
    my ( $self, $c ) = @_;

    if ($c->request->params->{spreadsheet}){

        my $upload = $c->request->upload('datafile');
        unless ($upload){
            $c->stash->{error_msg} = 'Error: No file uploaded';
            return;
        }

        # Attempt to parse spreadsheet
        # spreadsheet parse returns hash of worksheet names to csv files
        my $worksheets;
        try{
            $c->log->debug('Parsing spreadsheet '.$upload->filename);
            $worksheets = spreadsheet_to_csv($upload->tempname);
            $c->log->debug('Worksheets: ', (join ", ", keys %{ $worksheets || {} }) );
        }
        catch{
            $c->stash->{error_msg} = 'Error parsing spreadsheet '.$upload->filename.': '.$_;
            return;
        };

        # Stash worksheet names and tmp file names
        $c->stash->{worksheets} = $worksheets;
        return;
    }

    return;
}

sub dna_concentration_update :Path( '/user/dna_concentration_update' ) :Args(0) {
    my ( $self, $c ) = @_;

    my @map_params = grep{ $_ =~ /_map$/ } keys %{ $c->request->params };
    $c->log->debug('Map params: ', (join ", ", @map_params) );
    unless(@map_params){
        $c->flash->{error_msg} = "No worksheet to plate name mappings provided";
    }

    # Generate hash of plates to csv files
    my %csv_for_plate;
    foreach my $map_name (@map_params){
        my $plate_name = $c->request->params->{$map_name};
        my $worksheet_name = $map_name;
        $worksheet_name =~ s/_map$//;

        unless($plate_name){
            $c->log->debug("Ignoring worksheet $worksheet_name as no plate name has been provided for it" );
            next;
        }

        # This should not happen
        my $csv_name = $c->request->params->{$worksheet_name}
            or die "No temporary filepath found for worksheet $worksheet_name";

        $csv_for_plate{$plate_name} = $csv_name;
    }

    unless(%csv_for_plate){
        $c->flash->{error_msg} = "There were no plate updates to run";
    }

    ## no critic (RequireBriefOpen)
    $c->model('Golgi')->txn_do( sub{
        # Perform update for each plate
        while ( my ($plate, $csv) = each %csv_for_plate){
            open (my $fh, "<", $csv) or die $!;
            my %params = (
                csv_fh     => $fh,
                plate_name => $plate,
                species    => $c->session->{selected_species},
                user_name  => $c->user->name,
                from_concentration => 1,
            );

            my $msg;
            try{
                $msg = $c->model('Golgi')->update_plate_dna_status( \%params );
                close $fh;
                $c->flash->{success_msg} .= "<br>Uploaded dna status information onto plate $plate:<br>"
                    . join("<br>", @{ $msg || [] });
            }
            catch {
                $c->flash->{error_msg} .= "<br>Error encountered while updating dna status data for plate $plate:<br>".$_;
            };
        }

        # If updates for any plate produced error messages we clear out the success message
        # and rollback the transaction so user can correct the file and start again
        if ($c->flash->{error_msg}){
            $c->flash->{success_msg} = undef;
            $c->log->debug("Rolling back DNA concentration update");
            $c->model('Golgi')->txn_rollback;
        }
    });
    ## use critic

    $c->response->redirect($c->uri_for('/user/dna_concentration_upload'));
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

    # set plate_type (usen in genotyping_qc_data.tt), and true on plate_type (used in grid.tt)
    $c->stash->{plate_type} = $plate->type;
    $c->stash->{$plate->type} = 1;

    my @value_names = (
        { title => 'Call', field=>'call'},
        { title => 'Copy Number', field => 'copy_number'},
        { title => 'Range', field => 'copy_number_range'},
        { title => 'Confidence', field => 'confidence' },
        { title => 'VIC', field => 'vic' },
    );
    my @assay_types = sort map { $_->id } $model->schema->resultset('GenotypingResultType')->all;

    $c->stash->{assay_types} = \@assay_types;
    $c->stash->{value_names} = \@value_names;

    return;
}

sub genotyping_qc_report : Path( '/user/genotyping_qc_report') : Args(1) {
    my ( $self, $c, $plate_name ) = @_;
    # generate the report for the plate as a CSV and return to the browser
    #
    $c->assert_user_roles( 'read' );


#    my $plate_name = $c->request->param('plate_name');

    my $model = $c->model('Golgi');
    my $plate = $model->retrieve_plate({ name => $plate_name});

    my @csv_plate_data = $model->csv_genotyping_qc_plate_data( $plate_name, $c->session->{selected_species});
# Add newlines to the end of each array line.
    @csv_plate_data = map { $_ . "\n" } @csv_plate_data;
    $c->response->status( 200 );
    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => 'attachment; filename='
            . $plate_name
            . '_gqc.csv' );
    my $body = join q{}, @csv_plate_data;
    $c->response->body( $body );
    return;
}

sub genotyping_qc_report_xlsx : Path( '/user/genotyping_qc_report_xlsx') : Args(1) {
    my ( $self, $c, $plate_name ) = @_;
    $c->assert_user_roles( 'read' );

    my $model = $c->model('Golgi');
    my $plate = $model->retrieve_plate({ name => $plate_name});

    my @csv_plate_data = $model->csv_genotyping_qc_plate_data( $plate_name, $c->session->{selected_species});

    @csv_plate_data = map { $_ . "\n" } @csv_plate_data;
    $c->response->status( 200 );
    $c->response->content_type( 'application/xlsx' );
    $c->response->header( 'Content-Disposition' => 'attachment; filename='
            . $plate_name
            . '_gqc.xlsx' );
    my $body = join q{}, @csv_plate_data;
    $body = get_raw_spreadsheet($plate_name, $body);
    $c->response->body( $body );
    return;
}


sub genotyping_grid_help : Path( '/user/genotyping_grid_help') : Args(0) {
    return;
}

sub update_colony_picks_step_1 : Path( '/user/update_colony_picks_step_1' ) :Args(0) {
    my ( $self, $c ) = @_;
    return;
}

sub update_colony_picks_step_2 : Path( '/user/update_colony_picks_step_2' ) :Args(0) {
    my ( $self, $c ) = @_;
    my $params = $c->request->params;
    my $model = $c->model('Golgi');
    my $colony_fields;
    my $plate_name = $params->{plate_name};
    my $well_name = $params->{well_name};

    try{
        $colony_fields = $model->get_well_colony_pick_fields_values($params);
    }
    catch{
        $c->flash->{error_msg} = "$_";
        $c->res->redirect( $c->uri_for('/user/update_colony_picks_step_1') );
    };

    $c->stash(
        colony_pick_fields => $colony_fields,
        plate_name => $plate_name,
        well_name => $well_name,
    );

    return;

}

sub update_colony_picks : Path( '/user/update_colony_picks' ) :Args(0) {
    my ( $self, $c ) = @_;
    my $params = $c->request->params;
    my $model = $c->model('Golgi');

    $params->{created_by} = $c->user->name;

    try{
        $c->model('Golgi')->txn_do(
            sub {
                 $model->update_well_colony_picks( $params );
                 $c->flash->{success_msg} = "Successfully added colony picks";
            }
        );
    }
    catch{
        $c->flash->{error_msg} = "$_";
    };
    $c->res->redirect( $c->uri_for('/user/update_colony_picks_step_1') );
    return;
}

sub upload_well_colony_picks_file_data  : Path( '/user/upload_well_colony_counts_file_data' ) :Args(0){
    my ( $self, $c ) = @_;

    my $well_colony_picks_data = $c->request->upload('datafile');
    $c->request->params->{created_by} = $c->user->name;

    unless ( $well_colony_picks_data ) {
        $c->flash->{error_msg} = 'No csv file with well colony counts data specified';
        $c->res->redirect( $c->uri_for('/user/update_colony_picks_step_1') );
        return;
    }

    $c->assert_user_roles('edit');
    try{
        $c->model('Golgi')->txn_do(
            sub {
                shift->upload_well_colony_picks_file_data( $well_colony_picks_data->fh, $c->request->params );
            }
        );
        $c->flash->{success_msg} = 'Successfully added well colony counts to wells';
    }
    catch{
        $c->flash->{error_msg} = "$_";
    };

    $c->res->redirect( $c->uri_for('/user/update_colony_picks_step_1') );
    return;
}

sub upload_genotyping_qc : Path( '/user/upload_genotyping_qc') : Args(0){
	my ($self, $c) = @_;

    my @assay_types = sort map { $_->id } $c->model('Golgi')->schema->resultset('GenotypingResultType')->all;
    $c->stash->{assays} = \@assay_types;

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
David Parry-Smith

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
