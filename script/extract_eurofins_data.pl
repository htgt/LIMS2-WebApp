#!/usr/bin/env perl

use strict;
use warnings;
use DateTime;
use Getopt::Long;
use Try::Tiny;
use Pod::Usage;
use Config::Tiny;
use LIMS2::Model::Util::ImportSequencing qw(extract_eurofins_data);
use LIMS2::Model;
use POSIX;

GetOptions(
    'help'      => sub { pod2usage( -verbose => 1 ) },
    'man'       => sub { pod2usage( -verbose => 2 ) },
    'db_update' => \my $db_update,
    'move'      => \my $move,
);

my @archives = @ARGV;

my @all_projects;

foreach my $archive(@archives){
    try{
        my @projects = extract_eurofins_data($archive,$move);
        push @all_projects, @projects;
    }
    catch{
        warn "Data extraction from archive $archive failed with error: $_";
    };
}

if($db_update){
    my $model = LIMS2::Model->new( user => 'lims2' );
    foreach my $project (@all_projects){
        # update in db
        my $now = strftime("%Y-%m-%dT%H:%M:%S", localtime(time));
        $model->schema->txn_do( sub{
          try{
              $model->update_sequencing_project({
                  name              => $project,
                  available_results => 1,
                  results_imported_date => $now,
              });
          }
          catch{
              warn "Could not update data availability info for project $project: $_";
              $model->schema->txn_rollback;
          };
        });
    }
}

=head1 NAME

extract_eurofins_data.pl - extract sequencing data generated by Eurofins and make
avaiable via LIMS2

=head1 SYNOPSIS

  extract_eurofins_data.pl [options] Order1234.zip Order5678.zip

      --help        Display a brief help message
      --man         Display the manual page
      --db_update   Update data availability status in LIMS2
      --move        Move archive after extraction

=head1 DESCRIPTION

Extract sequencing data archives generated by Eurofins and move into directory
specified by LIMS2_SEQ_FILE_DIR env variable.

Provide a list of locally downloaded archives to extract and import.

Use the --db_update flag if you want to set the data availability status of any projects
found in the import to true in LIMS2.

Use the --move flag to move the archives after extraction to the directory specified
by LIMS2_SEQ_ARCHIVE_DIR

=head1 AUTHOR

Anna Farne
