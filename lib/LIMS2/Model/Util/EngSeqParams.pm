package LIMS2::Model::Util::EngSeqParams;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            fetch_design_eng_seq_params
            fetch_well_eng_seq_params
            add_display_id
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Model::Constants qw($DEFAULT_ASSEMBLY);
use LIMS2::Model::ProcessGraph;

use Data::Dumper;

sub fetch_design_eng_seq_params{
	my ($design, $loxp) = @_;
	
	my %locus_for;
    
	foreach my $oligo (@{ $design->{oligos} }){
		my $locus_type = $oligo->{type};
		$locus_for{$locus_type} = $oligo->{locus}; 
	}

	my $params = build_eng_seq_params_from_loci(\%locus_for, $design->{type}, $loxp);
	$params->{design_id} = $design->{id};

    return $params;
}

sub build_eng_seq_params_from_loci{
	my ($loci, $type, $loxp) = @_;

    my $params;
    
    $params->{chromosome} = $loci->{G5}->{chr_name};
    $params->{strand} = $loci->{G5}->{chr_strand};
    $params->{assembly} = $loci->{G5}->{assembly};
    
    if ( $params->{strand} == 1 ) {
        $params->{five_arm_start} = $loci->{G5}->{chr_start};
        $params->{five_arm_end} = $loci->{U5}->{chr_end};
        $params->{three_arm_start} = $loci->{D3}->{chr_start};
        $params->{three_arm_end} = $loci->{G3}->{chr_end};
    }
    else {
        $params->{five_arm_start} = $loci->{U5}->{chr_start};
        $params->{five_arm_end} = $loci->{G5}->{chr_end};
        $params->{three_arm_start} = $loci->{G3}->{chr_start};
        $params->{three_arm_end} = $loci->{D3}->{chr_end};
    }
    
    return $params if ( $type eq 'deletion' or $type eq 'insertion');
    
    if ( $params->{strand} == 1 ) {
    	$params->{target_region_start} = $loci->{U3}->{chr_start};
    	$params->{target_region_end} = $loci->{D5}->{chr_end};
    	
    	return $params unless $loxp;
    	
    	$params->{loxp_start} = $loci->{D5}->{chr_end} + 1;
    	$params->{loxp_end} = $loci->{D3}->{chr_start} - 1;
    }
    else{
    	$params->{target_region_start} = $loci->{D5}->{chr_start};
    	$params->{target_region_end} = $loci->{U3}->{chr_end};
    	
    	return $params unless $loxp;
    	
    	$params->{loxp_start} = $loci->{D3}->{chr_end} + 1;
    	$params->{loxp_end} = $loci->{D5}->{chr_start} - 1;
    }
      
    return $params;
}

sub fetch_well_eng_seq_params{
	my ($well, $params) = @_;
	
	my ($well_params, $method);
	
	my $graph = LIMS2::Model::ProcessGraph->new({  start_with => $well, type => 'ancestors' });
	
	# Fetch cassette etc from process graph if not user supplied
	unless ($params->{cassette}){
		my $process_cassette = $graph->find_process($well, 'process_cassette');
		$params->{cassette} = $process_cassette ? $process_cassette->cassette->name
		                                                : undef ;		
	}

	unless (@{ $params->{recombinase} }){
		my $process_recombinases = $graph->find_process($well, 'process_recombinases');
		# FIXME: should these be sorted by rank?
		my @recombinases = map { $_->recombinase_id } $process_recombinases->all;
		$params->{recombinase} = \@recombinases;
	}

	unless ($params->{backbone} or $params->{is_allele}){
		my $process_backbone = $graph->find_process($well, 'process_backbone');
		$params->{backbone} = $process_backbone ? $process_backbone->backbone->name
		                                        : undef ;
	}

    # Always store recombinase
    $well_params->{recombinase} = $params->{recombinase};
    	
	my $design_type = $params->{design_type};
	
	if ($params->{is_allele}){
	    if ($params->{targeted_trap}) {
	        $well_params->{u_insertion}->{name} = $params->{cassette};        
	        $method = 'targeted_trap_allele_seq';
	    }
	    elsif ( $design_type eq 'conditional') {
	        $method = 'conditional_allele_seq';
	        $well_params->{u_insertion}->{name} = $params->{cassette};
	        $well_params->{d_insertion}->{name} = 'LoxP' ;
	    }
	    elsif ( $design_type eq 'insertion' ) {
	        $method = 'insertion_allele_seq';
	        $well_params->{insertion}->{name} = $params->{cassette};
	    }
	    elsif ( $design_type eq 'deletion' ) {
	        $method = 'deletion_allele_seq';        
	        $well_params->{insertion}->{name} = $params->{cassette};
	    }
	    else {
	        die( "Don't know how to generate allele seq for design of type $design_type" );
	    }		
	}
	else {
		$well_params->{backbone}->{name} = $params->{backbone};
		
	    if ( $design_type eq 'conditional') {
	        $method = 'conditional_vector_seq';
	        $well_params->{u_insertion}->{name} = $params->{cassette};
	        $well_params->{d_insertion}->{name} = 'LoxP' ;
	    }
	    elsif ( $design_type eq 'insertion' ) {
	        $method = 'insertion_vector_seq';
	        $well_params->{insertion}->{name} = $params->{cassette};
	    }
	    elsif ( $design_type eq 'deletion' ) {
	        $method = 'deletion_vector_seq';        
	        $well_params->{insertion}->{name} = $params->{cassette};
	    }
	    else {
	        die( "Don't know how to generate vector seq for design of type $design_type" );
	    }		
	}
		
	return $method,$well_params;
}

sub add_display_id{
	my ($stage, $params) = @_;
    
    my $seq_id;
    
    my $cassette = exists($params->{insertion}) ? $params->{insertion}->{name} 
                                                : $params->{u_insertion}->{name};
    
    if ($stage eq 'allele'){
        $seq_id = join '#', grep { $_ }   
                  $params->{design_id}, $cassette;	
    }
    else{
        $seq_id = join '#', grep { $_ } 
                  $params->{design_id}, $cassette, 
                  $params->{backbone}->{name},@{ $params->{recombinase} || [] };
    }
    
    $seq_id =~ s/\s+/_/g;
print "Display id: $seq_id\n";    
    $params->{display_id} = $seq_id;
    return $params;	
}

1;