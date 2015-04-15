#!/usr/bin/env perl

=head

This script was written to migrate existing project and sponsor data to
schema version 86.

Run the database migration ddl/versions/86/up.sql first, then run this script
to combine projects which differ only by sponsor_id and create the necessary
project to sponsor relationships in the new project_sponsors table.

STDOUT from the script lists any projects which need to be checked after the
script is run because they have conflicting information in fields which have been
added to the projects table relating to recovery status. In these cases the project
will have been created but the recovery information needs to be checked and manually
updated

=cut

use strict;
use warnings;

use LIMS2::Model;
use Log::Log4perl qw( :easy );
use Data::Dumper;
use Data::Compare;
use feature qw(say);

# For mouse projects I added column targeting_profile_id to projects
# table to allow for differect targeting stratagies for the same gene
# Migrate to schema version 88, delete mouse projects then rerun the script
# with this flag set to 1 to repeat the migration of mouse projects from old_projects table
my $mouse_only = 1;

my $unique_projects;

my $model = LIMS2::Model->new( user => 'lims2' );

my $SPONSOR_PROFILE = {
    'Syboss'               => 'homozygous',
    'Pathogens'            => 'homozygous',
    'Core'                 => 'homozygous',
    'Cre Knockin'          => 'cre_knockin',
    'EUCOMMTools Recovery' => 'ko_first',
#   'Cre Bac'       => 'cre_bac',
    'Barry Short Arm Recovery' => 'ko_first',
};

my @fields = qw(
	gene_id
	targeting_type
	species_id
	htgt_project_id
	effort_concluded
    recovery_comment
    priority
    recovery_class_id
);

foreach my $old_project($model->schema->resultset('OldProject')->all){
	my $key = join "_",
	    $old_project->species_id,
	    $old_project->gene_id,
	    $old_project->targeting_type;

    my $sponsor_id = $old_project->sponsor_id;
    my $data = { map { $_ => $old_project->$_ } @fields };

    if($old_project->species_id eq 'Mouse'){
        my $profile = $SPONSOR_PROFILE->{$sponsor_id};
        if($profile){
            $key.="_$profile";
            $data->{targeting_profile_id} = $profile;
        }
    }
    else{
        next if $mouse_only;
    }

	$unique_projects->{$key} ||= { sponsors => [] };

	push @{ $unique_projects->{$key}->{sponsors} }, $sponsor_id;

	my $existing_data = $unique_projects->{$key}->{data};
	if($existing_data){
        my $data_to_use = choose_data($existing_data, $data);
        if($data_to_use){
            $unique_projects->{$key}->{data} = $data_to_use;
        }
        else{
        	say "Error processing data for project $key. See diffs above";
        }
	}
	else{
        $unique_projects->{$key}->{data} = $data;
	}

}

#say "Project Sponsors:";
#say Dumper($unique_projects);
my %sponsors_by_id = map { $_->id => $_ } $model->schema->resultset('Sponsor')->all;

foreach my $key (keys %$unique_projects){
    my $sponsors = $unique_projects->{$key}->{sponsors};
    my $data = $unique_projects->{$key}->{data};

    say "Creating project $key";
    my $project = $model->create_project($data);
    foreach my $sponsor_id (@$sponsors){
    	say " ..adding sponsor $sponsor_id";
        $project->add_to_sponsors( $sponsors_by_id{$sponsor_id} );
    }
}

sub get_differences{
	my ($old, $new) = @_;
	my $diffs;
	foreach my $item(@fields){
        unless($old->{$item} eq $new->{$item}){
            $diffs->{$item}->{old} = $old->{$item};
            $diffs->{$item}->{new} = $new->{$item};
        }
	}
	return $diffs;
}

sub choose_data{
	my ($old, $new) = @_;
	my $data_to_use;
	my $diffs = get_differences($old,$new);
	if($diffs){
		# See if either of the sets of data contains new data that
		# is not undef or 0 then this is the set we want to use
        my $use_old = diffs_contain_data($diffs, 'old');
        my $use_new = diffs_contain_data($diffs, 'new');
        if($use_old and $use_new){
        	say "Both sets of data contain information. They must be compared manually";
        	say Dumper($diffs);
        	return;
        }
        elsif($use_old){
        	return $old;
        }
        elsif($use_new){
        	return $new;
        }
        else{
        	# There are differences but neither contain much so warn and return
        	say "Data differs but not in any meaningful way!";
        	say Dumper($diffs);
        	return $old;
        }
	}
	else{
		# They are both the same so return one of them
		return $old;
	}

	return;
}

sub diffs_contain_data{
	# $category: old or new
    my ($diffs, $category) = @_;
    my $score = 0;
    foreach my $item (@fields){
        if($diffs->{$item}){
        	if($diffs->{$item}->{$category}){
        		$score++;
        	}
        }
    }
    return $score;
}