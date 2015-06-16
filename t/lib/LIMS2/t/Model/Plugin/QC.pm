package LIMS2::t::Model::Plugin::QC;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Plugin::QC;

use LIMS2::Test;
use Test::Most;
use Try::Tiny;
use DateTime;
use Data::Dumper;
use JSON;

use LIMS2::Model::Util::QCTemplates qw( qc_template_display_data );

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Plugin/QC.pm - test class for LIMS2::Model::Plugin::QC

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
};

=head2 before

Code to run before every test

=cut

sub before : Test(setup) {

    #diag("running before test");
}

=head2 after

Code to run after every test

=cut

sub after : Test(teardown) {

    #diag("running after test");
}

=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup) {

    #diag("running before all tests");
}

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown : Test(shutdown) {

    #diag("running after all tests");
}

=head2 all_tests

Code to execute all tests

=cut

sub all_tests  : Test(99) {

    note "Testing creation of plate from QC results";

    {
	my $params = {
	    qc_run_id    => '534EE22E-3DBF-22E4-5EF2-1234F5CB64C7',
	    plate_type   => 'FINAL',
	    created_by   => 'test_user@example.org',
	    view_uri     => 'http://test/view',
	};

	ok my ($new_plate) = model->create_plates_from_qc($params), 'new plates created from QC';
	isa_ok $new_plate, 'LIMS2::Model::Schema::Result::Plate';
	is $new_plate->name, 'PCS05036_A_1', 'plate name correct';
	is $new_plate->type->id, 'FINAL', 'plate type is correct';
	my @wells = $new_plate->wells->all;
	is scalar @wells, 2, 'plate has 2 wells';
	my ($b02) = grep { $_->name eq 'B02'} @wells;
	my ($g12) = grep { $_->name eq 'G12'} @wells;
	ok $b02, 'well B02 created';
	ok $g12, 'well G12 created';
	ok my $result = $g12->well_qc_sequencing_result, 'well G12 has sequencing result';
	is $result->valid_primers, 'LR','well valid primers correct';
	is $result->mixed_reads, '0','well mixed reads correct';
	is $result->pass, '1','well pass correct';
	is $g12->accepted, '1', 'well accepted flag correct';
	my $view_uri = 'http://test/view?well_name=g12&plate_name=PCS05036_A_1&qc_run_id=534EE22E-3DBF-22E4-5EF2-1234F5CB64C7';
	is $result->test_result_url, $view_uri, 'well test result url correct';
    }

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

	is_deeply [ sort @{$qc_run->primers} ], [ 'LR', 'Z1', ], '.. primer list is correct';
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
	is_deeply $profiles, [ 'eucomm-post-cre', 'eucomm-promoter-driven-post-gateway', 'test' ], '.. profile list is correct';
    }

    note( "Testing Qc Run Deletion" );

    {
	ok my $qc_run = model->retrieve_qc_run( { id => '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8'  } )
	    , 'can retrieve single Qc Run';

	ok model->delete_qc_run( { id => '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8'  } ),
	    'can delete QC run';

	throws_ok {
	    model->retrieve_qc_run( { id => '687EE35E-9DBF-11E1-8EF3-9484F3CB94C8' } )
	} qr/No QcRun entity found matching/;
    }

    note ("Testing QC template and related run deletion");

    {
	    throws_ok {
		    model->delete_qc_template( { id => 200 } )
	    } qr/Template 200 has been used in one or more QC runs/;

	    ok model->delete_qc_template( { id => 200, delete_runs => 1 } ), 'can delete QC template and related runs';

	    throws_ok {
		    model->retrieve_qc_template( { id => 200 } )
	    } qr/No QcTemplate entity found/;

    }

    note ( "Testing creation of qc template plate from another plate");
    {

    	ok my $template_982 = model->create_qc_template_from_plate({ id => 982, template_name => 'template_982' }),
    	   'can create qc template from plate 982';
        ok my ($well) = $template_982->search_related('qc_template_wells',{ name => 'A01' }),
	       'can find well A01 on template';
	    my $params = decode_json($well->qc_eng_seq->params);
	    is_deeply $params->{recombinase}, ["flp"], 'qc template recombinase list is correct';
	    my ($template_display) = qc_template_display_data(model, $template_982, 'Mouse') ;
	    my ($well_data) = @{ $template_display };
	    is $well_data->{recombinase}, "flp", 'qc_template displays flp as existing recombinase';
	    is $well_data->{recombinase_new}, undef, 'qc_template displays no template specific recombinase';

    	ok my $template_982_cre = model->create_qc_template_from_plate({
    		id => 982,
    		template_name => 'template_982_cre',
    		recombinase => 'Cre'
    	}),
    	   'can create qc template from plate 982 with Cre';
        ok my ($well_cre) = $template_982_cre->search_related('qc_template_wells',{ name => 'A01' }),
	       'can find well A01 on template';
	    my $params_cre = decode_json($well_cre->qc_eng_seq->params);
	    is_deeply $params_cre->{recombinase}, ["flp","cre"], 'qc template recombinase list is correct';
	    my ($template_display_cre) = qc_template_display_data(model, $template_982_cre, 'Mouse');
	    my ($well_data_cre) = @{ $template_display_cre };
	    is $well_data_cre->{recombinase}, "flp", 'qc_template displays flp as existing recombinase';
	    is $well_data_cre->{recombinase_new}, "Cre", 'qc_template displays Cre template specific recombinase';

	    ok my $template = model->create_qc_template_from_plate({ id => 864, template_name => 'template_864' }),
	       'create_qc_template_from_plate should succeed';
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

