#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use LIMS2::Model::DBConnect;
use YAML::Any;
use JSON qw( decode_json );

use_ok 'LIMS2::Model';

ok my $schema = LIMS2::Model::DBConnect->connect( 'LIMS2_PROCESS_TEST', 'tests' ),
    'connect to LIMS2_TEST';

ok my $model = LIMS2::Model->new( schema => $schema ), 'instantiate model';

my $params = Load( do { local $/ = undef; <DATA> } );

$model->txn_do(
    sub {
        can_ok $model, 'create_qc_template';

        ok my $qc_template = $model->create_qc_template( $params ), 'create_qc_template should succeed';

        is $qc_template->name, 'VTP00001', '.. has correct plate name';

        ok my $qc_template_well = $qc_template->qc_template_wells->first, '.. can grab well';
        is $qc_template_well->name, 'A01', '.. has correct well name';

        ok my $qc_eng_seq = $qc_template_well->qc_eng_seq, '.. well belongs to a qc_eng_seq';
        is $qc_eng_seq->eng_seq_method, 'conditional_vector_seq', '.. qc_eng_seq has correct method';
        ok my $eng_seq_params = decode_json( $qc_eng_seq->eng_seq_params ), '.. can decode eng_seq_params';
        is $eng_seq_params->{transcript}, 'ENSMUST00000056146' ,'.. transcript is correct';

        ok my $qc_template_well_A02 = $qc_template->qc_template_wells->find(
            { name => 'A02' } ), 'grab second template well';
        is $qc_template_well_A02->qc_eng_seq_id, $qc_template_well->qc_eng_seq_id
            , '.. and both wells have same qc_eng_seq even though JSON input not in same order';

        ok my $qc_template_well_A03 = $qc_template->qc_template_wells->find(
            { name => 'A03' } ), 'grab third template well';
        isnt $qc_template_well_A03->qc_eng_seq_id, $qc_template_well->qc_eng_seq_id
            , '.. and this well has a different qc_eng_seq_id';

        $model->txn_rollback;
    }
);

done_testing;

__DATA__
---
name: VTP00001
wells:
    A01:
        eng_seq_method: conditional_vector_seq
        eng_seq_params: '{"target_region_start":127011877,"five_arm_start":127013739,"three_arm_end":127011800,"five_arm_end":127019673,"transcript":"ENSMUST00000056146","target_region_end":127013636,"three_arm_start":127007813,"backbone":{"name":"R3R4_pBR_DTA+_Bsd_amp","type":"intermediate-backbone"},"u_insertion":{"name":"pR6K_R1R2_ZP","type":"intermediate-cassette"},"chromosome":2,"strand":-1,"d_insertion":{"name":"LoxP","type":"LoxP"}}'
    A02:
        eng_seq_method: conditional_vector_seq
        eng_seq_params: '{"target_region_start":127011877,"three_arm_end":127011800,"five_arm_end":127019673,"transcript":"ENSMUST00000056146","target_region_end":127013636,"three_arm_start":127007813,"five_arm_start":127013739,"backbone":{"name":"R3R4_pBR_DTA+_Bsd_amp","type":"intermediate-backbone"},"u_insertion":{"name":"pR6K_R1R2_ZP","type":"intermediate-cassette"},"chromosome":2,"strand":-1,"d_insertion":{"name":"LoxP","type":"LoxP"}}'
    A03:
        eng_seq_method: conditional_vector_seq
        eng_seq_params: '{"target_region_start":127011877,"five_arm_start":127013739,"three_arm_end":127011800,"five_arm_end":127019673,"transcript":"ENSMUST00000056147","target_region_end":127013636,"three_arm_start":127007813,"backbone":{"name":"R3R4_pBR_DTA+_Bsd_amp","type":"intermediate-backbone"},"u_insertion":{"name":"pR6K_R1R2_ZP","type":"intermediate-cassette"},"chromosome":2,"strand":-1,"d_insertion":{"name":"LoxP","type":"LoxP"}}'
