package LIMS2::t::WebApp::Controller::User::CrisprLocateInStorage;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test model => { classname => __PACKAGE__ };

use strict;

my $mech = LIMS2::Test::mech();

sub all_tests : Tests {
    
    my $model = model();

    my $crispr_query = '187444,227040';

    $mech->get_ok('/user/crispr_locate_in_storage', 'Able to fetch Crispr locate in storage.');

    ok $mech->submit_form(
        form_id => 'find_crispr',
        fields => {
            crispr_input => $crispr_query,
        },
        button => 'locate_crispr',
    ), 'Able to submit form to locate Crisprs in storage.';

    ok $mech->content_contains('<td><input type="checkbox" id="selected_crispr" name="selected_crispr" value="227040,test_box,A02"></td>', 'Able to locate Crispr Ids.');

}

1;
