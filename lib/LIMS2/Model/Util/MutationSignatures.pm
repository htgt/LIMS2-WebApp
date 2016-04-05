package LIMS2::Model::Util::MutationSignatures;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::MutationSignatures::VERSION = '0.391';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
             get_mutation_signatures_barcode_data
          )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( uniq any );
use LIMS2::Exception;
use TryCatch;
use Hash::MoreUtils qw( slice_def );
use Data::Dumper;

sub get_mutation_signatures_barcode_data{
	my ($model, $species) = @_;

	my @processes = $model->schema->resultset('Process')->search(
	    {
		    type_id => 'doubling',
		},
		{
            order_by => { -desc => 'id' },
		})->all;
    DEBUG "Found ".scalar(@processes)." doubling processes";

    my @parent_well_ids;
	my @all_data;
    my @wells;

    foreach my $process (@processes){
        DEBUG "Generating information for process ".$process->id;
		my ($parent_well) = $process->input_wells;
		push @parent_well_ids, $parent_well->id;
		my ($child_well) = $process->output_wells;
        my $well = {
            parent  => $parent_well,
            child   => $child_well,
            oxygen_condition  => $process->get_parameter_value('oxygen_condition'),
            number_of_doublings => $process->get_parameter_value('doublings')
        };
        push @wells, $well;

        # Child well may have been expanded to produce more clone so add
        # any barcoded descendants of the child well too
        if($child_well){
            foreach my $descendant ($child_well->barcoded_descendants){
                DEBUG "Found descendant well: $descendant";
                # We report exactly the same data as for the original child
                # only the child well is now the new descendant
                my $data = {
                    parent              => $parent_well,
                    child               => $descendant,
                    oxygen_condition    => $well->{oxygen_condition},
                    number_of_doublings => $well->{number_of_doublings},
                };
                push @wells, $data;
            }
        }
    }

    my $design_data = $model->get_design_data_for_well_id_list(\@parent_well_ids);

	foreach my $well (@wells){
    	my ($parent_well) = $well->{parent};
		my ($child_well) = $well->{child};

        if($child_well){
            # Skip child wells on old plate versions
            next if ($child_well->plate and $child_well->plate->version);
        }

		my $state = $parent_well->barcode_state->id;
        my $well_id = $parent_well->{_column_data}->{id};
        my $symbol = $model->retrieve_gene( { species => $species, search_term => $design_data->{$well_id}->{gene_id} } )->{gene_symbol};

		my $data = {
			parent_well_id    => $well_id,
            gene_id           => $design_data->{$well_id}->{gene_id},
            gene_symbol       => $symbol,
			parent_barcode    => $parent_well->barcode,
           	state             => $state,
			oxygen_condition  => $well->{oxygen_condition},
		};

        # There should always be a doubling start event
		my $doubling_start = $parent_well->most_recent_barcode_event("doubling_in_progress");
		if($doubling_start){
            $data->{doubling_start} = $doubling_start->created_at;
		}

		if($child_well){
			$data->{number_of_doublings} = $well->{number_of_doublings};
			$data->{child_barcode}       = $child_well->barcode;
			$data->{child_plate_name}    = $child_well->plate_name;
            $data->{child_well_name}     = $child_well->name;
            $data->{child_well_accepted} = $child_well->is_accepted;
            $data->{child_well_accepted_str} = ($child_well->is_accepted ? 'Yes' : 'No' );
		}

		push @all_data, $data;
	}

    return \@all_data;
}

1;
