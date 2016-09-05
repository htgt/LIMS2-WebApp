#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.
my $pid = fork();
if ($pid == 0) {
    use Cwd;
    my $cwd = cwd();
    my $c = () = $cwd =~ /\//g;
    if ($c eq '9') {
        system qw{xterm -hold -e ../../../bin/lims2_launch_test_app.sh 1};
    } else {
        system qw{xterm -hold -e ../../bin/lims2_launch_test_app.sh 0};
    }
}
system('find ./t -name "*.t" | sort -f > t/test_manifest' );                               
eval 'use Test::Manifest';       # The new LIMS2 testing layout uses recursive test files
                                 # so we keep the actual list of files to test
                                 # in order, in t/test_manifest
name 'LIMS2-WebApp';
all_from 'lib/LIMS2/WebApp.pm';

requires 'Catalyst::Runtime' => '5.90006';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
install_script 'script/run_in_perlbrew';
auto_install;
WriteAll;
