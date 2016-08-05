package LIMS2::t::js::PublicReports::CloneGenotypingSearch;

BEGIN { 
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use Test::More tests => 1;
use Selenium::Firefox;
use feature qw(say);
use Data::Dumper;
use LIMS2::Test model => { classname => __PACKAGE__ };
use LIMS2::TestJS qw( setup_public find_by_link_text find_by_button_id cycle_windows close_additional_windows);
use Test::Mocha;

my $mocha = mock;

$DB::single=1;

#Log in Selenium
my $driver = Selenium::Firefox->new();
setup_public($driver);
$DB::single=1;
say $driver->get_title();

#Check All cache file
say my $url = $driver->get_current_url();
find_by_button_id($driver, "All");
say $driver->get_title();
$DB::single=1;

#Link opened in new tab
cycle_windows($driver);
close_additional_windows($driver);

#New window
say $driver->get_title();
find_by_button_id($driver,'expand');
$driver->click;

#Clone search
say "Test - Clone Genotyping Search";

find_by_link_text($driver, "Public Reports");
find_by_link_text($driver, "Clone Genotyping Search");

say $driver->get_title();

my $plate_well = q{
    $('#plate_well_name').val('HUFP0037_1_A_C01');
};
$driver->execute_script($plate_well);
find_by_button_id($driver, 'plate_well_search_button');

$mocha->done_testing();
$driver->quit();

1;