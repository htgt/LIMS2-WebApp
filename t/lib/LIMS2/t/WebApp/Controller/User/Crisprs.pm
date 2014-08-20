package LIMS2::t::WebApp::Controller::User::Crisprs;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::Crisprs;

use LIMS2::Test;

use strict;

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);
};

sub all_tests  : Test(5)
{
    # try to import some crisprs around Atad2 (targeted by design 84231)
    my $mech = mech();
    $mech->get_ok('/user/wge_crispr_group_importer');
    ok my $res = $mech->submit_form(
    	    fields => {
	            gene_id             => 'MGI:1917722',
	            gene_type_id        => 'MGI',
	            wge_crispr_id_left  => '388006081',
	            wge_crispr_id_right => '388006135',
            },
            button => 'import_crispr_group',
    	);
    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/wge_crispr_group_importer', 'we are still on importer page';
    $mech->content_contains('Successfully imported the following WGE ids: 388006081, 388006135');

=head
    $mech->get_ok('/user/design_target_gene_search');
    ok my $res = $mech->submit_form(

    	);
=cut
}

1;