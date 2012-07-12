package LIMS2::Model::Plugin::Process;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Process::VERSION = '0.004';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use List::MoreUtils qw( uniq notall );
use namespace::autoclean;
use Const::Fast;

requires qw( schema check_params throw retrieve log trace );

const my %PROCESS_INPUT_WELL_CHECK => (
    create_di => { number => 0, },
    int_recom => {
        number => 1,
        type   => [qw( DESIGN )],
    },
    '2w_gateway' => {
        number => 1,
        type   => [qw( INT POSTINT )],
    },
    '3w_gateway' => {
        number => 1,
        type   => [qw( INT )],
    },
    recombinase   => { number => 1, },
    cre_bac_recom => {
        number => 1,
        type   => [qw( DESIGN )],
    },
    rearray  => { number => 1, },
    dna_prep => {
        number => 1,
        type   => [qw( FINAL )],
    },
);

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

sub check_input_wells {
    my ( $self, $process ) = @_;

    my $process_type = $process->type_id;

    my @input_wells               = $process->input_wells;
    my $count                     = scalar @input_wells;
    my $expected_input_well_count = $PROCESS_INPUT_WELL_CHECK{$process_type}{number};
    $self->throw( Validation =>
            "$process_type process should have $expected_input_well_count input well(s) (got $count)"
    ) unless $count == $expected_input_well_count;

    return unless exists $PROCESS_INPUT_WELL_CHECK{$process_type}{type};

    my @types = uniq map { $_->plate->type_id } @input_wells;
    my %expected_input_process_types
        = map { $_ => 1 } @{ $PROCESS_INPUT_WELL_CHECK{$process_type}{type} };

    $self->throw( Validation => "$process_type process input well should be type "
            . join( ',', keys %expected_input_process_types )
            . ' (got '
            . join( ',', @types )
            . ')' )
        if notall { exists $expected_input_process_types{$_} } @types;

    return;
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_input_wells_create_di {
    my ( $self, $process ) = @_;

    $self->check_input_wells($process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_input_wells_int_recom {
    my ( $self, $process ) = @_;

    $self->check_input_wells($process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_input_wells_2w_gateway {
    my ( $self, $process ) = @_;

    $self->check_input_wells($process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_input_wells_3w_gateway {
    my ( $self, $process ) = @_;

    $self->check_input_wells($process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_input_wells_recombinase {
    my ( $self, $process ) = @_;

    $self->check_input_wells($process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_input_wells_cre_bac_recom {
    my ( $self, $process ) = @_;

    $self->check_input_wells($process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_input_wells_rearray {
    my ( $self, $process ) = @_;

    # XXX Does not allow for pooled rearray
    $self->check_input_wells($process);

    my @input_wells = $process->input_wells;

    # Output well type must be the same as the input well type
    my $in_type = $input_wells[0]->plate->type_id;
    my @output_types = uniq map { $_->plate->type_id } $process->output_wells;

    my @invalid_types = grep { $_ ne $in_type } @output_types;

    if ( @invalid_types > 0 ) {
        my $mesg
            = sprintf
            'rearray process should have input and output wells of the same type (expected %s, got %s)',
            $in_type, join( q/,/, @invalid_types );
        $self->throw( Validation => $mesg );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_input_wells_dna_prep {
    my ( $self, $process ) = @_;

    $self->check_input_wells($process);
    return;
}
## use critic

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
            process_input_wells => { well_id => $self->_well_id_for($input_well) } );
    }

    for my $output_well ( @{ $validated_params->{output_wells} || [] } ) {
        $process->create_related(
            process_output_wells => { well_id => $self->_well_id_for($output_well) } );
    }

    my $check_input_wells = '_check_input_wells_' . $validated_params->{type};
    $self->throw( Implementation =>
            "Don't know how to validate input wells for process type $validated_params->{type}" )
        unless $self->can($check_input_wells);

    $self->$check_input_wells($process);

    # XXX We have checked the types of the input wells; should we
    # check that (at the very least) all of the output wells are of
    # the same type?

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
                                  process_input_wells process_output_wells process_recombinases );

    for my $rs ( @related_resultsets ) {
        $process->search_related_rs( $rs )->delete;
    }

    $process->delete;

    return;
}


1;

__END__
