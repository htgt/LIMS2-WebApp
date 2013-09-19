package LIMS2::Model::Util::AlleleDetermination;

use strict;
use warnings FATAL => 'all';

use Moose;
use Try::Tiny;
use LIMS2::Exception;

# hashref of well gentoyping results keyed by well_id
has well_genotyping_results => (
    is         => 'rw',
    isa        => 'HashRef',
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
);

has current_well_id => (
    is       => 'rw',
    isa      => 'Int',
    required => 0,
);

has current_well_workflow => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has current_well_stage => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

sub BUILD{
    my ( $self ) = @_;

    #TODO: anything on construction?

    return;
}

sub determine_workflow_for_wells {
	my ( $self, $well_ids ) = @_;

    WELL_LOOP:
    foreach my $well_id ( @{ $well_ids } ) {
        unless ( defined $self->well_genotyping_results->{ $well_id } ) { next WELL_LOOP; }

    	my $curr_well_plate_type = $self->well_genotyping_results->{ $well_id }->{ 'plate_type' };

        unless ( ( $curr_well_plate_type eq 'EP_PICK' ) || ( $curr_well_plate_type eq 'SEP_PICK' ) ) { next; }

		my $sql_results;
		#TODO: add try catch
		# for first well we get to with a plate type, we are assuming all wells in list have same plate type
	    if ( $curr_well_plate_type eq 'EP_PICK' ) {
	        my $sql_query = $self->create_sql_select_summaries_fep( ( $well_ids ) );
	        $sql_results = $self->run_select_query( $sql_query );
		}
		elsif ( $curr_well_plate_type eq 'SEP_PICK' ) {
	        my $sql_query = $self->create_sql_select_summaries_sep( ( $well_ids ) );
	        $sql_results = $self->run_select_query( $sql_query );
	  	}

	  	my $count_rows = scalar @$sql_results;

	  	if ( $count_rows == 0 ) {
	  		# cannot determine workflow type
	  		next WELL_LOOP;
	  	}
	  	else {
		  	foreach my $sql_result ( @{ $sql_results } ) {
		  		my $well_id                        = $sql_result->{ 'well_id' };
		  		my $final_pick_recombinase_id      = $sql_result->{ 'final_pick_recombinase_id' };
		        my $final_pick_cassette_resistance = $sql_result->{ 'final_pick_cassette_resistance' };
		        my $ep_well_recombinase_id         = $sql_result->{ 'ep_well_recombinase_id' };

				$self->well_genotyping_results->{ $well_id }->{ 'workflow' } = $self->get_workflow( $well_id, $final_pick_recombinase_id, $final_pick_cassette_resistance, $ep_well_recombinase_id );
			}

			last WELL_LOOP;
		}
    }

    return;
}

sub get_workflow {
    my ( $self, $well_id, $final_pick_recombinase_id, $final_pick_cassette_resistance, $ep_well_recombinase_id ) = @_;

    my $workflow = 'unknown';

	# For the non-essential pathway they apply Cre to the vector to remove the critical region in the bsd cassette
	if ( $final_pick_recombinase_id eq 'Cre' ) {
		if ( $final_pick_cassette_resistance eq 'bsd' ) {
	        # Means standard workflow for non-essential genes using Bsd cassette first
	        $workflow = 'Ne1'; # Non-essential Bsd first
		}
	}
	else {
    	# For the essential pathway they apply Flp to remove the neo cassette after the first electroporation
		if ( $ep_well_recombinase_id eq 'Flp' ) {
		    if ( $final_pick_cassette_resistance eq 'neo' ) {
			    $workflow = 'E'; # Essential genes workflow
		    }
		}
		else {
			if ( $final_pick_cassette_resistance eq 'neo' ) {
			    # Means alternate workflow for non-essential genes using Neo cassette first      
			    $workflow = 'Ne1a'; # Non-essential Neo first
			}
		}
	}

	return $workflow;
}

sub determine_allele_types_for_wells {
    my ( $self, $well_ids ) = @_;

	# fetch genotyping qc results for list of well ids
	my @gc_results = $self->model->get_genotyping_qc_well_data( \@{ $well_ids }, 'dummy', $self->species );

	# create a hash keyed on well id copying results across from array returned from genotyping qc
	$self->well_genotyping_results ( {} );
	foreach my $well_gc_result( @gc_results ){
		$self->well_genotyping_results->{ $well_gc_result->{ 'id' } } = $well_gc_result;
	}

	# TODO: get workflow calculation into summaries generation
	$self->determine_workflow_for_wells( $well_ids );

    return $self->determine_allele_types_for_wells_with_data( $well_ids );
}

sub determine_allele_types_for_wells_with_data {
    my ( $self, $well_ids ) = @_;

	my $genotyping_allele_results = {};

	foreach my $well_id ( @{ $well_ids } ) {

		$self->current_well_id ( $well_id );

		my $current_allele_type;

		# attempt tp determine the allele type for this well and add the result into the output hashref
		try {
			$current_allele_type = $self->determine_allele_type_for_well();
		}
		catch {
			my $exception_message = $_;
			$current_allele_type = "Failed allele determination for $well_id: $exception_message";
        };

        $genotyping_allele_results->{ $well_id } = $current_allele_type;
	}

	return $genotyping_allele_results;
}

sub determine_allele_type_for_well {
	my ( $self ) = @_;

	unless ( defined $self->current_well_id ) {
		return 'Failed: no current well set';
	}

    unless ( defined $self->well_genotyping_results->{ $self->current_well_id } ) {
        return 'Failed: no hash entry for well ' . $self->current_well_id;
    }

    unless ( defined $self->well_genotyping_results->{ $self->current_well_id }->{ 'plate_type' } ) {
	    return 'Failed: plate type not present for well ' . $self->current_well_id;
	}

    $self->current_well_stage ( $self->well_genotyping_results->{ $self->current_well_id }->{ 'plate_type' } );
	unless ( ( $self->current_well_stage eq 'EP_PICK' ) || ( $self->current_well_stage eq 'SEP_PICK' ) ) {
		return 'Failed: stage type must be EP_PICK or SEP_PICK, found type ' . $self->current_well_stage . ' for well ' . $self->current_well_id;
	}

	unless ( defined $self->well_genotyping_results->{ $self->current_well_id }->{ 'workflow' } ) {
	    return 'Failed: workflow not present for well ' . $self->current_well_id;
	}

    $self->current_well_workflow ( $self->well_genotyping_results->{ $self->current_well_id }->{ 'workflow' } );

    unless ( $self->validate_assays() ) {
    	return 'Failed: validate assays';
    }

    if ( $self->current_well_workflow eq 'Ne1a' ) {
	   	return $self->determine_allele_type_for_well_workflow_Ne1a();
	}
	elsif ( $self->current_well_workflow eq 'Ne1' ) {
        return $self->determine_allele_type_for_well_workflow_Ne1();
	}
	elsif ( $self->current_well_workflow eq 'E' ) {
	   	return $self->determine_allele_type_for_well_workflow_E();
	}
	else {
		return 'Failed: unrecognised workflow type ' . $self->current_well_workflow . ' for well ' . $self->current_well_id;
	}

}

sub determine_allele_type_for_well_workflow_Ne1a {
    my ( $self ) = @_;

    my @allele_types;

    # Attempt to find a matching allele type using tight constraints
    push (@allele_types, 'wt/wt' )    if ( $self->is_wt_wt() );
    push (@allele_types, 'tm1a/wt' )  if ( $self->is_tm1a_wt() );
   	push (@allele_types, 'tm1e/wt' )  if ( $self->is_tm1e_wt() );
    push (@allele_types, 'wt/tm1' )   if ( $self->is_wt_tm1() );
   	push (@allele_types, 'tm1e/tm1' ) if ( $self->is_tm1e_tm1() );
    push (@allele_types, 'tm1a/tm1' ) if ( $self->is_tm1a_tm1() );

    push (@allele_types, 'tm1a/wt+bsd_offtarg' ) if ( $self->is_tm1a_wt_bsd_off_targ() );
    push (@allele_types, 'wt+neo_offtarg/tm1' ) if ( $self->is_wt_neo_off_targ_tm1() );

	return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

	# Failed to find a match, so now retry with looser thresholds
	push (@allele_types, 'potential wt/wt' )    if ( $self->is_potential_wt_wt() );
	push (@allele_types, 'potential tm1a/wt' )  if ( $self->is_potential_tm1a_wt() );
	push (@allele_types, 'potential tm1e/wt' )  if ( $self->is_potential_tm1e_wt() );
	push (@allele_types, 'potential wt/tm1' )   if ( $self->is_potential_wt_tm1() );
	push (@allele_types, 'potential tm1e/tm1' ) if ( $self->is_potential_tm1e_tm1() );
	push (@allele_types, 'potential tm1a/tm1' ) if ( $self->is_potential_tm1a_tm1() );

	return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

    return 'Failed: unknown allele pattern';
}

sub determine_allele_type_for_well_workflow_Ne1 {
    my ( $self ) = @_;

    my @allele_types;

    # Attempt to find a matching allele type using tight constraints
   	push (@allele_types, 'wt/wt' )    if ( $self->is_wt_wt() );
   	push (@allele_types, 'tm1/wt' )   if ( $self->is_tm1_wt() );
   	push (@allele_types, 'tm1/tm1a' ) if ( $self->is_tm1_tm1a() );
   	push (@allele_types, 'wt/tm1a' )  if ( $self->is_wt_tm1a() );
   	push (@allele_types, 'tm1/tm1e' ) if ( $self->is_tm1_tm1e() );
   	push (@allele_types, 'wt/tm1e' )  if ( $self->is_wt_tm1e() );

   	#TODO: any off target types here?

    return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

	# Failed to find a match, so now retry with looser thresholds
   	push (@allele_types, 'potential wt/wt' )    if ( $self->is_potential_wt_wt() );
   	push (@allele_types, 'potential tm1/wt' )   if ( $self->is_potential_tm1_wt() );
   	push (@allele_types, 'potential tm1/tm1a' ) if ( $self->is_potential_tm1_tm1a() );
   	push (@allele_types, 'potential wt/tm1a' )  if ( $self->is_potential_wt_tm1a() );
   	push (@allele_types, 'potential tm1/tm1e' ) if ( $self->is_potential_tm1_tm1e() );
   	push (@allele_types, 'potential wt/tm1e' )  if ( $self->is_potential_wt_tm1e() );

	return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

    return 'Failed: unknown allele pattern';
}

sub determine_allele_type_for_well_workflow_E {
    my ( $self ) = @_;

    my @allele_types;

    # Attempt to find a matching allele type using tight constraints
   	push (@allele_types, 'wt/wt' )    if ( $self->is_wt_wt() );
	push (@allele_types, 'tm1a/wt' )  if ( $self->is_tm1a_wt() );
	push (@allele_types, 'tm1c/wt' )  if ( $self->is_tm1c_wt() );
	push (@allele_types, 'tm1e/wt' )  if ( $self->is_tm1e_wt() );
	push (@allele_types, 'tm1f/wt' )  if ( $self->is_tm1f_wt() );
   	push (@allele_types, 'wt/tm1' )   if ( $self->is_wt_tm1() );
	push (@allele_types, 'tm1a/tm1' ) if ( $self->is_tm1a_tm1() );
	push (@allele_types, 'tm1c/tm1' ) if ( $self->is_tm1c_tm1() );
	push (@allele_types, 'tm1e/tm1' ) if ( $self->is_tm1e_tm1() );
	push (@allele_types, 'tm1f/tm1' ) if ( $self->is_tm1f_tm1() );

   	#TODO: any off target types here?

    return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

	# Failed to find a match, so now retry with looser thresholds
   	push (@allele_types, 'potential wt/wt' )    if ( $self->is_potential_wt_wt() );
	push (@allele_types, 'potential tm1a/wt' )  if ( $self->is_potential_tm1a_wt() );
	push (@allele_types, 'potential tm1c/wt' )  if ( $self->is_potential_tm1c_wt() );
	push (@allele_types, 'potential tm1e/wt' )  if ( $self->is_potential_tm1e_wt() );
	push (@allele_types, 'potential tm1f/wt' )  if ( $self->is_potential_tm1f_wt() );
   	push (@allele_types, 'potential wt/tm1' )   if ( $self->is_potential_wt_tm1() );
	push (@allele_types, 'potential tm1a/tm1' ) if ( $self->is_potential_tm1a_tm1() );
	push (@allele_types, 'potential tm1c/tm1' ) if ( $self->is_potential_tm1c_tm1() );
	push (@allele_types, 'potential tm1e/tm1' ) if ( $self->is_potential_tm1e_tm1() );
	push (@allele_types, 'potential tm1f/tm1' ) if ( $self->is_potential_tm1f_tm1() );

	return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

    return 'Failed: unknown allele pattern';
}

sub is_wt_wt {
    my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                !$self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'Ne1' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.6, 3.4, 'en2-int' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.6, 3.4, 'en2-int' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'E' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                !$self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1a_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'E' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1e_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                $self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
    elsif( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                $self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_wt_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1e_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
    elsif( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1a_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
    elsif( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1a_wt_bsd_off_targ {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_wt_neo_off_targ_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.6, 3.4, 'en2-int' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.6, 3.4, 'en2-int' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1_tm1a {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.6, 3.4, 'en2-int' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_wt_tm1a {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.6, 3.4, 'en2-int' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1_tm1e {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.6, 3.4, 'en2-int' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_wt_tm1e {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.6, 3.4, 'en2-int' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1c_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                !$self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1f_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                !$self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.6, 2.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1c_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_tm1f_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.6, 1.4, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.4, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_wt_wt {
    my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                !$self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'Ne1' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.3, 3.7, 'en2-int' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.3, 3.7, 'en2-int' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'E' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                !$self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1a_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'Ne1' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.3, 3.7, 'en2-int' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.3, 3.7, 'en2-int' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'E' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			#TODO: what tests to check here?
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1e_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' )  &&
                $self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
    elsif( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                $self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_wt_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1' ) {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1e_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
	elsif( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1a_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}
    if( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loadel' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1_tm1a {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.3, 3.7, 'en2-int' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_wt_tm1a {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.3, 3.7, 'en2-int' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1_tm1e {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.3, 3.7, 'en2-int' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_wt_tm1e {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'Ne1') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                $self->is_assay_copy_number_in_rng( 2.3, 3.7, 'en2-int' ) &&
                $self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1c_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                !$self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1f_wt {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
			return (
				$self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
				$self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                !$self->is_marker_present( 0.3, 'neo' )
			);
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 1.3, 2.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                !$self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1c_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_potential_tm1f_tm1 {
	my ( $self ) = @_;

    if( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'SEP_PICK' ) {
			return (
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loacrit' ) &&
                $self->is_assay_copy_number_in_rng( 0.3, 1.7, 'loatam' ) &&
                $self->is_assay_copy_number_in_rng( 0.0, 0.7, 'loadel' ) &&
                !$self->is_marker_present( 0.3, 'neo' ) &&
                $self->is_marker_present( 0.5, 'bsd' )
			);
		}
	}

	return 0;
}

sub is_assay_copy_number_in_rng {
    my ( $self, $min, $max, $assay_name ) = @_;

    my $value = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#copy_number' };

    if ( defined $value && $value ne '-' ) {
        return $self->is_value_in_range ( $min, $max, $value );
    }
    else {
        return 0;
    }
}

sub is_marker_present {
    my ( $self, $threshold, $marker ) = @_;

    my $value = $self->well_genotyping_results->{ $self->current_well_id }->{ $marker . '#copy_number' };

    if ( ( defined $value ) && ( $value ne '-' ) && ( $value >= $threshold ) ) {
    	return 1;
    }
    else {
    	return 0;
    }
}

sub is_value_in_range {
	my ( $self, $min, $max, $value ) = @_;

    if ( ( $value >= $min ) && ( $value <= $max ) ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub validate_assays {
	my ( $self ) = @_;

	LIMS2::Exception->throw( "validate assays: no current well set" ) unless $self->current_well_id;

	if( $self->current_well_workflow eq 'Ne1a') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
            return ( $self->validate_assay ( 'loacrit' ) &&
            	     $self->validate_assay ( 'loatam' ) &&
            	     $self->validate_assay ( 'neo' )
            );
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return ( $self->validate_assay ( 'loacrit' ) &&
            	     $self->validate_assay ( 'loatam' ) &&
            	     $self->validate_assay ( 'loadel' ) &&
            	     $self->validate_assay ( 'neo' ) &&
            	     $self->validate_assay ( 'bsd' )
            );
		}
	}
	elsif( $self->current_well_workflow eq 'Ne1') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
            return ( $self->validate_assay ( 'loacrit' ) &&
            	     $self->validate_assay ( 'loadel' ) &&
            	     $self->validate_assay ( 'en2-int' )
            );
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return ( $self->validate_assay ( 'loacrit' ) &&
            	     $self->validate_assay ( 'loatam' ) &&
            	     $self->validate_assay ( 'loadel' ) &&
            	     $self->validate_assay ( 'en2-int' ) &&
            	     $self->validate_assay ( 'neo' ) &&
            	     $self->validate_assay ( 'bsd' )
            );
		}
	}
	elsif( $self->current_well_workflow eq 'E') {
		if ( $self->current_well_stage eq 'EP_PICK' ) {
            return ( $self->validate_assay ( 'loacrit' ) &&
            	     $self->validate_assay ( 'loatam' ) &&
            	     $self->validate_assay ( 'neo' )
            );
		}
		elsif ( $self->current_well_stage eq 'SEP_PICK' ) {
			return ( $self->validate_assay ( 'loacrit' ) &&
            	     $self->validate_assay ( 'loatam' ) &&
            	     $self->validate_assay ( 'loadel' ) &&
            	     $self->validate_assay ( 'neo' ) &&
            	     $self->validate_assay ( 'bsd' )
            );
		}
	}

	return 1;
}

sub validate_assay {
	my ( $self, $assay_name ) = @_;

	my $cn = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#copy_number' };
	my $cnr = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#copy_number_range' };
	#TODO: add checks on confidence and vic
	#my $conf = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#confidence' };
	#my $vic = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#vic' };

    unless ( defined $cn && $cn ne '-' ) {
    	LIMS2::Exception->throw( "$assay_name assay validation: Copy Number not present" );
	}

	unless ( defined $cnr && $cnr ne '-' ) {
		LIMS2::Exception->throw( "$assay_name assay validation: Copy Number Range not present" );
	}

	unless ( $cnr <= 0.4 ) {
		LIMS2::Exception->throw( "$assay_name assay validation: Copy Number Range above threshold" );
	}

	# TODO: add validations for confidence and vic

	return 1;
}

# Generic method to run select SQL
sub run_select_query {
   my ( $self, $sql_query ) = @_;

   my $sql_result = $self->model->schema->storage->dbh_do(
      sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare( $sql_query );
         $sth->execute or die "Unable to execute query: $dbh->errstr\n";
         $sth->fetchall_arrayref({

         });
      }
    );

    return $sql_result;
}

sub create_sql_select_summaries_fep {
    my ( $self, $well_ids ) = @_;
    # create a comma separated list for SQL
    $well_ids = join q{,}, @{ $well_ids };

my $sql_query =  <<"SQL_END";
select distinct ep_pick_well_id as well_id, final_pick_recombinase_id, final_pick_cassette_resistance, ep_well_recombinase_id
from summaries
where ep_pick_well_id IN ($well_ids)
SQL_END

    return $sql_query;
}

sub create_sql_select_summaries_sep {
    my ( $self, $well_ids ) = @_;

    # create a comma separated list for SQL
    $well_ids = join q{,}, @{ $well_ids };

my $sql_query =  <<"SQL_END";
select distinct sep_pick_well_id as well_id, final_pick_recombinase_id, final_pick_cassette_resistance, ep_well_recombinase_id
from summaries
where sep_pick_well_id IN ($well_ids)
and ep_pick_well_id > 0
SQL_END

    return $sql_query;
}

1;

__END__
