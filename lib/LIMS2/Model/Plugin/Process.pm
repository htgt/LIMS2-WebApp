package LIMS2::Model::Plugin::Plate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub _well_id_for {
    my ( $self, $data ) = @_;

    my %search;
    if ( $data->{id} ) {
        $search{ 'me.id' } = $data->{id};
    }
    if ( $data->{well_name} ) {
        $search{ 'me.name' } = $data->{well_name};
    }
    if ( $data->{plate_name} ) {
        $search{ 'plate.name' } = $data->{plate_name};
    }

    return $self->retrieve( Well => \%search, { join => 'plate' } )->id;
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

sub _pspec_create_process_aux_data_create_di {
    return {
        design_id => { validate => 'existing_design_id' },
        bacs      => { validate => 'hashref', optional => 1 }
    }
}

sub _create_process_aux_data_create_di {
    my ( $self, $params, $process ) = @_;

    my $validated_params = $self->check_params(
    
}


