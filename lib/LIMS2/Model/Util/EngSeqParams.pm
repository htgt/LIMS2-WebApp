package LIMS2::Model::Util::EngSeqParams;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::EngSeqParams::VERSION = '0.035';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            fetch_design_eng_seq_params
            fetch_well_eng_seq_params
            add_display_id
            generate_genbank_for_qc_well
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Model::Constants qw($DEFAULT_ASSEMBLY);
use LIMS2::Model::ProcessGraph;
use EngSeqBuilder;
use JSON;
use Data::Dumper;

sub fetch_design_eng_seq_params{
	my ($design, $loxp) = @_;

	my %locus_for;
    my @not_found;

	foreach my $oligo (@{ $design->{oligos} }){
		my $locus_type = $oligo->{type};
		$locus_for{$locus_type} = $oligo->{locus} or push @not_found ,$locus_type;
	}

    if(@not_found){
    	die "No design oligo loci found for design ".$design->{id}." oilgos ".(join ", ", @not_found);
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

	# Fetch cassette etc from process graph if not user supplied
	unless ($params->{cassette}){
		my $cassette = $well->cassette;
		$params->{cassette} = $cassette ? $cassette->name
		                                : undef ;
	}

	unless (@{ $params->{recombinase} }){
		$params->{recombinase} = $well->recombinases;
	}

	unless ($params->{backbone} or $params->{is_allele}){
		my $backbone = $well->backbone;
		$params->{backbone} = $backbone ? $backbone->name
		                                : undef ;
	}

    # Always store recombinase (in lower case)
    my @recom = map { lc $_ } @{ $params->{recombinase} };
    $well_params->{recombinase} = \@recom;

    # We always need a cassette
    die "No cassette found for well ".$well->id unless $params->{cassette};

	my $design_type = $params->{design_type};

	if ($params->{is_allele}){

		## no critic (ProhibitCascadingIfElse)

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

        ## use critic

	}
	else {
		$well_params->{backbone}->{name} = $params->{backbone}
		    or die "No backbone found for well ".$well->id;

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

    $params->{display_id} = $seq_id;
    return $params;
}

sub generate_genbank_for_qc_well{
	my ($qc_well, $tmp_fh) = @_;

	my $method = $qc_well->qc_eng_seq->method;
	my $params = decode_json($qc_well->qc_eng_seq->params);

	my $builder = EngSeqBuilder->new;
	my $seq = $builder->$method( %{ $params });

    my $seq_io = Bio::SeqIO->new( -fh => $tmp_fh, -format => 'genbank' );
    $seq_io->write_seq( $seq );

    return;
}

1;