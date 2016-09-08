package LIMS2::t::js::PublicReports::Reports;

BEGIN { 
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}


use Selenium::Firefox;
use feature qw(say);
use Data::Dumper;
use LIMS2::Test model => { classname => __PACKAGE__ };
use LIMS2::TestJS qw( setup_public setup_user find_by cycle_windows close_additional_windows);
use Test::More tests => 42;


#Log in Selenium
my $driver = setup_public();

#Check All cache file

my @pages = ('All', 'Experimental Cancer Genetics', 'Human Genetics', 'Mutation', 'Pathogen', 'Stem Cell Engineering', 'Transfacs');

foreach my $page (@pages) {
    check_cache($driver, $page);
}

$driver->shutdown_binary;

sub check_cache {
    my ($driver, $page) = @_;

    say $page;
    ok (find_by($driver, 'id', $page));
    say $driver->get_title();


    #Link opened in new tab

    ok (cycle_windows($driver));
    close_additional_windows($driver);


    #New window
    say $driver->get_title();
    ok (find_by($driver,'id', 'expand'));
    my $status = check_expansion($driver);
    is ($status, 'none', 'Collapsed rows');
    $driver->click;
    $status = check_expansion($driver);
    is ($status, '', 'Expanded rows');

    #Clone search
    say "Test - Clone Genotyping Search";

    ok (find_by($driver, 'link_text', "HTGT LIMS2"));
}

sub check_expansion {
    my ($driver) = @_;

    $display = q(
        return $('.gene_row')[0].style.display;
    );

    return $value = $driver->execute_script($display);
}
1;
