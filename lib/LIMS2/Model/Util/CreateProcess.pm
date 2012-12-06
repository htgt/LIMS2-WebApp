package LIMS2::Model::Util::CreateProcess;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CreateProcess::VERSION = '0.035';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            process_fields
            process_plate_types
            process_aux_data_field_list
            link_process_wells
            create_process_aux_data
          )
    ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;
use List::MoreUtils qw( uniq notall none );
use LIMS2::Model::Util qw( well_id_for );
use LIMS2::Exception::Implementation;
use LIMS2::Exception::Validation;
use LIMS2::Model::Constants qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS %PROCESS_INPUT_WELL_CHECK );

my %process_field_data = (
    final_cassette => {
        values => sub{ return _eng_seq_type_list( shift, 'final-cassette' ) },
        label  => 'Cassette (Final)',
        name   => 'cassette',
    },
    final_backbone => {
        values => sub{ return [ map{ $_->name } shift->schema->resultset('Backbone')->all ] },
        label  => 'Backbone (Final)',
        name   => 'backbone',
    },
    intermediate_cassette => {
        values => sub{ return _eng_seq_type_list( shift, 'intermediate-cassette' ) },
        label  => 'Cassette (Intermediate)',
        name   => 'cassette',
    },
    intermediate_backbone => {
        values => sub{ return _eng_seq_type_list( shift, 'intermediate-backbone' ) },
        label  => 'Backbone (Intermediate)',
        name   => 'backbone',
    },
    cell_line => {
        values => sub{ return [ map{ $_->name } shift->schema->resultset('CellLine')->all ] },
        label  => 'Cell Line',
        name   => 'cell_line',
    },
    recombinase => {
        values => sub{ return [ map{ $_->id } shift->schema->resultset('Recombinase')->all ] },
        label  => 'Recombinase',
        name   => 'recombinase',
    },
);

sub process_fields {
    my ( $model, $process_type ) = @_;
    my %process_fields;
    my $fields = exists $PROCESS_SPECIFIC_FIELDS{$process_type} ? $PROCESS_SPECIFIC_FIELDS{$process_type} : [];

    for my $field ( @{ $fields } ) {
        LIMS2::Exception::Implementation->throw(
            "Don't know how to setup process field $field"
        ) unless exists $process_field_data{$field};

        my $field_values = $process_field_data{$field}{values}->($model);
        $process_fields{$field} = {
            values => $field_values,
            label  => $process_field_data{$field}{label},
            name   => $process_field_data{$field}{name},
        };
    }

    return \%process_fields;
}

sub _eng_seq_type_list {
    my ( $model, $type ) = @_;

    my $eng_seqs = $model->eng_seq_builder->list_seqs( type => $type );

    return [ map{ $_->{name} } @{ $eng_seqs } ];
}

sub process_plate_types {
    my ( $model, $process_type ) = @_;
    my $plate_types;

    if ( exists $PROCESS_PLATE_TYPES{$process_type} ) {
        $plate_types = $PROCESS_PLATE_TYPES{$process_type};
    }
    else {
        $plate_types = [ map{ $_->id } @{ $model->list_plate_types } ];
    }

    return $plate_types;
}

sub process_aux_data_field_list {
    return [ uniq map{ $process_field_data{$_}{name} } keys %process_field_data ];
}

sub link_process_wells {
    my ( $model, $process, $params ) = @_;

    for my $input_well ( @{ $params->{input_wells} || [] } ) {
        $process->create_related(
            process_input_wells => { well_id => well_id_for( $model, $input_well) } );
    }

    for my $output_well ( @{ $params->{output_wells} || [] } ) {
        $process->create_related(
            process_output_wells => { well_id => well_id_for( $model, $output_well) } );
    }

    check_process_wells( $model, $process, $params );

    return;
}

my %process_check_well = (
    create_di              => \&_check_wells_create_di,
    int_recom              => \&_check_wells_int_recom,
    '2w_gateway'           => \&_check_wells_2w_gateway,
    '3w_gateway'           => \&_check_wells_3w_gateway,
    recombinase            => \&_check_wells_recombinase,
    cre_bac_recom          => \&_check_wells_cre_bac_recom,
    rearray                => \&_check_wells_rearray,
    dna_prep               => \&_check_wells_dna_prep,
    clone_pick             => \&_check_wells_clone_pick,
    clone_pool             => \&_check_wells_clone_pool,
    first_electroporation  => \&_check_wells_first_electroporation,
    second_electroporation => \&_check_wells_second_electroporation,
    freeze                 => \&_check_wells_freeze,
);

sub check_process_wells {
    my ( $model, $process, $params ) = @_;

    my $process_type = $params->{type};
    LIMS2::Exception::Implementation->throw(
        "Don't know how to validate wells for process type $process_type"
    ) unless exists $process_check_well{ $process_type };

    $process_check_well{ $process_type }->( $model, $process );

    return;
}

sub check_input_wells {
    my ( $model, $process ) = @_;

    my $process_type = $process->type_id;

    my @input_wells               = $process->input_wells;
    my $count                     = scalar @input_wells;
    my $expected_input_well_count = $PROCESS_INPUT_WELL_CHECK{$process_type}{number};
    LIMS2::Exception::Validation->throw(
            "$process_type process should have $expected_input_well_count input well(s) (got $count)"
    ) unless $count == $expected_input_well_count;

    return unless exists $PROCESS_INPUT_WELL_CHECK{$process_type}{type};

    my @types = uniq map { $_->plate->type_id } @input_wells;
    my %expected_input_process_types
        = map { $_ => 1 } @{ $PROCESS_INPUT_WELL_CHECK{$process_type}{type} };

    LIMS2::Exception::Validation->throw(
        "$process_type process input well should be type "
        . join( ',', keys %expected_input_process_types )
        . ' (got '
        . join( ',', @types )
        . ')'
    ) if notall { exists $expected_input_process_types{$_} } @types;

    return;
}

sub check_output_wells {
    my ( $model, $process ) = @_;

    my $process_type = $process->type_id;

    my @output_wells = $process->output_wells;
    my $count        = scalar @output_wells;
    # Only expect one output well per process, but schema can handle multiple
    LIMS2::Exception::Validation->throw(
        "Process should have 1 output well (got $count)"
    ) unless $count == 1;

    return unless exists $PROCESS_PLATE_TYPES{$process_type};

    my @types = uniq map { $_->plate->type_id } @output_wells;
    my %expected_output_process_types
        = map { $_ => 1 } @{ $PROCESS_PLATE_TYPES{$process_type} };

    LIMS2::Exception::Validation->throw(
        "$process_type process output well should be type "
        . join( ',', keys %expected_output_process_types )
        . ' (got '
        . join( ',', @types )
        . ')'
    ) if notall { exists $expected_output_process_types{$_} } @types;

    return;
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_create_di {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_int_recom {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_2w_gateway {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_3w_gateway {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_recombinase {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_cre_bac_recom {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_rearray {
    my ( $model, $process ) = @_;

    # XXX Does not allow for pooled rearray
    check_input_wells( $model, $process);

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
        LIMS2::Exception::Validation->throw( $mesg );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_dna_prep {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_clone_pick {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_clone_pool {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_first_electroporation {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_second_electroporation {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);

    #two input wells, one must be xep, other dna
    my @input_well_types = map{ $_->plate->type_id } $process->input_wells;

    if ( ( none { $_ eq 'XEP' } @input_well_types ) || ( none { $_ eq 'DNA' } @input_well_types ) ) {
        LIMS2::Exception::Validation->throw(
            'second_electroporation process types require two input wells, one of type XEP '
            . 'and the other of type DNA'
            . ' (got ' . join( ',', @input_well_types ) . ')'
        );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_freeze {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

my %process_aux_data = (
    create_di              => \&_create_process_aux_data_create_di,
    int_recom              => \&_create_process_aux_data_int_recom,
    '2w_gateway'           => \&_create_process_aux_data_2w_gateway,
    '3w_gateway'           => \&_create_process_aux_data_3w_gateway,
    recombinase            => \&_create_process_aux_data_recombinase,
    cre_bac_recom          => \&_create_process_aux_data_cre_bac_recom,
    rearray                => \&_create_process_aux_data_rearray,
    dna_prep               => \&_create_process_aux_data_dna_prep,
    clone_pick             => \&_create_process_aux_data_clone_pick,
    clone_pool             => \&_create_process_aux_data_clone_pool,
    first_electroporation  => \&_create_process_aux_data_first_electroporation,
    second_electroporation => \&_create_process_aux_data_second_electroporation,
    freeze                 => \&_create_process_aux_data_freeze,
);

sub create_process_aux_data {
    my ( $model, $process, $params ) = @_;

    my $process_type = $process->type_id;
    LIMS2::Exception::Implementation->throw(
        "Don't know how to create auxiliary data for process type $process_type"
    ) unless exists $process_aux_data{ $process_type };

    $process_aux_data{ $process_type }->( $model, $params, $process );

    return;
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
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_create_di() );

    $process->create_related( process_design => { design_id => $validated_params->{design_id} } );

    for my $bac_params ( @{ $validated_params->{bacs} || [] } ) {
        my $validated_bac_params = $model->check_params(
            $bac_params,
            {   bac_plate   => { validate => 'bac_plate' },
                bac_library => { validate => 'bac_library' },
                bac_name    => { validate => 'bac_name' }
            }
        );
        my $bac_clone = $model->retrieve(
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
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_int_recom );

    $process->create_related( process_cassette => { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    return;
}
## use critic

sub pspec__create_process_aux_data_2w_gateway {
    return {
        cassette    => { validate => 'existing_final_cassette', optional => 1 },
        backbone    => { validate => 'existing_backbone', optional => 1 },
        recombinase => { optional => 1 },
        REQUIRE_SOME => { cassette_or_backbone => [ 1, qw( cassette backbone ) ], },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_2w_gateway {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_2w_gateway );

    if ( $validated_params->{cassette} && $validated_params->{backbone} ) {
        LIMS2::Exception::Validation->throw(
            '2w_gateway process can have either a cassette or backbone, not both' );
    }

    $process->create_related( process_cassette => { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } )
        if $validated_params->{cassette};
    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } )
        if $validated_params->{backbone};

    if ( $validated_params->{recombinase} ) {
        _create_process_aux_data_recombinase(
            $model,
            { recombinase => $validated_params->{recombinase} }, $process );
    }

    return;
}
## use critic

sub pspec__create_process_aux_data_3w_gateway {
    return {
        cassette    => { validate => 'existing_final_cassette' },
        backbone    => { validate => 'existing_backbone' },
        recombinase => { optional => 1 },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_3w_gateway {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_3w_gateway );

    $process->create_related( process_cassette => { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    if ( $validated_params->{recombinase} ) {
        _create_process_aux_data_recombinase(
            $model,
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
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_recombinase );

    LIMS2::Exception::Validation->throw(
        "recombinase process should have 1 or more recombinases"
    ) unless @{ $validated_params->{recombinase} };

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
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_cre_bac_recom );

    $process->create_related( process_cassette => { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    return;
}
## use critic

sub pspec__create_process_aux_data_first_electroporation {
    return {
        cell_line => { validate => 'existing_cell_line' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_first_electroporation {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_first_electroporation );

    $process->create_related( process_cell_line => { cell_line_id => _cell_line_id_for( $model, $validated_params->{cell_line} ) } );

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

sub _cassette_id_for {
    my ( $model, $cassette_name ) = @_;

    my $cassette = $model->retrieve( Cassette => { name => $cassette_name } );
    return $cassette->id;
}

sub _backbone_id_for {
    my ( $model, $backbone_name ) = @_;

    my $backbone = $model->retrieve( Backbone => { name => $backbone_name } );
    return $backbone->id;
}

sub _cell_line_id_for {
	my ( $model, $cell_line_name ) = @_;

	my $cell_line = $model->retrieve( CellLine => { name => $cell_line_name });
	return $cell_line->id;
}

1;

__END__
