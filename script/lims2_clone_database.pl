#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

#use Config::General;
use Getopt::Long;
use Pod::Usage;
use Readonly;
use LIMS2::DBUtils::Databases;

# A utility to simplify copying a "production" type database to a development server
# Lars G. Erlandsen, 'Viking'
# Jun 25 2013

=head1 NAME

lims2_clone_database.pl - LIMS2 utility to clone databases and load fixture data

=head1 SYNOPSIS

lims2_clone_database.pl [-switch] [ [-switch] .. ]

=head2 Switches

=over 4

=item --man

Generate a formatted pod page showing this message.

=item --help

Help page. You are looking at it.

=item --source_defn

The source database definition to use in the yaml file. It defaults to the B<$LIMS2_CLONEFROM_DB> environment variable.

=item --destination_defn

The destination database definition to use in the yaml file. It defaults to B<$LIMS2_DB> environment variable.

=item --source_role

The source role to use within the yaml file. 

=item --no_source_role

Must be set to '1' to prevent the "-role=rolename" being used for the source database dump 

=item --destination_role

The destination role to use within the yaml file. 

=item --destination_db

The destination database on the target server. It defaults to I<lims2_unittest_> followed by the user name of the user running the script, i.e. I<lims2_unittest_le6> in the author's case.

=item --overwrite

Must be set to '1' for the destination database to be dropped if it exists.

=item --with_data

Must be set to '1' to also copy the content of the source database across.

=item --create_test_role

Must be set to '1' to also create the necessary test roles and MD5 tables for system testing

=back


=head1 DESCRIPTION

An (hopefully) easy-to-use utility to dump a LIMS2 database definition and re-create it on another server.
There are flags and switches to protect or enable the overwriting of existing databases,
switches to copy the data or skip it,
and various switches to specify source and target identifiers.

The script will use the ".yaml" connection profiles to find connection details,
and expects the environment variable B<LIMS2_DBCONNECT_CONFIG> to point to it.

=head1 EXAMPLES

Assume the following I<dbconnect.yaml> file:

    LIMS2_LIVE:
      schema_class: LIMS2::Model::Schema
      dsn: 'dbi:Pg:host=pgsrv5;port=5437;dbname=lims2_live'
      AutoCommit: 1
      roles:
	webapp:
	  user: lims2_live_webapp
	  password: <withheld_password>
	webapp_ro:
	  user: lims2_live_webapp_ro
	  password: <withheld_password>
	tasks:
	  user: lims2_live_task
	  password: <withheld_password>
	lims2_live_admin:
	  user: <withheld_user>
	  password: <withheld_password>
    LIMS2_DEVEL_MY_UNITTEST:
      schema_class: LIMS2::Model::Schema
      dsn: 'dbi:Pg:host=htgt-db;port=5441;dbname=lims2_dev'
      AutoCommit: 1
      roles:
	lims2:
	  user: lims2
	  password: <withheld_password>

To dump the production definition from B<LIMS2_LIVE>, database I<lims2_live>,
to B<LIMS2_DEVEL_MY_UNITTEST>, database I<lims2_unittest_le6>,
dropping and re-creating the database as necessary,
using source role lims2_live_admin (logging in as <withheld_user>)
and destination role I<lims2>,
and creating the test roles and tables, use the command:

lims2_clone_database.pl \
    --source_defn LIMS2_LIVE \
    --source_role lims2_live_admin \
    --destination_defn LIMS2_DEVEL_MY_UNITTEST \
    --destination_role lims2 \
    --destination_db lims2_unittest_le6
    --overwrite 1 \
    --with_data 0 \
    --create_test_role 1



=head1 AUTHOR

Lars G. Erlandsen

=cut

my ($help, $man);

my (%config) = (
    'source_defn' => $ENV{LIMS2_CLONEFROM_DB},
    'destination_defn' => $ENV{LIMS2_DB},
    'source_role' => undef,
    'no_source_role' => 0,
    'destination_role' => undef,
    'destination_db' => 'lims2_unittest_' . $ENV{USER},
    'overwrite' => 0,
    'with_data' => 0,
    'create_test_role' => 0,
);

GetOptions(
    'help'                 => sub { $help = 1; pod2usage( -verbose => 1 ) },
    'man'                  => sub { $man = 1; pod2usage( -verbose => 2 ) },
    'source_defn=s'        => \$config{source_defn},
    'destination_defn=s'   => \$config{destination_defn},
    'source_role=s'        => \$config{source_role},
    'no_source_role=i'     => \$config{no_source_role},
    'destination_role=s'   => \$config{destination_role},
    'destination_db=s'     => \$config{destination_db},
    'overwrite=i'          => \$config{overwrite},
    'with_data=i'          => \$config{with_data},
    'create_test_role=i'   => \$config{create_test_role},
) or (pod2usage(2) && exit(1));

exit(0) if ($help || $man);

syntax("Option 'source_defn' cannot be blank") unless ($config{source_defn});
syntax("Option 'destination_defn' cannot be blank") unless ($config{destination_defn});
syntax("Option 'source_role' cannot be blank") unless ($config{source_role});
syntax("Option 'destination_role' cannot be blank") unless ($config{destination_role});
syntax("Option 'destination_db' cannot be blank") unless ($config{destination_db});

#print "Survived the Getopt cull...\n";

# Initialise object
my ($obj) = LIMS2::DBUtils::Databases->new(
    source_defn => $config{source_defn},
    destination_defn => $config{destination_defn},
    source_role => $config{source_role},
    destination_role => $config{destination_role}
);

# Clone database
my $ret = $obj->clone_database(
    overwrite => $config{overwrite},
    with_data => $config{with_data},
    no_source_role => $config{no_source_role},
    destination_db => $config{destination_db},
    create_test_role => $config{create_test_role}
);
exit($ret ? 0 : 1);

sub syntax {
    my (@errors) = @_;
    print STDERR join("\n", @errors) . "\n";
    pod2usage(2);
    exit(1);
}

__END__

