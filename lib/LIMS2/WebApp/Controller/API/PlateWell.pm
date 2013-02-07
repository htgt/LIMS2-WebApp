package LIMS2::WebApp::Controller::API::PlateWell;
use Moose;
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::PlateWell - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub plate_list :Path('/api/plate') :Args(0) :ActionClass('REST') {
}

sub plate_list_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my ( $plate_list ) = $c->model('Golgi')->txn_do(
        sub {
            shift->list_plates( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $plate_list );
}

sub plate :Path('/api/plate') :Args(0) :ActionClass('REST') {
}

sub plate_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $plate = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_plate( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $plate );
}

sub plate_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $plate = $c->model('Golgi')->txn_do(
        sub {
            shift->create_plate( $c->request->data )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/plate', { id => $plate->id } ),
        entity => $plate
    );
}

sub well :Path('/api/well') :Args(0) :ActionClass('REST') {
}

sub well_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $well = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_well( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $well );
}

sub well_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $well = $c->model('Golgi')->txn_do(
        sub {
            shift->create_well( $c->request->data )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/well', { id => $well->id } ),
        entity => $well
    );
}

sub well_DELETE {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    $c->model('Golgi')->txn_do(
        sub {
            shift->delete_well( $c->request->params );
        }
    );

    return $self->status_no_content( $c );
}

sub well_accepted_override :Path('/api/well/accepted') :Args(0) :ActionClass('REST') {
}

sub well_accepted_override_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $override = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_well_accepted_override( $c->request->params );
        }
    );

    return $self->status_ok( $c, entity => $override );
}

sub well_accepted_override_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $override = $c->model('Golgi')->txn_do(
        sub {
            shift->create_well_accepted_override( $c->request->data )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/well/accepted', { well_id => $override->well_id } ),
        entity   => $override
    );
}

sub well_accepted_override_PUT {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $override = $c->model('Golgi')->txn_do(
        sub {
            shift->update_well_accepted_override( $c->request->data )
        }
    );

    return $self->status_ok(
        $c,
        entity => $override
    );
}

sub well_recombineering_result :Path('/api/well/recombineering_result') :Args(0) :ActionClass('REST') {
}

sub well_recombineering_result_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $rec_results = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_well_recombineering_results( $c->request->params );
        }
    );

    return $self->status_ok( $c, entity => $rec_results );
}

sub well_recombineering_result_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $rec_result = $c->model('Golgi')->txn_do(
        sub {
            shift->create_well_recombineering_result( $c->request->data )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/well/recombineering_result', { well_id => $rec_result->well_id } ),
        entity   => $rec_result
    );
}

sub well_dna_status :Path('/api/well/dna_status') :Args(0) :ActionClass('REST') {
}

sub well_dna_status_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $dna_status = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_well_dna_status( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $dna_status );
}

sub well_dna_status_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $dna_status = $c->model('Golgi')->txn_do(
        sub {
            shift->create_well_dna_status( $c->request->data )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/well/dna_status', { well_id => $dna_status->well_id } ),
        entity   => $dna_status
    );
}

sub well_genotyping_qc_list :Path('/api/well/genotyping_qc') :Args(0) :ActionClass('REST'){
}

sub well_genotyping_qc_list_GET {
    my ( $self, $c ) = @_;
    $c->assert_user_roles('read');

    my $plate_name = $c->request->param('plate_name');

    my $model = $c->model('Golgi');

    my $plate = $model->retrieve_plate({ name => $plate_name});
    my @well_data = $model->get_genotyping_qc_browser_data(
        $plate_name,
        $c->session->{selected_species}
    );
#    my $debug_limit = 10;
#	my @well_data;
#	foreach my $well ($plate->wells){
#		my $datum = $well->all_genotyping_qc_data;
#		push @well_data, $datum;
#        last if !$debug_limit--;
#    }
    return $self->status_ok( $c, entity => \@well_data );
}

sub well_genotyping_qc :Path('/api/well/genotyping_qc') :Args(1) :ActionClass('REST') {
}

sub well_genotyping_qc_PUT{
    my ( $self, $c, $well_id ) = @_;

    $c->assert_user_roles('edit');
    my $data = $c->request->data;
    my $plate_name = $c->request->param('plate_name');

    # $data will contain a key for well 'id' and a key whose name is the column name
    # and whose value is the new value to be passed as an update.
    # e.g. 'chr1#call' => 'fail'
    delete $data->{'id'}; # this is already in $well_id
    my ( $assay_type, $assay_value ) = each %{$data};

    my $model = $c->model('Golgi');
    my $params = {};


    $params->{assay_name} = $assay_type;
    $params->{assay_value} = $assay_value;
    $params->{well_id} = $well_id;
    $params->{created_by} = $c->user->name;


    # Transaction happens at the controller level
    # need transaction_do to start here...
    $model->txn_do(
        sub {
            shift->update_genotyping_qc_value( $params );
        }
    ); # end transaction
    # and finish here.
    my $new_data = $c->model('Golgi')->retrieve_well({ id => $well_id})->all_genotyping_qc_data(
        $model,
        $c->session->{selected_species}
    );

    return $self->status_created(
        $c,
        location => $c->uri_for('/api/well/genotyping_qc', {plate_name => $plate_name}),
        entity => $new_data,
    );
}

sub well_dna_quality :Path('/api/well/dna_quality') :Args(0) :ActionClass('REST') {
}

sub well_dna_quality_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $dna_quality = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_well_dna_quality( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $dna_quality );
}

sub well_dna_quality_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $dna_quality = $c->model('Golgi')->txn_do(
        sub {
            shift->create_well_dna_quality( $c->request->data )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/well/dna_quality', { well_id => $dna_quality->well_id } ),
        entity   => $dna_quality
    );
}

sub well_qc_sequencing_result :Path('/api/well/qc_sequencing_result') :Args(0) :ActionClass('REST') {
}

sub well_qc_sequencing_result_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $qc_sequencing_result = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_well_qc_sequencing_result( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $qc_sequencing_result );
}

sub well_qc_sequencing_result_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $qc_sequencing_result = $c->model('Golgi')->txn_do(
        sub {
            shift->create_well_qc_sequencing_result( $c->request->data )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/well/qc_sequencing_result', { well_id => $qc_sequencing_result->well_id } ),
        entity   => $qc_sequencing_result
    );
}

sub well_qc_sequencing_result_DELETE {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    $c->model('Golgi')->txn_do(
        sub {
            shift->delete_well_qc_sequencing_result( $c->request->params )
        }
    );

    return $self->status_no_content( $c );
}

sub well_colony_picks :Path('/api/well/colony_picks') :Args(0) :ActionClass('REST') {
}

sub well_colony_picks_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $colony_picks = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_well_colony_picks( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $colony_picks );
}

sub well_colony_picks_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $colony_picks = $c->model('Golgi')->txn_do(
        sub {
            shift->create_well_colony_picks( $c->request->data )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/well/colony_picks', { well_id => $colony_picks->well_id } ),
        entity   => $colony_picks
    );
}

sub well_primer_bands :Path('/api/well/primer_bands') :Args(0) :ActionClass('REST') {
}

sub well_primer_bands_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $primer_bands = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_well_primer_bands( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $primer_bands );
}

sub well_primer_bands_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $primer_bands = $c->model('Golgi')->txn_do(
        sub {
            shift->create_well_primer_bands( $c->request->data )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/well/primer_bands', { well_id => $primer_bands->well_id } ),
        entity   => $primer_bands
    );
}


sub plate_assay_complete :Path('/api/plate/assay_complete') :Args(0) :ActionClass('REST') {
}

sub plate_assay_complete_PUT {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    my %params = (
        %{ $c->request->params },
        %{ $c->request->data }
    );

    $c->model('Golgi')->txn_do(
        sub {
            shift->set_plate_assay_complete( \%params );
        }
    );

    return $self->status_no_content( $c );
}

sub well_assay_complete :Path('/api/well/assay_complete') :Args(0) :ActionClass('REST') {
}

sub well_assay_complete_PUT {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    my %params = (
        %{ $c->request->params },
        %{ $c->request->data }
    );

    $c->model('Golgi')->txn_do(
        sub {
            shift->set_well_assay_complete( \%params );
        }
    );

    return $self->status_no_content( $c );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
