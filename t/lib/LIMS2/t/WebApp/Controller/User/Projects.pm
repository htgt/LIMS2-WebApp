package LIMS2::t::WebApp::Controller::User::Projects;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test model => { classname => __PACKAGE__ };

use strict;

## no critic

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($FATAL);
}

my $mech = LIMS2::Test::mech();

sub manage_projects_tests : Test(21) {
    $mech->get_ok('/user/select_species?species=Mouse');

    $mech->get_ok('/user/manage_projects');
    $mech->content_lacks('Project ID');

    # Test project search options
    $mech->click_button( name => 'search_projects' );
    $mech->content_contains('MGI:1914632');
    $mech->content_contains('Brd3');
    $mech->content_contains('MGI:109393');
    $mech->content_contains('Slc4a1');

    $mech->set_fields(
    	gene => 'MGI:1914632',
    	targeting_type => '',
    	sponsor => '',
    );
    $mech->click_button( name => 'search_projects' );
    $mech->content_contains('MGI:1914632');
    $mech->content_contains('Brd3');
    $mech->content_lacks('MGI:109393');
    $mech->content_lacks('Slc4a1');

    $mech->set_fields(
    	gene => '',
    	targeting_type => '',
    	sponsor => 'Core',
    );
    $mech->click_button( name => 'search_projects' );
    $mech->content_contains('No projects found');

    $mech->set_fields(
    	gene => '',
    	targeting_type => 'single_targeted',
    	sponsor => '',
    );
    $mech->click_button( name => 'search_projects' );
    $mech->content_contains('No projects found');

    # Test project create options
    my $new_gene = 'MGI:107374';
    $mech->set_fields(
        gene => $new_gene,
        targeting_type => '',
        sponsor => 'Core'
    );
    $mech->click_button( name => 'create_project');
    $mech->content_contains('targeting_type, is missing');

    $mech->set_fields(
        gene => $new_gene,
        targeting_type => 'single_targeted',
        sponsor => 'Core'
    );
    $mech->click_button( name => 'create_project');
    $mech->content_contains('New project created');
    $mech->title_is('View Project');

    $mech->get_ok('/user/manage_projects');
    $mech->set_fields(
        gene => $new_gene,
        targeting_type => 'single_targeted',
    );
    $mech->click_button( name => 'create_project' );
    $mech->content_contains('Project already exists (see list below)');
    $mech->content_contains('Pitx1');

    $mech->set_fields(
        gene => $new_gene,
        targeting_type => 'double_targeted',
    );
    $mech->click_button( name => 'create_project' );
    $mech->content_contains('New project created');
    $mech->title_is('View Project');

}

sub view_edit_project_tests : Test(17){
    $mech->get_ok('/user/select_species?species=Mouse');

    $mech->get_ok('/user/view_project?project_id=12');
    $mech->content_contains('MGI:109393');
    $mech->content_contains('Slc4a1');

    # Test update sponsors
    is_deeply(_selected_sponsors($mech), [ 'Syboss' ], 'correct sponsors selected');

    $mech->tick('sponsors','Core');
    $mech->click_button( name => 'update_sponsors' );
    $mech->content_contains('Project sponsor list updated');
    $mech->content_contains('Core/Syboss');
    $mech->content_lacks('All/Core/Syboss','Sponsor All not added for mouse');
    is_deeply(_selected_sponsors($mech), [ 'Core', 'Syboss' ], 'correct sponsors selected');

    $mech->untick('sponsors','Syboss');
    $mech->click_button( name => 'update_sponsors' );
    $mech->content_contains('Project sponsor list updated');
    is_deeply(_selected_sponsors($mech), [ 'Core' ], 'correct sponsors selected');

    # Test add experiment
    $mech->form_name('add_experiment_form');
    $mech->set_fields(
        crispr_id => 12345,
    );
    $mech->click_button( name => 'add_experiment');
    $mech->content_contains('crispr_id, is invalid');

    $mech->form_name('add_experiment_form');
    $mech->set_fields(
        crispr_id => 69848,
    );
    $mech->click_button( name => 'add_experiment');
    $mech->content_contains('Experiment created');

    $mech->form_name('add_experiment_form');
    $mech->set_fields(
        crispr_id => 69848,
        design_id => 1002582,
    );
    $mech->click_button( name => 'add_experiment');
    $mech->content_contains('Experiment created');

    # Test delete experiment
    my @delete_forms = grep { $_->attr('name') eq 'delete_experiment_form' } $mech->forms;
    is (scalar @delete_forms, 2, '2 experiments listed');

    $mech->form_number(2);
    $mech->click_button( name => 'delete_experiment');
    $mech->content_contains('Deleted experiment');

    @delete_forms = grep { $_->attr('name') eq 'delete_experiment_form' } $mech->forms;
    is (scalar @delete_forms, 1, '1 experiment listed');

}

sub edit_human_sponsor_list : Test(10){
    $mech->get_ok('/user/select_species?species=Human');

    $mech->get_ok('/user/view_project?project_id=13');
    $mech->content_contains('HGNC:19417');
    $mech->content_contains('ZNF404');

    $mech->tick('sponsors','Pathogen');
    $mech->click_button( name => 'update_sponsors' );
    $mech->content_contains('Project sponsor list updated');
    $mech->content_contains('All/Pathogen', 'Sponsor All has been automatically added');
    is_deeply(_selected_sponsors($mech), [ 'Pathogen' ], 'correct sponsors selected');

    $mech->untick('sponsors','Pathogen');
    $mech->tick('sponsors','Transfacs');
    $mech->click_button( name => 'update_sponsors' );
    $mech->content_contains('Project sponsor list updated');
    $mech->content_lacks('All/Transfacs', 'Sponsor All has not been automatically added for Transfacs project');
    is_deeply(_selected_sponsors($mech), [ 'Transfacs' ], 'correct sponsors selected');

}

sub _selected_sponsors{
	my ($mech) = @_;

	my $sponsor_form = $mech->form_name('update_sponsors_form');
    my @all = $sponsor_form->find_input('sponsors','checkbox');
    my @selected = map { $_->value } grep { $_->{current} } @all;
    return [ sort @selected ];
}
1;
