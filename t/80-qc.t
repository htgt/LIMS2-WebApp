#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use JSON qw( encode_json decode_json );
use HTTP::Request::Common;
use HTTP::Status qw( :constants );

my $mech = mech();

note "Testing creation of QC template from plate";

{
	my $template = 'test_template';
	my $source = 'MOHFAS0001_A';
	
	$mech->get_ok('/user/create_template_plate');
 
    ok $mech->submit_form(
        form_id => 'create_template_plate',
        fields  => {
        	template_plate   => $template,
        },
        button  => 'create_from_plate'
    ), 'submit create template from plate with no plate';
    ok $mech->success, 'response is success';
    $mech->content_like( qr/You must provide a source plate/, 'source plate name must be provided');

    $mech->back;
    ok $mech->submit_form(
        form_id => 'create_template_plate',
        fields  => {
            source_plate   => $source,            
        },
        button  => 'create_from_plate'
    ), 'submit create template from plate with no template';
    ok $mech->success, 'response is success';
    $mech->content_like( qr/You must provide a name for the template plate/, 'template plate name must be provided');

    $mech->back;               
    ok $mech->submit_form(
        form_id => 'create_template_plate',
        fields  => {
            template_plate => $template,
            source_plate   => $source,
        },
        button  => 'create_from_plate'
    ), 'create template from plate';
    ok $mech->success, 'response is success';
    $mech->content_like( qr/Template .*$template.* was successfully created/, 'template created successfully');
    
    ok my $res = model->retrieve_qc_templates( { name => $template } ), 'retrieved qc template';
    is @{$res}, 1, 'one qc template found';
    is (scalar $res->[0]->qc_template_wells, 96, '96 qc_template_wells found for template');
}

note "Testing creation of QC template from CSV upload";

{
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,source_plate,source_well\n"
                      . "A01,MOHFAS0001_A,B01\n"
                      . "A02,MOHFAS0001_A,B02");
    $test_file->seek( 0, 0 );

    $mech->back;
    my $template = 'test_template_csv';
    ok $mech->submit_form(
        form_id => 'create_template_plate',
        fields  => {
            template_plate => $template,
        },
        button  => 'create_from_csv'
    ), 'create template from csv upload with no file';
    ok $mech->success, 'response is success';
    $mech->content_like( qr/You must select a csv file containing the well list/, 'csv file must be provided');
    
    $mech->back;
    ok $mech->submit_form(
        form_id => 'create_template_plate',
        fields  => {
            template_plate => $template,
            datafile       => $test_file->filename
        },
        button  => 'create_from_csv'
    ), 'create template from csv upload';
    ok $mech->success, 'response is success';
    $mech->content_like( qr/Template .*$template.* was successfully created/, 'template created successfully');
    
    ok my $res = model->retrieve_qc_templates( { name => $template } ), 'retrieved qc template';
    is @{$res}, 1, 'one qc template found';
    is (scalar $res->[0]->qc_template_wells, 2, '2 qc_template_wells found for template');
    my $created_id = $res->[0]->id;

    $mech->back;
    ok $mech->submit_form(
        form_id => 'create_template_plate',
        fields  => {
            template_plate => $template,
            datafile       => $test_file->filename
        },
        button  => 'create_from_csv'
    ), 'create template from csv upload with existing name';
    ok $mech->success, 'response is success';
    $mech->content_like( qr/QC template $template already exists/, 'cannot use existing template name');

    # Attempt to view newly created template plate
    $mech->get_ok('/user/browse_templates', 'can browse templates');
    $mech->content_contains($template, 'new template seen in browse templates');
    $mech->get_ok('/user/view_template?id='.$created_id);
    $mech->title_is('View Template');
    $mech->content_contains($template, 'new template can be viewed');
    $mech->content_contains('MOHFAS0001_A', 'new template refers to correct source plate');
    
    my @gbk_links = $mech->find_all_links( url_regex => qr/genbank_well_id/ );
    $mech->link_content_like(\@gbk_links, qr/LOCUS/, 'genbank file download links work');
    
    # Delete the new template
    $mech->get_ok('/user/delete_template?id='.$created_id, 'can delete template');
    $mech->title_is('Browse Templates', 'delete redirects to browse templates');
    $mech->content_lacks($template, 'new template is no longer listed');
     
}

note "Testing creation of QC template with overrides";
{
	my $template = "test_overrides";
	my $source = 'MOHFAS0001_A';
	my $cassette = 'L1L2_st1';
	my $backbone = 'PL611';
	my $recom = 'Dre';
	
	$mech->get_ok('/user/create_template_plate');
	
    ok $mech->submit_form(
        form_id => 'create_template_plate',
        fields  => {
        	template_plate   => $template,
        	source_plate     => $source,
        	cassette         => $cassette,
        	backbone         => $backbone,
        	recombinase      => $recom,
        },
        button  => 'create_from_plate'
    ), 'submit create template from plate with overrides';
    ok $mech->success, 'response is success';
    
    ok $mech->follow_link( url_regex => qr/view_template/), 'can view new qc template';
    $mech->content_like(qr/$cassette/,'cassette override value used in new template');
    $mech->content_like(qr/$backbone/,'backbone override value used in new template');
    $mech->content_like(qr/$recom/i,'recombinase override value used in new template');
    
    $template = "test_overrides_csv";

    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,source_plate,source_well,cassette,backbone,recombinase\n"
                      . "A01,MOHFAS0001_A,B01,$cassette,$backbone,$recom\n"
                      . "A02,MOHFAS0001_A,B02,$cassette,$backbone,$recom");
    $test_file->seek( 0, 0 );
    
    $mech->get_ok('/user/create_template_plate');
    ok $mech->submit_form(
        form_id => 'create_template_plate',
        fields  => {
        	template_plate => $template,
        	datafile       => $test_file->filename
        },
        button  => 'create_from_csv'
    ), 'submit create template from csv with overrides';
    ok $mech->success, 'response is success';
    
    ok $mech->follow_link( url_regex => qr/view_template/), 'can view new qc template';
    $mech->content_like(qr/$cassette/,'cassette override value used in new template');
    $mech->content_like(qr/$backbone/,'backbone override value used in new template');
    $mech->content_like(qr/$recom/i,'recombinase override value used in new template');        
   
}

note "Testing creation of plates from QC run";
{
	my $qc_run_id = '534EE22E-3DBF-22E4-5EF2-1234F5CB64C7';
	$mech->get_ok('/user/view_qc_run?qc_run_id='.$qc_run_id);
	ok $mech->follow_link( url_regex => qr/create_plates/i ), 'can view create plate page';
	my @name_inputs = $mech->find_all_inputs( type => 'text', name_regex => qr/rename_plate/ );
	is scalar @name_inputs, 1, '1 plate rename input found';
    print "Input name: ", $name_inputs[0]->name, "\n";
    
    ok $mech->submit_form(
        form_id => 'create_plates',
        fields  => {
        	$name_inputs[0]->name => $name_inputs[0]->value,
        	process_type => '2w_gateway',
        	plate_type   => 'FINAL',
        },
        button => 'create',
    ), 'submit plate creation form with wrong process';
    $mech->content_like(qr/2w_gateway process can have either a cassette or backbone, not both/, 'incorrect process type error reported');
      
    ok $mech->submit_form(
        form_id => 'create_plates',
        fields  => {
        	$name_inputs[0]->name => $name_inputs[0]->value,
        	process_type => '3w_gateway',
        	plate_type   => 'FINAL',
        },
        button => 'create',
    ), 'submit plate creation form';
    
    $mech->content_like(qr/The following plates where created/,'new plate created');
    $mech->title_is('Browse Plates', 'plate creation redirects to browse plates');
    ok $mech->follow_link( text => $name_inputs[0]->value ), 'can view new plate';
    ok $mech->follow_link( text => 'Well Details'), 'can view well details';
    $mech->text_contains('B02', 'well B02 created');
    $mech->text_contains('G12', 'well G12 created');    
}

note "Testing creation and retrieval of QC template";

my $template;

{
    my $template_data = test_data( 'qc_template.yaml' );
    my $template_name = $template_data->{name};

    ok my $res = $mech->request( POST '/api/qc_template', 'Content-Type' => 'application/json', Content => encode_json( $template_data ) ), "POST qc_template $template_name";
    ok $res->is_success, '...request should succeed';
    is $res->code, HTTP_CREATED, '...status is created';

    lives_ok {
        $template = decode_json( $res->content )
    } '...decoding JSON lives';

    like $res->header('location') || '', qr(\Q/api/qc_template?id=$template->{id}\E$), '...location header is correct';
}

note "Testing creation and retrieval of QC run";

my $run_data = test_data( 'qc_run.yaml' );
$run_data->{qc_template_name} = $template->{name};
my $test_results = delete $run_data->{test_results};

{
    ok my $res = $mech->request( POST '/api/qc_run', 'Content-Type' => 'application/json', Content => encode_json( $run_data ) ), "POST qc_run $run_data->{id}";
    ok $res->is_success, '...request should succeed';
    is $res->code, HTTP_CREATED, '..status is created';
    like $res->header('location'), qr(\Q/api/qc_run?id=$run_data->{id}\E$), '...location header is correct';
}

note "Testing creation and retrieval of QC sequencing reads";

{
    my @seq_reads_data = test_data( 'qc_seq_reads.yaml' );

    for my $s ( @seq_reads_data ) {
        ok my $res = $mech->request( POST '/api/qc_seq_read', 'Content-Type' => 'application/json', Content => encode_json( $s ) ), "POST qc_seq_read $s->{id}";
        ok $res->is_success, '...request should succeed';
        is $res->code, HTTP_CREATED, '...status is "created"';
        like $res->header('location'), qr(\Q/api/qc_seq_read?id=$s->{id}\E$), '...location header is correct';
    }
}

# XXX Retrieve QC run not yet implemented
# {
#     my $url = "/api/qc_run?id=$run_data->{id}";
#     ok my $res = $mech->request( GET $url, 'Content-Type' => 'application/json' ), "GET $url";
#     ok $res->is_success, '...request should succeed';
#     is $res->code, HTTP_OK, '...status is ok';
#     my $run;
#     lives_ok {
#         $run = decode_json( $res->content );
#     } '...decoding JSON lives';
#     is $run->{id}, $run_data->{id}, '...run id is correct';
# }

note "Testing creation and retrieval of test results";

for my $test_result ( @{ $test_results } ) {
    # Make sure the eng_seq_id exists in the database
    my $eng_seq_id = model->schema->resultset( 'QcEngSeq' )->search( {}, { order_by => \'RANDOM()', limit => 1 } )->first->id;
    $test_result->{qc_eng_seq_id} = $eng_seq_id;
    for my $alignment ( @{ $test_result->{alignments} } ) {
        $alignment->{qc_eng_seq_id} = $eng_seq_id;
    }
    $test_result->{qc_run_id} = $run_data->{id};
    my $test_result_id;
    {
        ok my $res = $mech->request( POST '/api/qc_test_result', 'Content-Type' => 'application/json', Content => encode_json( $test_result ) ), 'POST /api/qc_test_result';
        ok $res->is_success, '...request should succeed';
        is $res->code, HTTP_CREATED, '...status is created';
        like $res->header('location'), qr(\Q/api/qc_test_result?id=\E\d+$), '...location header is correct';
        ( $test_result_id ) = $res->header('location') =~ m/(\d+)$/;
    }
    {
        my $url = "/api/qc_test_result?id=$test_result_id";
        ok my $res = $mech->request( GET $url, 'Content-Type' => 'application/json' ), "GET $url";
        ok $res->is_success, '...request should succeed';
        is $res->code, HTTP_OK, '...status is ok';
        my $entity;
        lives_ok {
            $entity = decode_json( $res->content );
        } '...decoding JSON lives';
        is $entity->{id}, $test_result_id, '...it has the expected id';
    }
}

done_testing();
