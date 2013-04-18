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
use Smart::Comments;

Log::Log4perl->easy_init($DEBUG);

extends qw( LIMS2::ReportGenerator );

# Rows on report view
Readonly my @SINGLE_TARGETED_REPORT_CATEGORIES => (
	'Targeting',
    'Targeted Genes',
    'Vectors',
    'Valid DNA',
    'First Electroporations',
    'Accepted ES Clones',
);

Readonly my @DOUBLE_TARGETED_REPORT_CATEGORIES => (
	'Targeting',
    'Targeted Genes',
    'Vectors',
    'Vectors Neo and Bsd',
    'Vectors Neo only',
    'Vectors Bsd only',
    'Valid DNA',
    'Valid DNA Neo and Bsd',
    'Valid DNA Neo only',
    'Valid DNA Bsd only',
    'First Electroporations',
    'First Electroporations Neo only',
    'First Electroporations Bsd only',
    'Second Electroporations',
    'Accepted ES Clones',
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

has sponsor_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_sponsor_data {
    my $self = shift;
    my %sponsor_data;

    my @sponsor_ids = @{ $self->sponsors };

    ### @sponsor_ids

    foreach my $sponsor_id ( @sponsor_ids ) {
        DEBUG "building data for sponsor id = ".$sponsor_id;
        $self->_build_sponsor_column_data( $sponsor_id, \%sponsor_data );
    }

    return \%sponsor_data;
}

sub _build_sponsor_column_data {
    my ( $self, $sponsor_id, $sponsor_data ) = @_;

    DEBUG "building column data for sponsor id = ".$sponsor_id;
    
    # select what targeting types this project has and how many genes it is targeting
    my $sponsor_tt_counts = $self->select_sponsor_targeting_type_and_genes( $sponsor_id );

    ### $sponsor_tt_counts

    foreach my $sponsor_tt ( @$sponsor_tt_counts ) {

        my $targeting_type = $sponsor_tt->{ targeting_type };
        my $number_genes = $sponsor_tt->{ genes };
        
        DEBUG "targeting_type = ".$targeting_type;
        DEBUG "number genes = ".$number_genes;
       
		if ( $targeting_type eq 'single_targeted' ) {
			# if it has single-targeted projects fill in single-targeted data
			$self->_build_single_targeted_column_data( $sponsor_id, $sponsor_data, $targeting_type, $number_genes );
		}
		elsif ( $targeting_type eq 'double_targeted' ) {
			# if it has double_targeted projects fetch double-targeted data
			$self->_build_double_targeted_column_data( $sponsor_id, $sponsor_data, $targeting_type, $number_genes );
		}
    }
}

sub _build_single_targeted_column_data {

	my ( $self, $sponsor_id, $sponsor_data, $targeting_type, $number_genes ) = @_;

	DEBUG "fetching column data for single-targeted projects ";

	$sponsor_data->{'Targeting'}{$sponsor_id} = $targeting_type;

	my $count_tgs = $number_genes;
	$sponsor_data->{'Targeted Genes'}{$sponsor_id} = $count_tgs;

	# only look if targeted genes found
	my $count_vectors = 0;
	if ( $count_tgs > 0 ) {
	  $count_vectors = $self->vectors( $sponsor_id, $targeting_type );
	}
	$sponsor_data->{'Vectors'}{$sponsor_id} = $count_vectors;

	$sponsor_data->{'Vectors Neo and Bsd'}{$sponsor_id} = -1;
	$sponsor_data->{'Vectors Neo only'}{$sponsor_id} = -1;
	$sponsor_data->{'Vectors Bsd only'}{$sponsor_id} = -1;

	# only look if vectors found
	my $count_dna = 0;
	if ( $count_vectors > 0 ) {
	  $count_dna = $self->dna( $sponsor_id, $targeting_type );
	}
	$sponsor_data->{'Valid DNA'}{$sponsor_id} = $count_dna;

	$sponsor_data->{'Valid DNA Neo and Bsd'}{$sponsor_id} = -1;
	$sponsor_data->{'Valid DNA Neo only'}{$sponsor_id} = -1;
	$sponsor_data->{'Valid DNA Bsd only'}{$sponsor_id} = -1;

	# only look if dna found
	my $count_eps = 0;
	if ( $count_dna > 0 ) {
	  $count_eps = $self->electroporations( $sponsor_id, $targeting_type );
	}
	$sponsor_data->{'First Electroporations'}{$sponsor_id} = $count_eps;

	$sponsor_data->{'First Electroporations Neo only'}{$sponsor_id} = -1;
	$sponsor_data->{'First Electroporations Bsd only'}{$sponsor_id} = -1;

	$sponsor_data->{'Second Electroporations'}{$sponsor_id} = -1;

	# only look if first electroporations found
	my $count_clones = 0;
	if ( $count_eps > 0 ) {
	  $count_clones = $self->clones( $sponsor_id, $targeting_type );
	} 
	$sponsor_data->{'Accepted ES Clones'}{$sponsor_id} = $count_clones;

}

sub _build_double_targeted_column_data {
  
	my ( $self, $sponsor_id, $sponsor_data, $targeting_type, $number_genes ) = @_;

	DEBUG "fetching column data for double-targeted projects ";

	$sponsor_data->{'Targeting'}{$sponsor_id} = $targeting_type;

	my $count_tgs = $number_genes;
	$sponsor_data->{'Targeted Genes'}{$sponsor_id} = $count_tgs;

	# only look if targeted genes found
	my $count_vectors = 0;
	if ( $count_tgs > 0 ) {
	  $count_vectors = $self->vectors( $sponsor_id, $targeting_type );
	}
	$sponsor_data->{'Vectors'}{$sponsor_id} = $count_vectors;

	# only look if vectors found
	my $count_neo_vectors = 0;
	my $count_blast_vectors = 0;
	if ( $count_vectors > 0 ) {
	  $count_neo_vectors = $self->resistance_vectors( $sponsor_id, $targeting_type, 'neoR' );
	  $count_blast_vectors = $self->resistance_vectors( $sponsor_id, $targeting_type, 'blastR' );
	}   
	$sponsor_data->{'Vectors Neo only'}{$sponsor_id} = $count_neo_vectors;
	$sponsor_data->{'Vectors Bsd only'}{$sponsor_id} = $count_blast_vectors;

	# only look if vectors found
	my $count_dna = 0;
	if ( $count_vectors > 0 ) {
	  $count_dna = $self->dna( $sponsor_id, $targeting_type );
	}
	$sponsor_data->{'Valid DNA'}{$sponsor_id} = $count_dna;

	# only look if DNA found
	my $count_neo_dna = 0;
	my $count_blast_dna = 0;
	if ( $count_dna > 0 ) {
	  $count_neo_dna = $self->resistance_dna( $sponsor_id, $targeting_type, 'neoR' );
	  $count_blast_dna = $self->resistance_dna( $sponsor_id, $targeting_type, 'blastR' );
	}
	$sponsor_data->{'Valid DNA Neo only'}{$sponsor_id} = $count_neo_dna;
	$sponsor_data->{'Valid DNA Bsd only'}{$sponsor_id} = $count_blast_dna;

	# only look if dna found
	my $count_eps = 0;
	if ( $count_dna > 0 ) {
	  $count_eps = $self->electroporations( $sponsor_id, $targeting_type );
	}
	$sponsor_data->{'First Electroporations'}{$sponsor_id} = $count_eps;

	# only look if electroporations found
	my $count_neo_eps = 0;
	my $count_blast_eps = 0;
	if ( $count_eps > 0 ) {
	  $count_neo_eps = $self->resistance_electroporations( $sponsor_id, $targeting_type, 'neoR' );
	  $count_blast_eps = $self->resistance_electroporations( $sponsor_id, $targeting_type, 'blastR' );
	} 
	$sponsor_data->{'First Electroporations Neo only'}{$sponsor_id} = $count_neo_eps;
	$sponsor_data->{'First Electroporations Bsd only'}{$sponsor_id} = $count_blast_eps;

	# only look if electroporations found
	my $count_second_eps = 0;
	if ( $count_eps > 0 ) {
	  $count_second_eps = $self->second_electroporations( $sponsor_id, $targeting_type );
	} 
	$sponsor_data->{'Second Electroporations'}{$sponsor_id} = $count_second_eps;

	# only look if electroporations found
	my $count_clones = 0;
	if ( $count_eps > 0 ) {
	  $count_clones = $self->clones( $sponsor_id, $targeting_type );
	} 
	$sponsor_data->{'Accepted ES Clones'}{$sponsor_id} = $count_clones;

}

sub select_sponsor_targeting_type_and_genes {
    my ( $self, $sponsor_id ) = @_;
    
    DEBUG "selecting targeting type and genes for sponsor id = ".$sponsor_id;

    my $sql_results;

    my $sql_query = $self->create_sql_select_targeting_type_and_genes_for_a_sponsor( $sponsor_id );

    DEBUG "sql query = ".$sql_query;

    $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

# Generate front page report matrix
sub generate_top_level_report_for_sponsors {
    my $self = shift;   

    # filled from Sponsors table
    my $columns = $self->build_columns;

    my $data = $self->sponsor_data;

	DEBUG '-------------- MAIN DATA ---------------------';
	### $data
	DEBUG '------------- END MAIN DATA ------------------';

    my $title = $self->build_name;

    my $st_rows = \@SINGLE_TARGETED_REPORT_CATEGORIES;
    my $dt_rows = \@DOUBLE_TARGETED_REPORT_CATEGORIES;

    my %return_params = (
        report_id => 'SponsRep',
        title     => $title,
        columns   => $columns,
        st_rows   => $st_rows,
        dt_rows   => $dt_rows,
		data      => $data,
    );

    return \%return_params;
}

# Set up SQL query to select targeting type and genes for a sponsor id
sub create_sql_select_targeting_type_and_genes_for_a_sponsor {
    my ( $self, $sponsor_id ) = @_;
    
my $sql_query =  <<"SQL_END";
SELECT sponsor_id, targeting_type, count(id) AS genes
FROM  projects
WHERE sponsor_id = '$sponsor_id'
GROUP BY sponsor_id, targeting_type
ORDER BY targeting_type DESC, sponsor_id ASC
SQL_END

    return $sql_query;
}

# Set up SQL query to count targeted genes for a sponsor id
# sub create_sql_count_targeted_gene_projects_for_sponsor {
#   my ( $self, $sponsor_id, $targeting_type ) = @_;
# 
#   DEBUG "building query with sponsor_id = ".$sponsor_id." and targeting_type = ".$targeting_type;
# 
# my $sql_query =  <<"SQL_END";
# SELECT COUNT(sponsor_id) 
# FROM projects 
# WHERE sponsor_id = '$sponsor_id'
# AND targeting_type = '$targeting_type'; 
# SQL_END
# 
#   return $sql_query;
# }

# Dynamically generate SQL query
sub generate_sql {
    my ($self, $params ) = @_;

    ### $params 

    # params hash contains:
    # 'sql_type' = 'count' or 'select'
    # 'targeting_type' = 'single_targeted' or 'double_targeted'
    # 'stage' = 'vectors', 'dna', 'fep', 'sep', 'clones'
    # 'use_resistance' = 't' or 'f'
    # 'resistance_type' = 'neoR' or 'blastR'
    # 'use_promoter' = 't' or 'f'
    # 'is_promoterless' = 't' or 'f'

    my $sql_type        = $params->{ 'sql_type' };
    my $sponsor_id      = $params->{ 'sponsor_id' };
    my $targeting_type  = $params->{ 'targeting_type' };
    my $stage           = $params->{ 'stage' };
    my $use_resistance  = $params->{ 'use_resistance' };
    my $resistance_type = $params->{ 'resistance_type' };
    my $use_promoter    = $params->{ 'use_promoter' };
    my $is_promoterless = $params->{ 'is_promoterless' };

my $sql_query;

my $sql_query_with =  <<"SQL_WITH_END";
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
AND p.targeting_type = '$targeting_type'
)
SQL_WITH_END

my $sql_query_count = <<"SQL_COUNT_END";
SELECT count(distinct(s.design_gene_id))
SQL_COUNT_END

my $sql_query_select_st_vectors = <<"SQL_SELECT_ST_VECTORS_END";
SELECT s.design_gene_id, s.design_gene_symbol, s.final_cassette_name AS cassette_name, s.final_plate_name AS plate_name, s.final_well_name AS well_name
SQL_SELECT_ST_VECTORS_END

my $sql_query_select_dt_vectors = <<"SQL_SELECT_DT_VECTORS_END";
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name, s.final_pick_plate_name AS plate_name, s.final_pick_well_name AS well_name
SQL_SELECT_DT_VECTORS_END

my $sql_query_select_dna = <<"SQL_SELECT_DNA_END";
SELECT s.design_gene_id, s.design_gene_symbol, s.dna_plate_name AS plate_name, s.dna_well_name AS well_name
SQL_SELECT_DNA_END

my $sql_query_select_fep = <<"SQL_SELECT_FEP_END";
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name AS plate_name, s.ep_well_name AS well_name
SQL_SELECT_FEP_END

my $sql_query_select_sep = <<"SQL_SELECT_SEP_END";
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_plate_name AS plate_name, s.sep_well_name AS well_name
SQL_SELECT_SEP_END

my $sql_query_select_st_clones = <<"SQL_SELECT_ST_CLONES_END";
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_pick_plate_name AS plate_name, s.ep_pick_well_name AS well_name
SQL_SELECT_ST_CLONES_END

my $sql_query_select_dt_clones = <<"SQL_SELECT_DT_CLONES_END";
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_pick_plate_name AS plate_name, s.sep_pick_well_name AS well_name
SQL_SELECT_DT_CLONES_END

my $sql_query_body_final = <<"SQL_BODY_FINALS_END";
FROM summaries s
INNER JOIN cassettes c ON c.name = s.final_cassette_name
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE s.final_qc_seq_pass = true
AND s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
AND (
    (pr.conditional IS NULL) 
    OR 
    (
        pr.conditional IS NOT NULL AND (
            (c.resistance = 'neoR' AND s.final_cassette_conditional = pr.conditional) 
            OR 
            (
                c.resistance = 'blastR' AND (
                    (pr.conditional = true AND s.final_cassette_conditional) 
                    OR 
                    (pr.conditional = false AND s.final_cassette_conditional)
                )
            )
        )
    )
)
AND (
    (pr.promoter IS NULL) 
    OR 
    (pr.promoter IS NOT NULL AND pr.promoter = s.final_cassette_promoter)
)
AND (
    (pr.cre IS NULL) 
    OR 
    (pr.cre IS NOT NULL AND s.final_cassette_cre = pr.cre)
)
AND (
    (pr.well_has_cre IS NULL) 
    OR 
    (
        (pr.well_has_cre = true AND s.final_recombinase_id = 'Cre') 
        OR 
        (pr.well_has_cre = false AND (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL))
    )
)
AND (
    (pr.well_has_no_recombinase IS NULL) 
    OR 
    (        
        pr.well_has_no_recombinase IS NOT NULL AND (
            (pr.well_has_no_recombinase = true AND (s.final_recombinase_id = '' OR s.final_recombinase_id IS NULL))
            OR 
            (pr.well_has_no_recombinase = false AND s.final_recombinase_id IS NOT NULL)
        )
    )
)
SQL_BODY_FINALS_END

my $sql_where_vectors = <<"SQL_WHERE_VECTORS_END";
AND (
    (pr.targeting_type = 'single_targeted' AND s.final_qc_seq_pass = true)
    OR
    (pr.targeting_type = 'double_targeted' AND s.final_pick_qc_seq_pass = true)
)
SQL_WHERE_VECTORS_END

my $sql_where_dna = <<"SQL_WHERE_DNA_END";
AND s.dna_status_pass = true
SQL_WHERE_DNA_END

my $sql_where_fep = <<"SQL_WHERE_FEP_END";
AND s.ep_well_id > 0
SQL_WHERE_FEP_END

my $sql_where_sep = <<"SQL_WHERE_SEP_END";
AND s.sep_well_id > 0
SQL_WHERE_SEP_END

my $sql_where_clones = <<"SQL_WHERE_CLONES_END";
AND (
    (pr.targeting_type = 'single_targeted' AND s.ep_pick_well_accepted = true)
    OR
    (pr.targeting_type = 'double_targeted' AND s.sep_pick_well_accepted = true)
)
SQL_WHERE_CLONES_END

my $sql_where_resistance;
if ( defined $resistance_type ) {
$sql_where_resistance = <<"SQL_WHERE_RESISTANCE_END";
AND c.resistance = '$resistance_type'
SQL_WHERE_RESISTANCE_END
}

my $sql_where_promoter = <<"SQL_WHERE_P_END";
AND (
    (pr.targeting_type = 'single_targeted' AND s.final_cassette_promoter = true)
    OR
    (pr.targeting_type = 'double_targeted' AND s.final_pick_cassette_promoter = true)
)
SQL_WHERE_P_END

my $sql_where_promoterless = <<"SQL_WHERE_PL_END";
AND (
    (pr.targeting_type = 'single_targeted' AND s.final_cassette_promoter = false)
    OR
    (pr.targeting_type = 'double_targeted' AND s.final_pick_cassette_promoter = false)
)
SQL_WHERE_PL_END

my $sql_select_group_by_st_vectors = <<"SQL_GRP_BY_ST_VECTORS_END";
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_cassette_name, s.final_plate_name, s.final_well_name
ORDER BY s.design_gene_symbol, s.final_cassette_name, s.final_plate_name, s.final_well_name
SQL_GRP_BY_ST_VECTORS_END

my $sql_select_group_by_dt_vectors = <<"SQL_GRP_BY_DT_VECTORS_END";
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_plate_name, s.final_pick_well_name
ORDER BY s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_plate_name, s.final_pick_well_name
SQL_GRP_BY_DT_VECTORS_END

my $sql_select_group_by_dna = <<"SQL_GRP_BY_DNA_END";
GROUP by s.design_gene_id, s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_GRP_BY_DNA_END

my $sql_select_group_by_fep = <<"SQL_GRP_BY_FEP_END";
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_GRP_BY_FEP_END

my $sql_select_group_by_sep = <<"SQL_GRP_BY_SEP_END";
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_plate_name, s.sep_well_name
ORDER BY s.design_gene_symbol, s.sep_plate_name, s.sep_well_name
SQL_GRP_BY_SEP_END

my $sql_select_group_by_st_clones = <<"SQL_GRP_BY_ST_CLONES_END";
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
ORDER BY s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
SQL_GRP_BY_ST_CLONES_END

my $sql_select_group_by_dt_clones = <<"SQL_GRP_BY_DT_CLONES_END";
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_pick_plate_name, s.sep_pick_well_name
ORDER BY s.design_gene_symbol, s.sep_pick_plate_name, s.sep_pick_well_name
SQL_GRP_BY_DT_CLONES_END

    # params hash contains:
    # 'sql_type' = 'count' or 'select'
    # 'targeting_type' = 'single_targeted' or 'double_targeted'
    # 'stage' = 'vectors', 'dna', '1st electroporations', '2nd electroporations', 'accepted_clones'
    # 'use_resistance' = 't' or 'f'
    # 'resistance_type' = 'neoR' or 'blastR'
    # 'use_promoter' = 't' or 'f'
    # 'is_promoterless' = 't' or 'f'

    # start with with query section 
    $sql_query = $sql_query_with;
    
    # add the relevant select clause
    if ( $sql_type eq 'count' ) {

        # same for all counts
        $sql_query = $sql_query.' '.$sql_query_count;       
    }
    elsif ( $sql_type eq 'select' ) {
        
        # select varies by stage and targeting type
        if ( $stage eq 'vectors' ) {
            if ( $targeting_type eq 'single_targeted' ) {
                $sql_query = $sql_query.' '.$sql_query_select_st_vectors;
            }
            elsif ( $targeting_type eq 'double_targeted' ) {
                $sql_query = $sql_query.' '.$sql_query_select_dt_vectors;
            }
        }
        elsif ( $stage eq 'dna' ) {
            $sql_query = $sql_query.' '.$sql_query_select_dna;
        }
        elsif ( $stage eq 'fep' ) {
            $sql_query = $sql_query.' '.$sql_query_select_fep;
        }
        elsif ( $stage eq 'sep' ) {
            $sql_query = $sql_query.' '.$sql_query_select_sep;
        }
        elsif ( $stage eq 'clones' ) {
            if ( $targeting_type eq 'single_targeted' ) {
                $sql_query = $sql_query.' '.$sql_query_select_st_clones;
            }
            elsif ( $targeting_type eq 'double_targeted' ) {
                $sql_query = $sql_query.' '.$sql_query_select_dt_clones;
            }
        }

    }

    # add the main body clause
    $sql_query = $sql_query.' '.$sql_query_body_final;
    
    # add the relevant optional where clauses depending on stage
    if ( $stage eq 'vectors' ) {
        $sql_query = $sql_query.' '.$sql_where_vectors;
    }
    elsif ( $stage eq 'dna' ) {
        $sql_query = $sql_query.' '.$sql_where_vectors.' '.$sql_where_dna;
    }
    elsif ( $stage eq 'fep' ) {
        $sql_query = $sql_query.' '.$sql_where_vectors.' '.$sql_where_dna.' '.$sql_where_fep;
    }
    elsif ( $stage eq 'sep' ) {
        $sql_query = $sql_query.' '.$sql_where_vectors.' '.$sql_where_dna.' '.$sql_where_sep;
    }
    elsif ( $stage eq 'clones' ) {
        $sql_query = $sql_query.' '.$sql_where_vectors.' '.$sql_where_dna.' '.$sql_where_clones;
    }

    # add resistance check if required
    if ( $use_resistance eq 't' ) {
        if (defined $resistance_type ) {
            $sql_query = $sql_query.' '.$sql_where_resistance;
        }
    }

    # add the relevant group by and order by clauses
    if ( $sql_type eq 'select' ) {

        if ( $stage eq 'vectors' ) {
            if ( $targeting_type eq 'single_targeted' ) {
                $sql_query = $sql_query.' '.$sql_select_group_by_st_vectors;
            }
            elsif ( $targeting_type eq 'double_targeted' ) {
                $sql_query = $sql_query.' '.$sql_select_group_by_dt_vectors;
            }
        }
        elsif ( $stage eq 'dna' ) {
            $sql_query = $sql_query.' '.$sql_select_group_by_dna;
        }
        elsif ( $stage eq 'fep' ) {
            $sql_query = $sql_query.' '.$sql_select_group_by_fep;
        }
        elsif ( $stage eq 'sep' ) {
            $sql_query = $sql_query.' '.$sql_select_group_by_sep;
        }
        elsif ( $stage eq 'clones' ) {
            if ( $targeting_type eq 'single_targeted' ) {
                $sql_query = $sql_query.' '.$sql_select_group_by_st_clones;
            }
            elsif ( $targeting_type eq 'double_targeted' ) {
                $sql_query = $sql_query.' '.$sql_select_group_by_dt_clones;
            }
        }

    }

    ### $sql_query
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

    my $params = {
        'sql_type'          => 'count',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'vectors',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    $count = $self->run_count_query( $sql_query );

    return $count;
}

sub resistance_vectors {
    my ( $self, $sponsor_id, $targeting_type, $resistance ) = @_;

    DEBUG 'finding '.$targeting_type.' vectors woth resistance '.$resistance.' for sponsor id = '.$sponsor_id;

    my $count = 0;

    my $params = {
        'sql_type'          => 'count',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'vectors',
        'use_resistance'    => 't',
        'resistance_type'   => $resistance,
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    $count = $self->run_count_query( $sql_query );

    return $count;
}

sub dna {
    my ( $self, $sponsor_id, $targeting_type ) = @_;
    
    DEBUG "finding dna for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

    my $count = 0;

    my $params = {
        'sql_type'          => 'count',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'dna',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    $count = $self->run_count_query( $sql_query );

    return $count;
}

sub resistance_dna {
    my ( $self, $sponsor_id, $targeting_type, $resistance ) = @_;

    DEBUG "finding double_targeted neoR dna for sponsor id = ".$sponsor_id;

    my $count = 0;

    my $params = {
        'sql_type'          => 'count',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'dna',
        'use_resistance'    => 't',
        'resistance_type'   => $resistance,
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    $count = $self->run_count_query( $sql_query );

    return $count;
}

sub electroporations {
    my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding electroporations for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

    my $count = 0;

    my $params = {
        'sql_type'          => 'count',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'fep',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    $count = $self->run_count_query( $sql_query );

    return $count;
}

sub resistance_electroporations {
    my ( $self, $sponsor_id, $targeting_type, $resistance ) = @_;

    DEBUG "finding ".$resistance." electroporations for sponsor id = ".$sponsor_id;

    my $count = 0;
    
    my $params = {
        'sql_type'          => 'count',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'fep',
        'use_resistance'    => 't',
        'resistance_type'   => $resistance,
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );
    
    DEBUG "sql query = ".$sql_query;

    $count = $self->run_count_query( $sql_query );

    return $count;
}

sub second_electroporations {
    my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding second electroporations for sponsor id = ".$sponsor_id;

    my $count = 0;

    my $params = {
        'sql_type'          => 'count',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'sep',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );
    
    DEBUG "sql query = ".$sql_query;

    $count = $self->run_count_query( $sql_query );

    return $count;
}

sub clones {
    my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding clones for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

    my $count = 0;

    my $params = {
        'sql_type'          => 'count',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'clones',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

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
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'cassette_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'cassette name' ];
        }
        elsif ( $stage eq 'Valid DNA' ) {
            $display_stage = 'Valid DNA';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
        elsif ( $stage eq 'First Electroporations' ) {
            $display_stage = 'First Electroporations';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
       elsif ( $stage eq 'Accepted ES Clones' ) {
            $display_stage = 'Accepted ES Clones';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
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
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'cassette_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'cassette name' ];
        }
        elsif ( $stage eq 'Vectors Neo only' ) {
            $display_stage = 'Neomycin-resistant Vectors';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'cassette_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'cassette name' ];
        }
        elsif ( $stage eq 'Vectors Bsd only' ) {
            $display_stage = 'Blasticidin-resistant Vectors';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'cassette_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'cassette name' ];
        }
        elsif ( $stage eq 'Valid DNA' ) {
            $display_stage = 'Valid DNA';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
        elsif ( $stage eq 'Valid DNA Neo only' ) {
            $display_stage = 'Neomycin-resistant Valid DNA';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
        elsif ( $stage eq 'Valid DNA Bsd only' ) {
            $display_stage = 'Blasticidin-resistant Valid DNA';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
        elsif ( $stage eq 'First Electroporations' ) {
            $display_stage = 'First Electroporations';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
        elsif ( $stage eq 'First Electroporations Neo only' ) {
            $display_stage = 'First Electroporations Neo only';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
        elsif ( $stage eq 'First Electroporations Bsd only' ) {
            $display_stage = 'First Electroporations Bsd only';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
        elsif ( $stage eq 'Second Electroporations' ) {
            $display_stage = 'Second Electroporations';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
       elsif ( $stage eq 'Accepted ES Clones' ) {
            $display_stage = 'Accepted ES Clones';
            $columns = [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ];
            $display_columns = [ 'gene id', 'gene symbol', 'plate name', 'well name' ];
        }
        else {
            # TODO: Error unknown type
        }
    }

    my %return_params = (
        'report_id'         => 'SponsRepSub',
        'disp_target_type'  => $display_targeting_type,
        'disp_stage'        => $display_stage,
        'columns'           => $columns,
        'display_columns'   => $display_columns,
        'data'              => $data,
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
        elsif ( $stage eq 'First Electroporations' ) {
           $sub_report_data = $self->electroporations_report( $sponsor_id, $targeting_type );
        }
        elsif ( $stage eq 'Accepted ES Clones' ) {
           $sub_report_data = $self->accepted_clones_report( $sponsor_id, $targeting_type       );
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
        elsif ( $stage eq 'Vectors Neo only' ) {
            $sub_report_data = $self->resistance_vectors_report( $sponsor_id, $targeting_type, 'neoR' );
        }
        elsif ( $stage eq 'Vectors Bsd only' ) {
            $sub_report_data = $self->resistance_vectors_report( $sponsor_id, $targeting_type, 'blastR' );
        }
        elsif ( $stage eq 'Valid DNA' ) {
            $sub_report_data = $self->valid_dna_report( $sponsor_id, $targeting_type );
        }
        elsif ( $stage eq 'Valid DNA Neo only' ) {
            $sub_report_data = $self->resistance_valid_dna_report( $sponsor_id, $targeting_type, 'neoR' );
        }
        elsif ( $stage eq 'Valid DNA Bsd only' ) {
            $sub_report_data = $self->resistance_valid_dna_report( $sponsor_id, $targeting_type, 'blastR' );
        }
        elsif ( $stage eq 'First Electroporations' ) {
           $sub_report_data = $self->first_electroporations_report( $sponsor_id, $targeting_type );
        }
        elsif ( $stage eq 'First Electroporations Neo only' ) {
           $sub_report_data = $self->resistance_first_electroporations_report( $sponsor_id, $targeting_type, 'neoR' );
        }
        elsif ( $stage eq 'First Electroporations Bsd only' ) {
           $sub_report_data = $self->resistance_first_electroporations_report( $sponsor_id, $targeting_type, 'blastR' );
        }
        elsif ( $stage eq 'Second Electroporations' ) {
           $sub_report_data = $self->second_electroporations_report( $sponsor_id );
        }
        elsif ( $stage eq 'Accepted ES Clones' ) {
           $sub_report_data = $self->accepted_clones_report( $sponsor_id, $targeting_type       );
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

    my $params = {
        'sql_type'          => 'select',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'vectors',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    my $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub resistance_vectors_report {
    my ( $self, $sponsor_id, $targeting_type, $resistance ) = @_;

    DEBUG 'selecting '.$targeting_type.' vectors with resistance '.$resistance.' with for sponsor id = '.$sponsor_id;

    my $params = {
        'sql_type'          => 'select',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'vectors',
        'use_resistance'    => 't',
        'resistance_type'   => $resistance,
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    my $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub valid_dna_report {
    my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG 'selecting valid DNA for sponsor id = '.$sponsor_id.' and targeting_type = '.$targeting_type;
    
    my $params = {
        'sql_type'          => 'select',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'dna',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    my $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub resistance_valid_dna_report {
    my ( $self, $sponsor_id, $targeting_type, $resistance ) = @_;

    DEBUG 'selecting valid DNA for '.$targeting_type.' projects with resistance '.$resistance.' for sponsor id = '.$sponsor_id;
    
    my $params = {
        'sql_type'          => 'select',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'vectors',
        'use_resistance'    => 't',
        'resistance_type'   => $resistance,
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    my $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub first_electroporations_report {
    my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG 'selecting first electroporations for '.$targeting_type.' projects for sponsor id = '.$sponsor_id;

    my $params = {
        'sql_type'          => 'select',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'fep',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    my $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}


sub resistance_first_electroporations_report {
    my ( $self, $sponsor_id, $targeting_type, $resistance ) = @_;

    DEBUG 'selecting first electroporations with resistance '.$resistance.' for sponsor id = '.$sponsor_id;

    my $params = {
        'sql_type'          => 'select',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'fep',
        'use_resistance'    => 't',
        'resistance_type'   => $resistance,
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    my $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub second_electroporations_report {
    my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG 'selecting second electroporations for sponsor id = '.$sponsor_id;

    my $params = {
        'sql_type'          => 'select',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'sep',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    my $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub accepted_clones_report {
    my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG 'selecting accepted clones for '.$targeting_type.' projects for sponsor id = '.$sponsor_id;

    my $params = {
        'sql_type'          => 'select',
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'clones',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    DEBUG "sql query = ".$sql_query;

    my $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}
1;