#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use LIMS2::Model::DBConnect;
use YAML::Any;

use_ok 'LIMS2::Model';

ok my $schema = LIMS2::Model::DBConnect->connect( 'LIMS2_PROCESS_TEST', 'tests' ),
    'connect to LIMS2_TEST';

ok my $model = LIMS2::Model->new( schema => $schema ), 'instantiate model';

my $params = Load( do { local $/ = undef; <DATA> } );

$model->txn_do(
    sub {
        can_ok $model, 'create_qc_run';

        ok my $qc_sequencing_project = $model->create_qc_sequencing_project(
            $params->{qc_sequencing_project} ), 'create_qc_sequencing_project should succeed';

        ok my $qc_template = $model->create_qc_template( $params->{qc_template} )
            , 'create_qc_template should succeed';

        ok my $qc_run = $model->create_qc_run( $params->{qc_run} )
            ,'create_qc_run should succeed';

        ok my $qc_seq_read = $model->create_qc_seq_read( $params->{qc_seq_read} )
            ,'create_qc_seq_read should succeed';

        ok $params->{qc_test_result}{qc_eng_seq_id} =
            $qc_template->qc_template_wells->first->qc_eng_seq_id
                , 'set qc_eng_seq_id for qc_test_result';

        ok my $qc_test_result = $model->create_qc_test_result( $params->{qc_test_result} )
            ,'create_qc_test_result should succeed';

        is $qc_test_result->well_name, 'A01', '.. has correct well_name';
        is $qc_test_result->qc_run_id, $qc_run->id, '.. linked to correct qc_run';

        ok my $qc_test_result_alignment_maps = $qc_test_result->qc_test_result_alignment_maps
            , 'can grab qc_test_result_alignment_maps';

        is $qc_test_result_alignment_maps->count, 2, '.. has 2 alignment map';
        ok my $qc_test_result_alignment = $qc_test_result_alignment_maps->first->qc_test_result_alignment
            , 'can grab qc_test_result_alignment';

        is $qc_test_result_alignment->primer_name, 'R3', '.. correct primer name';
        is $qc_test_result_alignment->qc_seq_read_id, $qc_seq_read->id
            , '.. belongs to correct qc_seq_read';

        ok my $qc_test_result_align_region = $qc_test_result_alignment->qc_test_result_align_regions->first
            , 'can grab qc_test_result_align_region';

        is $qc_test_result_align_region->name, 'Target Region', '.. has correct name';


        $model->txn_rollback;
    }
);

done_testing;

__DATA__
---
qc_test_result:
    qc_run_id: 47291142-5BA3-11E1-8E63-B870F3CB94C8
    well_name: A01
    plate_name: PG00253_Z_4
    score: 10917
    pass: 1
    qc_test_result_alignments:
      - qc_seq_read_id: PSA002_A_2d10.p1kaR3
        primer_name: R3
        query_start: 1
        query_end: 2
        query_strand: 1
        target_start: 3
        target_end: 4
        target_strand: 1
        score: 23421
        pass: 1
        features: blah
        cigar: 'cigar: blah'
        op_str: M 21 I 1
        alignment_regions:
          - name: Target Region
            length: 234
            match_count: 345
            query_str: ATGC
            target_str: ATGCGC
            match_str: '  |||'
            pass: 1
      - qc_seq_read_id: PSA002_A_2d10.p1kaR3
        primer_name: R3
        query_start: 1
        query_end: 2
        query_strand: 1
        target_start: 3
        target_end: 4
        target_strand: 1
        score: 100000
        pass: 1
        features: blah
        cigar: 'cigar: blah'
        op_str: M 21 I 1
        alignment_regions:
          - name: Target Region
            length: 234
            match_count: 345
            query_str: ATGC
            target_str: ATGCGC
            match_str: '  |||'
            pass: 1

qc_seq_read:
    id: PSA002_A_2d10.p1kaR3
    qc_sequencing_project: PG00259_Z
    description: bases 28 to 738 (QL to QR)
    seq: CTATGAAAAAATTTTTTTCCCCCCCCGGGGGGGCGTAAGTCC
    length: 42

qc_sequencing_project:
    name: PG00259_Z

qc_run:
    id: 47291142-5BA3-11E1-8E63-B870F3CB94C8
    date: 2011-02-12T12:50:50
    profile: eucomm-post-cre
    software_version: 1.1.2
    qc_sequencing_projects: PG00259_Z
    qc_template_name: VTP00001

qc_template:
    name: VTP00001
    wells:
        A01:
            eng_seq_method: conditional_vector_seq
            eng_seq_params: '{"target_region_start":127011877,"five_arm_start":127013739,"three_arm_end":127011800,"five_arm_end":127019673,"transcript":"ENSMUST00000056146","target_region_end":127013636,"three_arm_start":127007813,"backbone":{"name":"R3R4_pBR_DTA+_Bsd_amp","type":"intermediate-backbone"},"u_insertion":{"name":"pR6K_R1R2_ZP","type":"intermediate-cassette"},"chromosome":2,"strand":-1,"d_insertion":{"name":"LoxP","type":"LoxP"}}'
