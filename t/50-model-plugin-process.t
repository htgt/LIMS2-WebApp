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
    is $process_design->design_id, 1, 'process_design has correct design_id';
    ok my $process_bacs = $process->process_bacs, 'process has process_bacs';
    is $process_bacs->count, 1, 'only has one bac';
    ok my $bac_clone = $process_bacs->next->bac_clone, 'can retrieve bac clone from process';
    is $bac_clone->name, 'CT7-156D8', '.. and has correct bac_clone';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, '100', '..and is on correct plate';
}

throws_ok {
    my $process = model->create_process( $create_di_process_data->{invalid_input_wells} );
} qr/create_di process should have 0 input wells \(got 1\)/;

throws_ok {
    my $process = model->create_process( $create_di_process_data->{invalid_design_id} );
} qr/design_id, is invalid: existing_design_id/;


note( "Testing int_recom process creation" );
my $int_recom_process_data= test_data( 'int_recom_process.yaml' );

{
    ok my $process = model->create_process( $int_recom_process_data->{valid_input} ),
        'create_process for type int_recom should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'int_recom',
        'process is of correct type';

    ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
    is $process_cassette->cassette, 'pR6K_R1R2_ZP', 'process_cassette has correct cassette';
    ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
    is $process_backbone->backbone, 'R3R4_pBR_amp', 'process_backbone has correct backbone';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'A01', 'input well has correct name';
    is $input_well->plate->name, '100', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'PCS100', '..and is on correct plate';
}

#throws_ok {
    #my $process = model->create_process( $create_di_process_data->{missing_input_well} );
#} qr/int_recom process should have 1 input wells \(got 0\)/;

#throws_ok {
    #my $process = model->create_process( $create_di_process_data->{invalid_input_well} );
#} qr/int_recom process input well should be type 'DESIGN' \(got POSTINT\)/;


note( "Testing 2w_gateway process creation" );
my $process_data_2w_gateway= test_data( '2w_gateway_process.yaml' );

{
    ok my $process = model->create_process( $process_data_2w_gateway->{valid_input} ),
        'create_process for type 2w_gateway should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, '2w_gateway',
        'process is of correct type';

    ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
    is $process_cassette->cassette, 'L1L2_Bact_P', 'process_cassette has correct cassette';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'A01', 'input well has correct name';
    is $input_well->plate->name, 'PCS100', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'PGS100', '..and is on correct plate';

    ok my $process_recombinases = $process->process_recombinases, 'process has process_recombinases';
    is $process_recombinases->count, 1, 'has 1 recombinase';
    is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';
}

#throws_ok {
    #my $process = model->create_process( $create_di_process_data->{missing_input_well} );
#} qr/2w_gateway process should have 1 input wells \(got 0\)/;

#throws_ok {
    #my $process = model->create_process( $create_di_process_data->{invalid_input_well} );
#} qr/2w_gateway process input well should be type or 'INT' or 'POSTINT' \(got DESIGN\)/;

note( "Testing 3w_gateway process creation" );
my $process_data_3w_gateway= test_data( '3w_gateway_process.yaml' );

{
    ok my $process = model->create_process( $process_data_3w_gateway->{valid_input} ),
        'create_process for type 3w_gateway should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, '3w_gateway',
        'process is of correct type';

    ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
    is $process_cassette->cassette, 'L1L2_Bact_P', 'process_cassette has correct cassette';

    ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
    is $process_backbone->backbone, 'PL611', 'process_backbone has correct backbone';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'A01', 'input well has correct name';
    is $input_well->plate->name, 'PCS100', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'PGS100', '..and is on correct plate';

    ok my $process_recombinases = $process->process_recombinases, 'process has process_recombinases';
    is $process_recombinases->count, 1, 'has 1 recombinase';
    is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';
}

note( "Testing cre_bac_recom process creation" );
my $cre_bac_recom_process_data= test_data( 'cre_bac_recom_process.yaml' );

{
    ok my $process = model->create_process( $cre_bac_recom_process_data->{valid_input} ),
        'create_process for type cre_bac_recom should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'cre_bac_recom',
        'process is of correct type';

    ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
    is $process_cassette->cassette, 'pR6K_R1R2_ZP', 'process_cassette has correct cassette';
    ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
    is $process_backbone->backbone, 'R3R4_pBR_amp', 'process_backbone has correct backbone';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, 'only one input well';
    my $input_well = $input_wells->next;
    is $input_well->name, 'A01', 'input well has correct name';
    is $input_well->plate->name, '100', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'PCS100', '..and is on correct plate';
}

#throws_ok {
    #my $process = model->create_process( $cre_bac_recom_process_data->{missing_input_well} );
#} qr/int_recom process should have 1 input wells \(got 0\)/;

#throws_ok {
    #my $process = model->create_process( $cre_bac_recom_process_data->{invalid_input_well} );
#} qr/int_recom process input well should be type 'DESIGN' \(got POSTINT\)/;


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
    is $input_well->name, 'A01', 'input well has correct name';
    is $input_well->plate->name, 'PCS100', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'PGS100', '..and is on correct plate';

    ok my $process_recombinases = $process->process_recombinases, 'process has process_recombinases';
    is $process_recombinases->count, 1, 'has 1 recombinase';
    is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';
}

#throws_ok {
    #my $process = model->create_process( $recombinase_process_data->{missing_recombinase} );
#} qr/missing recombinase/;

#throws_ok {
    #my $process = model->create_process( $recombinase_process_data->{missing_input_well} );
#} qr/recombinase process should have 1 input wells \(got 0\)/;

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
    is $input_well->plate->name, 'PCS100', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'PGS100', '..and is on correct plate';
}

#throws_ok {
    #my $process = model->create_process( $rearray_process_data->{missing_input_well} );
#} qr/missing input well/;

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
    is $input_well->plate->name, 'PCS100', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'PGS100', '..and is on correct plate';
}

#throws_ok {
    #my $process = model->create_process( $dna_prep_process_data->{missing_input_well} );
#} qr/missing input well/;

done_testing();
