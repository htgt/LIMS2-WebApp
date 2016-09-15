package LIMS2::t::js::Admin::Announcements;

BEGIN { 
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use Test::More tests => 15;
use Selenium::Firefox;
use LIMS2::Test model => { classname => __PACKAGE__ }; #Required for fixtures
use LIMS2::TestJS qw( setup_user find_by );

#Scripts
my $alert = q/
    var container = arguments[0];
    var alert = arguments[1];
    var res = $('#' + container).find('.' + alert)[0].textContent.trim();
    if (container == 'main') {
        res = res.slice(8);
    }
    return res;
/;

my $announcement = q{
    $('#message_field').val("This was a triumph");
    $('#expiry_date').val("01/01/2099");
    $('input[name="priority"][value="normal"]').prop("checked",true)
    $('input[name="lims_checkbox"]')[0].click();
    return;
};

#Log in Selenium
my $driver = setup_user(); 

#Tests
my $alerts = {
    'alert-warning' =>  '01\/08\/2016:\s+Don\'t Panic',
};

alert_modal($driver, $alerts);
ok( find_by($driver, 'link_text', 'test_user@example.org'), 'User action menu' );
$driver->pause(500);

ok( find_by($driver, 'link_text', 'Manage Announcements'), "Announcement menu" );
$driver->pause(500);
ok( find_by($driver, 'class', 'btn-primary'), "Nav to creation");

$driver->execute_script($announcement);
ok( find_by($driver, 'id', 'create_announcement_button'), "Create announcement" );

ok( find_by($driver,'link_text','HTGT LIMS2'), "Return home" );
$driver->pause(1000);

my ($day, $month, $year) = (localtime)[3,4,5];
my $today = sprintf( "%02d", $day) . "\/" . sprintf( "%02d", ($month + 1) ) . "\/" . ( $year + 1900 ) . ':';
$alerts->{'alert-info'} = $today . '\s+This was a triumph';

alert_modal($driver, $alerts); 

#Remember to close your browser handle.
$driver->shutdown_binary;
$driver->pause(1000);

sub alert_modal {
    my ($driver, $alerts) = @_;

    check_alerts($driver, 'main', $alerts);
    ok( find_by($driver, 'class','glyphicon-envelope'), "Open modal" );
    
    $driver->pause(1000);

    check_alerts($driver, 'announceModal', $alerts);
    ok( find_by($driver, 'class', 'close'), "Close modal" );

    $driver->pause(1000);

    return;
}

sub check_alerts {
    my ($driver, $section, $alerts) = @_;
 
    my @keys = keys %{ $alerts };

    foreach my $key (@keys){
        my $alert_res = $driver->execute_script($alert, $section, $key);
        my $req = $alerts->{$key};
        my $test = $section . ' - ' . $key . ' alert';
        
        if ($section eq 'main') {
            $req = 'Announcement ' . $req;
        } 
        
        like($alert_res, qr/$req/, $test);
    }

    return;
}

1;
