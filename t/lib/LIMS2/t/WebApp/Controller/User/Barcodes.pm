package LIMS2::t::WebApp::Controller::User::Barcodes;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::Barcodes;
use LIMS2::Model::Util::BarcodeActions qw(checkout_well_barcode);

use LIMS2::Test model => { classname => __PACKAGE__ };
use File::Temp ':seekable';
use JSON;

use strict;

BEGIN
{
    # use Log::Log4perl qw( :easy );
    # Log::Log4perl->easy_init( $FATAL );
};


sub mutation_signatures_workflow_test : Test(16){
    my $mech = LIMS2::Test::mech();
    my $model = model();

    my $plate = "PIQ0002";
    my $barcode ="BC1234";

    note("Add a barcode to a PIQ well");

    ok my $well = $model->retrieve_well({ plate_name => $plate, well_name => "A01" }),
        "can retrieve well";
    ok my $well_barcode = $model->create_well_barcode({ well_id => $well->id, barcode => $barcode, state => 'in_freezer' }),
        "can add barcode to well";

    note("Checkout barcode");
    $mech->get_ok('/user/well_checkout');

    $mech->set_fields(
        barcode => $barcode,
    );
    $mech->click_button(name => 'submit_barcode');
    $mech->base_like(qr{/user/well_checkout});
    $mech->click_button(name => 'confirm_checkout');

    note("Start barcode doubling under normoxic conditions");
    $mech->get_ok('/user/scan_barcode');

    $mech->set_fields(
        barcode => $barcode,
    );
    $mech->click_button(name => 'submit_barcode');
    $mech->base_like(qr{/user/scan_barcode});
    $mech->follow_link(url_regex => qr/piq_start_doubling/);
    $mech->base_like(qr{/user/piq_start_doubling});
    $mech->set_fields(
        oxygen_condition => 'normoxic',
    );
    $mech->click_button(name => 'confirm_start_doubling');
    $mech->base_like(qr{/user/scan_barcode});
    $mech->set_fields(
        barcode => $barcode,
    );
    $mech->click_button(name => 'submit_barcode');
    $mech->base_like(qr{/user/scan_barcode});
    $mech->content_contains($barcode);
    $mech->content_contains('doubling_in_progress');

    #note("Create an MS_QC plate at 12 doublings");

    #note("Create an MS_QC plate at 24 doublings");

    note("Freeze back at 24 doublings");
    $mech->follow_link(url_regex => qr/freeze_back/);
    $mech->set_fields(
        number_of_doublings   => 24,
        qc_piq_plate_name_1   => 'PIQ_QC',
        qc_piq_well_name_1    => 'A01',
        qc_piq_well_barcode_1 => 'FRTEST1',
        number_of_wells_1     => 3,
        qc_piq_plate_name_2   => 'PIQ_QC',
        qc_piq_well_name_2    => 'A02',
        qc_piq_well_barcode_2 => 'FRTEST2',
        number_of_wells_2     => 3
    );
    $mech->click_button( name => 'create_piq_wells' );
    $mech->content_contains('QC PIQ well has been added to plate PIQ_QC');
    my ($form) = $mech->forms;
    my @inputs = grep { $_->type eq 'text' } $form->inputs;
    my %fields;
    foreach my $input (@inputs){
        my $bc = $input->name;
        $bc =~ s/barcode_/BC/;
        $fields{ $input->name } = $bc;
    }
    $mech->set_fields( %fields );
    $mech->click_button( name => 'submit_piq_barcodes' );
    $mech->content_contains('added to well');


    note("Use API to retrieve original barcode");
    $mech->get_ok('/public_api/mutation_signatures_info/FRTEST1');
    ok my $json = from_json($mech->content), "can parse JSON from mutation signatures API";
    my ($sibling) = @{ $json->{sibling_barcodes} || [] };
    is $sibling, 'FRTEST2', 'sibling barcode retrieved by mutation signatures API';

    note("Use API to retrieve child barcode");

}

sub all_tests  : Test(45) {
    my $mech = LIMS2::Test::mech();;
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    my $res;

    note("Create QC plate");

    $mech->get_ok('/user/create_qc_plate');
    $mech->title_is('Create Plate for QC');

    # no name: error
    $mech->set_fields(
            plate_type => 'CGAP_QC',
            wellbarcodesfile => $test_file->filename,
            plate_name => undef,
        );
    $mech->click_button(name => 'create_plate');
    $mech->base_like(qr{/user/create_qc_plate});
    $mech->content_contains('No plate name provided');

    # exsiting name: error
    $mech->set_fields(
            plate_type => 'CGAP_QC',
            wellbarcodesfile => $test_file->filename,
            plate_name => 'PIQ_CRE_0001',
        );
    $mech->click_button(name => 'create_plate');
    $mech->base_like(qr{/user/create_qc_plate});
    $mech->content_contains('already exists. Please use a different name');

    # no plate type: error
    $mech->set_fields(
            plate_name => 'CGAP_QC_TEST',
            wellbarcodesfile => $test_file->filename,
            plate_type => undef,
        );
    $mech->click_button(name => 'create_plate');
    $mech->base_like(qr{/user/create_qc_plate});
    $mech->content_contains('No plate type provided');

    # no file: error
    $mech->set_fields(
            plate_type => 'CGAP_QC',
            plate_name => 'CGAP_QC_TEST',
            wellbarcodesfile => undef,
        );
    $mech->click_button(name => 'create_plate');
    $mech->base_like(qr{/user/create_qc_plate});
    $mech->content_contains('You must select a barcode csv file to upload');


    # file contains unknown barcode
    $test_file->print("A01,mybarcode");
    $test_file->seek(0,0);

    $mech->set_fields(
            plate_name => 'CGAP_QC_TEST',
            plate_type => 'CGAP_QC',
            wellbarcodesfile => $test_file->filename,
        );
    $mech->click_button(name => 'create_plate');
    $mech->base_like(qr{/user/create_qc_plate});
    $mech->content_contains('Barcode mybarcode not found');

    my $plate = model->retrieve_plate({ name => 'PIQ_CRE_0001' });
    my ($well) = $plate->wells;

    # file contains barcode still in_freezer
    model->create_well_barcode({ well_id => $well->id, barcode => 'mybarcode', state => 'in_freezer' });

    $mech->set_fields(
            plate_name => 'CGAP_QC_TEST',
            plate_type => 'CGAP_QC',
            wellbarcodesfile => $test_file->filename,
        );
    $mech->click_button(name => 'create_plate');
    $mech->base_like(qr{/user/create_qc_plate});
    $mech->content_contains('Barcode mybarcode state: in_freezer');


    ok checkout_well_barcode(model,{ barcode => 'mybarcode', user => 'test_user@example.org' });

    # file has no header (works)
    $mech->set_fields(
            plate_name => 'CGAP_QC_TEST',
            plate_type => 'CGAP_QC',
            wellbarcodesfile => $test_file->filename,
        );
    $mech->click_button(name => 'create_plate');
    $mech->base_like(qr{/user/view_plate});

    # file has well,barcode header (works)
    $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,barcode\nA01,mybarcode");
    $test_file->seek(0,0);

    $mech->get_ok('/user/create_qc_plate');
    $mech->set_fields(
            plate_name => 'CGAP_QC_TEST_2',
            plate_type => 'CGAP_QC',
            wellbarcodesfile => $test_file->filename,
        );
    $mech->click_button(name => 'create_plate');
    $mech->base_like(qr{/user/view_plate});

    # new plate has correct type (CGAP_QC)
    ok my $new_plate = model->retrieve_plate({ name => 'CGAP_QC_TEST_2' }), 'can find new qc plate';
    is $new_plate->type_id, 'CGAP_QC','has correct plate type';

    # well on new plate has correct parent process (cgap_qc)
    ok my $new_well = model->retrieve_well({ plate_name => 'CGAP_QC_TEST_2', well_name => 'A01' }), 'can find well A01';
    ok my ($process) = $new_well->parent_processes, 'can find well input process';
    is $process->type_id, 'cgap_qc','process has correct type';

    # well on new plate has no barcode
    is $new_well->barcode, undef, 'new well has no barcode';

    # well on new plate has correct parent well
    ok my ($parent_well) = $new_well->parent_wells, 'can find parent well';
    is $parent_well->barcode, 'mybarcode','parent well has correct barcode';

    # test double targeted plates '''SFP'''
    $mech->get_ok('/user/scan_barcode');

    ok $res = $mech->submit_form(
        fields => {
            barcode => 1127078153
        },
        button => 'submit_barcode',
    );
    ok $res->is_success, '...response is success';
    $mech->content_contains('Well details for barcode 1127078153');
    $mech->content_contains('HUFP0130_2_B');
    $mech->content_contains('HGNC:12630');
    $mech->content_contains('USP7');
    $mech->content_contains('1016222');

    $mech->get_ok('/user/scan_barcode');
    ok $res = $mech->submit_form(
        fields => {
            barcode => 1128143241
        },
        button => 'submit_barcode',
    );
    ok $res->is_success, '...response is success';
    $mech->content_contains('Well details for barcode 1128143241');
    $mech->content_contains('HUSFP0001_1_A');
    $mech->content_contains('HGNC:11998');
    $mech->content_contains('TP53');
    $mech->content_contains('3181');
    $mech->content_contains('10000553');
    $mech->content_contains('HGNC:25356');
    $mech->content_contains('SPRTN');



}

1;

