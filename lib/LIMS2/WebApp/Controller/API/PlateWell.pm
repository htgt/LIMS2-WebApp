package LIMS2::WebApp::Controller::API::PlateWell;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use LIMS2::Model::Util::Miseq qw( query_miseq_details wells_generator );
use LIMS2::Model::Util::BarcodeActions qw( create_barcoded_plate );
use JSON;
use POSIX;

BEGIN { extends 'LIMS2::Catalyst::Controller::REST'; }

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

sub well_toggle_to_report : Path( '/api/well/toggle_to_report' ) : Args(0) : ActionClass( 'REST' ) {
}

sub well_toggle_to_report_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->toggle_to_report( { id => $c->request->param( 'id' ),
                to_report => $c->request->param( 'to_report' ) } );
        }
    );

    return $self->status_ok( $c, entity => $project->as_hash );
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
    my @plate_well_data = $model->get_genotyping_qc_plate_data(
        $plate_name,
        $c->session->{selected_species}
    );
    return $self->status_ok( $c, entity => \@plate_well_data );
}

sub well_genotyping_qc :Path('/api/well/genotyping_qc') :Args(1) :ActionClass('REST') {
}

sub well_genotyping_qc_PUT{
    my ( $self, $c, $well_id ) = @_;
    $c->assert_user_roles('edit');

    my $data = $c->request->data;
    my $plate_name = $c->request->param('plate_name');
    my $species = $c->session->{'selected_species'};
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
    # The session species is required for the gene symbol lookup
    my @well_list;
    push @well_list, $well_id;
    my ($new_data) = $model->get_genotyping_qc_well_data( \@well_list, $plate_name, $species );

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

sub genotyping_qc_save_distribute_changes :Path('/api/plate/genotyping_qc_save_distribute_changes') :Args(0) :ActionClass('REST') {
}

sub genotyping_qc_save_distribute_changes_GET {
    my ( $self, $c ) = @_;
    # accept the calculated allele type genotyping pass results and set the well accepted flag accordingly

    $c->assert_user_roles( 'edit' );

    my $plate_name = $c->request->params->{ 'plate_name' };

    my $model = $c->model('Golgi');
    my $plate = $model->retrieve_plate({ 'name' => $plate_name } );

    return unless $plate;

    my @plate_data = $model->get_genotyping_qc_plate_data( $plate_name, $c->session->{ 'selected_species' } );

    # apply updates to well accepted flag for each well
    my $failed;
    try {
        foreach my $well_hash ( @plate_data ) {
            # if find update_accepted then run update
            if ( exists $well_hash->{ 'update_for_accepted' } ) {

                my $update_for_accepted = $well_hash->{ 'update_for_accepted' };
                my $well_id             = $well_hash->{ 'id' };
                if ( exists $well_hash->{ 'accepted_rules_version' } ) {
                    my $rules_version   = $well_hash->{ 'accepted_rules_version' };
                    $model->update_well_accepted( { 'well_id' => $well_id, 'accepted' => $update_for_accepted, 'accepted_rules_version' => $rules_version, } );
                }
                else {
                    $model->update_well_accepted( { 'well_id' => $well_id, 'accepted' => $update_for_accepted, } );
                }

                if ( $update_for_accepted ) {
                    $well_hash->{ 'accepted' } = 'yes';
                }
                else {
                    $well_hash->{ 'accepted' } = 'no';
                }
            }
        }
    }
    catch {
        $failed = $_;
    };

    if ( defined $failed ) {
        return $self->status_bad_request( $c, message => $_ );
    }

    return $self->status_ok( $c, entity => \@plate_data );
}

sub well_genotyping_crispr_qc :Path('/api/fetch_genotyping_info_for_well') :Args(1) :ActionClass('REST') {
}

sub well_genotyping_crispr_qc_GET {
    my ( $self, $c, $barcode ) = @_;

    #if this is slow we should use processgraph instead of 1 million traversals
    $c->assert_user_roles('read');

    my $well = $c->model('Golgi')->retrieve_well( { barcode => $barcode } );

    return $self->status_bad_request( $c, message => "Barcode $barcode doesn't exist" )
        unless $well;

    my ( $data, $error );
    try {
        #needs to be given a method for finding genes
        $data = $well->genotyping_info( sub { $c->model('Golgi')->find_genes( @_ ); } );
        $data->{child_barcodes} = $well->distributable_child_barcodes;
    }
    catch {
        #get string representation if its a lims2::exception
        $error = ref $_ && $_->can('as_string') ? $_->as_string : $_;
    };

    return $error ? $self->status_bad_request( $c, message => $error )
                  : $self->status_ok( $c, entity => $data );
}

sub create_piq_plate :Path('/api/create_piq_plate') :Args(0) :ActionClass('REST') {
}

sub create_piq_plate_GET {
    my ( $self, $c ) = @_;

    return;
}

sub create_piq_plate_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $json = $c->request->param('relations');
    my $data = decode_json $json;

    $data->{created_by} = $c->user->name;
    $data->{species} = $c->session->{selected_species};
    $data->{created_at} = strftime("%Y-%m-%dT%H:%M:%S", localtime(time));
    $data->{type} = 'PIQ';
    $data->{wells} = _transform_wells($data->{wells});
    my $barcodes = $data->{barcodes};
    delete $data->{barcodes};

    my $plate;# = $c->model('Golgi')->create_plate($data);
    if ($barcodes) {
        $plate = create_barcoded_plate($c->model('Golgi'), {
            plate_name          => $data->{name},
            barcode_for_well    => $barcodes,
            user                => $c->user->name,
        });
    }

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/plate', { id => $plate->id } ),
        entity   => $plate
    );
}

sub _transform_wells {
    my ( $wells_hash ) = @_;

    my @wells_arr;
    foreach my $well (keys %{ $wells_hash }) {
        my $well_relation = {
            well_name       => $well,
            process_type    => 'dist_qc',
            parent_well     => $wells_hash->{$well}->{parent_well},
            parent_plate    => $wells_hash->{$well}->{parent_plate},
        };

        push (@wells_arr, $well_relation);
    }

    return \@wells_arr;
}

sub wells_parent_plate :Path('/api/wells_parent_plate') :Args(0) :ActionClass('REST') {
}

sub wells_parent_plate_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');
    my $term = $c->request->param('plate');

    my $plate_rs = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $term });

    unless ($plate_rs) {
        return $self->status_bad_request(
            $c,
            message => "Bad Request: Can not find Plate: " . $term,
        );
    }
    my @wells = $c->model('Golgi')->schema->resultset('Well')->search({ plate_id => $plate_rs->id });
    my $mapping;
    foreach my $well (@wells) {
        foreach my $plate_well_rs (@{ $well->parent_plates }) {
            my $plate = $plate_well_rs->{plate};
            unless ($mapping->{$plate->name}) {
                $mapping->{$plate->name}->{type} = $plate->type->id;
            }
            push @{ $mapping->{$plate->name}->{wells} }, $well->name;
        }
    }

    my $json = JSON->new->allow_nonref;
    my $json_parents = $json->encode($mapping);

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $json_parents );

    return;
}

sub sibling_miseq_plate :Path('/api/sibling_miseq_plate') :Args(0) :ActionClass('REST') {
}

sub sibling_miseq_plate_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');
    my $term = $c->request->param('plate');

    my $plate_rs = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $term });

    unless ($plate_rs) {
        return $self->status_bad_request(
            $c,
            message => "Bad Request: Can not find Plate: " . $term,
        );
    }

    my @results = query_miseq_details($c->model('Golgi'), $plate_rs->id);
    my $class_mapping;
    foreach my $result (@results) {
        if ($result->{miseq_classification} ne 'Not Called' && $result->{miseq_classification} ne 'Mixed') {
            my $class_details = {
                classification  => $result->{miseq_classification},
                experiment_id   => $result->{experiment_id},
                miseq_exp_name  => $result->{miseq_experiment_name},
                miseq_plate_name => $result->{output_plate_name},
            };
            push (@{ $class_mapping->{$result->{origin_well_name}} }, $class_details);
        }
    }

    my $json = JSON->new->allow_nonref;
    my $json_parents = $json->encode($class_mapping);

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $json_parents );

    return;
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
