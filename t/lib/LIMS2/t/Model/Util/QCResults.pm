package LIMS2::t::Model::Util::QCResults;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::QCResults qw(
            retrieve_qc_run_results
            retrieve_qc_run_summary_results
            retrieve_qc_run_seq_well_results
            retrieve_qc_alignment_results
            retrieve_qc_seq_read_sequences
            retrieve_qc_eng_seq_sequence
            build_qc_runs_search_params
            infer_qc_process_type
            );

use LIMS2::Test;
use Try::Tiny;
use IO::File;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/QCResults.pm - test class for LIMS2::Model::Util::QCResults

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
};

=head2 before

Code to run before every test

=cut

sub before : Test(setup)
{
    #diag("running before test");
};

=head2 after

Code to run after every test

=cut

sub after  : Test(teardown)
{
    #diag("running after test");
};


=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup)
{
    #diag("running before all tests");
};

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown  : Test(shutdown)
{
    #diag("running after all tests");
};

=head2 all_tests

Code to execute all tests

=cut

sub almost_all_tests  : Test(48)
{

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

}

sub test_infer_qc_process_type : Test(29) {
    note( 'DESIGN source plates' );
    throws_ok {
        infer_qc_process_type( { cassette => 'foo', backbone => 'bar' }, 'POSTINT', 'DESIGN' )
    } qr/Can only create PREINT or INT plate from a DESIGN template plate/
        , 'throws error when trying to create non INT plate';

    throws_ok {
        infer_qc_process_type( { cassette => 'foo' }, 'INT', 'DESIGN' )
    } qr/A cassette and backbone were not specified when the DESIGN template plate was created/
        , 'throws error for missing cassette and backbone';

    throws_ok {
        infer_qc_process_type( { recombinase => 'foo' }, 'INT', 'DESIGN' )
    } qr/A recombinase was specified when the DESIGN template plate was created/
        , 'throws error for unwanted recombinase';

    is infer_qc_process_type( { cassette => 'foo', backbone => 'bar' }, 'INT', 'DESIGN' ), 'int_recom',
        'correctly infers int_recom process for DESIGN to INT';


    note( 'INT source plates' );
    throws_ok {
        infer_qc_process_type( { cassette => 'foo' }, 'INT', 'INT' )
    } qr/Cassette \/ backbone was specified when the INT template plate was created/
        , 'throws error for unwanted cassette or backbone INT to INT';

    is infer_qc_process_type( {}, 'INT', 'INT' ), 'rearray',
        'correctly infers rearray process for INT to INT';

    is infer_qc_process_type( { recombinase => 'foo' }, 'INT', 'INT' ), 'recombinase',
        'correctly infers recombinase process for INT to INT';

    throws_ok {
        infer_qc_process_type( {}, 'POSTINT', 'INT' )
    } qr/A cassette and or backbone were not specified when the INT template plate was created/
        , 'throws error when trying to create POSTINT plate with no cassette or backbone specified';

    is infer_qc_process_type( { cassette => 'foo', backbone => 'bar' }, 'POSTINT', 'INT' ), '3w_gateway',
        'correctly infers 3w_gateway process for POSTINT plate';

    is infer_qc_process_type( { cassette => 'foo', recombinase => 'foo' }, 'FINAL', 'INT' ), '2w_gateway',
        'correctly infers 2w_gateway process for FINAL plate';

    throws_ok {
        infer_qc_process_type( {}, 'FINAL_PICK', 'INT' )
    } qr/Can not create FINAL_PICK/
        , 'throws error when trying to create FINAL_PICK plate';

    throws_ok {
        infer_qc_process_type( {}, 'FOO', 'INT' )
    } qr/Can not handle FOO plate type/
        , 'throws error when trying to create unknown plate';


    note( 'POSTINT source plate' );
    throws_ok {
        infer_qc_process_type( {}, 'INT', 'POSTINT' )
    } qr/Can not create INT plate from POSTINT/
        , 'throws error when trying to create INT plate';

    throws_ok {
        infer_qc_process_type( {}, 'FINAL_PICK', 'POSTINT' )
    } qr/Can not create FINAL_PICK plate from POSTINT/
        , 'throws error when trying to create FINAL_PICK plate';

    is infer_qc_process_type( { cassette => 'foo', backbone => 'bar' }, 'POSTINT', 'POSTINT' ), '3w_gateway',
        'correctly infers 3w_gateway process for POSTINT plate';

    is infer_qc_process_type( { backbone => 'bar' }, 'POSTINT', 'POSTINT' ), '2w_gateway',
        'correctly infers 2w_gateway process for POSTINT plate';

    is infer_qc_process_type( { recombinase => 'bar' }, 'FINAL', 'POSTINT' ), 'recombinase',
        'correctly infers recombinase process for FINAL plate';

    is infer_qc_process_type( { }, 'FINAL', 'POSTINT' ), 'rearray',
        'correctly infers rearray process for FINAL plate';


    note( 'FINAL source plate' );
    throws_ok {
        infer_qc_process_type( {}, 'INT', 'FINAL' )
    } qr/Can not create INT plate from FINAL/
        , 'throws error when trying to create INT plate';

    throws_ok {
        infer_qc_process_type( { cassette => 'foo' }, 'FINAL', 'FINAL' )
    } qr/Cassette \/ backbone was specified when the FINAL template plate was created/
        , 'throws error when trying to create FINAL plate while specifying cassette';

    throws_ok {
        infer_qc_process_type( { cassette => 'foo' }, 'FINAL_PICK', 'FINAL' )
    } qr/Cassette \/ backbone was specified when the FINAL template plate was created/
        , 'throws error when trying to create FINAL_PICK plate while specifying cassette';

    throws_ok {
        infer_qc_process_type( { recombinase => 'foo' }, 'FINAL_PICK', 'FINAL' )
    } qr/A recombinase was specified when the FINAL template plate was created/
        , 'throws error when trying to create FINAL_PICK plate while specifying recombinase';

    is infer_qc_process_type( {}, 'FINAL', 'FINAL' ), 'rearray',
        'correctly infers rearray process for FINAL plate';

    is infer_qc_process_type( { recombinase => 'foo' }, 'FINAL', 'FINAL' ), 'recombinase',
        'correctly infers recombinase process for FINAL plate';

    is infer_qc_process_type( { }, 'FINAL_PICK', 'FINAL' ), 'final_pick',
        'correctly infers final_pick process for FINAL_PICK plate';

    note( 'FINAL_PICK source plate' );
    throws_ok {
        infer_qc_process_type( {}, 'FINAL', 'FINAL_PICK' )
    } qr/Can only create a FINAL_PICK plate from another FINAL_PICK/
        , 'throws error when trying to create FINAL plate';

    throws_ok {
        infer_qc_process_type( { cassette => 'foo' }, 'FINAL_PICK', 'FINAL_PICK' )
    } qr/Cassette \/ backbone was specified when the FINAL_PICK template plate was created/
        , 'throws error when trying to create FINAL_PICK plate while specifying cassette';

    throws_ok {
        infer_qc_process_type( { recombinase => 'foo' }, 'FINAL_PICK', 'FINAL_PICK' )
    } qr/A recombinase was specified when the FINAL_PICK template plate was created/
        , 'throws error when trying to create FINAL_PICK plate while specifying recombinase';

    is infer_qc_process_type( {}, 'FINAL_PICK', 'FINAL_PICK' ), 'rearray',
        'correctly infers rearray process for FINAL_PICK plate';
}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

