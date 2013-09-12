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

# A utility to simplify generating static fixture data by copying table entries from a "production" type database
# Lars G. Erlandsen, 'Viking'
# Sep  2 2013

=head1 NAME

lims2_create_static_fixtures.pl - LIMS2 utility to create static fixture files from a database

=head1 SYNOPSIS

lims2_create_static_fixtures.pl [-switch] [ [-switch] .. ]

=head2 Switches

=over 4

=item --man

Generate a formatted pod page showing this message.

=item --help

Help page. You are looking at it.

=item --source_defn

The source database definition to use in the yaml file. It defaults to the B<$LIMS2_DB> environment variable.

=item --source_role

The source role to use within the yaml file.

=item --destination

The destination directory where the fixture files are written to. It defaults to 'root/static/test/fixtures'.

=item --fixtures

The schema classes that will be used to generate the test files. See inside this program if you need to change these.

=item --set

Choose one of the (built-in) fixture sets to use: 'static' or 'dynamic'

=back


=head1 DESCRIPTION

An (hopefully) easy-to-use utility to dump tables containing static reference data into csv files.
These will in turn be used to populate a database with static fixture data for unit and functional testing.

The script will use the ".yaml" connection profiles configuration file to find connection details,
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

To create fixture files from B<LIMS2_LIVE>,
using source role lims2 (logging in as <withheld_user>), use the command:

lims2_create_static_fixtures.pl \
    --source_defn LIMS2_LIVE \
    --source_role lims2


=head1 AUTHOR

Lars G. Erlandsen

=cut

my ($help, $man);

my (%config) = (
    'source_defn' => $ENV{LIMS2_DB},
    'source_role' => '',
    #'destination' => 'root/static/test/fixtures/reference_data',
    'destination' => 'root/static/test/fixtures/andrew',
    'fixtures' => [ ],
);

my %fixturesets = (
    'static' => [ qw(
	Assembly
	BacLibrary
	Backbone
	CassetteFunction
	Cassette
	CellLine
	Chromosome
	ColonyCountType
	CrisprLociType
	DesignCommentCategory
	DesignOligoType
	DesignType
	GeneType
	GenotypingPrimerType
	GenotypingResultType
	MutationDesignType
	PlateType
	PrimerBandType
	ProcessType
	Recombinase
	RecombineeringResultType
	Role
	Species
	SpeciesDefaultAssembly
	Sponsor
    ) ],
    'dynamic' => [ qw(
	User
	Design
	GeneDesign
	Plate
	ProcessBackbone
	ProcessCassette
	ProcessCellLine
	ProcessDesign
	Process
	ProcessInputWell
	ProcessOutputWell
	ProcessRecombinase
	Well
    ) ],
);

GetOptions(
    'help'                 => sub { $help = 1; pod2usage( -verbose => 1 ) },
    'man'                  => sub { $man = 1; pod2usage( -verbose => 2 ) },
    'source_defn=s'        => \$config{source_defn},
    'source_role=s'        => \$config{source_role},
    'destination=s'          => \$config{destination},
    'fixtures=s@'          => \$config{fixtures},
    'set=s'          => \$config{fixtureset},
) or (pod2usage(2) && exit(1));

exit(0) if ($help || $man);

syntax("Option 'source_defn' cannot be blank") unless ($config{source_defn});
syntax("Option 'source_role' cannot be blank") unless ($config{source_role});

# Standard set of fixtures to use where none have been provided
if ($config{fixtureset}) {
    $config{fixtures} = $fixturesets{$config{fixtureset}};
}
if (scalar(@{$config{fixtures}}) == 0)
{
    print "No schema fixtures supplied -- using default set.\n";
    $config{fixtures} = $fixturesets{static};
}

# Handles
my $schema = LIMS2::Model::DBConnect->connect( $config{source_defn}, $config{source_role} );
print STDERR "Connected to database...\n";

# Iterate over the tables
for my $resultsource_name (@{$config{fixtures}})
{
    print "Dumping result source '$resultsource_name'\n";
    dump_table($schema, $resultsource_name);
}

sub dump_table
{
    my ($schema, $resultsource_name) = @_;
    my $filename = $config{destination} . '/' . $resultsource_name . '.csv';

    my $schemasource = $schema->source( $resultsource_name );
    my $resultset = $schema->resultset( $resultsource_name );
    my @column_names = $schemasource->columns;
    print Data::Dumper->Dump([\@column_names], [qw(*column_names)]);
    my $rs = $resultset->search;
    my $done_heading = 0;

    # Initialise Text::CSV
    my $csv = Text::CSV->new ( { binary => 1, eol => $/, always_quote => 1 } )  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV->error_diag ();

    # Open output file
    print "Opening file '$filename' for output\n";
    open my $fh, ">:encoding(utf8)", $filename or die 'Open error for ' . $filename . ": $!";
    # Column names
    $csv->print ($fh, \@column_names);

    while (my $record = $rs->next) {
	my @row;
	my %inflated = $record->get_columns();
	print Data::Dumper->Dump([\%inflated], [qw(*inflated)]);
	for my $key (@column_names) {
	    push(@row, $inflated{$key});
	}
	$csv->print ($fh, \@row);
    }
    close $fh or die 'Close error for ' . $filename . ": $!";
}

sub syntax {
    my (@errors) = @_;
    print STDERR join("\n", @errors) . "\n";
    pod2usage(2);
    exit(1);
}

__END__

