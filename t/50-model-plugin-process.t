#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most;
use Try::Tiny;
use DateTime;

note( "Testing create_di process creation" );
my $create_di_process_data= test_data( 'create_di_process.yaml' );

{
    ok my $process = model->create_process( $create_di_process_data->{valid_input} ),
        'create_process for type create_di should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'create_di',
        'process is of correct type';

    ok my $process_design = $process->process_design, 'process has a process_design';
    is $process_design->design_id, 95120, 'process_design has correct design_id';
    ok my $process_bacs = $process->process_bacs, 'process has process_bacs';
    is $process_bacs->count, 1, 'only has one bac';
    ok my $bac_clone = $process_bacs->next->bac_clone, 'can retrieve bac clone from process';
    is $bac_clone->name, 'RP24-135L5', '.. and has correct bac_clone';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, '100', '..and is on correct plate';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $create_di_process_data->{invalid_input_wells} );
} qr/create_di process should have 0 input well\(s\) \(got 1\)/;

throws_ok {
    my $process = model->create_process( $create_di_process_data->{invalid_design_id} );
} qr/design_id, is invalid: existing_design_id/;

throws_ok {
    my $process = model->create_process( $create_di_process_data->{invalid_output_well} );
} qr/create_di process output well should be type DESIGN \(got INT\)/;


note( "Testing int_recom process creation" );
my $int_recom_process_data= test_data( 'int_recom_process.yaml' );

{
    ok my $process = model->create_process( $int_recom_process_data->{valid_input} ),
        'create_process for type int_recom should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'int_recom',
        'process is of correct type';

    ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
    is $process_cassette->cassette->name, 'pR6K_R1R2_ZP', 'process_cassette has correct cassette';
    ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
    is $process_backbone->backbone->name, 'R3R4_pBR_amp', 'process_backbone has correct backbone';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'F06', 'input well has correct name';
    is $input_well->plate->name, '100', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'PCS00177_A', '..and is on correct plate';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $int_recom_process_data->{missing_input_well} );
} qr/int_recom process should have 1 input well\(s\) \(got 0\)/;

throws_ok {
    my $process = model->create_process( $int_recom_process_data->{invalid_input_well} );
} qr/int_recom process input well should be type DESIGN \(got EP\)/;

throws_ok {
    my $process = model->create_process( $int_recom_process_data->{invalid_output_well} );
} qr/int_recom process output well should be type INT \(got EP\)/;

throws_ok {
    my $process = model->create_process( $int_recom_process_data->{multiple_output_wells} );
} qr/Process should have 1 output well \(got 2\)/;


note( "Testing 2w_gateway process creation" );
my $process_data_2w_gateway= test_data( '2w_gateway_process.yaml' );

{
    ok my $process = model->create_process( $process_data_2w_gateway->{valid_input} ),
        'create_process for type 2w_gateway should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, '2w_gateway',
        'process is of correct type';

    ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
    is $process_cassette->cassette->name, 'L1L2_Bact_P', 'process_cassette has correct cassette';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'G02', 'input well has correct name';
    is $input_well->plate->name, 'PCS00177_A', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'I01', 'output well has correct name';
    is $output_well->plate->name, 'MOHSAS0001_A', '..and is on correct plate';

    ok my $process_recombinases = $process->process_recombinases, 'process has process_recombinases';
    is $process_recombinases->count, 1, 'has 1 recombinase';
    is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $process_data_2w_gateway->{require_cassette_or_backbone} );
} qr/cassette_or_backbone, is missing/;

throws_ok {
    my $process = model->create_process( $process_data_2w_gateway->{either_cassette_or_backbone} );
} qr/2w_gateway process can have either a cassette or backbone, not both/;

throws_ok {
    my $process = model->create_process( $process_data_2w_gateway->{missing_input_well} );
} qr/2w_gateway process should have 1 input well\(s\) \(got 0\)/;

throws_ok {
    my $process = model->create_process( $process_data_2w_gateway->{invalid_input_well} );
} qr/2w_gateway process input well should be type (INT|,|POSTINT)+ \(got DESIGN\)/;

throws_ok {
    my $process = model->create_process( $process_data_2w_gateway->{invalid_output_well} );
} qr/2w_gateway process output well should be type (FINAL|,|POSTINT)+ \(got DESIGN\)/;


note( "Testing 3w_gateway process creation" );
my $process_data_3w_gateway= test_data( '3w_gateway_process.yaml' );

{
    ok my $process = model->create_process( $process_data_3w_gateway->{valid_input} ),
        'create_process for type 3w_gateway should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, '3w_gateway',
        'process is of correct type';

    ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
    is $process_cassette->cassette->name, 'L1L2_Bact_P', 'process_cassette has correct cassette';

    ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
    is $process_backbone->backbone->name, 'L3L4_pZero_kan', 'process_backbone has correct backbone';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'G02', 'input well has correct name';
    is $input_well->plate->name, 'PCS00177_A', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'J01', 'output well has correct name';
    is $output_well->plate->name, 'MOHSAS0001_A', '..and is on correct plate';

    ok my $process_recombinases = $process->process_recombinases, 'process has process_recombinases';
    is $process_recombinases->count, 1, 'has 1 recombinase';
    is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $process_data_3w_gateway->{missing_input_well} );
} qr/3w_gateway process should have 1 input well\(s\) \(got 0\)/;

throws_ok {
    my $process = model->create_process( $process_data_3w_gateway->{invalid_input_well} );
} qr/3w_gateway process input well should be type INT \(got DESIGN\)/;

throws_ok {
    my $process = model->create_process( $process_data_3w_gateway->{invalid_output_well} );
} qr/3w_gateway process output well should be type (FINAL|,|POSTINT)+ \(got DESIGN\)/;


note( "Testing cre_bac_recom process creation" );
my $cre_bac_recom_process_data= test_data( 'cre_bac_recom_process.yaml' );

{
    ok my $process = model->create_process( $cre_bac_recom_process_data->{valid_input} ),
        'create_process for type cre_bac_recom should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'cre_bac_recom',
        'process is of correct type';

    ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
    is $process_cassette->cassette->name, 'pR6K_R1R2_ZP', 'process_cassette has correct cassette';
    ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
    is $process_backbone->backbone->name, 'R3R4_pBR_amp', 'process_backbone has correct backbone';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'F06', 'input well has correct name';
    is $input_well->plate->name, '100', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'M02', 'output well has correct name';
    is $output_well->plate->name, 'PCS00177_A', '..and is on correct plate';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $cre_bac_recom_process_data->{invalid_input_well} );
} qr/cre_bac_recom process input well should be type DESIGN \(got INT\)/;

throws_ok {
    my $process = model->create_process( $cre_bac_recom_process_data->{invalid_output_well} );
} qr/cre_bac_recom process output well should be type INT \(got EP\)/;


note( "Testing recombinase process creation" );
my $recombinase_process_data= test_data( 'recombinase_process.yaml' );

{
    ok my $process = model->create_process( $recombinase_process_data->{valid_input} ),
        'create_process for type recombinase should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'recombinase',
        'process is of correct type';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'G02', 'input well has correct name';
    is $input_well->plate->name, 'PCS00177_A', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'M01', 'output well has correct name';
    is $output_well->plate->name, 'MOHSAS0001_A', '..and is on correct plate';

    ok my $process_recombinases = $process->process_recombinases, 'process has process_recombinases';
    is $process_recombinases->count, 1, 'has 1 recombinase';
    is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $recombinase_process_data->{invalid_output_well} );
} qr/recombinase process output well should be type (POSTINT|,|XEP|FINAL)+ \(got EP\)/;


note( "Testing rearray process creation" );
my $rearray_process_data= test_data( 'rearray_process.yaml' );

{
    ok my $process = model->create_process( $rearray_process_data->{valid_input} ),
        'create_process for type rearray should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'rearray',
        'process is of correct type';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'A01', 'input well has correct name';
    is $input_well->plate->name, 'MOHFAS0001_A', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'N01', 'output well has correct name';
    is $output_well->plate->name, 'MOHSAS0001_A', '..and is on correct plate';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $rearray_process_data->{input_and_output_wells_different_type} );
} qr/rearray process should have input and output wells of the same type/;

note( "Testing dna_prep process creation" );
my $dna_prep_process_data= test_data( 'dna_prep_process.yaml' );

{
    ok my $process = model->create_process( $dna_prep_process_data->{valid_input} ),
        'create_process for type dna_prep should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'dna_prep',
        'process is of correct type';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'A01', 'input well has correct name';
    is $input_well->plate->name, 'MOHSAS0001_A', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'N01', 'output well has correct name';
    is $output_well->plate->name, 'MOHSAQ0001_A_2', '..and is on correct plate';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $dna_prep_process_data->{invalid_input_well} );
} qr/dna_prep process input well should be type FINAL/;

throws_ok {
    my $process = model->create_process( $dna_prep_process_data->{invalid_output_well} );
} qr/dna_prep process output well should be type DNA \(got INT\)/;


note( "Testing first_electroporation process creation" );
my $first_electroporation_data= test_data( 'first_electroporation.yaml' );

{
    ok my $process = model->create_process( $first_electroporation_data->{valid_input} ),
        'create_process for type first_electroporation should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'first_electroporation',
        'process is of correct type';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'A01', 'input well has correct name';
    is $input_well->plate->name, 'MOHSAQ0001_A_2', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'N01', 'output well has correct name';
    is $output_well->plate->name, 'FEP0006', '..and is on correct plate';

    ok my $process_cell_line = $process->process_cell_line, 'process has process_cell_line';
    is $process_cell_line->cell_line, 'foo cell line', 'is correct cell line';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $first_electroporation_data->{invalid_output_well} );
} qr/first_electroporation process output well should be type EP \(got SEP\)/;


note( "Testing second_electroporation process creation" );
my $second_electroporation_data= test_data( 'second_electroporation.yaml' );

{
    ok my $process = model->create_process( $second_electroporation_data->{valid_input} ),
        'create_process for type second_electroporation should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'second_electroporation',
        'process is of correct type';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 2, 'has two input wells';
    my $first_input_well = $input_wells->next;
    is $first_input_well->name, 'A01', 'input well has correct name';
    like $first_input_well->plate->name, qr/MOH(S|F)AQ0001_A_2/, '..and is on correct plate';
    my $second_input_well = $input_wells->next;
    is $second_input_well->name, 'A01', 'input well has correct name';
    like $second_input_well->plate->name, qr/XEP0006/, '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'N01', 'output well has correct name';
    is $output_well->plate->name, 'SEP0006', '..and is on correct plate';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $second_electroporation_data->{invalid_output_well} );
} qr/second_electroporation process output well should be type SEP \(got EP\)/;

throws_ok {
    my $process = model->create_process( $second_electroporation_data->{invalid_input_wells} );
} qr/second_electroporation process types require two input wells, one of type XEP and the other of type DNA/;


note( "Testing clone_pick process creation" );
my $clone_pick_process_data= test_data( 'clone_pick_process.yaml' );

{
    ok my $process = model->create_process( $clone_pick_process_data->{valid_input} ),
        'create_process for type clone_pick should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'clone_pick',
        'process is of correct type';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'A01', 'input well has correct name';
    is $input_well->plate->name, 'FEP0006', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'N01', 'output well has correct name';
    is $output_well->plate->name, 'FEPD0006_1', '..and is on correct plate';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process'; 
}

throws_ok {
    my $process = model->create_process( $clone_pick_process_data->{invalid_output_well} );
} qr/clone_pick process output well should be type (EP_PICK|,|SEP_PICK|XEP_PICK)+ \(got SEP\)/;

## Not currently testing the processes listed below, they have no auxillary process data so all
## we would be testing is the input well checks, find some way to test this seperately?
## freeze
## clone_pool
##
## can also test dna_prep and rearray process like this

done_testing();
