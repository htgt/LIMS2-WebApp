use Selenium::Firefox;
use Selenium::Remote::Driver;
use feature qw(say);
use Getopt::Long;
use Data::Dumper;
use JSON;

my $driver = @ARGV[0];
print Dumper $driver;
my $js = JSON->new;
$driver = $js->convert_blessed($driver);
#print Dumper $driver;

print Dumper $driver;
#print Dumper $driver->get_sessions();

say "Test - View Traces";
$DB::single=1;
say $driver->get_title();
my $url = $driver->get_current_url();
$driver->navigate( $url . '/view_traces');
say $driver->get_title();
