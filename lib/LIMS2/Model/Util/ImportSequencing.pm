package LIMS2::Model::Util::ImportSequencing;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::ImportSequencing::VERSION = '0.473';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
             extract_eurofins_data
             fetch_archives_added_since
             get_seq_file_import_date
             backup_data
          )
    ]
};

use Log::Log4perl qw( :easy );
use Hash::MoreUtils qw( slice_def );
use Archive::Zip qw( :ERROR_CODES );
use Path::Class;
use POSIX;
use File::Path qw(remove_tree);
use Data::Dumper;
use LIMS2::Model::Util qw( random_string );
use File::stat;
use LIMS2::Model;
use Try::Tiny;
BEGIN {
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->easy_init( { level => $DEBUG } );
    }
}
my $STRING_TO_REMOVE = qr/_premix-w\.-temp/;
my $PROJECT_NAME_RX = qr/^(.*)_\d+[a-z]{1}\d{2}\./;

sub extract_eurofins_data{
	my ($archive, $move_archive) = @_;

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
	my %projects_modified;
	my %project_versions;
	my @moves;

	# One directory per plate, e.g. plate_CGaP_EDQ0034_SF
	# For each directory find scf and seq (not seq.clipped) files
	# Work out project name from root of file names
	# Create project directory in warehouse (LIMS2_SEQ_FILE_DIR) if not exists
	# Move fixed files to this directory
	while( my $plate_dir = $temp_dir->next ){
		next unless -d $plate_dir;
		foreach my $data_file ($plate_dir->children){
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

            # Store list of moves to make
            # We might need to backup some project directories before we do this
            my $move = {
            	from => $fixed_file,
            	to   => $project_dir,
            };
            push @moves, $move;

            my $target_location = $project_dir->file( $fixed_file->basename );
            if(-e $target_location){
            	WARN "File already exists at $target_location. Will create backup of $project_dir";
            	$projects_modified{$project_name} = $project_dir;
            }
		}

	}
	foreach my $modified_dir (values %projects_modified){
		my $project = $modified_dir->basename;
        my $version = backup_data($modified_dir, $project);
        # method returns project versions so db can be updated with this info
        $project_versions{$project} = $version;
	}

    perform_file_moves(@moves);


    my $time_stamp = update_archive_names_lists(\%projects,$archive_file);

    if($move_archive){
	    # Store orig archives in warehouse too
	    my $dir_path = $ENV{LIMS2_SEQ_ARCHIVE_DIR}
	        or LOGDIE "Cannot move archive file as LIMS2_SEQ_ARCHIVE_DIR is not set";
	    INFO "Moving original archive $archive_file to $dir_path";
	    my $archive_dir = dir($dir_path);
	    $time_stamp =~ s/\s/_/g;
	    my $archive_to = $archive_dir->file( $archive_file->basename.".$time_stamp" );
	    $archive_file->move_to( $archive_to ) or LOGDIE "Cannot move archive file $archive_file to $archive_to - $!";
    }

	# Tidy up temporarily unpacked files
	remove_tree($temp_dir->stringify) or LOGDIE "Could not remove $temp_dir - $!";

	# Return list of projects seen
	my @sorted_projects = sort keys %projects;

	return (\@sorted_projects,\%project_versions);
}

sub update_archive_names_lists{
	my ($projects, $archive_file) = @_;

	# Create file archive_names.txt in this dir if not exists
	# Append archive name to this file
	my $time_stamp = strftime("%Y-%m-%d %H:%M:%S", localtime(time));
	foreach my $project_dir (values %$projects){
		my $project_list = $project_dir->file('archive_names.txt');
	    my $fh = $project_list->opena or die "Cannot open $project_list for appending - $!";
	    my $archive_name = $archive_file->basename;
	    print $fh "$time_stamp,$archive_name\n";
	    close $fh;
	    INFO "Sequencing data in project directory $project_dir updated\n";
	}
	return $time_stamp;
}

sub perform_file_moves{
	my @moves = @_;
	foreach my $move (@moves){
		my $fixed_file = $move->{from};
		my $project_dir = $move->{to};
        INFO "Moving $fixed_file to $project_dir";
	    $fixed_file->move_to($project_dir) or LOGDIE "Could not move $fixed_file to $project_dir - $!";
	}
    return;
}

sub backup_data{
    my ($modified_dir, $project) = @_;

	my $version = random_string(6);
	my $versioned_dir = $modified_dir->subdir($version);
	$versioned_dir->mkpath
	    or die "Could not create $versioned_dir - $!";

    DEBUG "Copying all files from $modified_dir to $versioned_dir to avoid overwriting";

    foreach my $file ($modified_dir->children){
    	if($file =~/\.(seq|scf)$/){
	        # Use cp -p command to preserve timestamps of original files
            system('cp','-p', $file->stringify, $versioned_dir) == 0
                or die "Could not copy $file to $versioned_dir - $!";
    	}
    }

    if(-e $modified_dir->file('archive_names.txt')){
        $modified_dir->file('archive_names.txt')->copy_to($versioned_dir)
            or die "Could not copy archive_names.txt from $modified_dir to $versioned_dir - $!";
    }

    insert_backup($version, $project);

    return $version;
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

    # Remove underscore from names which have "_<primer>" added by EF
    # because the plate was sequenced with more than one primer
    # e.g. HFP0015_B_1e06.p1k_PNF.scf
    $new_name =~ s/p1k_/p1k/;

    return $new_name;
}

sub get_seq_file_import_date {
    my ($project, $read_name, $backup) = @_;
    my $dir;

    if ($backup) {
        $dir = $ENV{LIMS2_SEQ_FILE_DIR} . '/' . $project . '/' . $backup . '/' . $read_name . '.seq';
    } else {
        $dir = $ENV{LIMS2_SEQ_FILE_DIR} . '/' . $project . '/' . $read_name . '.seq';
    }

    my $fh;
    my $file = open($fh, '<', $dir);
    my $stats = stat($fh);
    close $fh;
    my $date_time;

    try {
        my @date = localtime($stats->ctime);
        $date[5] += 1900;
        $date[4] += 1;
        for (my $t = 0; $t < 5; $t++) {
            $date[$t] = sprintf("%02d",$date[$t]);
        }
        $date_time = "$date[5]-$date[4]-$date[3] $date[2]:$date[1]:$date[0]";
    } catch {
        $date_time = '-';
    };
    return $date_time;
}

sub insert_backup {
    my ($dir, $project) = @_;
    my $model = LIMS2::Model->new( user => 'lims2' );

    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime(time));

    $model->schema->txn_do( sub{
      try{
          $model->create_sequencing_project_backup({
              directory         => $dir,
              creation_date     => $now,
          }, $project);
      }
      catch{
          warn "Could not create_sequencing_project_backup for project $project: $_";
          $model->schema->txn_rollback;
      };
    });
    return;
}

1;
