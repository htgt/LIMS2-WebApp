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

has current_well_validation_msg => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has allele_config => (
    is       => 'rw',
    isa      => 'HashRef',
    builder   => '_build_allele_config',
);

has assay_dispatches => (
    is       => 'rw',
    isa      => 'HashRef',
    lazy_build => 1,
);

has validation_dispatches => (
    is       => 'rw',
    isa      => 'HashRef',
    lazy_build => 1,
);

has allele_translation => (
    is       => 'rw',
    isa      => 'HashRef',
    builder  => '_build_allele_translation',
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

sub _build_assay_dispatches {
    my ( $self ) = @_;

	my $assay_dispatches = {
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

	return $assay_dispatches;
}

sub _build_validation_dispatches {
    my ( $self ) = @_;

	my $validation_dispatches = {
		'loacrit'    => sub { $self->validate_assay( 'loacrit' ) },
		'loatam'     => sub { $self->validate_assay( 'loatam' ) },
		'loadel'     => sub { $self->validate_assay( 'loadel' ) },
		'neo'        => sub { $self->validate_assay( 'neo' ) },
		'bsd'        => sub { $self->validate_assay( 'bsd' ) },
	};

	return $validation_dispatches;
}

sub _build_allele_translation {
	my ( $self ) = @_;

	my $allele_translation = $self->allele_config->{ 'allele_translation' };

	return $allele_translation;
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

		  		# NB $self->current_well_id not set yet
		  		my $well_id                        = $sql_result->{ 'well_id' };
		  		my $final_pick_recombinase_id      = $sql_result->{ 'final_pick_recombinase_id' };
		        my $final_pick_cassette_resistance = $sql_result->{ 'final_pick_cassette_resistance' };
		        my $ep_well_recombinase_id         = $sql_result->{ 'ep_well_recombinase_id' };

	            # store fields in main hash (or blank if not set)
		        $self->well_genotyping_results->{ $well_id }->{ 'final_pick_recombinase_id' }      = $sql_result->{ 'final_pick_recombinase_id' } // '';
		        $self->well_genotyping_results->{ $well_id }->{ 'final_pick_cassette_resistance' } = $sql_result->{ 'final_pick_cassette_resistance' } // '';
		        $self->well_genotyping_results->{ $well_id }->{ 'ep_well_recombinase_id' }         = $sql_result->{ 'ep_well_recombinase_id' } // '';

	            # calculate workflow for well
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

 #    print "well id : " . $well_id . "\n" if ( defined $well_id );
 #    print "final_pick_recombinase_id : " . $final_pick_recombinase_id . "\n" if ( defined $final_pick_recombinase_id );
 #    print "final_pick_cassette_resistance : " . $final_pick_cassette_resistance . "\n" if ( defined $final_pick_cassette_resistance );
	# print "ep_well_recombinase_id : " . $ep_well_recombinase_id . "\n" if ( defined $ep_well_recombinase_id );

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
			$current_allele_type = "Failed allele determination, Exception: $exception_message";
        };

        # store message in main hash
		$self->well_genotyping_results->{ $self->current_well_id }->{ 'allele_determination' } = $current_allele_type;

		# add result to minimal well / result hash
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

    $self->current_well_validation_msg ( '' );
    unless ( $self->validate_assays() ) {
    	return 'Failed: validate assays : ' . $self->current_well_validation_msg;
    }

	my @allele_types;

	# Attempt to find a matching allele type using normal constraints
   	my $normal_assays = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ 'normal' };

   	foreach my $normal_key ( keys %{ $normal_assays } ) {
   		push ( @allele_types, ( $self->allele_translation->{ $normal_key } ) )    if ( $self->is_allele_test( 'normal', $normal_key ) );
   	}

	return join ( '; ', ( sort @allele_types ) ) if ( scalar @allele_types > 0 );

	# Failed to find a match, so now retry with looser thresholds
	my $loose_assays = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ 'loose' };

 	foreach my $loose_key ( keys %{ $loose_assays } ) {
   		push ( @allele_types, ( $self->allele_translation->{ $loose_key } ) )   if ( $self->is_allele_test( 'loose', $loose_key ) );
   	}

   	if ( scalar @allele_types > 0 ) {
		return join ( '; ', ( sort @allele_types ) );
	}
	else {
		my @pattern;
		# pull out the assay values for display
		foreach my $assay_name ( 'bsd','loacrit','loadel','loatam','neo' ) {
			push ( @pattern, ( $assay_name . "=" . ( $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#copy_number' } // '-' ) ) );
		}
		my $pattern_string = join ( ' ', ( @pattern ) );
    	return 'Failed: unknown allele pattern : ' . $self->current_well_workflow . " " . $self->current_well_stage . " " . $pattern_string;
	}
}

sub is_allele_test {
    my ( $self, $range_type, $test_name ) = @_;

	# Get the specific logic for this particular workflow and scope into this method:
	my $logic_string = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ $range_type }->{ $test_name };

	# if ( defined $logic_string ) {
	# 	print "Logic string for workflow = " . $self->current_well_workflow . ", stage = " . $self->current_well_stage . ", range type = " . $range_type . ", test = " . $test_name . " : " . $logic_string . "\n";
	# }

	LIMS2::Exception->throw( "allele checking: no logic string defined" ) unless ( defined $logic_string );

	# logic string looks like this: 'is_loacrit_1 AND is_loatam_1 AND is_loadel_0 AND is_neo_present AND is_bsd_present'
	# Get the parser to read this, interpret logic and run our coded methods "is_loacrit_1" etc
	my $parser = Parse::BooleanLogic->new();
	my $tree   = $parser->as_array( $logic_string );

	my $callback = sub {
		my $self    = pop;
		my $operand = $_[0]->{ 'operand' };
		my $method  = $self->assay_dispatches->{ $operand };
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

	# Get the specific logic for this particular workflow and scope into this method:
	my $validation_logic_string = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ 'validation' }->{ 'assays' };

	 # if ( defined $validation_logic_string ) {
	 # 	print "Logic string for validation " . $self->current_well_workflow . " stage " . $self->current_well_stage . " : " . $validation_logic_string . "\n";
	 # }

	LIMS2::Exception->throw( "validation: no logic string defined" ) unless ( defined $validation_logic_string );

	# logic string looks like this: 'loacrit AND loatam AND neo'
	# Get the parser to read this, interpret logic and run correct validate assay methods
	my $parser = Parse::BooleanLogic->new();
	my $tree   = $parser->as_array( $validation_logic_string );

	my $callback = sub {
		my $self    = pop;
		my $operand = $_[0]->{ 'operand' };
		my $method  = $self->validation_dispatches->{ $operand };
		return $method->();
	};

	my $result = $parser->solve( $tree, $callback, $self );

	return $result;
}

sub validate_assay {
	my ( $self, $assay_name ) = @_;

	# print "validating assay : $assay_name\n";

	my $cn = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#copy_number' };
	my $cnr = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#copy_number_range' };
	#TODO: add checks on confidence and vic
	#my $conf = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#confidence' };
	#my $vic = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#vic' };

    unless ( defined $cn && $cn ne '-' ) {
    	# LIMS2::Exception->throw( "$assay_name assay validation: Copy Number not present" );
    	$self->current_well_validation_msg ( $self->current_well_validation_msg . "$assay_name assay validation: Copy Number not present. " );
    	return 0;
	}

	unless ( defined $cnr && $cnr ne '-' ) {
		# LIMS2::Exception->throw( "$assay_name assay validation: Copy Number Range not present" );
		$self->current_well_validation_msg ( $self->current_well_validation_msg . "$assay_name assay validation: Copy Number Range not present. " );
    	return 0;
	}

	unless ( $cnr <= 0.4 ) {
		# LIMS2::Exception->throw( "$assay_name assay validation: Copy Number Range above threshold" );
		$self->current_well_validation_msg ( $self->current_well_validation_msg . "$assay_name assay validation: Copy Number Range above threshold. " );
    	return 0;
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
