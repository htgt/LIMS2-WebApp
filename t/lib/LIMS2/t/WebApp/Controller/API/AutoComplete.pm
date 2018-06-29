package LIMS2::t::WebApp::Controller::API::AutoComplete;
use base qw(Test::Class);
use JSON;
use Test::Most;
use LIMS2::WebApp::Controller::API::AutoComplete;
use LIMS2::Test model => { classname => __PACKAGE__ };
use strict;

sub all_tests : Test(7)
{
    my $mech = LIMS2::Test::mech();
    $mech->get_ok('/select_species?species=Human');
    note('Single type');
    {
        $mech->get_ok('/api/autocomplete/plate_names?term=Miseq&type=FP',
            { 'content-type' => 'application/json' }
        );
        ok my @names = @{ decode_json($mech->content) };
        is_deeply( [sort @names], ['Miseq_004_FP'] );
    }
    note('Multiple types');
    {
        $mech->get_ok('/api/autocomplete/plate_names?term=Miseq&type=FP,MISEQ,PIQ',
            { 'content-type' => 'application/json' }
        );
        ok my @names = sort @{ decode_json($mech->content) };
        is_deeply( \@names, [qw/Miseq_004 Miseq_004_FP/] );
    }
}

1;

