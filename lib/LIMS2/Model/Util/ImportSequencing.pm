package LIMS2::Model::Util::ImportSequencing;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::ImportSequencing::VERSION = '0.353';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
             extract_eurofins_data
             fetch_archives_added_since
          )
    ]
};

use Log::Log4perl qw( :easy );;
use Hash::MoreUtils qw( slice_def );
use Archive::Zip qw( :ERROR_CODES );
use Path::Class;
use POSIX;
use File::Path qw(remove_tree);
use Data::Dumper;

Log::Log4perl->easy_init( { level => $INFO } );

my $STRING_TO_REMOVE = qr/_premix-w\.-temp/;
my $PROJECT_NAME_RX = qr/^(.*)_\d+[a-z]{1}\d{2}\./;

sub extract_eurofins_data{
	my ($archive, $move) = @_;

	# Unpack zip archive
	my $tmp_dir_name = $archive;
	$tmp_dir_name =~ s/\.zip$//g;

	if ($tmp_dir_name eq $archive){
		LOGDIE "Archive $archive is not a .zip file";
	}

    my $archive_file = file($archive);

    # Add unique timestamp to dir so we don't clash if
    # script fails before removing it and then gets run again
    $tmp_dir_name.="_".time();
	my $temp_dir = dir($tmp_dir_name);
	$temp_dir->mkpath;

	INFO "Unzipping archive $archive_file...";
	my $zip = Archive::Zip->new();
	unless( $zip->read("$archive_file") == AZ_OK ){
		LOGDIE "Could not inflate zip $archive_file - $!";
	}
	$zip->extractTree( '', $temp_dir );
	INFO "Unzipping complete";



	# Keep track of which project we have found in archive
	my %projects;

	# One directory per plate, e.g. plate_CGaP_EDQ0034_SF
	# For each directory find scf and seq (not seq.clipped) files
	# Work out project name from root of file names
	# Create project directory in warehouse (LIMS2_SEQ_FILE_DIR) if not exists
	# Move fixed files to this directory
	while( my $plate_dir = $temp_dir->next ){
		next unless -d $plate_dir;
		while(my $data_file = $plate_dir->next){
			my ($project_name, $fixed_file);
	        #if ($data_file =~ /\.seq\.clipped$/){
	        if($data_file =~ /\.seq$/){
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

            INFO "Moving $fixed_file to $project_dir";
	        $fixed_file->move_to($project_dir) or LOGDIE "Could not move $fixed_file to $project_dir - $!";
		}

	}

	# Create file archive_names.txt in this dir if not exists
	# Append archive name to this file
	my $time_stamp = strftime("%Y-%m-%d %H:%M:%S", localtime(time));
	foreach my $project_dir (values %projects){
		my $project_list = $project_dir->file('archive_names.txt');
	    my $fh = $project_list->opena or die "Cannot open $project_list for appending - $!";
	    my $archive_name = $archive_file->basename;
	    print $fh "$time_stamp,$archive_name\n";
	    close $fh;
	    INFO "Sequencing data in project directory $project_dir updated\n";
	}


    if($move){
	    # Store orig archives in warehouse too
	    my $dir_path = $ENV{LIMS2_SEQ_ARCHIVE_DIR}
	        or LOGDIE "Cannot move archive file as LIMS2_SEQ_ARCHIVE_DIR is not set";
	    INFO "Moving original archive $archive_file to $dir_path";
	    my $archive_dir = dir($dir_path);
	    my $archive_to = $archive_dir->file( $archive_file->basename );
	    $archive_file->move_to( $archive_to ) or LOGDIE "Cannot move archive file $archive_file to $archive_to - $!";
    }

	# Tidy up temporarily unpacked files
	remove_tree($temp_dir->stringify) or LOGDIE "Could not remove $temp_dir - $!";

	# Return list of projects seen
	my @sorted_projects = sort keys %projects;
	return @sorted_projects;
}

# Remove "premix-w.-temp" from file names and read names:
# e.g. EDQ0034_1a03.p1kSF_premix-w.-temp.scf
sub fix_scf_file{
    my $file = shift;

    DEBUG "SCF file name: $file\n";
    my $new_name = _get_new_name("$file");

    my $new_file = file($new_name);
    $file->move_to( $new_file ) or die "Could not move $file to $new_file";

    my ($project_name) = ( $new_file->basename =~ /$PROJECT_NAME_RX/g );

    DEBUG "New SCF file name: ".($new_file || "");
    DEBUG "Project name: ".($project_name ||  "");
    return ($project_name, $new_file);
}

# EDQ0034_1a03.p1kSF_premix-w.-temp.seq
# >EDQ0034_1a05.p1kSF_premix-w.-temp -- 17..634 of sequence
sub fix_seq_file{
    my $file = shift;

    DEBUG "Seq file name: $file\n";
    my @lines = $file->slurp;

    my $new_name = _get_new_name("$file");

    my $new_file = file($new_name);
    my $fh = $new_file->openw or LOGDIE "Can't open $new_file for writing - $!";

    foreach my $line (@lines){
    	my $new_read_name = _get_new_name($line);

    	print $fh $new_read_name;
    }

    close $fh;

    my ($project_name) = ( $new_file->basename =~ /$PROJECT_NAME_RX/g );
    DEBUG "New seq file name: ".($new_file || "");
    DEBUG "Project name: ".($project_name ||  "");
    return ($project_name, $new_file);
}

sub _get_new_name{
	my ($new_name) = @_;

    $new_name =~ s/$STRING_TO_REMOVE//;

    # tmp fix to convert SF -> SF1
    $new_name =~ s/p1kSF\b/p1kSF1/;
    $new_name =~ s/p1kSR\b/p1kSR1/;

    return $new_name;
}

1;

