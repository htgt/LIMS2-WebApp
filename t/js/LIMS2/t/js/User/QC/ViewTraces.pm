package LIMS2::t::js::User::QC::ViewTraces;

BEGIN { 
	# Set the environment to use test sequencing data directory

    # compile time requirements
    #{REQUIRE_PARENT}
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use Test::More tests => 15;
use Selenium::Firefox;
use feature qw(say);
use Getopt::Long;
use Data::Dumper;
use LIMS2::Test model => { classname => __PACKAGE__ };
use LIMS2::TestJS qw( setup_user find_by scroll_window );

#Scripts
my $well = q{
    $('#well_name').val('A01');
    return;
};

my $version = q{
    document.getElementById('data_set').selectedIndex = 1;
    return;
};

my $check_version = q{
    return document.getElementById('data_set').value;
};

#Log in Selenium
my $driver = setup_user();

#Check login
is ($driver->get_title(), 'HTGT LIMS2', 'Home page');
$driver->maximize_window();

#Navigation
ok( view_traces($driver), "Navigate to view_traces" );

#Select Sequencing Project
ok( select_project($driver), "Select from table");
$driver->pause(10000);
$driver->execute_script($well);

ok( find_by($driver, 'id', 'get_reads'), "Fetch reads");

#Test TV
my $seq = check_traceviewer($driver, $scroll);
isnt ($seq,'','Check TV click');
isnt ($seq,'GGCTCGTA','Check TV loc');

#Window had to be scrolled down. Reset
scroll_window($driver, -400);

#Test backup selection
$driver->execute_script($version);
$driver->execute_script($well);

ok( find_by($driver, 'id', 'get_reads'), "Fetch reads");
$driver->pause(1500);

#Check selected traces version
my $check = $driver->execute_script($check_version);
is ($check, '2016-04-18 15:02:42', 'Check version');

#Test TV again
$seq = check_traceviewer($driver);

isnt ($seq,'','Check backup TV click');
isnt ($seq,'GGCTCGTA','Check backup TV loc');

#Close window
$driver->quit();

sub view_traces {
    my ($driver) = @_;

    find_by($driver, 'link_text', 'QC');
    find_by($driver, 'link_text', 'View Sequencing Traces');
    is ($driver->get_title(), 'View Sequencing Traces', 'View traces');

    return 1;
}

sub select_project {
    my ($driver) = @_;
    
    my $selection = q(
        $('.seqName')[2].click();
    );
    $driver->execute_script($selection);
    return 1;
}

sub check_traceviewer {
    my ($driver) = @_;

    my $seq_script = q{
        return tv.fwd_plot._read;
    }; 

    scroll_window($driver, 400);
    ok( find_by($driver, 'class', 'traces'), "Open traceviewer" );
    $driver->pause(5000);
    ok( find_by($driver, 'class', 'trace_sequence'), "Click on TV seq");

    my $seq = $driver->execute_script($seq_script);

    return $seq;
}
1;
