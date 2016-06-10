package LIMS2::t::Model::Plugin::Process;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test model => { classname => __PACKAGE__ }, 'test_data';
use Try::Tiny;
use DateTime;
use File::Temp ':seekable';
use Data::Dumper;

use strict;
## no critic

=head1 NAME

LIMS2/t/Model/Plugin/Process.pm - test class for LIMS2::Model::Plugin::Process

=head1 DESCRIPTION

Test module structured for running under Test::Class

=cut

sub process_types : Tests() {

    note("Testing process types and fields creation");
    my @process_types = qw(
        create_di
        create_crispr
        cre_bac_recom
        int_recom
        2w_gateway
        3w_gateway
        legacy_gateway
        final_pick
        rearray
        dna_prep
        recombinase
        clone_pick
        clone_pool
        first_electroporation
        second_electroporation
        freeze
        xep_pool
        dist_qc
        crispr_vector
        single_crispr_assembly
        paired_crispr_assembly
        crispr_ep
        global_arm_shortening
        oligo_assembly
        cgap_qc
        ms_qc
        doubling
    );

    my @model_process_types = sort map { $_->id } @{ model->list_process_types };

    is_deeply(
        [ sort map { $_->id } @{ model->list_process_types } ],
        [ sort @process_types ],
        'process type list correct'
    );

    my $fields = model->get_process_fields( { process_type => 'recombinase' } );
    ok exists $fields->{'recombinase'}, 'recombinase process has recombinase field';
    $fields = model->get_process_fields( { process_type => 'int_recom' } );
    ok !exists $fields->{'recombinase'}, 'int_recom does not have recombinase field';

    is_deeply( model->get_process_plate_types( { process_type => 'cre_bac_recom' } ),
        [qw( INT )], 'cre_bac_recom plate types correct' );
    is_deeply(
        model->get_process_plate_types( { process_type => 'clone_pick' } ),
        [qw( EP_PICK SEP_PICK XEP_PICK )],
        'clone_pick plate types correct'
    );
}

sub create_di_process : Tests() {
    note("Testing create_di process creation");
    my $create_di_process_data = test_data('create_di_process.yaml');

    {
        ok my $process = model->create_process( $create_di_process_data->{valid_input} ),
            'create_process for type create_di should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'create_di', 'process is of correct type';

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
    }
    qr/create_di process should have 0 input well\(s\) \(got 1\)/;

    throws_ok {
        my $process = model->create_process( $create_di_process_data->{invalid_design_id} );
    }
    qr/design_id, is invalid: existing_design_id/;

    throws_ok {
        my $process = model->create_process( $create_di_process_data->{invalid_output_well} );
    }
    qr/create_di process output well should be type DESIGN \(got INT\)/;

}

sub create_crispr_process : Tests() {

    note("Testing create_crispr process creation");
    my $create_crispr_process_data = test_data('create_crispr_process.yaml');

    {
        ok my $process = model->create_process( $create_crispr_process_data->{valid_input} ),
            'create_process for type create_di should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'create_crispr', 'process is of correct type';

        ok my $process_crispr = $process->process_crispr, 'process has a process_crispr';
        is $process_crispr->crispr_id, 113, 'process_crispr has correct crispr_id';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'CRISPR_1', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $create_crispr_process_data->{invalid_input_wells} );
    }
    qr/create_crispr process should have 0 input well\(s\) \(got 1\)/;

    throws_ok {
        my $process = model->create_process( $create_crispr_process_data->{invalid_crispr_id} );
    }
    qr/crispr_id, is invalid: existing_crispr_id/;

    throws_ok {
        my $process = model->create_process( $create_crispr_process_data->{invalid_output_well} );
    }
    qr/create_crispr process output well should be type CRISPR \(got INT\)/;

}

sub int_recom_process : Tests() {
    note("Testing int_recom process creation");
    my $int_recom_process_data = test_data('int_recom_process.yaml');

    {
        ok my $process = model->create_process( $int_recom_process_data->{valid_input} ),
            'create_process for type int_recom should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'int_recom', 'process is of correct type';

        ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
        is $process_cassette->cassette->name, 'pR6K_R1R2_ZP',
            'process_cassette has correct cassette';
        ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
        is $process_backbone->backbone->name, 'R3R4_pBR_amp',
            'process_backbone has correct backbone';

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
    }
    qr/int_recom process should have 1 input well\(s\) \(got 0\)/;

    throws_ok {
        my $process = model->create_process( $int_recom_process_data->{invalid_input_well} );
    }
    qr/int_recom process input well should be type PREINT,DESIGN \(got EP\)/;

    throws_ok {
        my $process = model->create_process( $int_recom_process_data->{invalid_output_well} );
    }
    qr/int_recom process output well should be type INT \(got EP\)/;

    throws_ok {
        my $process = model->create_process( $int_recom_process_data->{multiple_output_wells} );
    }
    qr/Process should have 1 output well \(got 2\)/;
}

sub two_way_gateway_process : Tests() {
    note("Testing 2w_gateway process creation");
    my $process_data_2w_gateway = test_data('2w_gateway_process.yaml');

    {
        ok my $process = model->create_process( $process_data_2w_gateway->{valid_input} ),
            'create_process for type 2w_gateway should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, '2w_gateway', 'process is of correct type';
        ## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
        sub _create_process_aux_data_freeze {
            return;
        }
        ## use critic

        ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
        is $process_cassette->cassette->name, 'L1L2_Bact_P',
            'process_cassette has correct cassette';

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

        ok my $process_recombinases = $process->process_recombinases,
            'process has process_recombinases';
        is $process_recombinases->count, 1, 'has 1 recombinase';
        is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process
            = model->create_process( $process_data_2w_gateway->{require_cassette_or_backbone} );
    }
    qr/cassette_or_backbone, is missing/;

    throws_ok {
        my $process
            = model->create_process( $process_data_2w_gateway->{either_cassette_or_backbone} );
    }
    qr/2w_gateway process can have either a cassette or backbone, not both/;

    throws_ok {
        my $process = model->create_process( $process_data_2w_gateway->{missing_input_well} );
    }
    qr/2w_gateway process should have 1 input well\(s\) \(got 0\)/;

    throws_ok {
        my $process = model->create_process( $process_data_2w_gateway->{invalid_input_well} );
    }
    qr/2w_gateway process input well should be type (INT|,|POSTINT)+ \(got DESIGN\)/;

    throws_ok {
        my $process = model->create_process( $process_data_2w_gateway->{invalid_output_well} );
    }
    qr/2w_gateway process output well should be type (FINAL|,|POSTINT)+ \(got DESIGN\)/;

}

sub legacy_gateway_process : Tests() {
    note("Testing legacy_gateway process creation");
    my $process_data_legacy_gateway = test_data('legacy_gateway_process.yaml');

    {
        ok my $process = model->create_process( $process_data_legacy_gateway->{valid_input} ),
            'create_process for type legacy_gateway should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'legacy_gateway', 'process is of correct type';

        ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
        is $process_cassette->cassette->name, 'L1L2_Bact_P',
            'process_cassette has correct cassette';

        ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
        is $process_backbone->backbone->name, 'L3L4_pZero_kan',
            'process_backbone has correct backbone';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 1, 'only one input well';
        my $input_well = $input_wells->next;
        is $input_well->name, 'G02', 'input well has correct name';
        is $input_well->plate->name, 'PCS00177_A', '..and is on correct plate';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'FP1008', '..and is on correct plate';

        ok my $process_recombinases = $process->process_recombinases,
            'process has process_recombinases';
        is $process_recombinases->count, 1, 'has 1 recombinase';
        is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        model->create_process( $process_data_legacy_gateway->{require_cassette_or_backbone} );
    }
    qr/cassette_or_backbone, is missing/;

    throws_ok {
        model->create_process( $process_data_legacy_gateway->{invalid_input_well} );
    }
    qr/legacy_gateway process input well should be type INT \(got DESIGN\)/;

    throws_ok {
        model->create_process( $process_data_legacy_gateway->{invalid_output_well} );
    }
    qr/legacy_gateway process output well should be type FINAL_PICK \(got FINAL\)/;
}

sub three_way_gateway_process : Tests() {
    note("Testing 3w_gateway process creation");
    my $process_data_3w_gateway = test_data('3w_gateway_process.yaml');

    {
        ok my $process = model->create_process( $process_data_3w_gateway->{valid_input} ),
            'create_process for type 3w_gateway should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, '3w_gateway', 'process is of correct type';

        ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
        is $process_cassette->cassette->name, 'L1L2_Bact_P',
            'process_cassette has correct cassette';

        ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
        is $process_backbone->backbone->name, 'L3L4_pZero_kan',
            'process_backbone has correct backbone';

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

        ok my $process_recombinases = $process->process_recombinases,
            'process has process_recombinases';
        is $process_recombinases->count, 1, 'has 1 recombinase';
        is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $process_data_3w_gateway->{missing_input_well} );
    }
    qr/3w_gateway process should have 1 input well\(s\) \(got 0\)/;

    throws_ok {
        my $process = model->create_process( $process_data_3w_gateway->{invalid_input_well} );
    }
    qr/3w_gateway process input well should be type INT \(got DESIGN\)/;

    throws_ok {
        my $process = model->create_process( $process_data_3w_gateway->{invalid_output_well} );
    }
    qr/3w_gateway process output well should be type (FINAL|,|POSTINT)+ \(got DESIGN\)/;
}

sub cre_bac_recom_process : Tests() {
    note("Testing cre_bac_recom process creation");
    my $cre_bac_recom_process_data = test_data('cre_bac_recom_process.yaml');

    {
        ok my $process = model->create_process( $cre_bac_recom_process_data->{valid_input} ),
            'create_process for type cre_bac_recom should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'cre_bac_recom', 'process is of correct type';

        ok my $process_cassette = $process->process_cassette, 'process has a process_cassette';
        is $process_cassette->cassette->name, 'pR6K_R1R2_ZP',
            'process_cassette has correct cassette';
        ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
        is $process_backbone->backbone->name, 'R3R4_pBR_amp',
            'process_backbone has correct backbone';

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
    }
    qr/cre_bac_recom process input well should be type DESIGN \(got INT\)/;

    throws_ok {
        my $process = model->create_process( $cre_bac_recom_process_data->{invalid_output_well} );
    }
    qr/cre_bac_recom process output well should be type INT \(got EP\)/;
}

sub recombinase_process : Tests() {
    note("Testing recombinase process creation");
    my $recombinase_process_data = test_data('recombinase_process.yaml');

    {
        ok my $process = model->create_process( $recombinase_process_data->{valid_input} ),
            'create_process for type recombinase should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'recombinase', 'process is of correct type';

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

        ok my $process_recombinases = $process->process_recombinases,
            'process has process_recombinases';
        is $process_recombinases->count, 1, 'has 1 recombinase';
        is $process_recombinases->next->recombinase->id, 'Cre', 'is Cre recombinase';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $recombinase_process_data->{invalid_output_well} );
    }
    qr/recombinase process output well should be type (POSTINT|,|XEP|FINAL)+ \(got EP\)/;

    note("Testing adding recombinase to an existing process");
    my $add_recombinase_process_data = test_data('add_recombinase.yaml');
    {
        lives_ok { model->add_recombinase_data( $add_recombinase_process_data->{valid_input} ) }
        'should succeed for an EP_PICK plate';
        my @process = model->retrieve_well(
            {   plate_name => $add_recombinase_process_data->{valid_input}{plate_name},
                well_name  => $add_recombinase_process_data->{valid_input}{well_name}
            }
        )->parent_processes;
        is $process[0]->process_recombinases->first->recombinase_id, 'Dre', 'should be dre';
    }
    throws_ok {
        model->add_recombinase_data( $add_recombinase_process_data->{invalid_input} );
    }
    qr/invalid plate type; can only add recombinase to EP_PICK plates/;

    note("Testing adding recombinase using upload");
    {
        my $test_file = File::Temp->new or die( 'Could not create temp test file ' . $! );
        $test_file->print( "plate_name,well_name,recombinase\n"
                . "FEPD0006_1,A02,Dre\n"
                . "FEPD0006_1,A03,Dre\n"
                . "FEPD0006_1,A04,Dre\n" );
        $test_file->seek( 0, 0 );

        ok model->upload_recombinase_file_data($test_file), 'should succeed';
    }

    note("Testing adding recombinase using upload fails if csv data is incorrect");
    {
        my $test_file = File::Temp->new or die( 'Could not create temp test file ' . $! );
        $test_file->print( "plate_name,well_name,recombinase\n"
                . "FEPD0006_1,A05,Dre\n"
                . "FEPD0006_1,A06,Dre\n"
                . "FEP0006,C01,Dre\n" );
        $test_file->seek( 0, 0 );

        throws_ok {
            model->upload_recombinase_file_data($test_file);
        }
        qr/line 4: plate FEP0006, well C01 , recombinase Dre ERROR/;
    }

    note("Testing adding recombinase using upload fails if csv data is missing columns");
    {
        my $test_file = File::Temp->new or die( 'Could not create temp test file ' . $! );
        $test_file->print( "plate_name,well_name\n" . "FEPD0006_1,B01\n" );
        $test_file->seek( 0, 0 );

        throws_ok {
            model->upload_recombinase_file_data($test_file);
        }
        qr/invalid column names or data/;
    }
}

sub final_pick_process : Tests() {
    note("Testing final_pick process creation");
    my $final_pick_process_data = test_data('final_pick_process.yaml');

    {
        ok my $process = model->create_process( $final_pick_process_data->{valid_input} ),
            'create_process for type final_pick should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'final_pick', 'process is of correct type';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 1, 'only one input well';
        my $input_well = $input_wells->next;
        is $input_well->name, 'A01', 'input well has correct name';
        is $input_well->plate->name, 'MOHFAS0001_A', '..and is on correct plate';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'FP1008', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $final_pick_process_data->{invalid_output_well} );
    }
    qr/final_pick process output well should be type (FINAL|FINAL_PICK)+ \(got SEP\)/;
}

sub rearray_process : Tests() {
    note("Testing rearray process creation");
    my $rearray_process_data = test_data('rearray_process.yaml');

    {
        ok my $process = model->create_process( $rearray_process_data->{valid_input} ),
            'create_process for type rearray should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'rearray', 'process is of correct type';

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
        my $process = model->create_process(
            $rearray_process_data->{input_and_output_wells_different_type} );
    }
    qr/rearray process should have input and output wells of the same type/;
}

sub dna_prep_process : Tests() {
    note("Testing dna_prep process creation");
    my $dna_prep_process_data = test_data('dna_prep_process.yaml');

    {
        ok my $process = model->create_process( $dna_prep_process_data->{valid_input} ),
            'create_process for type dna_prep should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'dna_prep', 'process is of correct type';

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
    }
    qr/dna_prep process input well should be type FINAL/;

    throws_ok {
        my $process = model->create_process( $dna_prep_process_data->{invalid_output_well} );
    }
    qr/dna_prep process output well should be type DNA \(got INT\)/;
}

sub first_electroporation_process : Tests() {
    note("Testing first_electroporation process creation");
    my $first_electroporation_data = test_data('first_electroporation.yaml');

    {
        ok my $process = model->create_process( $first_electroporation_data->{valid_input} ),
            'create_process for type first_electroporation should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'first_electroporation', 'process is of correct type';

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
        is $process_cell_line->cell_line->name, 'oct4:puro iCre/iFlpO #11', 'is correct cell line';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $first_electroporation_data->{invalid_output_well} );
    }
    qr/first_electroporation process output well should be type EP \(got SEP\)/;

    note("Testing first_electroporation process creation with recombinase");
    {
        ok my $process = model->create_process( $first_electroporation_data->{'with_recombinase'} ),
            'create_process for type first_electroporation with recombinase should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'first_electroporation', 'process is of correct type';
        ok my $process_recombinases = $process->process_recombinases,
            'process has process_recombinases';
        is $process_recombinases->count, 1, 'has 1 recombinase';
        is $process_recombinases->next->recombinase->id, 'Flp', 'is Flp recombinase';
        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }
}

sub second_electroporation_process : Tests() {
    note("Testing second_electroporation process creation");
    my $second_electroporation_data = test_data('second_electroporation.yaml');

    {
        ok my $process = model->create_process( $second_electroporation_data->{valid_input} ),
            'create_process for type second_electroporation should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'second_electroporation', 'process is of correct type';

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
    }
    qr/second_electroporation process output well should be type SEP \(got EP\)/;

    throws_ok {
        my $process = model->create_process( $second_electroporation_data->{invalid_input_wells} );
    }
    qr/second_electroporation process types require two input wells, one of type XEP and the other of type DNA/;

    note("Testing second_electroporation process creation with recombinase");
    {
        ok my $process
            = model->create_process( $second_electroporation_data->{'with_recombinase'} ),
            'create_process for type second_electroporation with recombinase should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'second_electroporation', 'process is of correct type';
        ok my $process_recombinases = $process->process_recombinases,
            'process has process_recombinases';
        is $process_recombinases->count, 1, 'has 1 recombinase';
        is $process_recombinases->next->recombinase->id, 'Flp', 'is Flp recombinase';
        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }
}

sub clone_pick_process : Tests() {
    note("Testing clone_pick process creation");
    my $clone_pick_process_data = test_data('clone_pick_process.yaml');

    {
        ok my $process = model->create_process( $clone_pick_process_data->{valid_input} ),
            'create_process for type clone_pick should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'clone_pick', 'process is of correct type';

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
    }
    qr/clone_pick process output well should be type (EP_PICK|,|SEP_PICK|XEP_PICK)+ \(got SEP\)/;

    note('Testing clone_pick process with recombinase option');
    {
        ok my $process = model->create_process( $clone_pick_process_data->{'with_recombinase'} ),
            'create_process for type clone_pick with recombinase succeeds';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'clone_pick', 'process is of the correct type';
        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        my $output_well = $output_wells->next;
        ok my $recombinases = $output_well->recombinases, 'output_well can return recombinases';
        isa_ok $recombinases, 'ARRAY';
        is $recombinases->[0], 'Flp', 'recombinase is of the correct type (Flp)';
        ok my $process_recombinases = $process->process_recombinases,
            'process has process_recombinases';
        is $process_recombinases->count, 1, 'has 1 recombinase';
        is $process_recombinases->next->recombinase->id, 'Flp', 'is Flp recombinase';
        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }
}

sub clone_pool_process : Tests() {
    note("Testing clone_pool process creation");
    my $clone_pool_process_data = test_data('clone_pool_process.yaml');

    #TODO add new wells to fixture data

    {
        ok my $process = model->create_process( $clone_pool_process_data->{valid_input} ),
            'create_process for type clone_pool should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'clone_pool', 'process is of correct type';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 1, 'only one input well';
        my $input_well = $input_wells->next;
        is $input_well->name, 'A01', 'input well has correct name';
        is $input_well->plate->name, 'SEP0006', '..and is on correct plate';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'SEP_POOL0001', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $clone_pool_process_data->{invalid_output_well} );
    }
    qr/clone_pool process output well should be type (SEP_POOL|,|XEP_POOL)+ \(got SEP\)/;
}

sub freeze_process : Tests() {
    note("Testing freeze process creation");
    my $freeze_process_data = test_data('freeze_process.yaml');

    {
        ok my $process = model->create_process( $freeze_process_data->{valid_input} ),
            'create_process for type freeze should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'freeze', 'process is of correct type';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 1, 'only one input well';
        my $input_well = $input_wells->next;
        is $input_well->name, 'A01', 'input well has correct name';
        is $input_well->plate->name, 'FEPD0006_1', '..and is on correct plate';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A07', 'output well has correct name';
        is $output_well->plate->name, 'FFP0001', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $freeze_process_data->{invalid_output_well} );
    }
    qr/freeze process output well should be type (FP|,|SFP)+ \(got SEP\)/;
}

sub dist_qc_process : Tests() {
    note("Testing dist_qc process creation");
    my $dist_qc_process_data = test_data('dist_qc_process.yaml');

    {

        # check normal create works
        ok my $process = model->create_process( $dist_qc_process_data->{valid_input} ),
            'create_process for type dist_qc should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'dist_qc', 'process is of correct type';

        # check process inputs are correct
        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 1, 'only one input well';
        my $input_well = $input_wells->next;
        is $input_well->name, 'A01', 'input well has correct name';
        is $input_well->plate->name, 'FFP0001', '..and is on correct plate';

        # check process outputs are correct
        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'PIQ0001', '..and is on correct plate';

        # check that additional process using same source well cannot be created
        #throws_ok {
        #    my $invalid_process = model->create_process( $dist_qc_process_data->{invalid_input} );
        #}
        #qr/FP well FFP0001_A01 would be linked to PIQ wells PIQ0001_A01 and PIQ0002_A01/,
        #    'correctly throws create failure when FP source well already used';

        # check that process can be deleted
        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';

        throws_ok {
            my $invalid_output_process
                = model->create_process( $dist_qc_process_data->{invalid_output} );
        }
        qr/dist_qc process output well should be type (PIQ)+ \(got SEP\)/;
    }
}

sub xep_pool_process : Tests() {
    note("Testing xep_pool process creation");
    my $xep_pool_process_data = test_data('xep_pool_process.yaml');
    {
        ok my $process = model->create_process( $xep_pool_process_data->{valid_input} ),
            'create_process for type xep_pool should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'xep_pool', 'process is of correct type (xep_pool)';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 3, '...three input wells';
        my $input_well = $input_wells->next;

        # check the names of the input wells
        is $input_well->name, 'A01', 'first input well has correct name';

        # ...
        is $input_well->plate->name, 'FEPD0006_1', '..and is on correct plate';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'XEP0006', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    {
        ok my $process = model->create_process( $xep_pool_process_data->{one_input_well} ),
            'create_process for type xep_pool with one input well succeeds';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'xep_pool', 'process is of correct type (xep_pool)';
        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 1, '...one input well provided';
        my $input_well = $input_wells->next;
        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';

    }
    throws_ok {
        my $process = model->create_process( $xep_pool_process_data->{invalid_output_well} );
    }
    qr/xep_pool process output well should be type (XEP)/;
}

#NOTE the single_crispr_assembly and paired_crispr_assembly tests seem to need data that was
#     created in the testing of the crispr_vector process so the tests for the following
#     processes are bundled into one subroutine:
#     crispr_vector
#     single_crispr_assembly
#     paired_crispr_assembly
# TODO use fixture data for the tests so they can be split up
sub crispr_vector_and_assembly_processes : Tests() {
    note("Testing crispr_vector process creation");
    my $crispr_vector_process_data = test_data('crispr_vector_process.yaml');
    {
        ok my $process = model->create_process( $crispr_vector_process_data->{valid_input} ),
            'create_process for type crispr_vector should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'crispr_vector', 'process is of correct type (crispr_vector)';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 1, '...one input well';
        my $input_well = $input_wells->next;

        # check the names of the input wells
        is $input_well->name, 'A01', 'first input well has correct name';

        # ...
        is $input_well->plate->name, 'CRISPR_T1', '...and is on correct plate';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'CRISPR_V_T1', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';

        ok $process = model->create_process( $crispr_vector_process_data->{valid_input1} ),
            'create_process for type crispr_vector should succeed';
        ok $process = model->create_process( $crispr_vector_process_data->{valid_input2} ),
            'create_process for type crispr_vector should succeed';
        ok $process = model->create_process( $crispr_vector_process_data->{valid_input3} ),
            'create_process for type crispr_vector should succeed';
    }

    throws_ok {
        my $process = model->create_process( $crispr_vector_process_data->{invalid_output_well} );
    }
    qr/crispr_vector process output well should be type (CRISPR_V)/;

    throws_ok {
        my $process = model->create_process( $crispr_vector_process_data->{invalid_input_well} );
    }
    qr/crispr_vector process input well should be type (CRISPR)/;

    note("Testing single_crispr_assembly process creation");
    my $assembly_process_data = test_data('assembly_process.yaml');
    # Set up some DNA wells from CRISPR_V and FINAL_PICK fixture data
    ok model->create_process( $assembly_process_data->{crispr1_dna_prep} );
    ok model->create_process( $assembly_process_data->{crispr2_dna_prep} );
    ok model->create_process( $assembly_process_data->{crispr3_dna_prep} );
    ok model->create_process( $assembly_process_data->{final_pick_dna_prep} );

    {
        ok my $process = model->create_process( $assembly_process_data->{single_ep_valid_input} ),
            'create_process for type single_crispr_assembly should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'single_crispr_assembly',
            'process is of correct type (single_crispr_assembly)';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 2, '...two input wells';

        # check the names of the input wells
        my $input_well = $input_wells->next;
        is $input_well->name, 'A01', 'first input well has correct name';
        is $input_well->plate->name, 'DNA_T1', '...and is on correct plate';
        $input_well = $input_wells->next;
        is $input_well->name, 'A01', 'second input well has correct name';
        is $input_well->plate->name, 'DNA_FP1008', '...and is on correct plate';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'ASSEMBLY_S1', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $assembly_process_data->{single_ep_invalid_output_well} );
    }
    qr/single_crispr_assembly process output well should be type (ASSEMBLY)/;

    throws_ok {
        my $process = model->create_process( $assembly_process_data->{single_ep_invalid_input_well} );
    }
    qr/single_crispr_assembly process should have 2 input well\(s\) \(got 1\)/;

    note("Testing paired_crispr_assembly process creation");
    {
        my $assembly_process_data = test_data('assembly_process.yaml');

        ok my $process = model->create_process( $assembly_process_data->{paired_ep_valid_input} ),
            'create_process for type paired_crispr_assembly should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'paired_crispr_assembly',
            'process is of correct type (paired_crispr_assembly)';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 3, '...three input wells';

        # check the names of the input wells
        my $input_well = $input_wells->next;
        is $input_well->name, 'A01', 'first input well has correct name';
        is $input_well->plate->name, 'DNA_T1', '...and is on correct plate';
        $input_well = $input_wells->next;
        is $input_well->name, 'A02', 'second input well has correct name';
        is $input_well->plate->name, 'DNA_T1', '...and is on correct plate';
        $input_well = $input_wells->next;
        is $input_well->name, 'A01', 'second input well has correct name';
        is $input_well->plate->name, 'DNA_FP1008', '...and is on correct plate';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'ASSEMBLY_P1', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $assembly_process_data->{paired_ep_invalid_input1} );
    }
    qr/paired_crispr_assembly process input well should be type DNA \(got XEP,DNA\)/;

    throws_ok {
        my $process = model->create_process( $assembly_process_data->{paired_ep_invalid_input2} );
    }
    qr/paired_crispr_assembly requires DNA prepared from paired CRISPR_V wells. The provided pair is not valid/;

}

sub crispr_ep_process : Tests() {
    note("Testing crispr_ep process creation");
    my $crispr_ep_process_data = test_data('crispr_ep_process.yaml');
    ok my $process = model->create_process( $crispr_ep_process_data->{ep_valid_input} ),
        'create_process for type crispr_ep should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'crispr_ep', 'process is of correct type (crispr_ep)';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 1, '...one input well';

    # check the names of the input wells
    my $input_well = $input_wells->next;
    is $input_well->name, 'A01', 'first input well has correct name';
    is $input_well->plate->name, 'ASSEMBLY_S1', '...and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'CRISPR_EP_S1', '..and is on correct plate';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';

    throws_ok {
        my $process = model->create_process( $crispr_ep_process_data->{ep_missing_information} );
    }
    qr/nuclease, is missing/;

    throws_ok {
        my $process = model->create_process( $crispr_ep_process_data->{ep_invalid_output_well} );
    }
    qr/crispr_ep process output well should be type CRISPR_EP \(got XEP\)/;

    throws_ok {
        my $process = model->create_process( $crispr_ep_process_data->{ep_invalid_input_well} );
    }
    qr/crispr_ep process input well should be type ASSEMBLY,OLIGO_ASSEMBLY \(got CRISPR\)/;
}

sub global_arm_shortening_process : Tests() {
    note("Testing global_arm_shortening process creation");
    my $global_arm_shortening_process_data = test_data('global_arm_shortening_process.yaml');

    {
        ok my $process = model->create_process( $global_arm_shortening_process_data->{valid_input} ),
            'create_process for type global_arm_shortening should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'global_arm_shortening', 'process is of correct type';

        ok my $process_backbone = $process->process_backbone, 'process has a process_backbone';
        is $process_backbone->backbone->name, 'pAYAC184',
            'process_backbone has correct intermediate backbone';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 1, 'only one input well';
        my $input_well = $input_wells->next;
        is $input_well->name, 'C04', 'input well has correct name';
        is $input_well->plate->name, 'PCS00035_A', '..and is on correct plate';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'C04', 'output well has correct name';
        is $output_well->plate->name, 'INT_ARM_SHORTEN_TEST', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $global_arm_shortening_process_data->{missing_input_well} );
    }
    qr/global_arm_shortening process should have 1 input well\(s\) \(got 0\)/;

    throws_ok {
        my $process = model->create_process( $global_arm_shortening_process_data->{invalid_input_well} );
    }
    qr/global_arm_shortening process input well should be type INT \(got EP\)/;

    throws_ok {
        my $process = model->create_process( $global_arm_shortening_process_data->{invalid_output_well} );
    }
    qr/global_arm_shortening process output well should be type INT \(got EP\)/;

    throws_ok {
        my $process = model->create_process( $global_arm_shortening_process_data->{multiple_output_wells} );
    }
    qr/Process should have 1 output well \(got 2\)/;

    throws_ok {
        my $process = model->create_process( $global_arm_shortening_process_data->{non_arm_shortened_design} );
    }
    qr/The specified design 372441 is not set as a short arm design/;

    throws_ok {
        my $process = model->create_process( $global_arm_shortening_process_data->{wrong_arm_shortened_design} );
    }
    qr/The short arm design 222222 is not linked to the intermediate wells original design 103/;

    throws_ok {
        my $process = model->create_process( $global_arm_shortening_process_data->{backbone_wrong_resistance} );
    }
    qr/The antibiotic resistance on the intermediate backbone used in a global_arm_shortening process should be Chloramphenicol/;
}

sub oligo_assembly_process : Tests() {
    note("Testing oligo_assembly process creation");
    my $oligo_assembly_process_data = test_data('oligo_assembly_process.yaml');

    {
        ok my $process = model->create_process( $oligo_assembly_process_data->{valid_input} ),
            'create_process for type oligo_assembly should succeed';
        isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
        is $process->type->id, 'oligo_assembly', 'process is of correct type';

        ok my $process_crispr_tracker_rna = $process->process_crispr_tracker_rna,
            'process has a process_crispr_tracker_rna';
        is $process_crispr_tracker_rna->crispr_tracker_rna->name, 'standard',
            'process_crispr_tracker_rna has correct crispr tracker rna';

        ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
        is $input_wells->count, 2, 'two input well';
        my @input_well_plate_types = sort map { $_->plate->type_id } $input_wells->all;
        is_deeply \@input_well_plate_types, [ 'CRISPR', 'DESIGN' ], 'have a CRISPR and DESIGN input well';

        ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
        is $output_wells->count, 1, 'only one output well';
        my $output_well = $output_wells->next;
        is $output_well->name, 'A01', 'output well has correct name';
        is $output_well->plate->name, 'OLIGO_ASSEMBLY_TEST', '..and is on correct plate';

        lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
    }

    throws_ok {
        my $process = model->create_process( $oligo_assembly_process_data->{missing_input_well} );
    }
    qr/oligo_assembly process should have 2 input well\(s\) \(got 0\)/;

    throws_ok {
        my $process = model->create_process( $oligo_assembly_process_data->{invalid_input_well} );
    }
    qr/oligo_assembly process input well should be type CRISPR,DESIGN \(got DNA,DESIGN\)/;

    throws_ok {
        my $process = model->create_process( $oligo_assembly_process_data->{invalid_output_well} );
    }
    qr/oligo_assembly process output well should be type OLIGO_ASSEMBLY \(got EP\)/;

    throws_ok {
        my $process = model->create_process( $oligo_assembly_process_data->{not_nonsense_design} );
    }
    qr/oligo_assembly can only use nonsense type designs/;

    throws_ok {
        my $process = model->create_process( $oligo_assembly_process_data->{wrong_nonsense_design_crispr} );
    }
    qr/nonsense design is linked to crispr 113, not crispr 69543/;
}

1;

__END__

