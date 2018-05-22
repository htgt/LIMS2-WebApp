package LIMS2::t::WebApp::Controller::User::CreateMiseqDesign;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::CreateDesign;

use LIMS2::Test model => { classname => __PACKAGE__ };
use File::Temp ':seekable';

use strict;

## no critic

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
};

my $mech = LIMS2::Test::mech();

sub all_tests  : Test(6)
{
$DB::single=1;
    {        
	note( "Miseq default design pass" );
	$mech->get_ok( '/user/create_miseq_design' );
	$mech->title_is('Miseq Design Creation');
	ok my $res = $mech->submit_form(
	    form_id => 'crisprSearch',
	    fields  => {
	        presetSelection => 'Default',
            clearTextArea   => '187845',
        },
	    button  => 'action'
	), 'Submit form with successful crispr design';

    ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_miseq_design', '... stays on same page';
$DB::single=1;
    like $res->content, qr/No csv file containing design plate data uploaded/, '...throws error saying no csv file specified';
    }

}

## use critic

1;

__END__


