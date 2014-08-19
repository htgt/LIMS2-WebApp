package LIMS2::Model::Util::EngSeqParams;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::EngSeqParams::VERSION = '0.235';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            generate_well_eng_seq_params
            generate_genbank_for_qc_well
            fetch_well_eng_seq_params
            generate_crispr_eng_seq_params
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Model::ProcessGraph;
use LIMS2::Exception;
use EngSeqBuilder;
use JSON;
use Data::Dumper;
use Hash::MoreUtils qw( slice_def );
use List::MoreUtils qw( uniq );
use Try::Tiny;

sub pspec_generate_eng_seq_params {
	return {
        plate_name  => { validate => 'existing_plate_name', optional => 1 },
        well_name   => { validate => 'well_name', optional => 1 },
        well_id     => { validate => 'integer', rename => 'id', optional => 1 },
        cassette    => { validate => 'existing_cassette', optional => 1 },
        backbone    => { validate => 'existing_backbone', optional => 1 },
        recombinase => { validate => 'existing_recombinase', default => [], optional => 1 },
        stage       => { validate => 'non_empty_string', optional => 1 },
	}
}

sub generate_well_eng_seq_params{
    my ( $model, $params ) = @_;
	my $validated_params = $model->check_params( $params, pspec_generate_eng_seq_params );

    my $well = $model->retrieve_well( { slice_def $validated_params, qw( plate_name well_name id ) } );
    DEBUG("Generate eng seq params for well: $well ");

    my $design = $well->design;
    # If there is no design then the well may be linked to a crispr well
    # in that case call a seperate method to generate this type of eng seq
    unless ( $design ) {
        my $crispr = $well->crispr;
        LIMS2::Exception->throw( 'Can not produce eng seq params for well that has'
                . ' neither a design or crispr ancestor' )
            unless $crispr;

        return generate_crispr_eng_seq_params( $well, $crispr, $validated_params );
    }

    my $design_data = $design->as_hash;

    # Infer stage from plate type information
    my $stage;
    my $plate_type_descr = $well->plate->type->description;
    if ( $validated_params->{stage} ) {
        $stage = $validated_params->{stage};
    }
    else {
        $stage = $plate_type_descr =~ /ES/ ? 'allele' : 'vector';
    }

    my $design_params = fetch_design_eng_seq_params($design_data);

    # fetch canonical transcript for the gene if it exists and add the transcript id to the params
    # required to write exon features within genbank files for display in imits
    my $transcript_id;
    $transcript_id = try{ $design->fetch_canonical_transcript_id };
    if ( $transcript_id ) {
        DEBUG( "Transcript id: $transcript_id\n" );
        $design_params->{ 'transcript' } = $transcript_id;
    }

    my $input_params = {slice_def $validated_params, qw( cassette backbone recombinase targeted_trap)};
    $input_params->{is_allele} = 1 if $stage eq 'allele';
    $input_params->{design_type} = $design_data->{type};
    $input_params->{design_cassette_first} = $design_data->{cassette_first};

    my ($method,$well_params) = fetch_well_eng_seq_params($well, $input_params );

    my $eng_seq_params = { %$design_params, %$well_params };
    add_display_id($stage, $eng_seq_params);

    return $method, $well->id, $eng_seq_params;
}

sub fetch_design_eng_seq_params{
	my $design = shift;
	my %locus_for;
    my @not_found;

	foreach my $oligo (@{ $design->{oligos} }){
		my $locus_type = $oligo->{type};
		$locus_for{$locus_type} = $oligo->{locus} or push @not_found ,$locus_type;
	}

    if( @not_found ) {
        LIMS2::Exception->throw( "No design oligo loci found for design "
                . $design->{id} . " oilgos " . ( join ", ", @not_found ) );
    }

	my $params = build_eng_seq_params_from_loci(\%locus_for, $design->{type});
	$params->{design_id} = $design->{id};
    $params->{species}   = lc($design->{species});

    return $params;
}

=item

input:
Hashref of loci: {{G5=>{chr_name=>11,...}{G3=>{chr_name=>11,}}}
Type ("conditional" or "gibson" or "gibson-deletion")

Interrogates the oligo loci for the parameters to set to allow eng-seq-builder to run later:
the oligo loci are either G5/U5(U3/D5)/D3/G3 OR '5F', '5R', (EF, ER), '3F', '3R'

Returns hashref of params:
values: chromosome, strand, assembly, five_arm_start, five_arm_end, three_arm_start, three_arm_end,
(and optionally) target_region_start, target_region_end

=cut
sub build_eng_seq_params_from_loci{
	my ($loci, $type) = @_;

    my $params;

    if($type =~ /gibson/){
        $params->{chromosome} = $loci->{'5F'}->{chr_name};
        $params->{strand} = $loci->{'5F'}->{chr_strand};
        $params->{assembly} = $loci->{'5F'}->{assembly};
    }else{
        $params->{chromosome} = $loci->{G5}->{chr_name};
        $params->{strand} = $loci->{G5}->{chr_strand};
        $params->{assembly} = $loci->{G5}->{assembly};
    }

    if ( $params->{strand} == 1 ) {

	    if($type =~ /gibson/){

               $params->{five_arm_start} = $loci->{'5F'}->{chr_start};
               $params->{five_arm_end} = $loci->{'5R'}->{chr_end};
               $params->{three_arm_start} = $loci->{'3F'}->{chr_start};
               $params->{three_arm_end} = $loci->{'3R'}->{chr_end};

	    }else{

               $params->{five_arm_start} = $loci->{G5}->{chr_start};
               $params->{five_arm_end} = $loci->{U5}->{chr_end};
               $params->{three_arm_start} = $loci->{D3}->{chr_start};
               $params->{three_arm_end} = $loci->{G3}->{chr_end};

            }
    }
    else {
	    if($type =~ /gibson/){

                 $params->{five_arm_start} = $loci->{'5R'}->{chr_start};
                 $params->{five_arm_end} = $loci->{'5F'}->{chr_end};
                 $params->{three_arm_start} = $loci->{'3R'}->{chr_start};
                 $params->{three_arm_end} = $loci->{'3F'}->{chr_end};

	    }else{

                 $params->{five_arm_start} = $loci->{U5}->{chr_start};
                 $params->{five_arm_end} = $loci->{G5}->{chr_end};
                 $params->{three_arm_start} = $loci->{G3}->{chr_start};
                 $params->{three_arm_end} = $loci->{D3}->{chr_end};

	    }
    }

    return $params if ( $type eq 'deletion' or $type eq 'insertion' or $type eq 'gibson-deletion' );

    if ( $params->{strand} == 1 ) {
	    if ( $type eq 'gibson' ) {
    	        $params->{target_region_start} = $loci->{EF}->{chr_start};
    	        $params->{target_region_end} = $loci->{ER}->{chr_end};
	    }
        else {
    	        $params->{target_region_start} = $loci->{U3}->{chr_start};
    	        $params->{target_region_end} = $loci->{D5}->{chr_end};
	    }
    }
    else{
	    if ( $type eq 'gibson' ) {
    	        $params->{target_region_start} = $loci->{ER}->{chr_start};
    	        $params->{target_region_end} = $loci->{EF}->{chr_end};
	    }
        else {
    	        $params->{target_region_start} = $loci->{D5}->{chr_start};
    	        $params->{target_region_end} = $loci->{U3}->{chr_end};
	    }
    }

    return $params;
}

## no critic ( Subroutines::ProhibitExcessComplexity )
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
    my @recom = uniq map { lc $_ } @{ $params->{recombinase} };
    $well_params->{recombinase} = \@recom;

    # We always need a cassette
    LIMS2::Exception->throw( "No cassette found for well ". $well->id )
        unless $params->{cassette};

	my $design_type = $params->{design_type};
    my $cassette_first = $params->{design_cassette_first};

	if ($params->{is_allele}){

		## no critic (ProhibitCascadingIfElse)

	    if ( $design_type eq 'conditional' || $design_type eq 'artificial-intron' ) {
	        $method = 'conditional_allele_seq';
            if ( $cassette_first ) {
                $well_params->{u_insertion}->{name} = $params->{cassette};
                $well_params->{d_insertion}->{name} = 'LoxP' ;
            }
            else {
                $well_params->{u_insertion}->{name} = 'LoxP';
                $well_params->{d_insertion}->{name} = $params->{cassette};
            }
	    }
	    elsif ( $design_type eq 'insertion' ) {
	        $method = 'insertion_allele_seq';
	        $well_params->{insertion}->{name} = $params->{cassette};
	    }
	    elsif ( $design_type eq 'deletion' || $design_type =~ /gibson/ ) {
                # This needs fixing for a gibson: when we generate the expected sequence, we have to know
	        # whether the loxP has actually been inserted (by the pipeline) or whether the KO has been left as a deletion
		# I'm leaving it as a deletion because this will be made by the lab for the foreseeable future.
	        $method = 'deletion_allele_seq';
	        $well_params->{insertion}->{name} = $params->{cassette};
	    }
	    else {
            LIMS2::Exception->throw( "Don't know how to generate allele seq for design of type $design_type" );
	    }

        ## use critic

	}
	else {
		$well_params->{backbone}->{name} = $params->{backbone}
		    or die "No backbone found for well ".$well->id;

	    if ( $design_type eq 'conditional' || $design_type eq 'artificial-intron' ) {
	        $method = 'conditional_vector_seq';
            if ( $cassette_first ) {
                $well_params->{u_insertion}->{name} = $params->{cassette};
                $well_params->{d_insertion}->{name} = 'LoxP' ;
            }
            else {
                $well_params->{u_insertion}->{name} = 'LoxP';
                $well_params->{d_insertion}->{name} = $params->{cassette};
            }
	    }
	    elsif ( $design_type eq 'insertion' ) {
	        $method = 'insertion_vector_seq';
	        $well_params->{insertion}->{name} = $params->{cassette};
	    }
	    elsif ( $design_type eq 'deletion' || $design_type =~ /gibson/ ) {
                # This needs fixing for a gibson: when we generate the expected sequence, we have to know
	        # whether the loxP has actually been inserted (by the pipeline) or whether the KO has been left as a deletion
		# I'm leaving it as a deletion because this will be made by the lab for the foreseeable future.
	        $method = 'deletion_vector_seq';
	        $well_params->{insertion}->{name} = $params->{cassette};
	    }
	    else {
            LIMS2::Exception->throw( "Don't know how to generate vector seq for design of type $design_type" );
	    }
	}

	return $method,$well_params;
}
## use critic

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

=head2 generate_crispr_eng_seq_params

Generate eng seq params for a crispr vector.
The vector is just a backbone with a crispr, nothing more.
The source well will be linked to a crispr, and not a design.

=cut
sub generate_crispr_eng_seq_params {
    my ( $well, $crispr, $input_params ) = @_;
    my $params = {slice_def $input_params, qw( cassette backbone )};
    LIMS2::Exception->throw( 'Can not specify a cassette for crispr well' ) if $params->{cassette};

    my $backbone = $params->{backbone};
	unless ($backbone) {
		my $well_backbone = $well->backbone;
        LIMS2::Exception->throw( "No backbone found for well $well" ) unless $well_backbone;
        $backbone = $well_backbone->name;
	}

    #backbones in this list need to have the full guide rna
    #normally we take 19 bases and add a G at the start
    my %t7_backbones = map { $_ => 1 } qw( T7_gRNA_BSA1 );
    my $crispr_seq = exists $t7_backbones{ $backbone } ? $crispr->t7_vector_seq : $crispr->vector_seq;

    my $method = 'crispr_vector_seq';
    my $display_id = $backbone . '#' . $crispr->id;
    my %eng_seq_params = (
        crispr_seq => $crispr_seq,
        backbone   => { name => $backbone },
        display_id => $display_id,
        crispr_id  => $crispr->id,
        species    => lc($crispr->species_id),
    );

    return $method, $well->id, \%eng_seq_params;
}

1;
