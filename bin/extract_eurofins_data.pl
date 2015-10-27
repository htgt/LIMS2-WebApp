#!/usr/bin/env perl

use strict;
use warnings;
use DateTime;
use Getopt::Long;
use Try::Tiny;
use Pod::Usage;
use Config::Tiny;
use LIMS2::Model::Util::ImportSequencing qw(extract_eurofins_data fetch_archives_added_since);

GetOptions(
    'help'            => sub { pod2usage( -verbose => 1 ) },
    'man'             => sub { pod2usage( -verbose => 2 ) },
    'poll_interval=i' => \my $poll_interval,
    'local_archives'  => \my $local_archives,
    'db_update'       => \my $db_update,
);

my @archives;

if($poll_interval){

    $ENV{ EUROFINS_SFTP_CONFIG } or die "EUROFINS_SFTP_CONFIG environment variable not set";
    my $sftp_conf = Config::Tiny->read( $ENV{ EUROFINS_SFTP_CONFIG } )->{_};

    my $last_poll = DateTime->now()->subtract( minutes => $poll_interval );
    try{
        @archives = fetch_archives_added_since($last_poll, $sftp_conf);
    }
    catch{
        warn "Fetch archives failed with error: $_";
    };
}
elsif($local_archives){
    @archives = @ARGV;
}
else{
    die "You must provide a poll_interval or use the local_archives option";
}

my @all_projects;

foreach my $archive(@archives){
    try{
        my @projects = extract_eurofins_data($archive);
        push @all_projects, @projects;
    }
    catch{
        warn "Data extraction from archive $archive failed with error: $_";
    };
}

if($db_update){
    my $model = 'FIXME';
    foreach my $project (@all_projects){
        # update in db
        # use model method in transaction
    }
}

=head1 NAME

extract_eurofins_data.pl - extract sequencing data generated by Eurofins and make
avaiable via LIMS2

=head1 SYNOPSIS

  extract_eurofins_data.pl [options] --poll_interval 60

  OR

  extract_eurofins_data.pl [options] --local_archives Order1234.zip Order5678.zip

      --help            Display a brief help message
      --man             Display the manual page
      --db_update       Update data availability status in LIMS2

      --poll_interval   Provide a polling interval in minutes to poll the Eurofins
                        sFTP site for archives added since last poll and then import these
      --local_archives  Provide list of archives already on local file system


  Provide either poll_interval OR archives

=head1 DESCRIPTION

Extract sequencing data archives generated by Eurofins and move into directory
specified by LIMS2_SEQ_FILE_DIR env variable.

Either set the --local_archives flag and provide a list of locally downloaded archives
to extract/import, or provide a --poll_interval in minutes and this script will check the
Eurofins sFTP site for archives added within the poll interval, then download and extract
these. The sFTP site host, username and password should be specified in conf file at
EUROFINS_SFTP_CONFIG.

Use the --db_update flag if you want to set the data availability status of any projects
found in the import to true in LIMS2.

=head1 AUTHOR

Anna Farne