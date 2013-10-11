#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

#use Config::General;
use Getopt::Long;
use Pod::Usage;
use Readonly;
use Text::CSV;
use Data::Dumper;
use LIMS2::Model::DBConnect;
use LIMS2::Test qw(load_static_files load_dynamic_files load_files);

# A utility to simplify generating static fixture data by copying table entries from a "production" type database
# Lars G. Erlandsen, 'Viking'
# Sep 12 2013

=head1 NAME

lims2_load_fixtures.pl - LIMS2 utility to load static fixture files into a database from a set of files

=head1 SYNOPSIS

lims2_load_fixtures.pl [-switch] [ [-switch] .. ]

=head2 Switches

=over 4

=item --man

Generate a formatted pod page showing this message.

=item --help

Help page. You are looking at it.

=item --source

The source path on the server where the fixture files are read from. It defaults to '/static/test/fixtures'.

=item --type

Choose one of the (built-in) fixture sets to use: 'static' or 'dynamic'

=item --clear

Clear down the dynamic tables prior to loading new data

=back


=head1 DESCRIPTION

An (hopefully) easy-to-use utility to load data from a set of csv fixture files into tables in the database.

The script will use the ".yaml" connection profiles configuration file to find connection details,
and expects the environment variable B<LIMS2_DBCONNECT_CONFIG> to point to it.

The script will use the database specified in the B<$LIMS2_DB> environment variable.

=head1 EXAMPLES

To run the static data cleardown script in '/static/test/fixtures/00-clean-db.sql', run the command:

lims2_load_fixtures.pl \
    --source '/static/test/fixtures/00-clean-db.sql'

To load the static reference data in the directory '/static/test/fixtures/reference_data', run the command:

lims2_load_fixtures.pl \
    --type static \
    --source '/static/test/fixtures/reference_data'

=head1 AUTHOR

Lars G. Erlandsen

=cut

my ($help, $man);
my $clearout_file = '/static/test/fixtures/00-clean-db.sql';

my (%config) = (
    #'source' => 'root/static/test/fixtures/reference_data',
    'source' => 'root/static/test/fixtures/andrew',
    'fixturetype' => '',
    'fixtures' => [ ],
    'clear' => 0,
);

GetOptions(
    'help'                 => sub { $help = 1; pod2usage( -verbose => 1 ) },
    'man'                  => sub { $man = 1; pod2usage( -verbose => 2 ) },
    'source=s@'          => \$config{sources},
    'type=s'          => \$config{fixturetype},
    'clear=i'          => \$config{clear},
) or (pod2usage(2) && exit(1));

exit(0) if ($help || $man);

for my $resultsource_name (@{$config{sources}})
{
    #print "Loading file or directory '$resultsource_name'\n";

    if ($config{fixturetype} eq 'static') {
	# No need to clear out anything -- static data is loaded once,
	#  and in any case, each record is checked against the database before being loaded
	print STDERR "Loading static file(s) '$resultsource_name'\n";
	load_static_files($resultsource_name);
    } elsif ($config{fixturetype} eq 'dynamic') {
	if ($config{clear}) {
	    print STDERR "Clearing out files using '$clearout_file'\n";
	    load_files($clearout_file);
	}
	print STDERR "Loading dynamic file(s) '$resultsource_name'\n";
	load_dynamic_files($resultsource_name);
    } else {
	if ($config{clear}) {
	    print STDERR "Clearing out files using '$clearout_file'\n";
	    load_files($clearout_file);
	}
	print STDERR "Loading file(s) '$resultsource_name'\n";
	load_files($resultsource_name);
    }
}


sub syntax {
    my (@errors) = @_;
    print STDERR join("\n", @errors) . "\n";
    pod2usage(2);
    exit(1);
}

__END__

