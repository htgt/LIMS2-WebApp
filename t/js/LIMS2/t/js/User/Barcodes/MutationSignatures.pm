package LIMS2::t::js::User::Barcodes::MutationSignatures;

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use Test::More tests => 39;
use Selenium::Firefox;
use LIMS2::Test model => { classname => __PACKAGE__ }; #Required for fixtures
use LIMS2::TestJS qw( setup_user find_by );
use feature qw(say);
use Data::Dumper;

#Log in Selenium
my $driver = setup_user(); 

#Navigate to Mutation Signs
ok (find_by($driver, 'link_text', "Barcodes"));
ok (find_by($driver, 'link_text', "Mutation Signatures Barcodes"));

#Tests - check rows

my %accordions = (
    frozen_back             => 'FR07732569',
    doubling_in_progress    => 'FR07737676',
    discarded               => 'FR07737656',
);

foreach my $state (keys %accordions) {
    ok( find_by($driver, 'link_text', 'Barcodes with state ' . $state . ':'), "Find " . $state . " accordion" );
    $driver->pause(500);
    ok( open_accordion($driver, $state, %accordions->{$state}, "panel-body collapse in"), "Open " . $state . " accordion" ); #if running in debug, change to 'panel-body collapse in' else 'panel-body collapsing'
}

my $closure = q{
    $('.panel-body').collapse('hide');
    return 1;
};
ok( $driver->execute_script($closure), "Close all accordions" );

my $query = q{
    $('#query').val('FR07737676');
    return 1;
};
ok( $driver->execute_script($query), "Add search term" );
ok( find_by($driver, 'class_name', 'btn-primary') ); #Test search button
$driver->pause(500);
iterate_accordions($driver, "panel-body collapse in", %accordions); #if running in debug, change to 'panel-body collapse in' else 'panel-body collapsing'
check_search_results($driver);

ok( find_by($driver, 'class_name', 'btn-default') ); #Test clear button
iterate_accordions($driver, "panel-body collapse", %accordions); 

#Remember to close your browser handle.
$driver->shutdown_binary;

sub iterate_accordions {
    my ($driver, $collapse_state, %accordions) = @_;
    foreach my $state (keys %accordions) {
        ok( open_accordion($driver, $state, %accordions->{$state}, $collapse_state), $state . ' - ' . $collapse_state );
    }

    return;
}

sub open_accordion {
    my ($driver, $state, $barcode, $status) = @_;
    
    my $accordion = q{
        var arg = arguments;
        return $('#' + arg[0])[0].className;
    };

    my $check_row = q{
        var arg = arguments[0];
        return $('#' + arg).find('.bc_id')[0].textContent;
    };

    my $res = $driver->execute_script($accordion, $state);
    is ($res, $status, $state . " accordion open");
    $res = $driver->execute_script($check_row, $state);
    is ($res, $barcode, $state . " - first row");
    
    return 1;
}

sub check_search_results {
    my ($driver) = @_;

    my %states = (
        frozen_back_id          => 'Results found: 0',
        doubling_in_progress_id => 'Results found: 1',
        discarded_id            => 'Results found: 0',
    );

    my $count = q{
        var state = arguments[0];
        var found = $('#' + state)[0].textContent;
        return found;
    };

    foreach my $state (keys %states) {
        my $res = $driver->execute_script($count, $state);
        is ($res, %states->{$state}, $state . " results found");
    }

    return;
}

1;
