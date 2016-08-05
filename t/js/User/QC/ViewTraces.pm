package LIMS2::t::js::User::QC::ViewTraces;

BEGIN { 
    push @INC, 'lib/'; 
	# Set the environment to use test sequencing data directory

    # compile time requirements
    #{REQUIRE_PARENT}
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use Test::More tests => 1;
use Test::Simple;
use Selenium::Firefox;
use Selenium::Remote::Driver;
use feature qw(say);
use Getopt::Long;
use Data::Dumper;
use LIMS2::Test model => { classname => __PACKAGE__ };
use LIMS2::TestJS qw( setup find_by_link_text );
use Test::WWW::Jasmine;
use WWW::Selenium;
use Test::Mocha;

my $mocha = mock;

$DB::single=1;

#Log in Selenium
my $driver = Selenium::Firefox->new();
setup($driver);

say $driver->get_title();
say "Test - View Traces";

#Navigation by navbar
called_ok {
    $mocha->test_mock()
} atleast(1);


#Navigation by url
my $url = $driver->get_current_url();
$driver->navigate( $url );
say $driver->get_title();

#Select Sequencing Project

#Close window
$mocha->done_testing();
$driver->quit();

sub test_mock {
    my ($driver) = @_;
    find_by_link_text($driver, 'QC');
    find_by_link_text($driver, 'View Sequencing Traces');
    say $driver->get_title();
    return 1;
}

1;
