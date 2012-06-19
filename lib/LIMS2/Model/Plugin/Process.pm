package LIMS2::Model::Plugin::Plate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub _well_id_for {
    my ( $self, $data ) = @_;

    $self->retrieve_well( $data )->id;
}

sub pspec_create_process {
    return {
        type         => { validate => 'existing_process_type' },
        input_wells  => { optional => 1 },
        output_wells => { optional => 1 }
    }
}

sub create_process {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_process, ignore_unknown => 1 );
    
    my $process = $self->schema->resultset( 'Process' )->create(
        type_id => $validated_params->{type}
    );

    for my $input_well ( @{ $process->{input_wells} || [] } ) {
        $process->create_related(
            process_input_wells => { well_id => $self->_well_id_for( $input_well ) }
        );
    }
                         
    for my $output_well ( @{ $process->{output_wells} || [] } ) {
        $process->create_related(
            process_output_wells => { well_id => $self->_well_id_for( $output_well ) }
        );
    }

    delete @{$params}{ qw( type input_wells output_wells ) };

    my $method = '_create_process_aux_data_ ' . $validated_params->{type};

    $self->throw( Implementation => "Don't know how to create auxiliary data for process type $validated_params->{type}" )
        unless $self->can( $method );

    $self->$method( $params, $process );

    return $process;
}

sub pspec__create_process_aux_data_create_di {
    return {
        design_id => { validate => 'existing_design_id' },
        bacs      => { validate => 'hashref', optional => 1 }
    }
}

sub _create_process_aux_data_create_di {
    my ( $self, $params, $process ) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_process_aux_data_create_di );

    $process->create_related( process_design => { design_id => $validated_params->{design_id} } );

    for my $bac_params ( @{ $validated_params->{bacs} || [] } ) {
        my $validated_bac_params = $self->check_params( $bac_params, { bac_plate   => { validate => 'bac_plate' },
                                                                       bac_library => { validate => 'bac_library' },
                                                                       bac_name    => { validate => 'bac_name' }
                                                                   } );
        my $bac_clone = $self->retrieve( BacClone => {
            name           => $validated_bac_params->{bac_name},
            bac_library_id => $validated_bac_params->{bac_library}
        } );
        
        $process->create_related( process_bacs => {
            bac_plate    => $validated_bac_params->{bac_plate},
            bac_clone_id => $bac_clone->id
        } );
    }

    return;
}

sub _create_process_aux_data_dna_prep {
    return;
}




