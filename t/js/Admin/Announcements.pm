package LIMS2::t::js::Admin::Announcements;

BEGIN { 
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use Test::More tests => 3;
use Selenium::Firefox;
use LIMS2::Test model => { classname => __PACKAGE__ }; #Required for fixtures
use LIMS2::TestJS qw( setup_user find_by );

#Scripts
my $alert = q{
    var container = arguments[0];
    var res = $('#' + container).find('.alertModal')[0].innerText;
    if (container == 'main') {
        res = res.slice(2);
    }
    return res;
};

my $announcement = q{
    $('#message_field').val("This was a triumph");
    $('#expiry_date').val("01/01/2099");
    $('input[name="priority"][value="normal"]').prop("checked",true)
    $('input[name="lims_checkbox"]')[0].click();
    return;
};

#Log in Selenium
my $driver = Selenium::Firefox->new();
setup_user($driver); 

#Tests
my $alert_res = $driver->execute_script($alert, 'main');
is($alert_res, 'Announcement 01/08/2016: Don\'t Panic', 'Home alert');
ok( find_by($driver, 'class','glyphicon-envelope') );
$driver->pause(1000);
$alert_res = $driver->execute_script($alert, 'announceModal');
is($alert_res, '01/08/2016: Don\'t Panic', 'Modal alert');
find_by($driver, 'class', 'close');

find_by($driver, 'link_text', 'test_user@example.org');
find_by($driver, 'link_text', 'Manage Announcements');
find_by($driver, 'class', 'btn-primary');
$driver->execute_script($announcement);
find_by($driver, 'id', 'create_announcement_button');

$DB::single=1;


#Remember to close your browser handle.
$driver->quit();

1;
