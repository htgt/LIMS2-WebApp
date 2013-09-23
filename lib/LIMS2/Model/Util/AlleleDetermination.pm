package LIMS2::Model::Util::AlleleDetermination;

use strict;
use warnings FATAL => 'all';

use Moose;
use Try::Tiny;
use LIMS2::Exception;
use Parse::BooleanLogic;

use Smart::Comments;

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

has allele_config => (
    is       => 'rw',
    isa      => 'HashRef',
    builder   => '_build_allele_config',
);

has dispatches => (
    is       => 'rw',
    isa      => 'HashRef',
    lazy_build => 1,
);

sub BUILD{
    my ($self) = @_;
    return;
}

sub _build_allele_config {
	my ( $self ) = @_;

	#$self->log->debug( 'Reading configuration from ' . $self->conffile);

	my $conf_parser = Config::Scoped->new (
		file => 'conf/allele_determination.conf',
		warnings => { permissions => 'off' }
	);

	my $allele_config = $conf_parser->parse;

	return $allele_config;
}

sub _build_dispatches {
    my ( $self ) = @_;

	my $dispatches = {
		'is_loacrit_0'                => sub { $self->is_loacrit_0 },
		'is_loacrit_1'                => sub { $self->is_loacrit_1 },
		'is_loacrit_2'                => sub { $self->is_loacrit_2 },
		'is_loatam_0'                 => sub { $self->is_loatam_0 },
		'is_loatam_1'                 => sub { $self->is_loatam_1 },
		'is_loatam_2'                 => sub { $self->is_loatam_2 },
		'is_loadel_0'                 => sub { $self->is_loadel_0 },
		'is_loadel_1'                 => sub { $self->is_loadel_1 },
		'is_loadel_2'                 => sub { $self->is_loadel_2 },
        'is_neo_present'              => sub { $self->is_neo_present },
     	'is_neo_absent'               => sub { $self->is_neo_absent },
        'is_bsd_present'              => sub { $self->is_bsd_present },
        'is_bsd_absent'               => sub { $self->is_bsd_absent },
   		'is_potential_loacrit_0'      => sub { $self->is_potential_loacrit_0 },
		'is_potential_loacrit_1'      => sub { $self->is_potential_loacrit_1 },
		'is_potential_loacrit_2'      => sub { $self->is_potential_loacrit_2 },
		'is_potential_loatam_0'       => sub { $self->is_potential_loatam_0 },
		'is_potential_loatam_1'       => sub { $self->is_potential_loatam_1 },
		'is_potential_loatam_2'       => sub { $self->is_potential_loatam_2 },
		'is_potential_loadel_0'       => sub { $self->is_potential_loadel_0 },
		'is_potential_loadel_1'       => sub { $self->is_potential_loadel_1 },
		'is_potential_loadel_2'       => sub { $self->is_potential_loadel_2 },
	};

	return $dispatches;
}

sub determine_workflow_for_wells {
	my ( $self, $well_ids ) = @_;

    my @fepd_well_ids = ();
    my @sepd_well_ids = ();

    # SQL for selecting the fields for determining workflows differs for EP_PICK and SEP_PICK plate types
    # so need to identify which wells are of which type
    PLATE_TYPE_WELL_LOOP:
    foreach my $well_id ( @{ $well_ids } ) {
        unless ( defined $self->well_genotyping_results->{ $well_id } ) { next PLATE_TYPE_WELL_LOOP; }

    	my $curr_well_plate_type = $self->well_genotyping_results->{ $well_id }->{ 'plate_type' };

        if ( $curr_well_plate_type eq 'EP_PICK' ) {
        	push ( @fepd_well_ids, $well_id );
        }
        elsif ( $curr_well_plate_type eq 'SEP_PICK' ) {
        	push ( @sepd_well_ids, $well_id );
        }
        else {
        	next PLATE_TYPE_WELL_LOOP;
        }
    }

    my $count_fepd_wells = scalar @fepd_well_ids;

    if ( $count_fepd_wells > 0 ) {
		my $sql_query_fepd = $self->create_sql_select_summaries_fep( ( \@fepd_well_ids ) );
        $self->select_workflow_data( \@fepd_well_ids, $sql_query_fepd )
    }

    my $count_sepd_wells = scalar @sepd_well_ids;

    if ( $count_sepd_wells > 0 ) {
		my $sql_query_sepd = $self->create_sql_select_summaries_sep( ( \@sepd_well_ids ) );
        $self->select_workflow_data( \@sepd_well_ids, $sql_query_sepd )
    }

    return;
}

sub select_workflow_data {
    my ( $self, $well_ids, $sql_query ) = @_;

    try {
    	my $sql_results = $self->run_select_query( $sql_query );

  		my $count_results = scalar @$sql_results;

	  	if ( $count_results > 0 ) {
	  		# Calculate and set workflow for each well
	  		# Requires specific fields from summaries table
		  	foreach my $sql_result ( @{ $sql_results } ) {
		  		my $well_id                        = $sql_result->{ 'well_id' };
		  		my $final_pick_recombinase_id      = $sql_result->{ 'final_pick_recombinase_id' };
		        my $final_pick_cassette_resistance = $sql_result->{ 'final_pick_cassette_resistance' };
		        my $ep_well_recombinase_id         = $sql_result->{ 'ep_well_recombinase_id' };

				$self->well_genotyping_results->{ $well_id }->{ 'workflow' } = $self->calculate_workflow_for_well( $well_id, $final_pick_recombinase_id, $final_pick_cassette_resistance, $ep_well_recombinase_id );
			}
		}
	}
	catch {
		my $exception_message = $_;
		LIMS2::Exception::Implementation->throw( "Failed workflow determination select for wells: $exception_message" );
	};

	return;
}

sub calculate_workflow_for_well {
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

	# TOD:remove
	# $genotyping_allele_results

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

    if ( $self->current_well_stage eq 'EP_PICK' ) {
	    # Attempt to find a matching allele type using tight constraints
	    push (@allele_types, 'wt/wt' )    if ( $self->is_allele_test( 'wt_wt' ) );
	    push (@allele_types, 'tm1a/wt' )  if ( $self->is_allele_test( 'tm1a_wt' ) );
	   	push (@allele_types, 'tm1e/wt' )  if ( $self->is_allele_test( 'tm1e_wt' ) );

		return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

		# Failed to find a match, so now retry with looser thresholds
	   	push (@allele_types, 'potential wt/wt' )    if ( $self->is_allele_test( 'potential_wt_wt' ) );
		push (@allele_types, 'potential tm1a/wt' )  if ( $self->is_allele_test( 'potential_tm1a_wt' ) );
		push (@allele_types, 'potential tm1e/wt' )  if ( $self->is_allele_test( 'potential_tm1e_wt' ) );

		return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );
    }
    else {
   	    # Attempt to find a matching allele type using tight constraints
	    push (@allele_types, 'wt/wt' )    if ( $self->is_allele_test( 'wt_wt' ) );
	    push (@allele_types, 'tm1a/wt' )  if ( $self->is_allele_test( 'tm1a_wt' ) );
	   	push (@allele_types, 'tm1e/wt' )  if ( $self->is_allele_test( 'tm1e_wt' ) );

	    push (@allele_types, 'wt/tm1' )   if ( $self->is_allele_test( 'wt_tm1' ) );
	   	push (@allele_types, 'tm1e/tm1' ) if ( $self->is_allele_test( 'tm1e_tm1' ) );
	    push (@allele_types, 'tm1a/tm1' ) if ( $self->is_allele_test( 'tm1a_tm1' ) );

	    push (@allele_types, 'tm1a/wt+bsd_offtarg' ) if ( $self->is_allele_test( 'tm1a_wt_bsd_off_targ' ) );
	    push (@allele_types, 'wt+neo_offtarg/tm1' ) if ( $self->is_allele_test( 'wt_neo_off_targ_tm1' ) );

		return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

		# Failed to find a match, so now retry with looser thresholds
		push (@allele_types, 'potential wt/wt' )    if ( $self->is_allele_test( 'potential_wt_wt' ) );
		push (@allele_types, 'potential tm1a/wt' )  if ( $self->is_allele_test( 'potential_tm1a_wt' ) );
		push (@allele_types, 'potential tm1e/wt' )  if ( $self->is_allele_test( 'potential_tm1e_wt' ) );
		push (@allele_types, 'potential wt/tm1' )   if ( $self->is_allele_test( 'potential_wt_tm1' ) );
		push (@allele_types, 'potential tm1e/tm1' ) if ( $self->is_allele_test( 'potential_tm1e_tm1' ) );
		push (@allele_types, 'potential tm1a/tm1' ) if ( $self->is_allele_test( 'potential_tm1a_tm1' ) );

		return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );
    }

    return 'Failed: unknown allele pattern';
}

sub determine_allele_type_for_well_workflow_Ne1 {
    my ( $self ) = @_;

    my @allele_types;

    if ( $self->current_well_stage eq 'EP_PICK' ) {
	    # Attempt to find a matching allele type using tight constraints
	   	push (@allele_types, 'wt/wt' )    if ( $self->is_allele_test( 'wt_wt' ) );
	   	push (@allele_types, 'tm1/wt' )   if ( $self->is_allele_test( 'tm1_wt' ) );

	    return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

	   	# Failed to find a match, so now retry with looser thresholds
	   	push (@allele_types, 'potential wt/wt' )    if ( $self->is_allele_test( 'potential_wt_wt' ) );
	   	push (@allele_types, 'potential tm1/wt' )   if ( $self->is_allele_test( 'potential_tm1_wt' ) );

		return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );
    }
    else {
	    # Attempt to find a matching allele type using tight constraints
	   	push (@allele_types, 'wt/wt' )    if ( $self->is_allele_test( 'wt_wt' ) );
	   	push (@allele_types, 'tm1/wt' )   if ( $self->is_allele_test( 'tm1_wt' ) );
	   	push (@allele_types, 'tm1/tm1a' ) if ( $self->is_allele_test( 'tm1_tm1a' ) );
	   	push (@allele_types, 'wt/tm1a' )  if ( $self->is_allele_test( 'wt_tm1a' ) );
	   	push (@allele_types, 'tm1/tm1e' ) if ( $self->is_allele_test( 'tm1_tm1e' ) );
	   	push (@allele_types, 'wt/tm1e' )  if ( $self->is_allele_test( 'wt_tm1e' ) );

	   	#TODO: any off target types here?

	    return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

		# Failed to find a match, so now retry with looser thresholds
	   	push (@allele_types, 'potential wt/wt' )    if ( $self->is_allele_test( 'potential_wt_wt' ) );
	   	push (@allele_types, 'potential tm1/wt' )   if ( $self->is_allele_test( 'potential_tm1_wt' ) );
	   	push (@allele_types, 'potential tm1/tm1a' ) if ( $self->is_allele_test( 'potential_tm1_tm1a' ) );
	   	push (@allele_types, 'potential wt/tm1a' )  if ( $self->is_allele_test( 'potential_wt_tm1a' ) );
	   	push (@allele_types, 'potential tm1/tm1e' ) if ( $self->is_allele_test( 'potential_tm1_tm1e' ) );
	   	push (@allele_types, 'potential wt/tm1e' )  if ( $self->is_allele_test( 'potential_wt_tm1e' ) );

		return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );
	}

    return 'Failed: unknown allele pattern';
}

sub determine_allele_type_for_well_workflow_E {
    my ( $self ) = @_;

    my @allele_types;

    if ( $self->current_well_stage eq 'EP_PICK' ) {
	    # Attempt to find a matching allele type using tight constraints
	   	push (@allele_types, 'wt/wt' )    if ( $self->is_allele_test( 'wt_wt' ) );
		push (@allele_types, 'tm1a/wt' )  if ( $self->is_allele_test( 'tm1a_wt' ) );
		push (@allele_types, 'tm1c/wt' )  if ( $self->is_allele_test( 'tm1c_wt' ) );
		push (@allele_types, 'tm1e/wt' )  if ( $self->is_allele_test( 'tm1e_wt' ) );
		push (@allele_types, 'tm1f/wt' )  if ( $self->is_allele_test( 'tm1f_wt' ) );

	    return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

		# Failed to find a match, so now retry with looser thresholds
	   	push (@allele_types, 'potential wt/wt' )    if ( $self->is_allele_test( 'potential_wt_wt' ) );
		push (@allele_types, 'potential tm1a/wt' )  if ( $self->is_allele_test( 'potential_tm1a_wt' ) );
		push (@allele_types, 'potential tm1c/wt' )  if ( $self->is_allele_test( 'potential_tm1c_wt' ) );
		push (@allele_types, 'potential tm1e/wt' )  if ( $self->is_allele_test( 'potential_tm1e_wt' ) );
		push (@allele_types, 'potential tm1f/wt' )  if ( $self->is_allele_test( 'potential_tm1f_wt' ) );

		return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );
    }
    else {
	    # Attempt to find a matching allele type using tight constraints
	   	push (@allele_types, 'wt/wt' )    if ( $self->is_allele_test( 'wt_wt' ) );
		push (@allele_types, 'tm1a/wt' )  if ( $self->is_allele_test( 'tm1a_wt' ) );
		push (@allele_types, 'tm1c/wt' )  if ( $self->is_allele_test( 'tm1c_wt' ) );
		push (@allele_types, 'tm1e/wt' )  if ( $self->is_allele_test( 'tm1e_wt' ) );
		push (@allele_types, 'tm1f/wt' )  if ( $self->is_allele_test( 'tm1f_wt' ) );
	   	push (@allele_types, 'wt/tm1' )   if ( $self->is_allele_test( 'wt_tm1' ) );
		push (@allele_types, 'tm1a/tm1' ) if ( $self->is_allele_test( 'tm1a_tm1' ) );
		push (@allele_types, 'tm1c/tm1' ) if ( $self->is_allele_test( 'tm1c_tm1' ) );
		push (@allele_types, 'tm1e/tm1' ) if ( $self->is_allele_test( 'tm1e_tm1' ) );
		push (@allele_types, 'tm1f/tm1' ) if ( $self->is_allele_test( 'tm1f_tm1' ) );

	   	#TODO: any off target types here?

	    return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );

		# Failed to find a match, so now retry with looser thresholds
	   	push (@allele_types, 'potential wt/wt' )    if ( $self->is_allele_test( 'potential_wt_wt' ) );
		push (@allele_types, 'potential tm1a/wt' )  if ( $self->is_allele_test( 'potential_tm1a_wt' ) );
		push (@allele_types, 'potential tm1c/wt' )  if ( $self->is_allele_test( 'potential_tm1c_wt' ) );
		push (@allele_types, 'potential tm1e/wt' )  if ( $self->is_allele_test( 'potential_tm1e_wt' ) );
		push (@allele_types, 'potential tm1f/wt' )  if ( $self->is_allele_test( 'potential_tm1f_wt' ) );
	   	push (@allele_types, 'potential wt/tm1' )   if ( $self->is_allele_test( 'potential_wt_tm1' ) );
		push (@allele_types, 'potential tm1a/tm1' ) if ( $self->is_allele_test( 'potential_tm1a_tm1' ) );
		push (@allele_types, 'potential tm1c/tm1' ) if ( $self->is_allele_test( 'potential_tm1c_tm1' ) );
		push (@allele_types, 'potential tm1e/tm1' ) if ( $self->is_allele_test( 'potential_tm1e_tm1' ) );
		push (@allele_types, 'potential tm1f/tm1' ) if ( $self->is_allele_test( 'potential_tm1f_tm1' ) );

		return join ( ', ', @allele_types ) if ( scalar @allele_types > 0 );
	}

    return 'Failed: unknown allele pattern';
}

sub is_allele_test {
    my ( $self, $test_name ) = @_;

	# Get the specific logic for this particular workflow and scope into this method:
	my $logic_string = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ $test_name };

	# if ( defined $logic_string ) {
	# 	print "Logic string for workflow " . $self->current_well_workflow . " stage " . $self->current_well_stage . " is " . $test_name . " : " . $logic_string . "\n";
	# }

	LIMS2::Exception->throw( "allele checking: no logic string defined" ) unless ( defined $logic_string );

	# logic string looks like this: 'is_loacrit_1 AND is_loatam_1 AND is_loadel_0 AND is_neo_present AND is_bsd_present'
	# Get the parser to read this, interpret logic and run our coded methods "is_loacrit_1" etc
	my $parser = Parse::BooleanLogic->new();
	my $tree   = $parser->as_array( $logic_string );

	my $callback = sub {
		my $self    = pop;
		my $operand = $_[0]->{ 'operand' };
		my $method  = $self->dispatches->{ $operand };
		return $method->();
	};

	my $result = $parser->solve( $tree, $callback, $self );

	return $result;
}

sub is_loacrit_0 {
    my ( $self ) = @_;

    my $loacrit_0_lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_0_lower_bound' };
	my $loacrit_0_upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_0_upper_bound' };

	return $self->is_assay_copy_number_in_rng( $loacrit_0_lower, $loacrit_0_upper, 'loacrit' );
}

sub is_loacrit_1 {
    my ( $self ) = @_;

    my $loacrit_1_lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_1_lower_bound' };
	my $loacrit_1_upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_1_upper_bound' };

	return $self->is_assay_copy_number_in_rng( $loacrit_1_lower, $loacrit_1_upper, 'loacrit' );
}

sub is_loacrit_2 {
    my ( $self ) = @_;

    my $loacrit_2_lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_2_lower_bound' };
	my $loacrit_2_upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_2_upper_bound' };

	return $self->is_assay_copy_number_in_rng( $loacrit_2_lower, $loacrit_2_upper, 'loacrit' );
}

sub is_loatam_0 {
    my ( $self ) = @_;

    my $loatam_0_lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_0_lower_bound' };
	my $loatam_0_upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_0_upper_bound' };

	return $self->is_assay_copy_number_in_rng( $loatam_0_lower, $loatam_0_upper, 'loatam' );
}

sub is_loatam_1 {
    my ( $self ) = @_;

    my $loatam_1_lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_1_lower_bound' };
	my $loatam_1_upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_1_upper_bound' };

	return $self->is_assay_copy_number_in_rng( $loatam_1_lower, $loatam_1_upper, 'loatam' );
}

sub is_loatam_2 {
    my ( $self ) = @_;

	my $loatam_2_lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_2_lower_bound' };
	my $loatam_2_upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_2_upper_bound' };

	return $self->is_assay_copy_number_in_rng( $loatam_2_lower, $loatam_2_upper, 'loatam' );
}

sub is_loadel_0 {
    my ( $self ) = @_;

    my $loadel_0_lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_0_lower_bound' };
	my $loadel_0_upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_0_upper_bound' };

	return $self->is_assay_copy_number_in_rng( $loadel_0_lower, $loadel_0_upper, 'loadel' );
}

sub is_loadel_1 {
    my ( $self ) = @_;

    my $loadel_1_lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_1_lower_bound' };
	my $loadel_1_upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_1_upper_bound' };

	return $self->is_assay_copy_number_in_rng( $loadel_1_lower, $loadel_1_upper, 'loadel' );
}

sub is_loadel_2 {
    my ( $self ) = @_;

    my $loadel_2_lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_2_lower_bound' };
	my $loadel_2_upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_2_upper_bound' };

	return $self->is_assay_copy_number_in_rng( $loadel_2_lower, $loadel_2_upper, 'loadel' );
}

sub is_potential_loacrit_0 {
    my ( $self ) = @_;

    my $loacrit_0_lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_0_lower_bound_loose' };
	my $loacrit_0_upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_0_upper_bound_loose' };

	return $self->is_assay_copy_number_in_rng( $loacrit_0_lower, $loacrit_0_upper, 'loacrit' );
}

sub is_potential_loacrit_1 {
    my ( $self ) = @_;

    my $loacrit_1_lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_1_lower_bound_loose' };
	my $loacrit_1_upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_1_upper_bound_loose' };

	return $self->is_assay_copy_number_in_rng( $loacrit_1_lower, $loacrit_1_upper, 'loacrit' );
}

sub is_potential_loacrit_2 {
    my ( $self ) = @_;

    my $loacrit_2_lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_2_lower_bound_loose' };
	my $loacrit_2_upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_2_upper_bound_loose' };

	return $self->is_assay_copy_number_in_rng( $loacrit_2_lower, $loacrit_2_upper, 'loacrit' );
}

sub is_potential_loatam_0 {
    my ( $self ) = @_;

    my $loatam_0_lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_0_lower_bound_loose' };
	my $loatam_0_upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_0_upper_bound_loose' };

	return $self->is_assay_copy_number_in_rng( $loatam_0_lower, $loatam_0_upper, 'loatam' );
}

sub is_potential_loatam_1 {
    my ( $self ) = @_;

    my $loatam_1_lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_1_lower_bound_loose' };
	my $loatam_1_upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_1_upper_bound_loose' };

	return $self->is_assay_copy_number_in_rng( $loatam_1_lower, $loatam_1_upper, 'loatam' );
}

sub is_potential_loatam_2 {
    my ( $self ) = @_;

    my $loatam_2_lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_2_lower_bound_loose' };
	my $loatam_2_upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_2_upper_bound_loose' };

	return $self->is_assay_copy_number_in_rng( $loatam_2_lower, $loatam_2_upper, 'loatam' );
}

sub is_potential_loadel_0 {
    my ( $self ) = @_;

    my $loadel_0_lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_0_lower_bound_loose' };
	my $loadel_0_upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_0_upper_bound_loose' };

	return $self->is_assay_copy_number_in_rng( $loadel_0_lower, $loadel_0_upper, 'loadel' );
}

sub is_potential_loadel_1 {
    my ( $self ) = @_;

    my $loadel_1_lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_1_lower_bound_loose' };
	my $loadel_1_upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_1_upper_bound_loose' };

	return $self->is_assay_copy_number_in_rng( $loadel_1_lower, $loadel_1_upper, 'loadel' );
}

sub is_potential_loadel_2 {
    my ( $self ) = @_;

    my $loadel_2_lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_2_lower_bound_loose' };
	my $loadel_2_upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_2_upper_bound_loose' };

	return $self->is_assay_copy_number_in_rng( $loadel_2_lower, $loadel_2_upper, 'loadel' );
}

sub is_neo_present {
    my ( $self ) = @_;

    my $neo_threshold = $self->allele_config->{ 'thresholds' }->{ 'neo_threshold' };

	return $self->is_marker_present( $neo_threshold, 'neo' );
}

sub is_neo_absent {
    my ( $self ) = @_;

    return !$self->is_neo_present();
}

sub is_bsd_present {
    my ( $self ) = @_;

    my $bsd_threshold = $self->allele_config->{ 'thresholds' }->{ 'bsd_threshold' };

	return $self->is_marker_present( $bsd_threshold, 'bsd' );
}

sub is_bsd_absent {
    my ( $self ) = @_;

    return !$self->is_bsd_present();
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

	LIMS2::Exception->throw( "validate assays: no current well set" )          unless $self->current_well_id;
	LIMS2::Exception->throw( "validate assays: no current well workflow set" ) unless $self->current_well_workflow;
	LIMS2::Exception->throw( "validate assays: no current well stage set" )    unless $self->current_well_stage;

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
            	     $self->validate_assay ( 'bsd' )
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

	LIMS2::Exception->throw( "validate assays: workflow and stage combination not found" );
	return 0;
}

# sub validate_assays {
# 	my ( $self ) = @_;

# 	LIMS2::Exception->throw( "validate assays: no current well set" )          unless $self->current_well_id;
# 	LIMS2::Exception->throw( "validate assays: no current well workflow set" ) unless $self->current_well_workflow;
# 	LIMS2::Exception->throw( "validate assays: no current well stage set" )    unless $self->current_well_stage;

# 	my $workflow = $self->current_well_workflow;
# 	my $stage    = $self->current_well_stage;



# 	if( ( $workflow eq 'Ne1a' ) && ( $stage eq 'EP_PICK' ) ) {
#         return ( $self->validate_assay ( 'loacrit' ) &&
#         	     $self->validate_assay ( 'loatam' ) &&
#         	     $self->validate_assay ( 'neo' )
#         );
# 	}


# 	if( ( $workflow eq 'Ne1a' ) && ( $stage eq 'SEP_PICK' ) ) {
# 		return ( $self->validate_assay ( 'loacrit' ) &&
#         	     $self->validate_assay ( 'loatam' ) &&
#         	     $self->validate_assay ( 'loadel' ) &&
#         	     $self->validate_assay ( 'neo' ) &&
#         	     $self->validate_assay ( 'bsd' )
#         );
# 	}


# 	if( ( $workflow eq 'Ne1' ) && ( $stage eq 'EP_PICK' ) ) {
#         return ( $self->validate_assay ( 'loacrit' ) &&
#         	     $self->validate_assay ( 'loadel' ) &&
#         	     $self->validate_assay ( 'bsd' )
#         );
# 	}

# 	if( ( $workflow eq 'Ne1' ) && ( $stage eq 'SEP_PICK' ) ) {
# 		return ( $self->validate_assay ( 'loacrit' ) &&
#         	     $self->validate_assay ( 'loatam' ) &&
#         	     $self->validate_assay ( 'loadel' ) &&
#         	     $self->validate_assay ( 'neo' ) &&
#         	     $self->validate_assay ( 'bsd' )
#         );
# 	}

# 	if( ( $workflow eq 'E' ) && ( $stage eq 'EP_PICK' ) ) {
#         return ( $self->validate_assay ( 'loacrit' ) &&
#         	     $self->validate_assay ( 'loatam' ) &&
#         	     $self->validate_assay ( 'neo' )
#         );
# 	}

# 	if( ( $workflow eq 'E' ) && ( $stage eq 'SEP_PICK' ) ) {
# 		return ( $self->validate_assay ( 'loacrit' ) &&
#         	     $self->validate_assay ( 'loatam' ) &&
#         	     $self->validate_assay ( 'loadel' ) &&
#         	     $self->validate_assay ( 'neo' ) &&
#         	     $self->validate_assay ( 'bsd' )
#         );
# 	}

# 	LIMS2::Exception->throw( "validate assays: workflow and stage combination not found" );
#   return 0;
# }

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
