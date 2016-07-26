#!/usr/bin/env perl

use Selenium::Firefox;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;
#use Test::More tests => 5;
#use Test::WWW::Jasmine;
#use WWW::Selenium;
$DB::single=1;

GetOptions(
    'help'      => sub { pod2usage( -verbose => 1 ) },
    'man'       => sub { pod2usage( -verbose => 2 ) },
    'log_out'   => \my $logged_out,
);

my @arg = @ARGV;

#Open local webapp
my $driver = Selenium::Firefox->new;
$driver->get('t87-dev.internal.sanger.ac.uk:3232');
say $driver->get_title();

unless ($logged_out) {
    my $elem = $driver->find_element_by_class('navbar-btn');
    $driver->mouse_move_to_location(element => $elem);
    $driver->click;
    say $driver->get_title();
    my $login = q{
        $('#username_field').val('test_user@example.org');
        $('#password_field').val('ahdooS1e');
        return;
    };
    $driver->execute_script($login);
    $elem = $driver->find_element_by_id('login_button');
    $driver->mouse_move_to_location(element => $elem);
    $driver->click;
    say $driver->get_title();
}
#Run page

#my $jasmine = Test::WWW::Jasmine->new(
#    spec_file   => 'spec/tests/Test.js',
#    jasmine_url => 'node_modules/jasmine/bin/jasmine.js',
#    browser_url => 'http://t87-dev.internal.sanger.ac.uk:3232/',
#    html_dir    => '../Testing/www/',
#    selenium    => $driver,
#);
#$jasmine->run();

$driver->quit();

=head1 NAME

lims2_js_test - Launch the Javascript testing suite for LIMS2

=head1 SYNOPSIS

  lims2_js_test [options] /path/to/test_file.pm (optional)

      --help        Display a brief help message
      --man         Display the manual page
      --log_out     Run tests on the front page

=head1 DESCRIPTION

Run all the  javascript relationed tests for LIMS2.

Use --log_out flag to run tests on the public reports.

If you desire to only test a single file, add the path to the test file following any options

=head1 AUTHOR

Peter Keen
