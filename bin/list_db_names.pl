#! /usr/bin/perl
use strict;
use warnings;
use YAML::XS qw/LoadFile/;
use Data::Dumper;
use Getopt::Long;

=head list_db_names
Lists the database names from the Yaml file defined by LIMS2_DBCONNECT_CONFIG
If the LIMS2_DB environment variable is set, asterisk the database named by that variable

If a database name is defined in ARGV[0], check whether it is in the list of names,
if it is, print the name as confirmation.

=cut
my $dbname_option = ''; # False value is default
my $help_option = '';

GetOptions(
    'dbname'       => \$dbname_option,
    'help|?'     => \$help_option,
)
or die usage_message();

if ($help_option) {
    die usage_message();
}


if ($ARGV[0]) {
    print check_db_name( get_db_names(), $ARGV[0] );
}
else {
    list_db_names( get_db_names() );
}

exit;

##
sub usage_message{
return << "END_DIE";

Usage: list_db_names.pl
    database_profile
    [--dbname]

Optional parameters in square brackets
Database profile is from dbconnect.yaml

Returns the profile name of the specified database, if it is present in dbconnect.yaml

Returns the list of database profiles from dbconnect.yaml

If the dbname option is specified, returns the database name listed in the postgresql
connection string from dbconnect.yaml.

END_DIE
}

sub get_db_names {
    if (exists $ENV{'LIMS2_DBCONNECT_CONFIG'} ) {
        return LoadFile($ENV{'LIMS2_DBCONNECT_CONFIG'})
            or die "Unable to process file to get list of database names\n" ;
    }
    else {
        print STDERR "You need to set LIMS2_DBCONNECT_CONFIG - have you run the correct setup script?\n";
    }

    return;
}

sub list_db_names {
    my $config = shift;

    my $current_db = $ENV{'LIMS2_DB'};

    my @config_keys = sort keys %$config;
    foreach my $key ( @config_keys ) {
        my $msg = $key;
        if ( $key eq $current_db ) {
            $msg .= ' (*)';
        }
        print $msg . "\n";
    }
    print "\n(*) Currently selected database\n";
    return;
}

sub check_db_name {
    my $config = shift;
    my $db_name_to_check = shift;

    my @config_keys = sort keys %$config;
    my ($match) = grep { /^$db_name_to_check$/ } @config_keys;

    if (! $match ) {
        return ( 0 );

    }

    if ( ! $dbname_option ) {
        return ($match);
    }
    # Process the full database name information
    my $dbname;
    # check the dsn line and parse out the database name
    # dsn: 'dbi:Pg:host=mcs16;port=5527;dbname=lims2_local_dp10'
    if ( $config->{$match}->{'dsn'} ) {
        if ( $config->{$match}->{'dsn'} =~ m/ dbname=(\w+) /xms ) {
            $dbname = $1;
        }
    }
    if (! $dbname) {
        $dbname = 'not found';
    }

    return $dbname;
}

