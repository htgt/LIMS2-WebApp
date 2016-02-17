#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use TryCatch;

my $model = LIMS2::Model->new({ user => 'tasks' });

my @wells_with_barcodes = $model->schema->resultset('Well')->search({
    'me.barcode' => { '!=' => undef },
},
{
	prefetch => 'plate'
});

say "Found ".scalar(@wells_with_barcodes)." wells with barcodes";

my %plates_with_old_wells;
my %plates_with_current_wells;

foreach my $bc_well (@wells_with_barcodes){

    my $barcode = $bc_well->barcode;
	my $ancestor_it = $bc_well->ancestors->depth_first_traversal( $bc_well, 'in' );

	my @old_versions;
	my $related_things = {};

	while ( my $ancestor = $ancestor_it->next() ){
		next if $ancestor->id == $bc_well->id; # Skip starting well

        # Ancestor cannot be an old version if:
        # on a current plate with no version
        last unless ($ancestor->plate ? $ancestor->plate->version : undef);

        # Or has its own barcode
        last if $ancestor->barcode;

		# Or is different well type
        last if $ancestor->plate_type ne $bc_well->plate_type;

        # Now that we know we have an old version of the well
        # Gather things linked to it
        _gather_related($ancestor,$related_things);

        # and flag it for delete
        push @old_versions, $ancestor;
	}

    my $earliest_version = $old_versions[-1];
    if($earliest_version and $earliest_version->id != $bc_well->id){
        $model->schema->txn_do(sub{
            say "--------------------------------------------";
            say "Merging old versions of well $bc_well (barcode: $barcode)";
            try{
            	# Link other attributes to $bc_well
                foreach my $relation (keys %$related_things){
                	my @existing = $bc_well->search_related($relation,{})->all;
                	if(@existing){
                		say "$relation found for current barcoded well AND old versions";
                	}
                	else{
                		say "$relation found for old well versions, relinking to barcoded well";
                		foreach my $related (@{ $related_things->{$relation} }){
                			$related->update({ well_id => $bc_well->id });
                		}
                	}
                }

            	# Link input processes of earliest version to $bc_well
            	foreach my $process ($earliest_version->parent_processes){
                    say "Linking inputs of $earliest_version to $bc_well";
                    foreach my $process_output ($process->process_output_wells){
                        $process_output->update({
                            well_id => $bc_well->id,
                        });
                    }
                }

                # Delete all @old_versions
                # Start with earliest version and delete its child processes
                # before deleting the well itself
                # There should be nothing else linked to the well by this stage
                # so simple delete should work. If it fails it means we have not
                # unlinked all related items.
                foreach my $old (reverse @old_versions){
                    say "Deleting old well version $old";
                    foreach my $process ($old->child_processes){
                        $model->delete_process({ id => $process->id });
                    }
                    $old->delete();
                }

            	# If $bc_well is on a versioned plate delete well name and plate_id
                if($bc_well->plate and $bc_well->plate->version){
                    say "Removing well name and plate ID from barcode $barcode on versioned plate";
                    $model->update_well_barcode({
                        barcode       => $barcode,
                        new_well_name => undef,
                        new_plate_id  => undef,
                        comment       => 'old well versions moved off plates',
                        user          => 'af11@sanger.ac.uk',
                    });
                }
            }
            catch($err){
                $model->schema->txn_rollback;
                say "ERROR: could not merge versioned wells for $bc_well (barcode: ".$bc_well->barcode.")";
                say "ERROR MESSAGE: $err";
            }
        });
    }
    elsif($bc_well->plate->version){
        # There is only one version of the well but it is on an old plate version
        # So well name and plate ID must be removed
        say "Removing well name and plate ID from barcode $barcode on versioned plate";
        $model->update_well_barcode({
            barcode       => $barcode,
            new_well_name => undef,
            new_plate_id  => undef,
            comment       => 'old well versions moved off plates',
            user          => 'af11@sanger.ac.uk',
        });
    }
}



sub _gather_related{
	my ($well, $related_things) = @_;

	my @well_relations = qw(
	crispr_es_qc_wells
	well_accepted_override
	well_chromosome_fail
	well_colony_counts
	well_comments
	well_dna_quality
	well_dna_status
	well_genotyping_results
	well_het_status
	well_lab_number
	well_primer_bands
	well_qc_sequencing_result
	well_recombineering_results
	well_targeting_neo_pass
	well_targeting_pass
	well_targeting_puro_pass
	);

    foreach my $relation (@well_relations){

        my @related = $well->search_related($relation,{})->all;
        if(@related){
        	if(exists $related_things->{$relation}){
        		say "WARNING: We already have related $relation";
        	}
        	else{
        		say " $relation found for $well";
        		$related_things->{$relation} =\@related;
        	}
        }
    }
    return;
}