package LIMS2::Model::Util::ReportForSponsors;

use strict;
use warnings FATAL => 'all';

use Moose;
use Hash::MoreUtils qw( slice_def );
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use LIMS2::Model::Util qw( sanitize_like_expr );
use List::MoreUtils qw( uniq );
use Log::Log4perl qw( :easy );
use namespace::autoclean;
use DateTime;
use Readonly;

Log::Log4perl->easy_init($DEBUG);

extends qw( LIMS2::ReportGenerator );

# Rows on report view
Readonly my @SINGLE_TARGETED_REPORT_CATEGORIES => (
    'Targeted Genes',
    'Vectors',
    'Valid DNA',
	'1st Allele Electroporations',
	'Accepted Clones',
);

Readonly my @DOUBLE_TARGETED_REPORT_CATEGORIES => (
    'Targeted Genes',
    'Vectors',
    'Neomycin Vectors',
    'Blasticidin Vectors',
    'Valid DNA',
    'Neomycin Valid DNA',
    'Blasticidin Valid DNA',
	'1st Allele Electroporations',
	'Neomycin 1st Allele Electroporations',
	'Blasticidin 1st Allele Electroporations',
	'2nd Allele Electroporations',
	'Accepted Clones',
);

has model => (
    is         => 'ro',
    isa        => 'LIMS2::Model',
    required   => 1,
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

#----------------------------------------------------------
# For Home page main report
#----------------------------------------------------------

has sponsors => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_sponsors {
    my $self = shift;

    my @sponsors = $self->model->schema->resultset('Sponsor')->search(
        { }, { order_by => { -asc => 'description' } }
    );

    return [ map{ $_->id } @sponsors ];
}

has sponsor_data_single => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_sponsor_data_single {
    my $self = shift;
    my %sponsor_data_single;

	my @sponsor_ids = @{ $self->sponsors };

	foreach my $sponsor_id ( @sponsor_ids ) {
		DEBUG "single data sponsor id = ".$sponsor_id;
		$self->_build_sponsor_column_data_single_targeted( $sponsor_id, \%sponsor_data_single );
    }

    return \%sponsor_data_single;
}

has sponsor_data_double => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_sponsor_data_double {
    my $self = shift;
	my %sponsor_data_double;

	my @sponsor_ids = @{ $self->sponsors };

	foreach my $sponsor_id ( @sponsor_ids ) {
		DEBUG "double data sponsor id = ".$sponsor_id;
		$self->_build_sponsor_column_data_double_targeted( $sponsor_id, \%sponsor_data_double );
    }

    return \%sponsor_data_double;
}


sub _build_sponsor_column_data_single_targeted {
	my ( $self, $sponsor_id, $sponsor_data_single ) = @_;

	my $targeting_type = 'single_targeted';

	DEBUG "fetching column data for single-targeted projects ";
	
	my $count_tgs = $self->genes( $sponsor_id, $targeting_type );
	$sponsor_data_single->{'Targeted Genes'}{$sponsor_id} = $count_tgs;

	# only look if targeted genes found
	my $count_vectors = 0;
	if ( $count_tgs > 0 ) {
		$count_vectors = $self->vectors( $sponsor_id, $targeting_type );
	}
	$sponsor_data_single->{'Vectors'}{$sponsor_id} = $count_vectors;

	$sponsor_data_single->{'Neomycin Vectors'}{$sponsor_id} = -1;
	$sponsor_data_single->{'Blasticidin Vectors'}{$sponsor_id} = -1;
	
	# only look if vectors found
	my $count_dna = 0;
	if ( $count_vectors > 0 ) {
		$count_dna = $self->dna( $sponsor_id, $targeting_type );
	}
	$sponsor_data_single->{'Valid DNA'}{$sponsor_id} = $count_dna;

    $sponsor_data_single->{'Neomycin Valid DNA'}{$sponsor_id} = -1;
	$sponsor_data_single->{'Blasticidin Valid DNA'}{$sponsor_id} = -1;

	# only look if dna found
	my $count_eps = 0;
	if ( $count_dna > 0 ) {
		$count_eps = $self->electroporations( $sponsor_id, $targeting_type );
	}
	$sponsor_data_single->{'1st Allele Electroporations'}{$sponsor_id} = $count_eps;

	$sponsor_data_single->{'Neomycin 1st Allele Electroporations'}{$sponsor_id} = -1;
    $sponsor_data_single->{'Blasticidin 1st Allele Electroporations'}{$sponsor_id} = -1;

	$sponsor_data_single->{'2nd Allele Electroporations'}{$sponsor_id} = -1;

	# only look if first electroporations found
	my $count_clones = 0;
	if ( $count_eps > 0 ) {
		$count_clones = $self->clones( $sponsor_id, $targeting_type );
	} 
    $sponsor_data_single->{'Accepted Clones'}{$sponsor_id} = $count_clones;

}

sub _build_sponsor_column_data_double_targeted {
	my ( $self, $sponsor_id, $sponsor_data_double ) = @_;

	my $targeting_type = 'double_targeted';

	DEBUG "fetching column data for double-targeted projects ";

	my $count_tgs = $self->genes( $sponsor_id, $targeting_type );
	$sponsor_data_double->{'Targeted Genes'}{$sponsor_id} = $count_tgs;

	# only look if targeted genes found
	my $count_vectors = 0;
	if ( $count_tgs > 0 ) {
		$count_vectors = $self->vectors( $sponsor_id, $targeting_type );
	}
    $sponsor_data_double->{'Vectors'}{$sponsor_id} = $count_vectors;

	# only look if vectors found
	my $count_neo_vectors = 0;
	my $count_blast_vectors = 0;
	if ( $count_vectors > 0 ) {
		$count_neo_vectors = $self->neo_vectors( $sponsor_id, $targeting_type );
		$count_blast_vectors = $self->blast_vectors( $sponsor_id, $targeting_type);
	}	
	$sponsor_data_double->{'Neomycin Vectors'}{$sponsor_id} = $count_neo_vectors;
	$sponsor_data_double->{'Blasticidin Vectors'}{$sponsor_id} = $count_blast_vectors;

	# only look if vectors found
	my $count_dna = 0;
	if ( $count_vectors > 0 ) {
		$count_dna = $self->dna( $sponsor_id, $targeting_type );
	}
    $sponsor_data_double->{'Valid DNA'}{$sponsor_id} = $count_dna;

    # only look if DNA found
	my $count_neo_dna = 0;
	my $count_blast_dna = 0;
	if ( $count_dna > 0 ) {
		$count_neo_dna = $self->neo_dna( $sponsor_id, $targeting_type );
		$count_blast_dna = $self->blast_dna( $sponsor_id, $targeting_type );
	}
	$sponsor_data_double->{'Neomycin Valid DNA'}{$sponsor_id} = $count_neo_dna;
	$sponsor_data_double->{'Blasticidin Valid DNA'}{$sponsor_id} = $count_blast_dna;

	# only look if dna found
	my $count_eps = 0;
	if ( $count_dna > 0 ) {
		$count_eps = $self->electroporations( $sponsor_id, $targeting_type );
	}
	$sponsor_data_double->{'1st Allele Electroporations'}{$sponsor_id} = $count_eps;

	# only look if electroporations found
	my $count_neo_eps = 0;
    my $count_blast_eps = 0;
	if ( $count_eps > 0 ) {
		$count_neo_eps = $self->resistance_electroporations( $sponsor_id, 'neoR' );
		$count_blast_eps = $self->resistance_electroporations( $sponsor_id, 'blastR' );
	} 
    $sponsor_data_double->{'Neomycin 1st Allele Electroporations'}{$sponsor_id} = $count_neo_eps;
    $sponsor_data_double->{'Blasticidin 1st Allele Electroporations'}{$sponsor_id} = $count_blast_eps;

	# only look if electroporations found
	my $count_second_eps = 0;
	if ( $count_eps > 0 ) {
		$count_second_eps = $self->second_electroporations( $sponsor_id, $targeting_type );
	} 
    $sponsor_data_double->{'2nd Allele Electroporations'}{$sponsor_id} = $count_second_eps;

	# only look if electroporations found
	my $count_clones = 0;
	if ( $count_eps > 0 ) {
		$count_clones = $self->clones( $sponsor_id, $targeting_type );
	} 
    $sponsor_data_double->{'Accepted Clones'}{$sponsor_id} = $count_clones;

}

# Generate front page report matrix
sub generate_top_level_report_for_sponsors {
	my $self = shift;	

    # filled from Sponsors table
	my $columns = $self->build_columns;

    # single- and double-targeted data filled by counting from DB
	my $st_data = $self->sponsor_data_single;
    my $dt_data = $self->sponsor_data_double;

	my $title = $self->build_name;

	my $st_rows = \@SINGLE_TARGETED_REPORT_CATEGORIES;
    my $dt_rows = \@DOUBLE_TARGETED_REPORT_CATEGORIES;

	my %return_params = (
		report_id => 'SponsRep',
        title     => $title,
        columns   => $columns,
		st_rows   => $st_rows,
		dt_rows   => $dt_rows,
        st_data   => $st_data,
        dt_data   => $dt_data,
	);

	return \%return_params;
}

# Set up SQL query to count targeted genes for a sponsor id
sub create_sql_count_targeted_gene_projects_for_sponsor {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

	DEBUG "building query with sponsor_id = ".$sponsor_id." and targeting_type = ".$targeting_type;

my $sql_query =  <<"SQL_END";
SELECT COUNT(sponsor_id) 
FROM projects 
WHERE sponsor_id = '$sponsor_id'
AND targeting_type = '$targeting_type'; 
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of vectors for single-targeted projects for a sponsor
sub create_sql_count_vectors_for_single_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_cassette_cre = pr.cre
AND s.final_cassette_promoter = pr.promoter
AND s.final_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_well_accepted = 't'
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of vectors for double-targeted projects for a sponsor
sub create_sql_count_vectors_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;
	
my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_pick_well_accepted = 't'
SQL_END

	return $sql_query;
}

# Set up SQL query to count vectors which contain specific resistance 
# cassettes for double-targeted projects for a sponsor
sub create_sql_count_resistance_vectors_for_double_targeted_sponsor_project {
    my ( $self, $sponsor_id, $resistance ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
INNER JOIN cassettes c ON c.name = s.final_pick_cassette_name
WHERE s.final_pick_well_accepted = 't'
AND c.resistance = '$resistance'
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of accepted DNA wells for single-targeted projects for a sponsor
sub create_sql_count_DNA_for_single_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_cassette_cre = pr.cre
AND s.final_cassette_promoter = pr.promoter
AND s.final_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_well_accepted = 't'
AND s.dna_status_pass = 't'
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of accepted DNA wells for double-targeted projects for a sponsor
sub create_sql_count_DNA_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of accepted resistance cassette DNA wells
# for double-targeted projects for a sponsor
sub create_sql_count_resistance_DNA_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id, $resistance ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
INNER JOIN cassettes c ON c.name = s.final_pick_cassette_name
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND c.resistance = '$resistance'
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of electroporations for single-targeted
# projects for a sponsor
sub create_sql_count_eps_for_single_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_cassette_cre = pr.cre
AND s.final_cassette_promoter = pr.promoter
AND s.final_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.ep_well_id > 0
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of first electroporations for double-targeted
# projects for a sponsor
sub create_sql_count_eps_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.ep_well_id > 0
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of 1st allele electroporations for a 
# specific resistance for double-targeted projects for a sponsor
sub create_sql_count_resistance_eps_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id, $resistance ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
INNER JOIN cassettes c ON c.name = s.final_pick_cassette_name
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.ep_well_id > 0
AND c.resistance = '$resistance'
SQL_END

	return $sql_query;
}

sub create_sql_count_second_eps_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.sep_well_id > 0
SQL_END

	return $sql_query;
}

sub create_sql_count_accepted_clones_for_single_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_cassette_cre = pr.cre
AND s.final_cassette_promoter = pr.promoter
AND s.final_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.ep_well_id > 0
AND s.ep_pick_well_accepted = 't'
SQL_END

	return $sql_query;
}

sub create_sql_count_accepted_clones_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT count(distinct(s.design_gene_id)) 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.sep_well_id > 0
AND s.sep_pick_well_accepted = 't'
SQL_END

	return $sql_query;
}

# Generic method to run count SQL
sub run_count_query {
   my ( $self, $sql_query ) = @_;

   my $count = 0;

   my $sql_result = $self->model->schema->storage->dbh_do(
      sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare( $sql_query );
         $sth->execute or die "Unable to execute query: $dbh->errstr\n";
         my @ret = $sth->fetchrow_array;
		 $count = $ret[0]; 
      }
   );

	return $count;
}

sub genes {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding targeted genes for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

	my $sql_query = $self->create_sql_count_targeted_gene_projects_for_sponsor( $sponsor_id, $targeting_type );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub vectors {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding vectors for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

	my $sql_query;

	if( $targeting_type eq 'single_targeted' ) {
       $sql_query = $self->create_sql_count_vectors_for_single_targeted_sponsor_project( $sponsor_id );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
       $sql_query = $self->create_sql_count_vectors_for_double_targeted_sponsor_project( $sponsor_id );
	}
    else {
       return 0;
    } 

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub neo_vectors {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding neoR vectors for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

    my $resistance = 'neoR'; 

	my $sql_query = $self->create_sql_count_resistance_vectors_for_double_targeted_sponsor_project( $sponsor_id, $resistance );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub blast_vectors {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding blastR vectors for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

	my $resistance = 'blastR';

	my $sql_query = $self->create_sql_count_resistance_vectors_for_double_targeted_sponsor_project( $sponsor_id, $resistance );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub dna {
	my ( $self, $sponsor_id, $targeting_type ) = @_;
    
    DEBUG "finding dna for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

    my $sql_query;

	if( $targeting_type eq 'single_targeted' ) {
       $sql_query = $self->create_sql_count_DNA_for_single_targeted_sponsor_project( $sponsor_id );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
       $sql_query = $self->create_sql_count_DNA_for_double_targeted_sponsor_project( $sponsor_id );
	}
    else {
       return 0;
    } 

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub neo_dna {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding neoR dna for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

    my $resistance = 'neoR'; 

	my $sql_query = $self->create_sql_count_resistance_DNA_for_double_targeted_sponsor_project( $sponsor_id, $resistance );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub blast_dna {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding neoR dna for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

    my $resistance = 'blastR'; 

	my $sql_query = $self->create_sql_count_resistance_DNA_for_double_targeted_sponsor_project( $sponsor_id, $resistance );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub electroporations {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding electroporations for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

	my $sql_query;	

	if( $targeting_type eq 'single_targeted' ) {
       $sql_query = $self->create_sql_count_eps_for_single_targeted_sponsor_project( $sponsor_id );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
       $sql_query = $self->create_sql_count_eps_for_double_targeted_sponsor_project( $sponsor_id );
	}
    else {
       return 0;
    } 

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub resistance_electroporations {
	my ( $self, $sponsor_id, $resistance ) = @_;

    DEBUG "finding ".$resistance." electroporations for sponsor id = ".$sponsor_id;

	my $count = 0;
	my $sql_query;	

	$sql_query = $self->create_sql_count_resistance_eps_for_double_targeted_sponsor_project( $sponsor_id, $resistance );
	
	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub second_electroporations {
	my ( $self, $sponsor_id ) = @_;

    DEBUG "finding second electroporations for sponsor id = ".$sponsor_id;

	my $count = 0;

	my $sql_query;	

	$sql_query = $self->create_sql_count_second_eps_for_double_targeted_sponsor_project( $sponsor_id );
	
	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub clones {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding clones for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

	my $sql_query;	

	if( $targeting_type eq 'single_targeted' ) {
       $sql_query = $self->create_sql_count_accepted_clones_for_single_targeted_sponsor_project( $sponsor_id );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
       $sql_query = $self->create_sql_count_accepted_clones_for_double_targeted_sponsor_project( $sponsor_id );
	}
    else {
       return 0;
    } 

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_count_query( $sql_query );

    return $count;
}

sub build_name {
    my $self = shift;

    my $dt = DateTime->now();

    return 'Pipeline Summary Report on ' . $dt->dmy;
};

sub build_columns {
    my $self = shift;

    return [
        'Stage',
        @{ $self->sponsors }
    ];
};

#----------------------------------------------------------
# Sub-reports
#----------------------------------------------------------

has sub_report_data => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

# Generate a sub-report for a specific targeting type, stage and sponsor
sub generate_sub_report {
	my ($self, $sponsor_id, $targeting_type, $stage) = @_;

	# reports differ based on combination of targeting type and stage
	
	# TODO: will initially just display same data for all
	my $data = $self->_build_sub_report_data($sponsor_id, $targeting_type, $stage);

	my ($columns, $display_columns, $display_targeting_type, $display_stage);
	
	if ( $targeting_type eq 'single_targeted' ) {
		$display_targeting_type = 'single-targeted';
		if ( $stage eq 'Targeted Genes' ) {			
			$display_stage = 'Targeted genes';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'number_of_designs' ];
			$display_columns = [ 'gene id', 'gene symbol', 'number of designs' ];
		}
		elsif ( $stage eq 'Vectors' ) {
			$display_stage = 'Vectors';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'backbone_name', 'cassette_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'backbone name', 'cassette name' ];
		}
		elsif ( $stage eq 'Valid DNA' ) {
			$display_stage = 'Valid DNA';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'dna_plate_name', 'dna_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
		elsif ( $stage eq '1st Allele Electroporations' ) {
			$display_stage = '1st Allele Electroporations';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'ep_plate_name', 'ep_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
       elsif ( $stage eq 'Accepted Clones' ) {
			$display_stage = 'Accepted Clones';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'ep_pick_plate_name', 'ep_pick_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
		else {
			# TODO: Error unknown type
		}
	} 
	elsif ( $targeting_type eq 'double_targeted' ) {
		$display_targeting_type = 'double-targeted';
		if ( $stage eq 'Targeted Genes' ) {
			$display_stage = 'Targeted genes';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'number_of_designs' ];
			$display_columns = [ 'gene id', 'gene symbol', 'number of designs' ];
		}
		elsif ( $stage eq 'Vectors' ) {
			$display_stage = 'Vectors';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'backbone_name', 'cassette_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'backbone name', 'cassette name' ];
		}
		elsif ( $stage eq 'Neomycin Vectors' ) {
			$display_stage = 'Neomycin-resistant Vectors';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'backbone_name', 'cassette_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'backbone name', 'cassette name' ];
		}
		elsif ( $stage eq 'Blasticidin Vectors' ) {
			$display_stage = 'Blasticidin-resistant Vectors';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'backbone_name', 'cassette_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'backbone name', 'cassette name' ];
		}
		elsif ( $stage eq 'Valid DNA' ) {
			$display_stage = 'Valid DNA';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'dna_plate_name', 'dna_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
		elsif ( $stage eq 'Neomycin Valid DNA' ) {
			$display_stage = 'Neomycin-resistant Valid DNA';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'dna_plate_name', 'dna_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
		elsif ( $stage eq 'Blasticidin-resistant Valid DNA' ) {
			$display_stage = 'Valid DNA';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'dna_plate_name', 'dna_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
		elsif ( $stage eq '1st Allele Electroporations' ) {
			$display_stage = '1st Allele Electroporations';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'ep_plate_name', 'ep_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
		elsif ( $stage eq 'Neomycin 1st Allele Electroporations' ) {
			$display_stage = 'Neomycin 1st Allele Electroporations';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'ep_plate_name', 'ep_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
		elsif ( $stage eq 'Blasticidin 1st Allele Electroporations' ) {
			$display_stage = 'Blasticidin 1st Allele Electroporations';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'ep_plate_name', 'ep_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
		elsif ( $stage eq '2nd Allele Electroporations' ) {
			$display_stage = '2nd Allele Electroporations';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'sep_plate_name', 'sep_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
       elsif ( $stage eq 'Accepted Clones' ) {
			$display_stage = 'Accepted Clones';
    		$columns = [ 'design_gene_id', 'design_gene_symbol', 'sep_pick_plate_name', 'sep_pick_well_name' ];
			$display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
		}
		else {
			# TODO: Error unknown type
		}
	}

	my %return_params = (
		'report_id' 		=> 'SponsRepSub',
		'disp_target_type'  => $display_targeting_type,
		'disp_stage'        => $display_stage,
        'columns'   		=> $columns,
		'display_columns' 	=> $display_columns,
        'data'   	  		=> $data,
	);

	return \%return_params;
}

sub _build_sub_report_data {
	my ($self, $sponsor_id, $targeting_type, $stage) = @_;
	
	my $sub_report_data;

	if ( $targeting_type eq 'single_targeted' ) {
		if ( $stage eq 'Targeted Genes' ) {
			$sub_report_data = $self->targeted_genes_report( $sponsor_id, $targeting_type );
		}
		elsif ( $stage eq 'Vectors' ) {
			$sub_report_data = $self->vectors_report ( $sponsor_id, $targeting_type );
		}

		elsif ( $stage eq 'Valid DNA' ) {
	       $sub_report_data = $self->valid_dna_report( $sponsor_id, $targeting_type );
		}
		elsif ( $stage eq '1st Allele Electroporations' ) {
	       $sub_report_data = $self->electroporations_report( $sponsor_id, $targeting_type );
		}
		elsif ( $stage eq 'Accepted Clones' ) {
	       $sub_report_data = $self->accepted_clones_report( $sponsor_id, $targeting_type 		);
		}
		else {
			# TODO: Error unknown type
		}
	} 
	elsif ( $targeting_type eq 'double_targeted' ) {
		if ( $stage eq 'Targeted Genes' ) {
			$sub_report_data = $self->targeted_genes_report( $sponsor_id, $targeting_type );
		}
		elsif ( $stage eq 'Vectors' ) {
			$sub_report_data = $self->vectors_report ( $sponsor_id, $targeting_type );
		}
		elsif ( $stage eq 'Neomycin Vectors' ) {
			$sub_report_data = $self->vectors_for_resistance_report( $sponsor_id, 'neoR' );
		}
		elsif ( $stage eq 'Blasticidin Vectors' ) {
			$sub_report_data = $self->vectors_for_resistance_report( $sponsor_id, 'blastR' );
		}
		elsif ( $stage eq 'Valid DNA' ) {
			$sub_report_data = $self->valid_dna_report( $sponsor_id, $targeting_type );
		}
		elsif ( $stage eq 'Neomycin Valid DNA' ) {
			$sub_report_data = $self->valid_dna_for_resistance_report( $sponsor_id, 'neoR' );
		}
		elsif ( $stage eq 'Blasticidin Valid DNA' ) {
			$sub_report_data = $self->valid_dna_for_resistance_report( $sponsor_id, 'blastR' );
		}
		elsif ( $stage eq '1st Allele Electroporations' ) {
	       $sub_report_data = $self->electroporations_report( $sponsor_id, $targeting_type );
		}
		elsif ( $stage eq 'Neomycin 1st Allele Electroporations' ) {
	       $sub_report_data = $self->first_electroporations_resistance_report( $sponsor_id, 'neoR' );
		}
		elsif ( $stage eq 'Blasticidin 1st Allele Electroporations' ) {
	       $sub_report_data = $self->first_electroporations_resistance_report( $sponsor_id, 'blastR' );
		}
		elsif ( $stage eq '2nd Allele Electroporations' ) {
	       $sub_report_data = $self->second_electroporations_report( $sponsor_id );
		}
		elsif ( $stage eq 'Accepted Clones' ) {
	       $sub_report_data = $self->accepted_clones_report( $sponsor_id, $targeting_type 		);
		}

		else {
			# TODO: Error unknown type
		}
	}
	#TODO: other stages + error handling

	# sub_report_data is a ref to an array of hashrefs

    return $sub_report_data;
}

# Set up SQL query to select targeted genes for a specific sponsor and targeting type
sub create_sql_select_targeted_genes {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

my $sql_query =  <<"SQL_END";
SELECT s.design_gene_id, s.design_gene_symbol, count(distinct(s.design_well_id)) AS number_of_designs
 FROM summaries s
 INNER JOIN projects p ON p.gene_id = s.design_gene_id 
 WHERE p.sponsor_id = '$sponsor_id'
 AND p.targeting_type = '$targeting_type'
 GROUP by s.design_gene_id, s.design_gene_symbol
 ORDER BY s.design_gene_symbol
SQL_END

	return $sql_query;
}

# Set up SQL query to select vectors for a single targeted project
sub create_sql_select_vectors_for_single_targeted_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_backbone_name AS backbone_name, s.final_cassette_name AS cassette_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_cassette_cre = pr.cre
AND s.final_cassette_promoter = pr.promoter
AND s.final_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
INNER JOIN cassettes c ON s.final_cassette_name = c.name
WHERE s.final_well_accepted = 't'
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_backbone_name, s.final_cassette_name
ORDER BY s.design_gene_symbol, s.final_cassette_name
SQL_END

	return $sql_query;
}

# Set up SQL query to select vectors for a double targeted project
sub create_sql_select_vectors_for_double_targeted_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_backbone_name AS backbone_name, s.final_pick_cassette_name AS cassette_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_pick_well_accepted = 't'
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_backbone_name, s.final_pick_cassette_name
ORDER BY s.design_gene_symbol, s.final_pick_cassette_name
SQL_END

	return $sql_query;
}

# Set up SQL query to select vectors with a specific resistance for a double-targeted project
sub create_sql_select_resistance_vectors_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id, $resistance ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_backbone_name AS backbone_name, s.final_pick_cassette_name AS cassette_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
INNER JOIN cassettes c ON c.name = s.final_pick_cassette_name
WHERE s.final_pick_well_accepted = 't'
AND c.resistance = '$resistance'
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_backbone_name, s.final_pick_cassette_name
 ORDER BY s.design_gene_symbol, s.final_pick_cassette_name
SQL_END

	return $sql_query;
}

# TODO: NB. Cre Knockin single-targeted projects have c.cre = t, others may not

# Set up SQL query to select accepted DNA wells for single-targeted projects
sub create_sql_select_DNA_for_single_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_cassette_cre = pr.cre
AND s.final_cassette_promoter = pr.promoter
AND s.final_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
INNER JOIN cassettes c ON c.name = s.final_cassette_name
WHERE s.final_well_accepted = 't'
AND s.dna_status_pass = 't'
GROUP by s.design_gene_id, s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_END

	return $sql_query;
}

# Set up SQL query to select accepted DNA wells for double-targeted projects
sub create_sql_select_DNA_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
INNER JOIN cassettes c ON c.name = s.final_pick_cassette_name
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
GROUP by s.design_gene_id, s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_END

	return $sql_query;
}

# Set up SQL query to select valid DNA with a specific resistance for a double-targeted project
sub create_sql_select_resistance_valid_DNA_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id, $resistance ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
INNER JOIN cassettes c ON c.name = s.final_pick_cassette_name
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND c.resistance = '$resistance' 
GROUP by s.design_gene_id, s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_END

	return $sql_query;
}

sub create_sql_select_electroporations_for_single_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_cassette_cre = pr.cre
AND s.final_cassette_promoter = pr.promoter
AND s.final_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.ep_well_id > 0
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_END

	return $sql_query;
}

sub create_sql_select_first_electroporations_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.ep_well_id > 0
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_END

	return $sql_query;
}

sub create_sql_select_resistance_first_eps_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id, $resistance ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
INNER JOIN cassettes c ON c.name = s.final_pick_cassette_name
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.ep_well_id > 0
AND c.resistance = '$resistance'
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_END

	return $sql_query;
}

sub create_sql_select_second_eps_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_plate_name, s.sep_well_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.sep_well_id > 0
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_plate_name, s.sep_well_name
ORDER BY s.design_gene_symbol, s.sep_plate_name, s.sep_well_name
SQL_END

	return $sql_query;
}

sub create_sql_select_accepted_clones_for_single_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name 
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_cassette_cre = pr.cre
AND s.final_cassette_promoter = pr.promoter
AND s.final_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.ep_well_id > 0
AND s.ep_pick_well_accepted = 't'
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
ORDER BY s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
SQL_END

	return $sql_query;
}

sub create_sql_select_accepted_clones_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id 
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_pick_plate_name, s.sep_pick_well_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
AND s.final_pick_cassette_cre = pr.cre
AND s.final_pick_cassette_promoter = pr.promoter
AND s.final_pick_cassette_conditional = pr.conditional
AND
(
CASE 
    WHEN pr.well_has_cre = 't' THEN s.final_pick_recombinase_id = 'Cre'
    WHEN pr.well_has_cre = 'f' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
END  
)
AND
(
CASE
   WHEN pr.well_has_no_recombinase = 't' THEN (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL)
   WHEN pr.well_has_no_recombinase = 'f' THEN s.final_pick_recombinase_id IS NOT NULL
END
)
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
WHERE s.final_pick_well_accepted = 't'
AND s.dna_status_pass = 't'
AND s.sep_well_id > 0
AND s.sep_pick_well_accepted = 't'
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_pick_plate_name, s.sep_pick_well_name
ORDER BY s.design_gene_symbol, s.sep_pick_plate_name, s.sep_pick_well_name
SQL_END

	return $sql_query;
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

sub targeted_genes_report {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG 'selecting targeted genes for sponsor id = '.$sponsor_id.' and targeting_type = '.$targeting_type;

	my $sql_results;

	my $sql_query = $self->create_sql_select_targeted_genes( $sponsor_id, $targeting_type );

	DEBUG "sql query = ".$sql_query;

	$sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub vectors_report {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG 'selecting vectors for sponsor id = '.$sponsor_id.' and targeting_type = '.$targeting_type;

	my $sql_results;
	my $sql_query;

	if ( $targeting_type eq 'single_targeted' ) { 
		$sql_query = $self->create_sql_select_vectors_for_single_targeted_project( $sponsor_id );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
		$sql_query = $self->create_sql_select_vectors_for_double_targeted_project( $sponsor_id );
	}
	# TODO : else error?

	DEBUG "sql query = ".$sql_query;

	$sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub vectors_for_resistance_report {
	my ( $self, $sponsor_id, $resistance ) = @_;

    DEBUG 'selecting vectors with resistance '.$resistance.' for sponsor id = '.$sponsor_id;

	my $sql_results;

	my $sql_query = $self->create_sql_select_resistance_vectors_for_double_targeted_sponsor_project( $sponsor_id, $resistance );

	DEBUG "sql query = ".$sql_query;

	$sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub valid_dna_report {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG 'selecting valid DNA for sponsor id = '.$sponsor_id.' and targeting_type = '.$targeting_type;

	my $sql_results;
	my $sql_query;

	if ( $targeting_type eq 'single_targeted' ) { 
		$sql_query = $self->create_sql_select_DNA_for_single_targeted_sponsor_project( $sponsor_id );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
		$sql_query = $self->create_sql_select_DNA_for_double_targeted_sponsor_project( $sponsor_id );
	}
	# TODO : else error?

	DEBUG "sql query = ".$sql_query;

	$sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub valid_dna_for_resistance_report {
	my ( $self, $sponsor_id, $resistance ) = @_;

    DEBUG 'selecting valid DNA with resistance '.$resistance.' for sponsor id = '.$sponsor_id;

	my $sql_results;

	my $sql_query = $self->create_sql_select_resistance_valid_DNA_for_double_targeted_sponsor_project( $sponsor_id, $resistance );

	DEBUG "sql query = ".$sql_query;

	$sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub electroporations_report {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG 'selecting electroporations for single-targeted projects for sponsor id = '.$sponsor_id;

	my $sql_results;

	my $sql_query;

	if ( $targeting_type eq 'single_targeted' ) { 
		$sql_query = $self->create_sql_select_electroporations_for_single_targeted_sponsor_project( $sponsor_id );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
		$sql_query = $self->create_sql_select_first_electroporations_for_double_targeted_sponsor_project( $sponsor_id );
	}
	# TODO : else error?

	DEBUG "sql query = ".$sql_query;

	$sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}


sub first_electroporations_resistance_report {
	my ( $self, $sponsor_id, $resistance ) = @_;

    DEBUG 'selecting first electroporations with resistance '.$resistance.' for sponsor id = '.$sponsor_id;

	my $sql_results;

	my $sql_query = $self->create_sql_select_resistance_first_eps_for_double_targeted_sponsor_project( $sponsor_id, $resistance );

	DEBUG "sql query = ".$sql_query;

	$sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub second_electroporations_report {
	my ( $self, $sponsor_id, $resistance ) = @_;

    DEBUG 'selecting second electroporations for sponsor id = '.$sponsor_id;

	my $sql_results;

	my $sql_query = $self->create_sql_select_second_eps_for_double_targeted_sponsor_project( $sponsor_id );

	DEBUG "sql query = ".$sql_query;

	$sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub accepted_clones_report {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG 'selecting accepted clones for '.$targeting_type.' projects for sponsor id = '.$sponsor_id;

	my $sql_results;

	my $sql_query;

	if ( $targeting_type eq 'single_targeted' ) { 
		$sql_query = $self->create_sql_select_accepted_clones_for_single_targeted_sponsor_project( $sponsor_id );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
		$sql_query = $self->create_sql_select_accepted_clones_for_double_targeted_sponsor_project( $sponsor_id );
	}
	# TODO : else error?

	DEBUG "sql query = ".$sql_query;

	$sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}
1;