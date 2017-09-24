package LIMS2::t::WebApp::Controller::User::CrisprBrowseAndStore;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test model => { classname => __PACKAGE__ };
use strict;

my $mech = LIMS2::Test::mech();

sub all_tests : Tests {
    
    my $model = model();

    my $box_name = "test_box";
    my $user = 'test_user@example.org';

#    my $storage_instance = LIMS2::Model::Util::CrisprOrderAndStorage->new({ model => $model });
#    my $crispr_storage = $storage_instance->create_new_box($user, $box_name);

    $mech->get_ok('/user/crispr_browse_and_store', 'Able to fetch Crispr storage box URL');

    ok my $res = $mech->submit_form(
        form_id => 'create_box',
        fields => {
            box_name => $box_name
        },
        button => 'action'
    ), 'Able to create a Crispr storage box.';

    ok $mech->content_contains('A01', 'Able to view Crispr storage box.');

    ok $mech->submit_form(
        form_id => 'store_crispr',
        fields => {
            box_name => $box_name,
            tube_location_input => 'A01',
            crispr_input => '227040',
        },
        button => 'action',
    ), 'Able to store Crispr in box.';


    ok $mech->content_contains('" class="btn btn-danger tip-top" style="border-radius:100%;height:30px;width:30px;margin:5px;"><span id="A01"></span>', 'Crispr location is able to be reserved.');

    ok $mech->submit_form(
        form_id => 'reset_tube',
        fields => {
            box_name => $box_name,
            tube_reset_input => 'A01',
        },
        button => 'action',
    ), 'Able to reset tube location in box.';

    ok $mech->content_contains('title="Location: A01" class="btn btn-success', 'Crispr location is able to be reset.');

}

1;
