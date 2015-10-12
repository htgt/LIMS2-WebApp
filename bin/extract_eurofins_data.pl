#!/usr/bin/env perl

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES );
use Path::Class;
use POSIX;
use File::Path qw(remove_tree);

my ($archive) = @ARGV;

# Unpack zip archive
my $tmp_dir_name = $archive;
$tmp_dir_name =~ s/\.zip$//g;

if ($tmp_dir_name eq $archive){
	die "Archive $archive is not a .zip file";
}

my $archive_file = file($archive);

my $temp_dir = dir($tmp_dir_name);
$temp_dir->mkpath;

print "Unzipping archive..";
my $zip = Archive::Zip->new();
unless( $zip->read("$archive_file") == AZ_OK ){
	die "Could not inflate zip $archive_file - $!";
}
$zip->extractTree( '', $temp_dir );
print "Done\n";

my $STRING_TO_REMOVE = qr/_premix-w\.-temp/;
my $PROJECT_NAME_RX = qr/^(.*)_\d+[a-z]{1}\d{2}\./;

# Keep track of which project we have found in archive
my %projects;

# One directory per plate, e.g. plate_CGaP_EDQ0034_SF
# For each directory find scf and seq.clipped files
# Work out project name from root of file names
# Create project directory in warehouse (LIMS2_SEQ_FILE_DIR) if not exists
# Move fixed files to this directory
while( my $plate_dir = $temp_dir->next ){
	next unless -d $plate_dir;
	while(my $data_file = $plate_dir->next){
		my ($project_name, $fixed_file);
        if ($data_file =~ /\.seq\.clipped$/){
        	($project_name, $fixed_file) = fix_seq_file($data_file);
        }
        elsif($data_file =~ /\.scf$/){
        	($project_name, $fixed_file) = fix_scf_file($data_file);
        }
        else{
        	next;
        }

        # Sometimes we get reads called Empty Well so no project name
        # Ignore them
        next unless $project_name;

        my $project_dir = $projects{ $project_name };
        unless($project_dir){
        	$project_dir = dir($ENV{LIMS2_SEQ_FILE_DIR},$project_name);
        	$project_dir->mkpath;
        	$projects{$project_name} = $project_dir;
        }

        $fixed_file->move_to($project_dir) or die "Could not move $fixed_file to $project_dir - $!";
	}

}

# Remove "premic-w.-temp" from file names and read names:
# e.g. EDQ0034_1a03.p1kSF_premix-w.-temp.scf
sub fix_scf_file{
    my $file = shift;

print "SCF file name: $file\n";
    my $new_name = "$file";
    $new_name =~ s/$STRING_TO_REMOVE//;

    my $new_file = file($new_name);
    $file->move_to( $new_file ) or die "Could not move $file to $new_file";

    my ($project_name) = ( $new_file->basename =~ /$PROJECT_NAME_RX/g );

print "New SCF file name: $new_file\n";
print "Project name: $project_name\n\n";
    return ($project_name, $new_file);
}

# EDQ0034_1a03.p1kSF_premix-w.-temp.seq.clipped
# >EDQ0034_1a05.p1kSF_premix-w.-temp -- 17..634 of sequence
sub fix_seq_file{
    my $file = shift;
print "Seq file name: $file\n";
    my @lines = $file->slurp;

    my $new_name = "$file";
    $new_name =~ s/$STRING_TO_REMOVE//;
    $new_name =~ s/\.clipped$//;
    my $new_file = file($new_name);
    my $fh = $new_file->openw or die "Can't open $new_file for writing - $!";

    foreach my $line (@lines){
    	$line =~ s/$STRING_TO_REMOVE//;
    	print $fh $line;
    }

    close $fh;

    my ($project_name) = ( $new_file->basename =~ /$PROJECT_NAME_RX/g );
print "New seq file name: $new_file\n";
print "Project name: $project_name\n\n";
    return ($project_name, $new_file);
}

# Create file archive_names.txt in this dir if not exists
# Append archive name to this file
my $time_stamp = strftime("%Y-%m-%d %H:%M:%S", localtime(time));
foreach my $project_dir (values %projects){
	my $project_list = $project_dir->file('archive_names.txt');
    my $fh = $project_list->opena or die "Cannot open $project_list for appending - $!";
    print $fh "$time_stamp,$archive\n";
    close $fh;
    print "Sequencing data in project directory $project_dir updated\n";
}


# Store orig archives in warehouse too
# FIXME: put this in environment variable
my $archive_dir = dir('/warehouse/team87_wh01/eurofins_order_archive_data');
my $archive_to = $archive_dir->file( $archive_file->basename );
$archive_file->move_to( $archive_to ) or die "Cannot move archive file $archive_file to $archive_to - $!";

# Tidy up temporarily unpacked files
remove_tree($temp_dir->stringify) or die "Could not remove $temp_dir - $!";