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
    Log::Log4perl->easy_init($OFF);
};

sub all_tests  : Test(21)
{
    # try to import some crisprs around Atad2 (targeted by design 84231)
    my $design_id = 84231;
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
    my @links = $mech->find_all_links(url_regex => qr{/user/crispr/\d*});
    is scalar @links, 2, 'found 2 crispr links after import';
    $mech->links_ok(\@links, 'can follow crispr links from import page');
    my ($group_id) = ($mech->content =~ /Crispr Group (\d*) Imported/);

    # load design target
    # Check new group is found for target
    my $target_data = test_data('create_design_targets_atad2.yaml');
    lives_ok { model->c_create_design_target( $target_data->{valid_design_target} ) } 'design target loaded';

    $mech->get_ok('/user/design_target_gene_search');
    ok $res = $mech->submit_form(
            fields => {
                genes        => 'MGI:1917722',
                crispr_types => 'group',
                off_target_algorithm => 'exhaustive',
            },
            button => 'action',
        );
    ok $res->is_success, 'gene target groups search is_success';
    $mech->content_contains('ENSMUSE00000125819');
    $mech->content_contains('WGE: 388006081');
    $mech->content_contains('WGE: 388006135');
    my @group_links = $mech->find_all_links(url_regex => qr{/user/crispr_group/\d*/view});
    my @crispr_links = $mech->find_all_links(url_regex => qr{/user/crispr/\d*});
    is scalar @group_links, 1, '1 crispr group link found on target page';
    is scalar @crispr_links, 2, '2 crispr links found on target page';
    $mech->links_ok(\@group_links,'can follow crispr group links');
    $mech->links_ok(\@crispr_links,'can follow crispr links');

    # attempt to link the crispr group to a design
    #(design doesn't actually show up in the form as it is wrong type and incompletely described in fixtures)
    ok $res = $mech->submit_form(
        fields => {
            crispr_group_pick => "$group_id:$design_id",
        },
        button => 'action'
        );
    ok $res->is_success, 'submitted request to link crispr group to design';
    $mech->content_contains('no crispr in the group lies wholly within target region of design');

}

1;
