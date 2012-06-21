package LIMS2::Model::Plugin::Process;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use List::MoreUtils qw( any );
use namespace::autoclean;
use Const::Fast;

use Smart::Comments;

requires qw( schema check_params throw retrieve log trace );

sub _well_id_for {
    my ( $self, $data ) = @_;

    $self->retrieve_well( $data )->id;
}

sub _check_input_wells_create_di {
    my ( $self, $process ) = @_;

    my $count = $process->process_input_wells_rs->count;

    $self->throw( Validation => "create_di process should have 0 input wells (got $count)" )
        unless $count == 0;

    return;
}

sub _check_input_wells_int_recom {
    my ( $self, $process ) = @_;

    my @input_wells = $process->input_wells;
    my $count = scalar @input_wells;

    $self->throw( Validation => "int_recom process should have 1 input well (got $count)" )
        unless $count == 1;

    my $type = $input_wells[0]->plate->type_id;

    $self->throw( Validation => "int_recom process input well should be type 'DESIGN' (got $type)" )
        unless $type eq 'DESIGN';

    return;
}

sub _check_input_wells_2w_gateway {
    my ( $self, $process ) = @_;

    my @input_wells = $process->input_wells;
    my $count = scalar @input_wells;

    $self->throw( Validation => "2w_gateway process should have 1 input well (got $count)" )
        unless $count == 1;

    my $type = $input_wells[0]->plate->type_id;

    #TODO check its both INT and POSTINT
    $self->throw( Validation => "2w_gateway process input well should be type 'INT' or 'POSTINT' (got $type)" )
        unless any { $type eq  $_ } qw( INT POSTINT );

    return;
}

sub _check_input_wells_3w_gateway {
    my ( $self, $process ) = @_;

    my @input_wells = $process->input_wells;
    my $count = scalar @input_wells;

    $self->throw( Validation => "3w_gateway process should have 1 input well (got $count)" )
        unless $count == 1;

    my $type = $input_wells[0]->plate->type_id;

    #TODO check its both INT and POSTINT
    $self->throw( Validation => "3w_gateway process input well should be type 'INT' or 'POSTINT' (got $type)" )
        unless any { $type eq  $_ } qw( INT POSTINT );

    return;
}

sub _check_input_wells_recombinase {
    my ( $self, $process ) = @_;

    my @input_wells = $process->input_wells;
    my $count = scalar @input_wells;

    $self->throw( Validation => "recombinase process should have 1 input well (got $count)" )
        unless $count == 1;

    #TODO can input well be of any type?

    return;
}

sub _check_input_wells_cre_bac_recom {
    my ( $self, $process ) = @_;

    my @input_wells = $process->input_wells;
    my $count = scalar @input_wells;

    $self->throw( Validation => "cre_bac_recom process should have 1 input well (got $count)" )
        unless $count == 1;

    my $type = $input_wells[0]->plate->type_id;

    $self->throw( Validation => "cre_bac_recom process input well should be type 'DESIGN' (got $type)" )
        unless $type eq 'DESIGN';

    return;
}

sub _check_input_wells_rearray {
    my ( $self, $process ) = @_;

    my @input_wells = $process->input_wells;
    my $count = scalar @input_wells;

    $self->throw( Validation => "rearray process should have 1 input well (got $count)" )
        unless $count == 1;

    return;
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
    ### $validated_params

    my $process = $self->schema->resultset( 'Process' )->create(
        { type_id => $validated_params->{type} }
    );

    for my $input_well ( @{ $process->{input_wells} || [] } ) {
        $process->create_related(
            process_input_wells => { well_id => $self->_well_id_for( $input_well ) }
        );
    }

    my $check_input_wells = '_check_input_wells_' . $validated_params->{type};
    $self->throw( Implementation => "Don't know how to validate input wells for process type $validated_params->{type}" )
        unless $self->can( $check_input_wells );

    $self->$check_input_wells( $process );

    for my $output_well ( @{ $process->{output_wells} || [] } ) {
        $process->create_related(
            process_output_wells => { well_id => $self->_well_id_for( $output_well ) }
        );
    }

    delete @{$params}{ qw( type input_wells output_wells ) };

    my $create_aux_data = '_create_process_aux_data_ ' . $validated_params->{type};
    $self->throw( Implementation => "Don't know how to create auxiliary data for process type $validated_params->{type}" )
        unless $self->can( $create_aux_data );
    ### $params

    $self->$create_aux_data( $params, $process );

    return $process;
}

sub pspec__create_process_aux_data_create_di {
    return {
        design_id => { validate => 'existing_design_id' },
        bacs      => { validate => 'hashref', optional => 1 } # validate called on each element of bacs array
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

sub pspec__create_process_aux_data_int_recom {
    return {
        cassette => { validate => 'existing_intermediate_cassette' },
        backbone => { validate => 'existing_intermediate_backbone' },
    };
}

sub _create_process_aux_data_int_recom {
    my ( $self, $params, $process ) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_process_aux_data_int_recom );

    $process->create_related( process_cassette => { cassette => $validated_params->{cassette} } );
    $process->create_related( process_backbone => { backbone => $validated_params->{backbone} } );

    return;
}

sub pspec__create_process_aux_data_2w_gateway {
    return {
        cassette     => { validate => 'existing_final_cassette', optional => 1 },
        backbone     => { validate => 'existing_final_backbone', optional => 1 },
        recombinases => { optional => 1},
        REQUIRE_SOME => {
            cassette_or_backbone => [ 1, qw( cassette backbone ) ],
        },
    };
}

sub _create_process_aux_data_int_2w_gateway {
    my ( $self, $params, $process ) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_process_aux_data_2w_gateway );

    $process->create_related( process_cassette => { cassette => $validated_params->{cassette} } )
        if $validated_params->{cassette};
    $process->create_related( process_backbone => { backbone => $validated_params->{backbone} } )
        if $validated_params->{backbone};

    map{ $self->_create_process_recombinase( $process, $_ ) }
        @{ $validated_params->{recombinases} }
            if $validated_params->{recombinases};

    return;
}

sub pspec__create_process_aux_data_3w_gateway {
    return {
        cassette     => { validate => 'existing_final_cassette' },
        backbone     => { validate => 'existing_final_backbone' },
        recombinases => { optional => 1 },
    };
}

sub _create_process_aux_data_int_3w_gateway {
    my ( $self, $params, $process ) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_process_aux_data_3w_gateway );

    $process->create_related( process_cassette   => { cassette => $validated_params->{cassette} } );
    $process->create_related( process_backbone   => { backbone => $validated_params->{backbone} } );

    map{ $self->_create_process_recombinase( $process, $_ ) }
        @{ $validated_params->{recombinases} }
            if $validated_params->{recombinases};

    return;
}

sub pspec__create_process_aux_data_recombinase {
    return {
        recombinases => { },
    };
}

sub _create_process_aux_data_recombinase {
    my ( $self, $params, $process ) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_process_aux_data_recombinase );

    $self->throw( Validation => "recombinase process should have 1 or more recombinases" )
        unless @{ $validated_params->{recombinases} };

    map{ $self->_create_process_recombinase( $process, $_ ) }
        @{ $validated_params->{recombinases} };

    return;
}

sub _create_process_recombinase {
    my ( $self, $process, $params ) = @_;

    my $validated_params = $self->check_params(
        $params, { recombinase => { validate => 'existing_recombinase' },
                   rank        => { validate => 'integer' } }
    );

    $process->create_related( process_recombinase => {
            recombinase => $validated_params->{recombinase},
            rank        => $validated_params->{rank},
        }
    );

    return;
}

sub pspec__create_process_aux_data_cre_bac_recom {
    return {
        cassette => { validate => 'existing_intermediate_cassette' },
        backbone => { validate => 'existing_intermediate_backbone' },
    };
}

sub _create_process_aux_data_cre_bac_recom {
    my ( $self, $params, $process ) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_process_aux_data_cre_bac_recom );

    $process->create_related( process_cassette => { cassette => $validated_params->{cassette} } );
    $process->create_related( process_backbone => { backbone => $validated_params->{backbone} } );

    return;
}

sub _create_process_aux_data_rearray {
    return;
}

sub _create_process_aux_data_dna_prep {
    return;
}

1;

__END__
