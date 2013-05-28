#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($FATAL);
}

use LIMS2::Test;
use Test::Most;
use Try::Tiny;
use IO::File;

BEGIN {
    use_ok(
        'LIMS2::Model::Util::QCResults', qw(
            retrieve_qc_run_results
            retrieve_qc_run_summary_results
            retrieve_qc_run_seq_well_results
            retrieve_qc_alignment_results
            retrieve_qc_seq_read_sequences
            retrieve_qc_eng_seq_sequence
            build_qc_runs_search_params
            )
    );
}

note('Test retrieve_qc_run_results');
{
    ok my $qc_run = model->retrieve_qc_run( { id => '534EE22E-3DBF-22E4-5EF2-1234F5CB64C7' } ),
        'retrieve qc run';

    ok my $qc_run_results = retrieve_qc_run_results($qc_run), 'retrieve qc run results';

    for my $result ( @{$qc_run_results} ) {
        is $result->{LR_pass}, 1, 'result has correct LR pass value' if exists $result->{LR_pass};
        is $result->{design_id}, 372441, 'result has correct design_id'
            if exists $result->{design_id};
        is $result->{plate_name}, 'PCS05036_A_1', 'result has correct plate name';
    }

}

note('Test retrieve_qc_run_summary_results');
{
    ok my $qc_run = model->retrieve_qc_run( { id => '534EE22E-3DBF-22E4-5EF2-1234F5CB64C7' } ),
        'retrieve qc run';

    ok my $qc_run_summary_results = retrieve_qc_run_summary_results($qc_run),
        'retrieve qc run summary results';
    my $result = $qc_run_summary_results->[0];

    is $result->{design_id},     372441, '.. correct design_id';
    is $result->{valid_primers}, 'LR',   '.. correct valid primer';
    is $result->{pass},          1,      '..correct pass level';

}

note('Test retrieve_qc_run_seq_well_results');
{
    my $qc_run_id = '534EE22E-3DBF-22E4-5EF2-1234F5CB64C7';
    ok my $seq_well = model->retrieve_qc_run_seq_well(
        {   qc_run_id  => $qc_run_id,
            plate_name => 'PCS05036_A_1',
            well_name  => 'B02',
        }
        ),
        'retrieve qc run seq well';

    ok my ( $seq_reads, $qc_seq_well_results ) = retrieve_qc_run_seq_well_results($qc_run_id, $seq_well),
        'can retrieve qc run seq well results';

    for my $seq_read ( @{$seq_reads} ) {
        isa_ok $seq_read, 'LIMS2::Model::Schema::Result::QcSeqRead';
    }

    my $result = $qc_seq_well_results->[0];
    is $result->{design_id}, 372441, '.. correct design id';
    is $result->{score},     2605,   '.. correct score';
    is $result->{pass},      0,      '.. correct pass value';

    ok my $seq_well2 = model->retrieve_qc_run_seq_well(
        {   qc_run_id  => $qc_run_id,
            plate_name => 'PCS05036_A_1',
            well_name  => 'A01',
        }
        ),
        'retrieve qc run seq well';

    throws_ok {
        retrieve_qc_run_seq_well_results($qc_run_id, $seq_well2);
    }
    'LIMS2::Exception::Validation', 'throws error if seq well has no seq reads';

}

note('Test retrieve_qc_alignment_results');
{
    ok my $qc_alignment = model->retrieve( 'QcAlignment' => { 'me.id' => 93 } ),
        'retrieve qc alignment';

    ok my $result = retrieve_qc_alignment_results( model->eng_seq_builder, $qc_alignment ),
        'can retrieve qc alignment results';

    is $result->{target}, '372441#L1L2_Bact_P#L3L4_pD223_DTA_T_spec', '.. correct target';
    is $result->{query}, 'PCS05036_A_1b02.p1kLR', '.. correct query';

}

note('Test retrieve_qc_seq_read_sequences');
{
    ok my $seq_well = model->retrieve_qc_run_seq_well(
        {   qc_run_id  => '534EE22E-3DBF-22E4-5EF2-1234F5CB64C7',
            plate_name => 'PCS05036_A_1',
            well_name  => 'B02',
        }
        ),
        'retrieve qc run seq well';

    ok my ( $filename, $seq ) = retrieve_qc_seq_read_sequences( $seq_well, 'fasta' ),
        'can retrieve qc seq read sequences';

    is $filename, 'seq_reads_PCS05036_A_1B02.fasta', '.. correct filename';
    like $seq,    qr/>PCS05036_A_1b02\.p1kLR/,       '..seq looks correct';

    ok my ( $other_filename, $other_seq ) = retrieve_qc_seq_read_sequences( $seq_well, 'blah' ),
        'retrieve qc seq read sequences with invalid format';

    is $other_filename, 'seq_reads_PCS05036_A_1B02.gbk', '.. defaults to genbank file';

    ok my $seq_well2 = model->retrieve_qc_run_seq_well(
        {   qc_run_id  => '534EE22E-3DBF-22E4-5EF2-1234F5CB64C7',
            plate_name => 'PCS05036_A_1',
            well_name  => 'A01',
        }
        ),
        'retrieve qc run seq well';

    throws_ok {
        retrieve_qc_seq_read_sequences($seq_well2);
    }
    'LIMS2::Exception::Validation', 'throws error if seq well has no seq reads';
}

note('Test retrieve_qc_eng_seq_sequence');
{
    ok my $qc_test_result = model->retrieve( 'QcTestResult' => { id => 70 } ),
        'can retrive qc test result';

    ok my ( $filename, $seq )
        = retrieve_qc_eng_seq_sequence( model->eng_seq_builder, $qc_test_result, 'fasta' ),
        'can retrieve qc eng seq sequence';

    is $filename, '372441#L1L2_Bact_P#L3L4_pD223_DTA_T_spec.fasta', '.. correct filename';
    like $seq,    qr/>372441#L1L2_Bact_P#L3L4_pD223_DTA_T_spec/,    '..seq looks correct';

    ok my ( $other_filename, $other_seq )
        = retrieve_qc_eng_seq_sequence( model->eng_seq_builder, $qc_test_result ),
        'retrieve qc seq read sequences with no format';

    is $other_filename, '372441#L1L2_Bact_P#L3L4_pD223_DTA_T_spec.gbk',
        '.. defaults to genbank file';
}

note('Test build_qc_runs_search_params');
{

    ok my $params_show_all
        = build_qc_runs_search_params( { show_all => 1, species_id => 'Mouse' } ),
        'can build qc runs search params';

    is_deeply $params_show_all,
        { 'me.upload_complete' => 't', 'qc_seq_project.species_id' => 'Mouse' },
        '.. search params correct with show_all option set';

    ok my $params_seq_project
        = build_qc_runs_search_params( { sequencing_project => 1, species_id => 'Mouse' } ),
        'can build qc runs search params';

    is_deeply $params_seq_project,
        {
        'me.upload_complete'                    => 't',
        'qc_seq_project.species_id'             => 'Mouse',
        'qc_run_seq_projects.qc_seq_project_id' => 1
        },
        '.. search params correct with sequencing project specified';

    ok my $params_template
        = build_qc_runs_search_params( { template_plate => 'test', species_id => 'Mouse' } ),
        'can build qc runs search params';

    is_deeply $params_template,
        {
        'me.upload_complete'        => 't',
        'qc_seq_project.species_id' => 'Mouse',
        'qc_template.name'          => 'test'
        },
        '.. search params correct with template plate specified';

    ok my $params_profile
        = build_qc_runs_search_params( { profile => 'foo', species_id => 'Mouse' } ),
        'can build qc runs search params';

    is_deeply $params_profile,
        {
        'me.upload_complete'        => 't',
        'qc_seq_project.species_id' => 'Mouse',
        'me.profile'                => 'foo'
        },
        '.. search params correct with profile specified';
}

done_testing();
