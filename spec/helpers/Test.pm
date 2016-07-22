use Test::More tests => 5;
use Test::WWW::Jasmine;
use WWW::Selenium; 
$DB::single=1;
my $sel = WWW::Selenium->new( host => "t87-dev.internal.sanger.ac.uk",
                                    port => 3232,
                                    browser => "*firefox",
                                    browser_url => "http://t87-dev.internal.sanger.ac.uk:3232/",
                                    default_names => 1,
                                    error_callback => sub { print $_; },
                                  );

my $jasmine = Test::WWW::Jasmine->new(
    spec_file   => 'spec/tests/Test.js',
    jasmine_url => 'node_modules/jasmine/bin/jasmine.js',
    browser_url => 'http://t87-dev.internal.sanger.ac.uk:3232/',
    html_dir    => 'spec/test_runner.html',
    selenium    => $sel,
);
 
$jasmine->run();
