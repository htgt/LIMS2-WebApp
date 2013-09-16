package LIMS2::Model::Util::AlleleDetermination;

use strict;
use warnings FATAL => 'all';

use Moose;
use Smart::Comments;

has well_genotyping_results => (
    is         => 'rw',
    isa        => 'HashRef',
);

has workflow => (
    is       => 'rw',
    isa      => 'Str',
);

has stage => (
    is       => 'rw',
    isa      => 'Str',
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has well => (
    is       => 'ro',
    isa      => 'LIMS2::Model::Schema::Result::Well',
    required => 1,
);

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
);

sub BUILD{
    my ($self) = @_;

    #$self->validate_config;

    return;
}

sub get_well_id {
    my ($self) = @_;

    if ( defined $self->well ) {
        return $self->well->id;
    }

    return;
}

sub determine_stage {
    my ($self) = @_;

    if ( defined $self->well ) {
    	$self->stage( $self->well->plate->type_id );
    }

    return;
}

sub determine_workflow {
	my ($self) = @_;
	# well plate type must be EP_PICK or SEP_PICK

	unless ( defined $self->stage ) {
	    return;
	}

	unless ( ( $self->stage eq 'EP_PICK' ) || ( $self->stage eq 'SEP_PICK' ) ) {
		return;
	}

	#my @ep_pick_types = ( "EP_PICK", "XEP", "FP" );
	#my @sep_pick_types = ( "SEP", "SEP_PICK", "SFP", "FP", "PIQ" );

	#if ( $self->stage ~~ @ep_pick_types ) {
    my $sql_results;
    if ( $self->stage eq 'EP_PICK' ) {
        my $sql_query = $self->create_sql_select_summaries_fep( $self->well->id );
        $sql_results = $self->run_select_query( $sql_query );
	}
	#elsif ( $self->stage ~~ @sep_pick_types ) {
	elsif ( $self->stage eq 'SEP_PICK' ) {
        my $sql_query = $self->create_sql_select_summaries_sep( $self->well->id );
        $sql_results = $self->run_select_query( $sql_query );
  	}

  	my $count_rows = scalar @$sql_results;

  	if ( $count_rows == 0 ) {
  		# cannot determine workflow type
  		return;
  	}

    # query will return 1 row (or zero if nothing on summaries table)
    my $final_pick_recombinase_id      = @$sql_results[0]->{ 'final_pick_recombinase_id' };
    my $final_pick_cassette_resistance = @$sql_results[0]->{ 'final_pick_cassette_resistance' };

	if ( $final_pick_recombinase_id eq 'Flp' ) {
	    if ( $final_pick_cassette_resistance eq 'neo' ) {
		    # Means Dox has been applied causing excision from Flp sites
		    $self->workflow ( 'E' ); # Essential genes workflow
		    return;
	    }
	}
	else {
		if ( $final_pick_cassette_resistance eq 'bsd' ) {
	        # Means standard workflow for non-essential genes using Bsd cassette first
	        $self->workflow ( 'Ne1' ); # Non-essential Bsd first
	        return;
		}
		elsif ( $final_pick_cassette_resistance = 'neo' ) {            
		    # Means alternate workflow for non-essential genes using Neo cassette first      
		    $self->workflow ( 'Ne1a' ); # Non-essential Neo first
		    return
		}
	}

    # Unknown workflow type
	$self->workflow ( 'Unknown' );
	return;
}

sub get_genotyping_qc_data_for_well {
    my ($self) = @_;

    unless ( defined $self->well ) {    	
    	return;
    }

	my $plate_name = $self->well->plate->name;

	my $species    = 'Mouse';
	# TODO: assumption here that this method only handles one well
	my @well_list = ( $self->well->id );

	my @gqc_results = $self->model->get_genotyping_qc_well_data( \@well_list, $plate_name, $species );
	my @gqc_results_minimised;

	my %gqc_results_minimised_template = (
	    id => '',
	    plate_name => '',
	    well => '',
	    'loacrit#confidence'        => '-',
	    'loacrit#copy_number'       => '-',
	    'loacrit#copy_number_range' => '-',
	    'loadel#confidence'         => '-',
	    'loadel#copy_number'        => '-',
	    'loadel#copy_number_range'  => '-',
	    'loatam#confidence'         => '-',
	    'loatam#copy_number'        => '-',
	    'loatam#copy_number_range'  => '-',
	    'neo#confidence'            => '-',
	    'neo#copy_number'           => '-',
	    'neo#copy_number_range'     => '-',
	    'bsd#confidence'            => '-',
	    'bsd#copy_number'           => '-',
	    'bsd#copy_number_range'     => '-',
	);

	foreach my $gqc_well_data ( @gqc_results ) {
	    # copy template hash
	    my %gqc_well_data_hash = %gqc_results_minimised_template;

	    # dereference well data hash
	    my %gqc_well_data = %{ $gqc_well_data };

	    # copy values across from well hash to new minimised hash
	    @gqc_well_data_hash{ keys %gqc_well_data_hash } = @gqc_well_data { keys %gqc_well_data_hash };

	    # add new well hash into new array
	    push @gqc_results_minimised, \%gqc_well_data_hash;
	}

    #TODO: assumption here that this method only handles one well
	$self->well_genotyping_results( $gqc_results_minimised[0] );

	return;
}

sub determine_allele_type_for_well {
    my ( $self ) = @_;

    unless ( defined $self->well ) {    	
        return 'failed: well';
    }

    unless ( defined $self->stage ) {
	    return 'failed: stage';
	}

	unless ( ( $self->stage eq 'EP_PICK' ) || ( $self->stage eq 'SEP_PICK' ) ) {
		return 'failed: stage type';
	}

	unless ( defined $self->well_genotyping_results ) {
		return 'failed: fetch genotyping';
	}

    unless ( $self->validate_assays() ) {
    	return 'failed: validate assays';
    }

    my @allele_types;
	my $allele_type;

   	push (@allele_types, 'wt/wt' )    if ( $self->is_wt_wt() );
    push (@allele_types, 'tm1a/wt' )  if ( $self->is_tm1a_wt() );
   	push (@allele_types, 'tm1e/wt' )  if ( $self->is_tm1e_wt() );
    push (@allele_types, 'wt/tm1' )   if ( $self->is_wt_tm1() );
   	push (@allele_types, 'tm1e/tm1' ) if ( $self->is_tm1e_tm1() );
    push (@allele_types, 'tm1a/tm1' ) if ( $self->is_tm1a_tm1() );

    push (@allele_types, 'tm1a/wt+bsd_offtarg' ) if ( $self->is_tm1a_wt_bsd_off_targ() );
    push (@allele_types, 'wt+neo_offtarg/tm1' ) if ( $self->is_wt_neo_off_targ_tm1() );


    if ( scalar @allele_types > 0 ) {
        return join ( ', ', @allele_types ); 
    }
    else {
		push (@allele_types, 'potential wt/wt' )    if ( $self->is_potential_wt_wt() );
		push (@allele_types, 'potential tm1a/wt' )  if ( $self->is_potential_tm1a_wt() );
		push (@allele_types, 'potential tm1e/wt' )  if ( $self->is_potential_tm1e_wt() );
		push (@allele_types, 'potential wt/tm1' )   if ( $self->is_potential_wt_tm1() );
		push (@allele_types, 'potential tm1e/tm1' ) if ( $self->is_potential_tm1e_tm1() );
		push (@allele_types, 'potential tm1a/tm1' ) if ( $self->is_potential_tm1a_tm1() );

        if ( scalar @allele_types > 0 ) {
	        return join ( ', ', @allele_types ); 
	    }
	    else {
	    	return 'failed: unknown';
	    }
    }
}

sub is_wt_wt {
    my ( $self ) = @_;

    #print "is wt_wt?\n";

    if( $self->workflow eq 'Ne1a' ) {
		if ( $self->stage eq 'EP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.6, 2.4) &&
                $self->is_loatam_rng(1.6, 2.4) &&
                !$self->is_neo_present(0.3)
			);
		}
		elsif ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.6, 2.4) &&
                $self->is_loatam_rng(1.6, 2.4) &&
                $self->is_loadel_rng(1.6, 2.4) &&
                !$self->is_neo_present(0.3) &&
                !$self->is_bsd_present(0.5)
			);
		}
	}
	elsif( $self->workflow eq 'Ne1' ) {
		if ( $self->stage eq 'EP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.6, 2.4) &&
                $self->is_loadel_rng(1.6, 2.4) &&
                !$self->is_bsd_present(0.3)
			);
		}
		elsif ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.6, 2.4) &&
                $self->is_loatam_rng(1.6, 2.4) &&
                $self->is_loadel_rng(1.6, 2.4) &&
                !$self->is_neo_present(0.3) &&
                !$self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_tm1a_wt {
	my ( $self ) = @_;

	#print "is tm1a_wt?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'EP_PICK' ) {
			return (
				$self->is_loacrit_rng(1.6, 2.4) &&
				$self->is_loatam_rng(0.6, 1.4) &&
                $self->is_neo_present(0.3)
			);
		}
		elsif ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.6, 2.4) &&
                $self->is_loatam_rng(0.6, 1.4) &&
                $self->is_loadel_rng(0.6, 1.4) &&
                $self->is_neo_present(0.3) &&
                !$self->is_bsd_present(0.5)
			);
		}
	}
	elsif( $self->workflow eq 'Ne1' ) {
		if ( $self->stage eq 'EP_PICK' ) {
			return (
                $self->is_loacrit_rng(0.6, 1.4) &&
                $self->is_loadel_rng(0.6, 1.4) &&
                $self->is_bsd_present(0.3)
			);
		}
		elsif ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(0.6, 1.4) &&
                $self->is_loatam_rng(0.6, 1.4) &&
                $self->is_loadel_rng(0.6, 1.4) &&
                !$self->is_neo_present(0.3) &&
                $self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_tm1e_wt {
	my ( $self ) = @_;

	#print "is tm1e_wt?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'EP_PICK' ) {
			return (
				$self->is_loacrit_rng(1.6, 2.4) &&
				$self->is_loatam_rng(1.6, 2.4) &&
                $self->is_neo_present(0.3)
			);
		}
		elsif ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.6, 2.4) &&
                $self->is_loatam_rng(1.6, 2.4) &&
                $self->is_loadel_rng(0.6, 1.4) &&
                $self->is_neo_present(0.3) &&
                !$self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_wt_tm1 {
	my ( $self ) = @_;

	#print "is wt_tm1?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(0.6, 1.4) &&
                $self->is_loatam_rng(0.6, 1.4) &&
                $self->is_loadel_rng(0.6, 1.4) &&
                !$self->is_neo_present(0.3) &&
                $self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_tm1e_tm1 {
	my ( $self ) = @_;

	#print "is tm1e_tm1?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(0.6, 1.4) &&
                $self->is_loatam_rng(0.6, 1.4) &&
                $self->is_loadel_rng(0.0, 0.4) &&
                $self->is_neo_present(0.3) &&
                $self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_tm1a_tm1 {
	my ( $self ) = @_;

	#print "is tm1a_tm1?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(0.6, 1.4) &&
                $self->is_loatam_rng(0.0, 0.4) &&
                $self->is_loadel_rng(0.0, 0.4) &&
                $self->is_neo_present(0.3) &&
                $self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_tm1a_wt_bsd_off_targ {
	my ( $self ) = @_;

	#print "is tm1a_wt_bsd_off_targ?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.6, 2.4) &&
                $self->is_loatam_rng(0.6, 1.4) &&
                $self->is_loadel_rng(0.6, 1.4) &&
                $self->is_neo_present(0.3) &&
                $self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_wt_neo_off_targ_tm1 {
	my ( $self ) = @_;

	#print "is wt_neo_off_targ_tm1?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(0.6, 1.4) &&
                $self->is_loatam_rng(0.6, 1.4) &&
                $self->is_loadel_rng(0.6, 1.4) &&
                $self->is_neo_present(0.3) &&
                $self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_potential_wt_wt {
    my ( $self ) = @_;

    #print "is potential wt_wt?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'EP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.3, 2.7) &&
                $self->is_loatam_rng(1.3, 2.7) &&
                !$self->is_neo_present(0.3)
			);
		}
		elsif ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.3, 2.7) &&
                $self->is_loatam_rng(1.3, 2.7) &&
                $self->is_loadel_rng(1.3, 2.7) &&
                !$self->is_neo_present(0.3) &&
                !$self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_potential_tm1a_wt {
	my ( $self ) = @_;

	#print "is potential tm1a_wt?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'EP_PICK' ) {
			return (
				$self->is_loacrit_rng(1.3, 2.7) &&
				$self->is_loatam_rng(0.3, 1.7) &&
                $self->is_neo_present(0.3)
			);
		}
		elsif ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.3, 2.7) &&
                $self->is_loatam_rng(0.3, 1.7) &&
                $self->is_loadel_rng(0.3, 1.7) &&
                $self->is_neo_present(0.3) &&
                !$self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_potential_tm1e_wt {
	my ( $self ) = @_;

	#print "is potential tm1e_wt?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'EP_PICK' ) {
			return (
				$self->is_loacrit_rng(1.3, 2.7) &&
				$self->is_loatam_rng(1.3, 2.7)  &&
                $self->is_neo_present(0.3)
			);
		}
		elsif ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(1.3, 2.7) &&
                $self->is_loatam_rng(1.3, 2.7) &&
                $self->is_loadel_rng(0.3, 1.7) &&
                $self->is_neo_present(0.3) &&
                !$self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_potential_wt_tm1 {
	my ( $self ) = @_;

	#print "is potential wt_tm1?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(0.3, 1.7) &&
                $self->is_loatam_rng(0.3, 1.7) &&
                $self->is_loadel_rng(0.3, 1.7) &&
                !$self->is_neo_present(0.3) &&
                $self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_potential_tm1e_tm1 {
	my ( $self ) = @_;

	#print "is potential tm1e_tm1?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(0.3, 1.7) &&
                $self->is_loatam_rng(0.3, 1.7) &&
                $self->is_loadel_rng(0.0, 0.7) &&
                $self->is_neo_present(0.3) &&
                $self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_potential_tm1a_tm1 {
	my ( $self ) = @_;

	#print "is potential tm1a_tm1?\n";

    if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'SEP_PICK' ) {
			return (
                $self->is_loacrit_rng(0.3, 1.7) &&
                $self->is_loatam_rng(0.0, 0.7) &&
                $self->is_loadel_rng(0.0, 0.7) &&
                $self->is_neo_present(0.3) &&
                $self->is_bsd_present(0.5)
			);
		}
	}

	return 0;
}

sub is_loacrit_rng {
    my ( $self, $min, $max ) = @_;

    my $value = $self->well_genotyping_results->{ 'loacrit#copy_number' };

    #print "LOACRIT min $min, max $max, value $value\n";

    if ( defined $value && $value ne '-' ) {
        return $self->is_value_in_range ( $min, $max, $value );
    }
    else {
        return 0;
    }
}

sub is_loatam_rng {
    my ( $self, $min, $max ) = @_;

    my $value = $self->well_genotyping_results->{ 'loatam#copy_number' };

    #print "LOATAM min $min, max $max, value $value\n";

    if ( defined $value && $value ne '-' ) {
        return $self->is_value_in_range ( $min, $max, $value );
    }
    else {
        return 0;
    }
}

sub is_loadel_rng {
    my ( $self, $min, $max ) = @_;

    my $value = $self->well_genotyping_results->{ 'loadel#copy_number' };

    #print "LOADEL min $min, max $max, value $value\n";

    if ( defined $value && $value ne '-' ) {
        return $self->is_value_in_range ( $min, $max, $value );
    }
    else {
        return 0;
    }
}

sub is_neo_present {
    my ( $self, $threshold ) = @_;

    my $value = $self->well_genotyping_results->{ 'neo#copy_number' };

    #print "Neo present? value $value, threshold $threshold\n";

    if ( ( defined $value ) && ( $value ne '-' ) && ( $value >= $threshold ) ) {
    	#print "Neo present\n";
    	return 1;
    }
    else {
    	#print "Neo absent\n";
    	return 0;
    }
}

# sub is_neo_absent {
# 	my ( $self, $threshold ) = @_;

# 	print "Neo absent?\n";

# 	return !$self->is_neo_present( $threshold );
# }

sub is_bsd_present {
    my ( $self, $threshold ) = @_;

    my $value = $self->well_genotyping_results->{ 'bsd#copy_number' };

    #print "Bsd present? value $value, threshold $threshold\n";

    if ( ( defined $value ) && ( $value ne '-' ) && ( $value >= $threshold ) ) {
    	#print "Bsd present\n";
    	return 1;
    }
    else {
    	#print "Bsd absent\n";
    	return 0;
    }
}

# sub is_bsd_absent {
# 	my ( $self, $threshold ) = @_;

# 	print "Bsd absent\n";

# 	return !$self->is_bsd_present( $threshold );
# }

sub is_value_in_range {
	my ( $self, $min, $max, $value ) = @_;

    if ( ( $value >= $min ) && ( $value <= $max ) ) {
    	#print "in range\n";
        return 1;
    }
    else {
    	#print "NOT in range\n";
        return 0;
    }
}

sub validate_assays {
	my ( $self ) = @_;

	if( $self->workflow eq 'Ne1a') {
		if ( $self->stage eq 'EP_PICK' ) {
            unless ( $self->validate_assay_loacrit &&
            	     $self->validate_assay_loatam &&
            	     $self->validate_assay_neo
            ) { 
                return 0;
            }			
		}
		elsif ( $self->stage eq 'SEP_PICK' ) {
			unless ( $self->validate_assay_loacrit &&
            	     $self->validate_assay_loatam &&
            	     $self->validate_assay_loadel &&
            	     $self->validate_assay_neo &&
            	     $self->validate_assay_bsd
            ) {
				return 0;
			}
		}
	}

	return 1;
}

sub validate_assay_loacrit {
	my ( $self ) = @_;

    my $cn   = $self->well_genotyping_results->{ 'loacrit#copy_number' };
	my $cnr  = $self->well_genotyping_results->{ 'loacrit#copy_number_range' };
	#my $conf = $self->well_genotyping_results->{ 'loacrit#confidence' };
	#my $vic = $self->well_genotyping_results->{ 'loacrit#vic' };

    unless ( defined $cn && $cn ne '-' ) {
    	print "LOACRIT assay validation error: Copy Number not present\n";
		return 0;
	}

	unless ( defined $cnr && $cnr ne '-' ) {
		print "LOACRIT assay validation error: Copy Number Range not present\n";
		return 0;
	}

	unless ( $cnr <= 0.4 ) {
		print "LOACRIT assay validation error: Copy Number Range above threshold\n";
		return 0;
	}

	# TODO: add validations for confidence and vic

	return 1;
}

sub validate_assay_loatam {
	my ( $self ) = @_;

    my $cn   = $self->well_genotyping_results->{ 'loatam#copy_number' };
	my $cnr  = $self->well_genotyping_results->{ 'loatam#copy_number_range' };
	#my $conf = $self->well_genotyping_results->{ 'loatam#confidence' };
	#my $vic = $self->well_genotyping_results->{ 'loatam#vic' };

    unless ( defined $cn && $cn ne '-' ) {
    	print "LOATAM assay validation error: Copy Number not present\n";
		return 0;
	}

	unless ( defined $cnr && $cnr ne '-' ) {
		print "LOATAM assay validation error: Copy Number Range not present\n";
		return 0;
	}

	unless ( $cnr <= 0.4 ) {
		print "LOATAM assay validation error: Copy Number Range above threshold\n";
		return 0;
	}

	# TODO: add validations for confidence and vic

	return 1;
}

sub validate_assay_loadel {
	my ( $self ) = @_;

    my $cn   = $self->well_genotyping_results->{ 'loadel#copy_number' };
	my $cnr  = $self->well_genotyping_results->{ 'loadel#copy_number_range' };
	#my $conf = $self->well_genotyping_results->{ 'loadel#confidence' };
	#my $vic = $self->well_genotyping_results->{ 'loadel#vic' };

    unless ( defined $cn && $cn ne '-' ) {
    	print "LOADEL assay validation error: Copy Number not present\n";
		return 0;
	}

	unless ( defined $cnr && $cnr ne '-' ) {
		print "LOADEL assay validation error: Copy Number Range not present\n";
		return 0;
	}

	unless ( $cnr <= 0.4 ) {
		print "LOADEL assay validation error: Copy Number Range above threshold\n";
		return 0;
	}

	# TODO: add validations for confidence and vic

	return 1;
}

sub validate_assay_neo {
	my ( $self ) = @_;

    my $cn   = $self->well_genotyping_results->{ 'neo#copy_number' };
	my $cnr  = $self->well_genotyping_results->{ 'neo#copy_number_range' };
	#my $conf = $self->well_genotyping_results->{ 'neo#confidence' };
	#my $vic = $self->well_genotyping_results->{ 'neo#vic' };

    unless ( defined $cn && $cn ne '-' ) {
    	print "NEO assay validation error: Copy Number not present\n";
		return 0;
	}

	unless ( defined $cnr && $cnr ne '-' ) {
		print "NEO assay validation error: Copy Number Range not present\n";
		return 0;
	}

	unless ( $cnr <= 0.4 ) {
		print "NEO assay validation error: Copy Number Range above threshold\n";
		return 0;
	}

	# TODO: add validations for confidence and vic

	return 1;
}

sub validate_assay_bsd {
	my ( $self ) = @_;

    my $cn   = $self->well_genotyping_results->{ 'bsd#copy_number' };
	my $cnr  = $self->well_genotyping_results->{ 'bsd#copy_number_range' };
	#my $conf = $self->well_genotyping_results->{ 'bsd#confidence' };
	#my $vic = $self->well_genotyping_results->{ 'bsd#vic' };

    unless ( defined $cn && $cn ne '-' ) {
    	print "BSD assay validation error: Copy Number not present\n";
		return 0;
	}

	unless ( defined $cnr && $cnr ne '-' ) {
		print "BSD assay validation error: Copy Number Range not present\n";
		return 0;
	}

	unless ( $cnr <= 0.4 ) {
		print "BSD assay validation error: Copy Number Range above threshold\n";
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
    my ( $self, $ep_pick_well_id ) = @_;

my $sql_query =  <<"SQL_END";
select final_pick_recombinase_id, final_pick_cassette_resistance
from summaries
where ep_pick_well_id = $ep_pick_well_id
and ep_pick_well_id > 0
group by final_pick_recombinase_id, final_pick_cassette_resistance
limit 1
SQL_END

    return $sql_query;
}

sub create_sql_select_summaries_sep {
    my ( $self, $sep_pick_well_id ) = @_;

my $sql_query =  <<"SQL_END";
select final_pick_recombinase_id, final_pick_cassette_resistance
from summaries
where sep_pick_well_id = $sep_pick_well_id
and ep_pick_well_id > 0
group by final_pick_recombinase_id, final_pick_cassette_resistance
limit 1
SQL_END

    return $sql_query;
}


1;

__END__
