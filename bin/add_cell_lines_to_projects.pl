#!/usr/bin/env perl

=head

This script was written to migrate existing project and sponsor data to
schema version 102.

Run the database migration ddl/versions/102 first, then run this script
to add the cell_line_id values to the projects table and create
additional projects if the gene has been sponsored in mutliple cell lines

Mutation and Experimental Cancer Genetics sponsor BOBSC-T6/8_B1,
the rest sponsor KOLF_2_C1

=cut

use strict;
use warnings;

use LIMS2::Model;
use Log::Log4perl qw( :easy );
use Data::Dumper;
use List::MoreUtils qw(uniq);

my $model = LIMS2::Model->new( user => 'lims2' );

my $cell_lines = {
    bob => $model->schema->resultset('CellLine')->search({ name => 'BOBSC-T6/8_B1' })->first,
    kolf => $model->schema->resultset('CellLine')->search({ name => 'KOLF_2_C1' })->first,
};


my $projects_rs = $model->schema->resultset('Project')->search({ species_id => 'Human' });

$model->schema->txn_do(sub{
    open (my $fh, ">", "new_projects.csv") or die $!;
    process_projects($projects_rs,$fh);
    close $fh;

	ERROR "Rolling back!";
	$model->schema->txn_rollback();

});

sub process_projects{
    my ($projects, $fh) = @_;
    while (my $project = $projects->next){
        DEBUG "Project ID: ".$project->id;
        my @sponsor_ids = $project->sponsor_ids;
        my @bob_sponsor_ids = grep { sponsor_cell_line($_) eq 'bob' } @sponsor_ids;
        my @kolf_sponsor_ids = grep { sponsor_cell_line($_) eq 'kolf' } @sponsor_ids;

        DEBUG "bob sponsors: ".join ",", @bob_sponsor_ids;
        DEBUG "kolf sponsors: ".join ",", @kolf_sponsor_ids;

        if(@bob_sponsor_ids and @kolf_sponsor_ids){
            # Update existing project with bob cell line
            # and list of bob sponsors
            $project->update({ cell_line_id => $cell_lines->{'bob'}->id });
            $model->update_project_sponsors({
                project_id => $project->id,
                sponsor_list => \@bob_sponsor_ids,
            });
            DEBUG "Bob project updated for gene ".$project->gene_id;

            # Create new project with kolf cell line and kolf sponsors
            my $kolf_project = $model->create_project({
                cell_line_id      => $cell_lines->{'kolf'}->id,
                gene_id           => $project->gene_id,
                targeting_type    => $project->targeting_type,
                species_id        => $project->species_id,
                targeting_profile_id => $project->targeting_profile_id,
                htgt_project_id   => $project->htgt_project_id,
                effort_concluded  => $project->effort_concluded,
                recovery_comment  => $project->recovery_comment,
                priority          => $project->priority,
                recovery_class_id => $project->recovery_class_id,
                sponsors          => \@kolf_sponsor_ids,
            });

            DEBUG "Kolf project created for gene ".$project->gene_id. " with ID ".$kolf_project->id;
            print $fh join ",", ($project->id, $kolf_project->id, $project->gene_id);
            print $fh "\n";
        }
        else{
            my $cell_line_id;
            if(@bob_sponsor_ids){
                $cell_line_id = $cell_lines->{'bob'}->id;
            }
            elsif(@kolf_sponsor_ids){
                $cell_line_id = $cell_lines->{'kolf'}->id;
            }
            else{
                DEBUG "No sponsored cell line identified for project ".$project->id;
            }

            DEBUG "Adding cell line ID ".$cell_line_id." to project ".$project->id;
            $project->update({ cell_line_id => $cell_line_id });
        }

    }
    return;
}

sub sponsor_cell_line{
	my ($sponsor) = @_;
	if($sponsor eq 'All'){
		return '';
	}

	if($sponsor eq 'Mutation' or $sponsor eq 'Experimental Cancer Genetics'){
		return 'bob';
	}

	return 'kolf';
<<<<<<< HEAD
}
=======
}
>>>>>>> devel
