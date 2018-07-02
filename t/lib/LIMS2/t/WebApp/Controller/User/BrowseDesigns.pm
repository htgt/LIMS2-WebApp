package LIMS2::t::WebApp::Controller::User::BrowseDesigns;
use warnings;
use strict;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::BrowseDesigns;
use LIMS2::Test model => { classname => __PACKAGE__ };

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/BrowseDesigns.pm - test class for LIMS2::WebApp::Controller::User::BrowseDesigns

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
    #{REQUIRE_PARENT}
};

sub all_tests  : Tests
{  

my %design_id = (
    correct=>{
	id => '10000841', 
	content => 'Genotyping Primers'
    }, 
    invalidid1=>{id => '201994', content => 'Design 201994 not found'}, 
    invalidid2=>{id => '10293840', content => 'Design 10293840 not found'},

    invalidid3=>{id => '102 9&gf5', content => 'Please enter a valid design id'} 
    
);


while (my ($s, $v) = each %design_id) {

use Data::Dumper;
print Dumper($design_id{$s}); 
    my $mech = LIMS2::Test::mech();
    ok(1, "Test of LIMS2::WebApp::Controller::User::BrowseDesigns");
    $mech->get_ok('select_species?species=Mouse');
    $mech->get_ok('/user/browse_designs');
    $mech->title_is('Browse Designs');
    ok my $res = $mech->submit_form(
	form_id =>'searchDesign', 
	fields => {
	    design_id => $design_id{$s}->{id}
	},
	button => 'action'
    ),'Submit Design Id with correct id';
    ok $res->is_success,'Response is success';
    $mech->content_contains($design_id{$s}->{content}); 

}
}

=head1 AUTHOR


=cut

## use critic

1;

__END__

