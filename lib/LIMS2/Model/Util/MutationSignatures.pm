package LIMS2::Model::Util::MutationSignatures;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::MutationSignatures::VERSION = '0.333';
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
	my ($model) = @_;

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
	foreach my $process (@processes){
		DEBUG "Generating information for process ".$process->id;
		my ($parent_well) = $process->input_wells;
		push @parent_well_ids, $parent_well->id;
		my ($child_well) = $process->output_wells;

		my $state = $parent_well->well_barcode->barcode_state->id;
		my $data = {
			parent_well_id    => $parent_well->id,
			parent_barcode    => $parent_well->well_barcode->barcode,
			state             => $state,
			oxygen_condition  => $process->get_parameter_value('oxygen_condition'),
		};

        # There should always be a doubling start event
		my $doubling_start = $parent_well->well_barcode->most_recent_event("doubling_in_progress");
		if($doubling_start){
            $data->{doubling_start} = $doubling_start->created_at;
		}

		if($child_well){
			$data->{number_of_doublings} = $process->get_parameter_value('doublings');
			$data->{child_barcode}       = ( $child_well->well_barcode ? $child_well->well_barcode->barcode : undef );
			$data->{child_plate_name}    = $child_well->plate->name;
            $data->{child_well_name}     = $child_well->name;
            $data->{child_well_accepted} = $child_well->is_accepted;
            $data->{child_well_accepted_str} = ($child_well->is_accepted ? 'Yes' : 'No' );
		}

		push @all_data, $data;
	}

    return \@all_data;
}

1;