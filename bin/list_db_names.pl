#! /usr/bin/perl
use strict;
use warnings;
use YAML::XS qw/LoadFile/;
use Data::Dumper;

=head list_db_names
Lists the database names from teh Yaml file defined by LIMS2_DBCONNECT_CONFIG
If the LIMS2_DB environment variable is set, asterisk the database named by that variable

If a database name is defined in ARGV[0], check whether it is in the list of names,
if it is, print the name as confirmation.

=cut

if ($ARGV[0]) {
    print check_db_name( get_db_names(), $ARGV[0] );
}
else {
    list_db_names( get_db_names() );
}

exit;

##
    
sub get_db_names {
    if (exists $ENV{'LIMS2_DBCONNECT_CONFIG'} ) {
        return LoadFile($ENV{'LIMS2_DBCONNECT_CONFIG'})
            or die "Unable to process file to get list of database names\n" ;
    }
    else {
        print STDERR "You need to set LIMS2_DBCONNECT_CONFIG - have you run the correct setup script?\n";
    }
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

    return $match // '0';
}

