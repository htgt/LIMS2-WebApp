package LIMS2::Model::Plugin::Process;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use List::MoreUtils qw( uniq notall );
use LIMS2::Model::Util::CreateProcess qw( process_fields process_plate_types check_process_wells );
use namespace::autoclean;
use Const::Fast;

requires qw( schema check_params throw retrieve log trace );

sub _well_id_for {
    my ( $self, $data ) = @_;

    return $self->retrieve_well($data)->id;
}

sub _cassette_id_for {
    my ( $self, $cassette_name ) = @_;

    my $cassette = $self->retrieve( Cassette => { name => $cassette_name } );
    return $cassette->id;
}

sub _backbone_id_for {
    my ( $self, $backbone_name ) = @_;

    my $backbone = $self->retrieve( Backbone => { name => $backbone_name } );
    return $backbone->id;
}

sub pspec_create_process {
    return {
        type         => { validate => 'existing_process_type' },
        input_wells  => { optional => 1 },
        output_wells => { optional => 1 }
    };
}

sub create_process {
    my ( $self, $params ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec_create_process, ignore_unknown => 1 );

    my $process
        = $self->schema->resultset('Process')->create( { type_id => $validated_params->{type} } );

    for my $input_well ( @{ $validated_params->{input_wells} || [] } ) {
        $process->create_related(
            process_input_wells => { well_id => well_id_for($input_well) } );
    }

    for my $output_well ( @{ $validated_params->{output_wells} || [] } ) {
        $process->create_related(
            process_output_wells => { well_id => well_id_for($output_well) } );
    }

    check_process_wells( $self, $process, $validated_params );

    delete @{$params}{qw( type input_wells output_wells )};

    my $create_aux_data = '_create_process_aux_data_' . $validated_params->{type};

    $self->throw( Implementation =>
            "Don't know how to create auxiliary data for process type $validated_params->{type}" )
        unless $self->can($create_aux_data);

    $self->$create_aux_data( $params, $process );

    return $process;
}

sub pspec__create_process_aux_data_create_di {
    return {
        design_id => { validate => 'existing_design_id' },
        bacs =>
            { validate => 'hashref', optional => 1 } # validate called on each element of bacs array
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_create_di {
    my ( $self, $params, $process ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec__create_process_aux_data_create_di );

    $process->create_related( process_design => { design_id => $validated_params->{design_id} } );

    for my $bac_params ( @{ $validated_params->{bacs} || [] } ) {
        my $validated_bac_params = $self->check_params(
            $bac_params,
            {   bac_plate   => { validate => 'bac_plate' },
                bac_library => { validate => 'bac_library' },
                bac_name    => { validate => 'bac_name' }
            }
        );
        my $bac_clone = $self->retrieve(
            BacClone => {
                name           => $validated_bac_params->{bac_name},
                bac_library_id => $validated_bac_params->{bac_library}
            }
        );

        $process->create_related(
            process_bacs => {
                bac_plate    => $validated_bac_params->{bac_plate},
                bac_clone_id => $bac_clone->id
            }
        );
    }

    return;
}
## use critic

sub pspec__create_process_aux_data_int_recom {
    return {
        cassette => { validate => 'existing_intermediate_cassette' },
        backbone => { validate => 'existing_intermediate_backbone' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_int_recom {
    my ( $self, $params, $process ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec__create_process_aux_data_int_recom );

    $process->create_related( process_cassette => { cassette_id => $self->_cassette_id_for( $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => $self->_backbone_id_for( $validated_params->{backbone} ) } );

    return;
}
## use critic

sub pspec__create_process_aux_data_2w_gateway {
    return {
        cassette    => { validate => 'existing_final_cassette', optional => 1 },
        backbone    => { validate => 'existing_final_backbone', optional => 1 },
        recombinase => { optional => 1 },
        REQUIRE_SOME => { cassette_or_backbone => [ 1, qw( cassette backbone ) ], },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_2w_gateway {
    my ( $self, $params, $process ) = @_;

    #TODO: throw error it both cassette and backbone supplied?
    my $validated_params
        = $self->check_params( $params, $self->pspec__create_process_aux_data_2w_gateway );

    $process->create_related( process_cassette => { cassette_id => $self->_cassette_id_for( $validated_params->{cassette} ) } )
        if $validated_params->{cassette};
    $process->create_related( process_backbone => { backbone_id => $self->_backbone_id_for( $validated_params->{backbone} ) } )
        if $validated_params->{backbone};

    if ( $validated_params->{recombinase} ) {
        $self->_create_process_aux_data_recombinase(
            { recombinase => $validated_params->{recombinase} }, $process );
    }

    return;
}
## use critic

sub pspec__create_process_aux_data_3w_gateway {
    return {
        cassette    => { validate => 'existing_final_cassette' },
        backbone    => { validate => 'existing_final_backbone' },
        recombinase => { optional => 1 },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_3w_gateway {
    my ( $self, $params, $process ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec__create_process_aux_data_3w_gateway );

    $process->create_related( process_cassette => { cassette_id => $self->_cassette_id_for( $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => $self->_backbone_id_for( $validated_params->{backbone} ) } );

    if ( $validated_params->{recombinase} ) {
        $self->_create_process_aux_data_recombinase(
            { recombinase => $validated_params->{recombinase} }, $process );
    }

    return;
}
## use critic

sub pspec__create_process_aux_data_recombinase {
    return { recombinase => { validate => 'existing_recombinase' }, };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_recombinase {
    my ( $self, $params, $process ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec__create_process_aux_data_recombinase );

    $self->throw( Validation => "recombinase process should have 1 or more recombinases" )
        unless @{ $validated_params->{recombinase} };

    my $rank = 1;
    foreach my $recombinase ( @{ $validated_params->{recombinase} } ) {
        $process->create_related(
            process_recombinases => {
                recombinase_id => $recombinase,
                rank           => $rank++,
            }
        );
    }

    return;
}
## use critic

sub pspec__create_process_aux_data_cre_bac_recom {
    return {
        cassette => { validate => 'existing_intermediate_cassette' },
        backbone => { validate => 'existing_intermediate_backbone' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_cre_bac_recom {
    my ( $self, $params, $process ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec__create_process_aux_data_cre_bac_recom );

    $process->create_related( process_cassette => { cassette_id => $self->_cassette_id_for( $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => $self->_backbone_id_for( $validated_params->{backbone} ) } );

    return;
}
## use critic

sub pspec__create_process_aux_data_first_electroporation {
    return {
        cell_line => { validate => 'non_empty_string' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_first_electroporation {
    my ( $self, $params, $process ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec__create_process_aux_data_first_electroporation );

    $process->create_related( process_cell_line => { cell_line => $validated_params->{cell_line} } );

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_second_electroporation {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_rearray {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_dna_prep {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_clone_pool {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_clone_pick {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_freeze {
    return;
}
## use critic

sub pspec_delete_process {
    return {
        id => { validate => 'integer' }
    }
}

sub delete_process {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_delete_process );

    my $process = $self->retrieve( Process => { id => $validated_params->{id} } );

    my @related_resultsets = qw(  process_backbone process_bacs process_cassette process_design
                                  process_input_wells process_output_wells process_recombinases
                                  process_cell_line
                                );

    for my $rs ( @related_resultsets ) {
        $process->search_related_rs( $rs )->delete;
    }

    $process->delete;

    return;
}

sub list_process_types {
    my ($self) = @_;

    return [
        $self->schema->resultset('ProcessType')->search( {}, { order_by => { -asc => 'id' } } ) ];
}

sub pspec_get_process_fields {
    return {
        process_type => { validate => 'existing_process_type' },
    };
}

sub get_process_fields {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_get_process_fields );

    return process_fields( $self, $validated_params->{process_type} );
}

sub pspec_get_process_plate_types {
    return {
        process_type => { validate => 'existing_process_type' },
    };
}

sub get_process_plate_types {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_get_process_plate_types );

    return process_plate_types( $self, $validated_params->{process_type} );
}

1;

__END__
