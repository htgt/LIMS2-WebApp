#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use LIMS2::Model::ProcessGraph;
use Log::Log4perl qw( :levels );
use Getopt::Long;

my $log_level = $WARN;
my $type      = 'descendants';

GetOptions(
    trace         => sub { $log_level = $TRACE },
    debug         => sub { $log_level = $DEBUG },
    verbose       => sub { $log_level = $INFO },
    'output=s'    => \my $output_file,
    'ancestors'   => sub { $type = 'ancestors' },
    'descendants' => sub { $type = 'descendants' }
) and @ARGV == 2
    or die "Usage: $0 PLATE_NAME WELL_NAME\n";

Log::Log4perl->easy_init(
    {
        level  => $log_level,
        layout => '%m%n'
    }
);

my ( $plate_name, $well_name ) = @ARGV;

#my $model = LIMS2::Model->new( user => 'tasks' );
my $model = LIMS2::Model->new( user => 'lims2' );

my $well = $model->retrieve_well( { plate_name => $plate_name, well_name => $well_name } );

my $graph;

if ( $type eq 'ancestors' ) {
    $graph = $well->ancestors;
}
elsif ( $type eq 'descendants' ) {
    $graph = $well->descendants;
}

$graph->render( output_file => $output_file );
