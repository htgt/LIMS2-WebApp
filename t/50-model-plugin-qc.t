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

note( "Testing QC template storage and retrieval" );

my $template_data = test_data( 'qc_template.yaml' );
my $template_name = $template_data->{name};

{
    ok my $res = model->retrieve_qc_templates( { name => $template_name } ),
        'retrieve_qc_templates should succeed';
    isa_ok $res, ref [],
        'retrieve_qc_templates return';
    is @{$res}, 0,
        'retrieve_qc_templates should return an empty array';
}

my $created_template;

lives_ok {
    $created_template = model->find_or_create_qc_template( $template_data );
} 'find_or_create_qc_template should live';

isa_ok $created_template, 'LIMS2::Model::Schema::Result::QcTemplate',
    'find_or_create_qc_template return';

{
    ok my $res = model->retrieve_qc_templates( { id => $created_template->id } ),
        'retrieve_qc_templates by id should succeed';
    is @{$res}, 1,
        'retrieve_qc_templates by id should return a 1-element array';
    is $res->[0]->id, $created_template->id,
        'the returned template has the expected id';
}

lives_ok {
    ok my $template = model->find_or_create_qc_template( $template_data ),
        'find_or_create_qc_template should succeed';
    isa_ok $template, 'LIMS2::Model::Schema::Result::QcTemplate',
        'the object it returns';
    is $template->id, $created_template->id,
        'attempting to create a template with the same parameters should return the original template';
} 'find_or_create_template a second time should live';

delete $template_data->{created_at};
$template_data->{wells}{A02}{eng_seq_params}{five_arm_end}++;

my $modified_created_template;

lives_ok {
    ok $modified_created_template = model->find_or_create_qc_template( $template_data ),
        'find_or_create_qc_tempalte with modified parameters should succeed';
    isa_ok $modified_created_template, 'LIMS2::Model::Schema::Result::QcTemplate',
        'the object it returns';
    isnt $modified_created_template->id, $created_template->id,
        'the modified template has a different id from the original';
};

{
    ok my $res = model->retrieve_qc_templates( { name => $template_name, latest => 0 } ),
        'retrieve_qc_templates, latest=0, should succeed';
    is @{$res}, 2,
        'it should return 2 templates';
    is $res->[0]->name, $res->[1]->name,
        'the returned templates have the same name';
}

{
    ok my $res = model->retrieve_qc_templates( { name => $template_name } ),
        'retrieve_qc_templates, implicit latest=1, should succeed';
    is @{$res}, 1,
        'it should return 1 template';
    is $res->[0]->id, $modified_created_template->id,
        'the returned template is the most recent';
}

{
    ok my $templates = model->retrieve_qc_templates( { id => $created_template->id } ),
        'retrieve_qc_templates by id should succeed';
    is @{$templates}, 1,
        'retrieve_qc_templates by id should return 1 template';
    is $templates->[0]->id, $created_template->id,
        'the returned template has the expected id';
    ok my $res = model->retrieve_qc_templates( { name => $template_name, created_before => $templates->[0]->created_at->iso8601 } ),
        'retrieve_qc_templates, created_before, should succeed';
    is @{$res}, 1,
        'it should return 1 template';
    is $res->[0]->id, $created_template->id,
        'the returned template is the original';
}

note( "Testing QC run storage" );

my $qc_run_data = test_data( 'qc_run.yaml' );

# Make sure the template_name is a valid template name
$qc_run_data->{qc_template_name} = $template_name;

# Test results are persisted separately
my $test_results = delete $qc_run_data->{test_results};

ok my $qc_run = model->create_qc_run( $qc_run_data ), 'create_qc_run';

note( "Testing QC seq read storage and retrieval" );

my @seq_reads_data = test_data( 'qc_seq_reads.yaml' );

for my $datum ( @seq_reads_data ) {
    $datum->{qc_run_id} = $qc_run->id;
    ok my $qc_seq_read = model->find_or_create_qc_seq_read( $datum ), "find_or_create_seq_read $datum->{id}";
    is $qc_seq_read->id, $datum->{id}, '...the read has the expected id';
    ok my $ret = model->retrieve_qc_seq_read( { id => $datum->{id} } ), 'retrieve_qc_seq_read should succeed';
    is $ret->id, $datum->{id}, '...the retrieved read has the expected id';
}

note( "Testing QC test result storage" );

for my $test_result ( @{ $test_results } ) {
    # Make sure the eng_seq_id exists in the database
    my $eng_seq_id = model->schema->resultset( 'QcEngSeq' )->search( {}, { order_by => \'RANDOM()', limit => 1 } )->first->id;
    $test_result->{qc_eng_seq_id} = $eng_seq_id;
    for my $alignment ( @{ $test_result->{alignments} } ) {
        $alignment->{qc_eng_seq_id} = $eng_seq_id;
    }
    $test_result->{qc_run_id} = $qc_run_data->{id};
    ok my $res = model->create_qc_test_result( $test_result ), 'create QC test result';
    isa_ok $res, 'LIMS2::Model::Schema::Result::QcTestResult';
}

note( "Testing set QC run upload complete" );

{
    ok my $qc_run = model->update_qc_run( { id => $qc_run_data->{id}, upload_complete => 1 } ), 'update_qc_run';
    is $qc_run->upload_complete, 1, 'the returned object has been updated';
}

note "Testing QC template deletion";

lives_ok {
    my $id = $created_template->id;
    ok model->delete_qc_template( { id => $id } ), 'delete template ' . $id . ' should succeed';
};

throws_ok {
    my $id = $modified_created_template->id;
    model->delete_qc_template( { id => $id } )
} qr/Template \d+ has been used in one or more QC runs, so cannot be deleted/;

note( "Testing Qc Run Retrieval" );

{
    ok my ($qc_runs_data) = model->retrieve_qc_runs( { species => 'Mouse' } ),
        'Can retrieve all qc runs';
    is scalar( @{$qc_runs_data} ), 2, '.. we have 2 qc runs';

    ok my ($qc_runs_profile_data)
        = model->retrieve_qc_runs( { species => 'Mouse', profile => 'eucomm-post-cre' } ),
        'Can retrieve all qc runs with specific profile';
    is scalar( @{$qc_runs_profile_data} ), 1, '.. we have no qc runs with specfied profile';

    ok my $qc_run = model->retrieve_qc_run( { id => '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8'  } )
        , 'can retrieve single Qc Run';
}

note ( 'Qc Run Seq Well Retrieval' );

{
    ok my $qc_seq_well = model->retrieve_qc_run_seq_well(
        {   qc_run_id  => '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8',
            plate_name => 'PCS04026_A_1',
            well_name  => 'B02'
        }
    ), 'can retrieve qc run seq well';

    isa_ok $qc_seq_well, 'LIMS2::Model::Schema::Result::QcRunSeqWell';

    is $qc_seq_well->qc_run_id, '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8', '..seq well belongs to correct Qc Run';
}

note ( 'Qc Run Results Retrieval' );

{
    lives_ok {
        model->qc_run_results( { qc_run_id => '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8' } ),
    } 'can retrieve Qc Run results';

    lives_ok {
        model->qc_run_summary_results( { qc_run_id => '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8' } )
    } 'can retrieve Qc Run summary results';

    lives_ok {
        model->qc_run_seq_well_results(
            {   qc_run_id  => '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8',
                plate_name => 'PCS04026_A_1',
                well_name  => 'B02'
            }
        )
    } 'can retrieve qc run seq well results';

    lives_ok {
        model->qc_alignment_result( { qc_alignment_id => 93 } )
    } 'can get qc alignment result';

    lives_ok {
        model->qc_seq_read_sequences(
            {   qc_run_id  => '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8',
                plate_name => 'PCS04026_A_1',
                well_name  => 'B02',
                format     => 'fasta',
            }
        )
    } 'can retrieve qc seq read sequences';

    lives_ok {
        model->qc_eng_seq_sequence(
            {   format  => 'fasta',
                qc_test_result_id => 70,
            }
        )
    } 'can retrieve qc eng seq sequence';

}

note ( "Testing List Profiles" );

{
    ok my $profiles = model->list_profiles(), 'list_profiles ok';
    is_deeply $profiles, [ 'eucomm-cre', 'eucomm-post-cre', 'test' ], '.. profile list is correct';
}

done_testing();
