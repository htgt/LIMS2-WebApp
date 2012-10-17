package LIMS2::Model::Util::EngSeqParams;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            fetch_design_eng_seq_params
            fetch_well_eng_seq_params
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Model::Constants qw($DEFAULT_ASSEMBLY);

use Data::Dumper;

sub fetch_design_eng_seq_params{
	my ($design) = @_;
	
	my %locus_for;
    
	foreach my $oligo (@{ $design->{oligos} }){
		my $locus_type = $oligo->{type};
		$locus_for{$locus_type} = $oligo->{locus}; 
	}
	
	my $params = build_eng_seq_params_from_loci(\%locus_for, $design->{type});
	
	$params->{type} = $design->{type};
    return $params;
}

sub build_eng_seq_params_from_loci{
	my ($loci, $type) = @_;

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
    }
    else{
    	$params->{target_region_start} = $loci->{D5}->{chr_start};
    	$params->{target_region_end} = $loci->{U3}->{chr_end};
    }
      
    return $params;
}

sub fetch_well_eng_seq_params{
	my ($well, $params) = @_;
	
	my $well_params;
	
	my $graph = LIMS2::Model::ProcessGraph->new({ start_with => $well});
	
	if ($params->{cassette}){
		$well_params->{u_insertion}->{name} = $params->{cassette};
	}
	else{
		my $process_cassette = $graph->find_process($well, 'process_cassette');
		$well_params->{u_insertion}->{name} = $process_cassette ? $process_cassette->cassette_id
		                                                        : undef ;
	}
	
	if($params->{backbone}){
		$well_params->{backbone}->{name} = $params->backbone_id;
	}
	else{
		# FIXME: backbone is not always needed?
		my $process_backbone = $graph->find_process($well, 'process_backbone');
		$well_params->{backbone}->{name} = $process_backbone ? $process_backbone->backbone_id
		                                                     : undef ;
	}
	
	if($params->{recombinase}){
		$well_params->{recombinase} = $params->{recombinase};
	}
	else{
		my $process_recombinases = $graph->find_process($well, 'process_recombinases');
		# FIXME: should these be sorted by rank?
		my @recombinases = map { $_->recombinase_id } $process_recombinases->all;
		$well_params->{recombinase} = \@recombinases;
	}
	
	return $well_params;
}

1;