package LIMS2::Model::Util::ReportForSponsors;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::ReportForSponsors::VERSION = '0.072';
}
## use critic


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
    'Vectors Neo',
    'Vectors Bsd',
    'Valid DNA',
    'Valid DNA Neo and Bsd',
    'Valid DNA Neo',
    'Valid DNA Bsd',
    'First Electroporations',
    'First Electroporations Neo',
    'First Electroporations Bsd',
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
# For Front Page Summary Report
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

    foreach my $sponsor_tt ( @$sponsor_tt_counts ) {

        my $targeting_type = $sponsor_tt->{ targeting_type };
        my $number_genes = $sponsor_tt->{ genes };

        DEBUG "targeting_type = ".$targeting_type;
        DEBUG "number genes = ".$number_genes;

        $self->_build_column_data( $sponsor_id, $sponsor_data, $targeting_type, $number_genes );

    }

    return;
}

sub _build_column_data {

    my ( $self, $sponsor_id, $sponsor_data, $targeting_type, $number_genes ) = @_;

    DEBUG 'Fetching column data: sponsor = '.$sponsor_id.', targeting_type = '.$targeting_type.', number genes = '.$number_genes;

    # --------- Targeting Type -----------
    $sponsor_data->{'Targeting'}{$sponsor_id} = $targeting_type;

    # --------- Targeted Genes -----------
    my $count_tgs = $number_genes;
    $sponsor_data->{'Targeted Genes'}{$sponsor_id} = $count_tgs;

    # ------------ Vectors ---------------
    # only look if targeted genes found
    my $count_vectors = 0;
    if ( $count_tgs > 0 ) {
      $count_vectors = $self->vectors( $sponsor_id, $targeting_type, 'count' );
    }
    $sponsor_data->{'Vectors'}{$sponsor_id} = $count_vectors;

    if ( $targeting_type eq 'double_targeted' ) {

        # only look if vectors found
        my $count_pairs_neo_bsd_vectors = 0;
        my $count_neo_vectors = 0;
        my $count_blast_vectors = 0;

        if ( $count_vectors > 0 ) {
          $count_pairs_neo_bsd_vectors = $self->vector_pairs_neo_and_bsd( $sponsor_id, $targeting_type, 'count' );

          $count_neo_vectors = $self->vectors_with_resistance( $sponsor_id, $targeting_type, 'neoR' , 'count');
          $count_blast_vectors = $self->vectors_with_resistance( $sponsor_id, $targeting_type, 'blastR', 'count' );
        }
        $sponsor_data->{'Vectors Neo and Bsd'}{$sponsor_id} = $count_pairs_neo_bsd_vectors;
        $sponsor_data->{'Vectors Neo'}{$sponsor_id} = $count_neo_vectors;
        $sponsor_data->{'Vectors Bsd'}{$sponsor_id} = $count_blast_vectors;

    }
    else {
        $sponsor_data->{'Vectors Neo and Bsd'}{$sponsor_id} = -1;
        $sponsor_data->{'Vectors Neo'}{$sponsor_id} = -1;
        $sponsor_data->{'Vectors Bsd'}{$sponsor_id} = -1;
    }

    # ------------- DNA ---------------
    # only look if vectors found
    my $count_dna = 0;
    if ( $count_vectors > 0 ) {
      $count_dna = $self->dna( $sponsor_id, $targeting_type, 'count' );
    }
    $sponsor_data->{'Valid DNA'}{$sponsor_id} = $count_dna;

    if ( $targeting_type eq 'double_targeted' ) {
        # only look if DNA found
        my $count_pairs_neo_bsd_dna = 0;
        my $count_neo_dna = 0;
        my $count_blast_dna = 0;

        if ( $count_dna > 0 ) {
            $count_pairs_neo_bsd_dna = $self->dna_pairs_neo_and_bsd( $sponsor_id, $targeting_type, 'count' );
            $count_neo_dna = $self->dna_with_resistance( $sponsor_id, $targeting_type, 'neoR', 'count' );
            $count_blast_dna = $self->dna_with_resistance( $sponsor_id, $targeting_type, 'blastR', 'count' );
        }
        $sponsor_data->{'Valid DNA Neo and Bsd'}{$sponsor_id} = $count_pairs_neo_bsd_dna;
        $sponsor_data->{'Valid DNA Neo'}{$sponsor_id} = $count_neo_dna;
        $sponsor_data->{'Valid DNA Bsd'}{$sponsor_id} = $count_blast_dna;
    }
    else {
        $sponsor_data->{'Valid DNA Neo and Bsd'}{$sponsor_id} = -1;
        $sponsor_data->{'Valid DNA Neo'}{$sponsor_id} = -1;
        $sponsor_data->{'Valid DNA Bsd'}{$sponsor_id} = -1;
    }

    # ---------- Electroporations -----------
    # only look if dna found
    my $count_eps = 0;
    if ( $count_dna > 0 ) {
      $count_eps = $self->first_electroporations( $sponsor_id, $targeting_type, 'count' );
    }
    $sponsor_data->{'First Electroporations'}{$sponsor_id} = $count_eps;

    if ( $targeting_type eq 'double_targeted' ) {

        # only look if electroporations found
        my $count_neo_eps = 0;
        my $count_blast_eps = 0;
        if ( $count_eps > 0 ) {
          $count_neo_eps = $self->first_electroporations_with_resistance( $sponsor_id, $targeting_type, 'neoR', 'count' );
          $count_blast_eps = $self->first_electroporations_with_resistance( $sponsor_id, $targeting_type, 'blastR', 'count' );
        }
        $sponsor_data->{'First Electroporations Neo'}{$sponsor_id} = $count_neo_eps;
        $sponsor_data->{'First Electroporations Bsd'}{$sponsor_id} = $count_blast_eps;

        # only look if electroporations found
        my $count_second_eps = 0;
        if ( $count_eps > 0 ) {
          $count_second_eps = $self->second_electroporations( $sponsor_id, $targeting_type, 'count' );
        }
        $sponsor_data->{'Second Electroporations'}{$sponsor_id} = $count_second_eps;

    }
    else {
        $sponsor_data->{'First Electroporations Neo'}{$sponsor_id} = -1;
        $sponsor_data->{'First Electroporations Bsd'}{$sponsor_id} = -1;
        $sponsor_data->{'Second Electroporations'}{$sponsor_id} = -1;
    }

    # ------------ Clones -------------
    # only look if electroporations found
    my $count_clones = 0;
    if ( $count_eps > 0 ) {
      $count_clones = $self->clones( $sponsor_id, $targeting_type, 'count' );
    }
    $sponsor_data->{'Accepted ES Clones'}{$sponsor_id} = $count_clones;

    return;
}

sub select_sponsor_targeting_type_and_genes {
    my ( $self, $sponsor_id ) = @_;

    DEBUG "selecting targeting type and genes for sponsor id = ".$sponsor_id;

    my $sql_results;

    my $sql_query = $self->create_sql_count_genes_for_a_sponsor( $sponsor_id );

    $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

# Generate front page report matrix
sub generate_top_level_report_for_sponsors {
    my $self = shift;

    # build information for report
    my $columns = $self->build_columns;
    my $data = $self->sponsor_data;
    my $title = $self->build_page_title;
    my $st_rows = \@SINGLE_TARGETED_REPORT_CATEGORIES;
    my $dt_rows = \@DOUBLE_TARGETED_REPORT_CATEGORIES;

    my %return_params = (
        'report_id' => 'SponsRep',
        'title'     => $title,
        'columns'   => $columns,
        'st_rows'   => $st_rows,
        'dt_rows'   => $dt_rows,
        'data'      => $data,
    );

    return \%return_params;
}

sub build_page_title {
    my $self = shift;

    # TODO: This date should relate to a timestamp indicating when summaries data was
    # last generated rather than just system date.
    my $dt = DateTime->now();

    return 'Pipeline Summary Report on ' . $dt->dmy;
};

# columns relate to project sponsors
sub build_columns {
    my $self = shift;

    return [
        'Stage',
        @{ $self->sponsors }
    ];
};

#----------------------------------------------------------
# For Sub-Reports
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
    my $data = $self->_build_sub_report_data($sponsor_id, $targeting_type, $stage);

    # for single-targeted projects
    my $st_rpt_flds = {
        'Targeted Genes'                    => {
            'display_stage'         => 'Targeted genes',
            'columns'               => [ 'gene_id', 'gene_symbol' ],
            'display_columns'       => [ 'gene id', 'gene symbol' ],
        },
        'Vectors'                           => {
            'display_stage'         => 'Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'cassette name' ],
        },
        'Valid DNA'                         => {
            'display_stage'         => 'Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
        'First Electroporations'            => {
            'display_stage'         => 'First Electroporations',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
        'Accepted ES Clones'                => {
            'display_stage'         => 'Accepted ES Clones',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
    };

    # for double-targeted projects
    my $dt_rpt_flds = {
        'Targeted Genes'                    => {
            'display_stage'         => 'Targeted genes',
            'columns'               => [ 'gene_id', 'gene_symbol' ],
            'display_columns'       => [ 'gene id', 'gene symbol' ],
        },
        'Vectors'                           => {
            'display_stage'         => 'Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'cassette name', 'plate name', 'well name' ],
        },
        'Vectors Neo and Bsd'               => {
            'display_stage'         => 'Vector pairs Neo and Bsd',
            'columns'               => [ 'project_id','design_id', 'design_gene_symbol' ],
            'display_columns'       => [ 'project id', 'design id', 'gene symbol' ],
        },
        'Vectors Neo'                  => {
            'display_stage'         => 'Neomycin-resistant Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'cassette name', 'plate name', 'well name' ],
        },
        'Vectors Bsd'                  => {
            'display_stage'         => 'Blasticidin-resistant Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'cassette name', 'plate name', 'well name' ],
        },
        'Valid DNA'                         => {
            'display_stage'         => 'Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
        'Valid DNA Neo and Bsd'             => {
            'display_stage'         => 'Valid DNA pairs Neo and Bsd',
            'columns'               => [ 'project_id','design_id', 'design_gene_symbol' ],
            'display_columns'       => [ 'project id', 'design id', 'gene symbol' ],
        },
        'Valid DNA Neo'                => {
            'display_stage'         => 'Neomycin-resistant Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
        'Valid DNA Bsd'                => {
            'display_stage'         => 'Blasticidin-resistant Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
        'First Electroporations'            => {
            'display_stage'         => 'First Electroporations',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
        'First Electroporations Neo'   => {
            'display_stage'         => 'First Electroporations Neo',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
        'First Electroporations Bsd'   => {
            'display_stage'         => 'First Electroporations Bsd',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
        'Second Electroporations'           => {
            'display_stage'         => 'Second Electroporations',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
        'Accepted ES Clones'                => {
            'display_stage'         => 'Accepted ES Clones',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene symbol', 'plate name', 'well name' ],
        },
    };

    my ($columns, $display_columns, $display_targeting_type, $display_stage);

    if ( $targeting_type eq 'single_targeted' ) {
        $display_targeting_type     = 'single-targeted';
        $display_stage              = $st_rpt_flds->{ $stage }->{ 'display_stage' };
        $columns                    = $st_rpt_flds->{ $stage }->{ 'columns' };
        $display_columns            = $st_rpt_flds->{ $stage }->{ 'display_columns' };
    }
    elsif ( $targeting_type eq 'double_targeted' ) {
        $display_targeting_type     = 'double-targeted';
        $display_stage              = $dt_rpt_flds->{ $stage }->{ 'display_stage' };
        $columns                    = $dt_rpt_flds->{ $stage }->{ 'columns' };
        $display_columns            = $dt_rpt_flds->{ $stage }->{ 'display_columns' };
    }
    else {
        return;
    }

    # return to controller to display home page
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

    my $query_type = 'select';
    my $sub_report_data;

    # dispatch table
    my $rep_for_stg = {
        'Targeted Genes'                    => {
            'func'      => \&genes,
            'params'    => [ $self, $sponsor_id, $targeting_type, $query_type ],
        },
        'Vectors'                           => {
            'func'      => \&vectors,
            'params'    => [ $self, $sponsor_id, $targeting_type, $query_type ],
        },
        'Vectors Neo and Bsd'               => {
            'func'      => \&vector_pairs_neo_and_bsd,
            'params'    => [ $self, $sponsor_id, $targeting_type, $query_type ],
        },
        'Vectors Neo'                  => {
            'func'      => \&vectors_with_resistance,
            'params'    => [ $self, $sponsor_id, $targeting_type, 'neoR', $query_type ],
        },
        'Vectors Bsd'                  => {
            'func'      => \&vectors_with_resistance,
            'params'    => [ $self, $sponsor_id, $targeting_type, 'blastR', $query_type ],
        },
        'Valid DNA'                         => {
            'func'      => \&dna,
            'params'    => [ $self, $sponsor_id, $targeting_type, $query_type ],
        },
        'Valid DNA Neo and Bsd'             => {
            'func'      => \&dna_pairs_neo_and_bsd,
            'params'    => [ $self, $sponsor_id, $targeting_type, $query_type ],
        },
        'Valid DNA Neo'                => {
            'func'      => \&dna_with_resistance,
            'params'    => [ $self, $sponsor_id, $targeting_type, 'neoR', $query_type ],
        },
        'Valid DNA Bsd'                => {
            'func'      => \&dna_with_resistance,
            'params'    => [ $self, $sponsor_id, $targeting_type, 'blastR', $query_type ],
        },
        'First Electroporations'            => {
            'func'      => \&first_electroporations,
            'params'    => [ $self, $sponsor_id, $targeting_type, $query_type ],
        },
        'First Electroporations Neo'   => {
            'func'      => \&first_electroporations_with_resistance,
            'params'    => [ $self, $sponsor_id, $targeting_type, 'neoR', $query_type ],
        },
        'First Electroporations Bsd'   => {
            'func'      => \&first_electroporations_with_resistance,
            'params'    => [ $self, $sponsor_id, $targeting_type, 'blastR', $query_type ],
        },
        'Second Electroporations'           => {
            'func'      => \&second_electroporations,
            'params'    => [ $self, $sponsor_id, $targeting_type, $query_type ],
        },
        'Accepted ES Clones'                => {
            'func'      => \&clones,
            'params'    => [ $self, $sponsor_id, $targeting_type, $query_type ],
        },
    };

    # check stage exists in the dispatch table, and run it passing in params
    $sub_report_data =  &{ $rep_for_stg->{ $stage }->{ 'func' } } ( @{$rep_for_stg->{ $stage }->{ 'params' }} );

    # sub_report_data is a ref to an array of hashrefs
    return $sub_report_data;
}

#----------------------------------------------------------
# Methods for Stages
#----------------------------------------------------------

sub genes {
    my ( $self, $sponsor_id, $targeting_type, $query_type ) = @_;

    DEBUG "genes for: sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

    if ( $query_type eq 'count' ) {

        my $sql_query = $self->create_sql_count_targeted_gene_projects_for_sponsor( $sponsor_id, $targeting_type );

        DEBUG "sql query = ".$sql_query;

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_query = $self->create_sql_sel_targeted_genes( $sponsor_id, $targeting_type );

        #DEBUG "sql query = ".$sql_query;

        my $sql_results = $self->run_select_query( $sql_query );

        # fetch gene symbols and return modified results set for display
        my @genes_for_display;
        foreach my $gene_row ( @$sql_results ) {
            my $gene_id = $gene_row->{ 'gene_id' };

            my $gene_symbol = $self->model->retrieve_gene( { search_term => $gene_id,  species => 'Mouse' } )->{gene_symbol};

            push @genes_for_display, { 'gene_id' => $gene_id, 'gene_symbol' => $gene_symbol };
        }

        # sort the array by gene symbol
        my @sorted_genes_for_display =  sort { $a->{ 'gene_symbol' } cmp $b-> { 'gene_symbol' } } @genes_for_display;

        return \@sorted_genes_for_display;
    }
}

sub vectors {
    my ( $self, $sponsor_id, $targeting_type, $query_type ) = @_;

    DEBUG 'selecting vectors: sponsor id = '.$sponsor_id.' , targeting_type = '.$targeting_type.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'vectors',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

sub vector_pairs_neo_and_bsd {
    my ( $self, $sponsor_id, $targeting_type, $query_type ) = @_;

    DEBUG 'selecting vector pairs: sponsor id = '.$sponsor_id.' and targeting_type = '.$targeting_type.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'vector_pairs',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

sub vectors_with_resistance {
    my ( $self, $sponsor_id, $targeting_type, $resistance, $query_type ) = @_;

    DEBUG 'selecting vectors: sponsor id = '.$sponsor_id.' and targeting_type = '.$targeting_type.', resistance =  '.$resistance.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'vectors',
        'use_resistance'    => 't',
        'resistance_type'   => $resistance,
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

   #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

sub dna {
    my ( $self, $sponsor_id, $targeting_type, $query_type ) = @_;

    DEBUG 'selecting dna: sponsor id = '.$sponsor_id.' and targeting_type = '.$targeting_type.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'dna',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

sub dna_pairs_neo_and_bsd {
    my ( $self, $sponsor_id, $targeting_type, $query_type ) = @_;

    DEBUG 'selecting dna pairs neo and bsd: sponsor id = '.$sponsor_id.' and targeting_type = '.$targeting_type.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'dna_pairs',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

sub dna_with_resistance {
    my ( $self, $sponsor_id, $targeting_type, $resistance, $query_type ) = @_;

    DEBUG 'selecting dna with resistance: sponsor id = '.$sponsor_id.', targeting_type = '.$targeting_type.', resistance '.$resistance.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'dna',
        'use_resistance'    => 't',
        'resistance_type'   => $resistance,
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

sub first_electroporations {
    my ( $self, $sponsor_id, $targeting_type, $query_type ) = @_;

    DEBUG 'selecting first electroporations: sponsor id = '.$sponsor_id.', targeting_type = '.$targeting_type.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'fep',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

sub first_electroporations_with_resistance {
    my ( $self, $sponsor_id, $targeting_type, $resistance, $query_type ) = @_;

    DEBUG 'selecting first electroporations with resistance: sponsor id = '.$sponsor_id.', resistance '.$resistance.', targeting_type = '.$targeting_type.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'fep',
        'use_resistance'    => 't',
        'resistance_type'   => $resistance,
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

sub second_electroporations {
    my ( $self, $sponsor_id, $targeting_type, $query_type ) = @_;

    DEBUG 'selecting second electroporations: sponsor id = '.$sponsor_id.', targeting_type = '.$targeting_type.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'sep',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

sub clones {
    my ( $self, $sponsor_id, $targeting_type, $query_type ) = @_;

    DEBUG 'selecting accepted clones: sponsor id = '.$sponsor_id.', targeting_type = '.$targeting_type.', query type = '.$query_type;

    my $params = {
        'sql_type'          => $query_type,
        'sponsor_id'        => $sponsor_id,
        'targeting_type'    => $targeting_type,
        'stage'             => 'clones',
        'use_resistance'    => 'f',
        'use_promoter'      => 'f',
    };

    my $sql_query = $self->generate_sql( $params );

    #DEBUG "sql query = ".$sql_query;

    if ( $query_type eq 'count' ) {

        my $count = 0;
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {

        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;

    }
}

#----------------------------------------------------------
# SQL
#----------------------------------------------------------

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

# Set up SQL query to select targeting type and count genes for a sponsor id
sub create_sql_count_genes_for_a_sponsor {
    my ( $self, $sponsor_id ) = @_;

my $sql_query =  <<"SQL_END";
SELECT p.sponsor_id, targeting_type, count(distinct(gene_id)) AS genes
FROM projects p
WHERE p.sponsor_id = '$sponsor_id'
GROUP BY p.sponsor_id, p.targeting_type
ORDER BY targeting_type DESC
;
SQL_END

    return $sql_query;
}

# Set up SQL query to select targeted genes for a specific sponsor and targeting type
sub create_sql_sel_targeted_genes {
    my ( $self, $sponsor_id, $targeting_type ) = @_;

my $sql_query =  <<"SQL_END";
SELECT distinct(p.gene_id)
FROM projects p
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = '$targeting_type'
ORDER BY p.gene_id
SQL_END

    return $sql_query;
}

# Dynamically generate SQL query
sub generate_sql {
    my ($self, $params ) = @_;

    # params hash contains:
    # 'sql_type' = 'count' or 'select'
    # 'targeting_type' = 'single_targeted' or 'double_targeted'
    # 'stage' = 'vectors', 'vector_pairs', 'dna', 'fep', 'sep', 'clones'
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

my $sql_with =  <<"SQL_WITH_END";
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

my $sql_with_neo =  <<'SQL_WITH_NEO_END';
, neo_vectors AS (
SQL_WITH_NEO_END

my $sql_with_bsd =  <<'SQL_WITH_BSD_END';
, bsd_vectors AS (
SQL_WITH_BSD_END

my $sql_count = <<'SQL_COUNT_END';
SELECT count(distinct(s.design_gene_id))
SQL_COUNT_END

my $sql_count_neo_and_bsd = <<'SQL_COUNT_NEO_BSD_END';
SELECT count(distinct(nv.design_gene_id))
SQL_COUNT_NEO_BSD_END

my $sql_sel_vectors = <<'SQL_SELECT_VECTORS_END';
SELECT s.design_gene_id, s.design_gene_symbol, s.final_cassette_name AS cassette_name, s.final_plate_name AS plate_name, s.final_well_name AS well_name
SQL_SELECT_VECTORS_END

my $sql_with_select_neo_and_bsd_vectors = <<'SQL_WITH_SELECT_NEO_BSD_END';
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol, s.final_cassette_name AS cassette_name, c.resistance
SQL_WITH_SELECT_NEO_BSD_END

my $sql_with_select_neo_and_bsd_dna = <<'SQL_WITH_SELECT_NEO_BSD_END';
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name, c.resistance
SQL_WITH_SELECT_NEO_BSD_END

my $sql_sel_neo_and_bsd_vectors = <<'SQL_SELECT_NEO_BSD_VECTORS_END';
SELECT nv.project_id, nv.design_id, nv.design_gene_symbol
SQL_SELECT_NEO_BSD_VECTORS_END

my $sql_sel_dna = <<'SQL_SELECT_DNA_END';
SELECT s.design_gene_id, s.design_gene_symbol, s.dna_plate_name AS plate_name, s.dna_well_name AS well_name
SQL_SELECT_DNA_END

my $sql_sel_neo_and_bsd_dna = <<'SQL_SELECT_NEO_BSD_DNA_END';
SELECT nv.project_id, nv.design_id, nv.design_gene_symbol
SQL_SELECT_NEO_BSD_DNA_END

my $sql_sel_fep = <<'SQL_SELECT_FEP_END';
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name AS plate_name, s.ep_well_name AS well_name
SQL_SELECT_FEP_END

my $sql_sel_sep = <<'SQL_SELECT_SEP_END';
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_plate_name AS plate_name, s.sep_well_name AS well_name
SQL_SELECT_SEP_END

my $sql_sel_st_clones = <<'SQL_SELECT_ST_CLONES_END';
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_pick_plate_name AS plate_name, s.ep_pick_well_name AS well_name
SQL_SELECT_ST_CLONES_END

my $sql_sel_dt_clones = <<'SQL_SELECT_DT_CLONES_END';
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_pick_plate_name AS plate_name, s.sep_pick_well_name AS well_name
SQL_SELECT_DT_CLONES_END

my $sql_body_final = <<"SQL_BODY_FINALS_END";
FROM summaries s
INNER JOIN cassettes c ON c.name = s.final_cassette_name
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
AND (
    (pr.conditional IS NULL) 
    OR 
    (pr.conditional IS NOT NULL AND s.final_cassette_conditional = pr.conditional)
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

my $sql_body_final_pick = <<"SQL_BODY_FINAL_PICK_END";
FROM summaries s
INNER JOIN cassettes c ON c.name = s.final_pick_cassette_name
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
AND (
    (pr.conditional IS NULL) 
    OR 
    (pr.conditional IS NOT NULL AND s.final_pick_cassette_conditional = pr.conditional)
)
AND (
    (pr.promoter IS NULL) 
    OR 
    (pr.promoter IS NOT NULL AND pr.promoter = s.final_pick_cassette_promoter)
)
AND (
    (pr.cre IS NULL) 
    OR 
    (pr.cre IS NOT NULL AND s.final_pick_cassette_cre = pr.cre)
)
AND (
    (pr.well_has_cre IS NULL) 
    OR 
    (
        (pr.well_has_cre = true AND s.final_pick_recombinase_id = 'Cre') 
        OR 
        (pr.well_has_cre = false AND (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL))
    )
)
AND (
    (pr.well_has_no_recombinase IS NULL) 
    OR 
    (        
     pr.well_has_no_recombinase IS NOT NULL AND (
      (pr.well_has_no_recombinase = true AND (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL))
       OR 
      (pr.well_has_no_recombinase = false AND s.final_pick_recombinase_id IS NOT NULL)
     )
    )
)
SQL_BODY_FINAL_PICK_END

my $sql_neo_and_bsd_body  = <<'SQL_BODY_NEO_AND_BSD_VECTORS_END';
FROM neo_vectors nv
INNER JOIN bsd_vectors bv ON bv.project_id = nv.project_id
AND bv.design_id = nv.design_id
SQL_BODY_NEO_AND_BSD_VECTORS_END

my $sql_where_vectors = <<"SQL_WHERE_VECTORS_END";
AND s.final_qc_seq_pass = true
SQL_WHERE_VECTORS_END

my $sql_where_dna = <<"SQL_WHERE_DNA_END";
AND s.dna_status_pass = true
AND (
    (pr.targeting_type = 'single_targeted' AND s.final_qc_seq_pass = true)
    OR
    (pr.targeting_type = 'double_targeted' AND s.final_pick_qc_seq_pass = true)
)
SQL_WHERE_DNA_END

my $sql_where_fep = <<'SQL_WHERE_FEP_END';
AND s.ep_well_id > 0
SQL_WHERE_FEP_END

my $sql_where_sep = <<'SQL_WHERE_SEP_END';
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

my $sql_sel_grpby_vectors = <<'SQL_GRP_BY_VECTORS_END';
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_cassette_name, s.final_plate_name, s.final_well_name
ORDER BY s.design_gene_symbol, s.final_cassette_name, s.final_plate_name, s.final_well_name
SQL_GRP_BY_VECTORS_END

my $sql_sel_with_grpby_neo_and_bsd_vectors = <<'SQL_SUB_GRP_BY_NEO_BSD_VECTORS_END';
GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol, s.final_cassette_name, c.resistance
ORDER BY pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol, s.final_cassette_name
)
SQL_SUB_GRP_BY_NEO_BSD_VECTORS_END

my $sql_sel_grpby_neo_and_bsd_vectors = <<'SQL_GRP_NEO_BSD_VECTORS_END';
GROUP BY nv.project_id, nv.design_id, nv.design_gene_symbol
ORDER BY nv.design_gene_symbol, nv.project_id, nv.design_id
SQL_GRP_NEO_BSD_VECTORS_END

my $sql_sel_grpby_dna = <<'SQL_GRP_BY_DNA_END';
GROUP by s.design_gene_id, s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_GRP_BY_DNA_END

my $sql_sel_with_grpby_neo_and_bsd_dna = <<'SQL_SUB_GRP_BY_NEO_BSD_DNA_END';
GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, c.resistance
ORDER BY pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name
)
SQL_SUB_GRP_BY_NEO_BSD_DNA_END

my $sql_sel_grpby_neo_and_bsd_dna = <<'SQL_GRP_BY_DNA_END';
GROUP by nv.project_id, nv.design_id, nv.design_gene_symbol
ORDER BY nv.design_gene_symbol, nv.project_id, nv.design_id
SQL_GRP_BY_DNA_END

my $sql_sel_grpby_fep = <<'SQL_GRP_BY_FEP_END';
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_GRP_BY_FEP_END

my $sql_sel_grpby_sep = <<'SQL_GRP_BY_SEP_END';
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_plate_name, s.sep_well_name
ORDER BY s.design_gene_symbol, s.sep_plate_name, s.sep_well_name
SQL_GRP_BY_SEP_END

my $sql_sel_grpby_st_clones = <<'SQL_GRP_BY_ST_CLONES_END';
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
ORDER BY s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
SQL_GRP_BY_ST_CLONES_END

my $sql_sel_grpby_dt_clones = <<'SQL_GRP_BY_DT_CLONES_END';
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_pick_plate_name, s.sep_pick_well_name
ORDER BY s.design_gene_symbol, s.sep_pick_plate_name, s.sep_pick_well_name
SQL_GRP_BY_DT_CLONES_END


    my $sql_snippets = {
        'sql_with'                                  => $sql_with,
        'sql_with_neo'                              => $sql_with_neo,
        'sql_with_bsd'                              => $sql_with_bsd,
        'sql_count'                                 => $sql_count,
        'sql_count_neo_and_bsd'                     => $sql_count_neo_and_bsd,
        'sql_sel_vectors'                           => $sql_sel_vectors,
        'sql_with_select_neo_and_bsd_vectors'       => $sql_with_select_neo_and_bsd_vectors,
        'sql_sel_neo_and_bsd_vectors'               => $sql_sel_neo_and_bsd_vectors,
        'sql_sel_dna'                               => $sql_sel_dna,
        'sql_with_select_neo_and_bsd_dna'           => $sql_with_select_neo_and_bsd_dna,
        'sql_sel_neo_and_bsd_dna'                   => $sql_sel_neo_and_bsd_dna,
        'sql_sel_fep'                               => $sql_sel_fep,
        'sql_sel_sep'                               => $sql_sel_sep,
        'sql_sel_st_clones'                         => $sql_sel_st_clones,
        'sql_sel_dt_clones'                         => $sql_sel_dt_clones,
        'sql_body_final'                            => $sql_body_final,
        'sql_body_final_pick'                       => $sql_body_final_pick,
        'sql_neo_and_bsd_body'                      => $sql_neo_and_bsd_body,
        'sql_where_vectors'                         => $sql_where_vectors,
        'sql_where_dna'                             => $sql_where_dna,
        'sql_where_fep'                             => $sql_where_fep,
        'sql_where_sep'                             => $sql_where_sep,
        'sql_where_clones'                          => $sql_where_clones,
        'sql_where_resistance'                      => $sql_where_resistance,
        'sql_where_promoter'                        => $sql_where_promoter,
        'sql_where_promoterless'                    => $sql_where_promoterless,
        'sql_sel_grpby_vectors'                     => $sql_sel_grpby_vectors,
        'sql_sel_with_grpby_neo_and_bsd_vectors'    => $sql_sel_with_grpby_neo_and_bsd_vectors,
        'sql_sel_grpby_neo_and_bsd_vectors'         => $sql_sel_grpby_neo_and_bsd_vectors,
        'sql_sel_grpby_dna'                         => $sql_sel_grpby_dna,
        'sql_sel_with_grpby_neo_and_bsd_dna'        => $sql_sel_with_grpby_neo_and_bsd_dna,
        'sql_sel_grpby_neo_and_bsd_dna'             => $sql_sel_grpby_neo_and_bsd_dna,
        'sql_sel_grpby_fep'                         => $sql_sel_grpby_fep,
        'sql_sel_grpby_sep'                         => $sql_sel_grpby_sep,
        'sql_sel_grpby_st_clones'                   => $sql_sel_grpby_st_clones,
        'sql_sel_grpby_dt_clones'                   => $sql_sel_grpby_dt_clones,
    };

    my $sql_for_stg = {
        'vectors'              => \&sql_vectors,
        'vector_pairs'         => \&sql_vector_pairs,
        'dna'                  => \&sql_dna,
        'dna_pairs'            => \&sql_dna_pairs,
        'fep'                  => \&sql_fep,
        'sep'                  => \&sql_sep,
        'clones'               => \&sql_clones,
    };

    if (defined $sql_for_stg->{ $stage }) {

        # generate the specific query
        my $gen_sql =  $sql_for_stg->{ $stage } ( $self, $params, $sql_snippets );

        return $gen_sql;

    }
    else
    {
        return;
    }
}

sub sql_vectors {
    my ( $self, $params, $sql ) = @_;

    my $sql_qry = $sql->{ 'sql_with' };

    if ( $params->{ 'sql_type' } eq 'count' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_count' };
    }
    elsif ( $params->{ 'sql_type' } eq 'select' ) {
        if ( $params->{ 'targeting_type' } eq 'single_targeted' ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_vectors' };
        }
        elsif ( $params->{ 'targeting_type' } eq 'double_targeted' ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_vectors' };
        }
    }

    $sql_qry = $sql_qry.' '.$sql->{ 'sql_body_final' }.' '.$sql->{ 'sql_where_vectors' };

    if ( $params->{ 'use_resistance' } eq 't' ) {
        if (defined $params->{ 'resistance_type' } ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_where_resistance' };
        }
    }

    if ( $params->{ 'sql_type' } eq 'select' ) {
        if ( $params->{ 'targeting_type' } eq 'single_targeted' ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_grpby_vectors' };
        }
        elsif ( $params->{ 'targeting_type' } eq 'double_targeted' ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_grpby_vectors' };
        }
    }

    return $sql_qry;

}

sub sql_vector_pairs {
    my ( $self, $params, $sql ) = @_;

    my $sql_qry = $sql->{ 'sql_with' };

    $sql_qry =  $sql_qry.' '.$sql->{ 'sql_with_neo' }.' '.$sql->{ 'sql_with_select_neo_and_bsd_vectors' }.' '.$sql->{ 'sql_body_final' }.' '.$sql->{ 'sql_where_vectors' }." AND c.resistance = 'neoR' ".$sql->{ 'sql_sel_with_grpby_neo_and_bsd_vectors' }.' '.$sql->{ 'sql_with_bsd' }.' '.$sql->{ 'sql_with_select_neo_and_bsd_vectors' }.' '.$sql->{ 'sql_body_final' }.' '.$sql->{ 'sql_where_vectors' }." AND c.resistance = 'blastR' ".$sql->{ 'sql_sel_with_grpby_neo_and_bsd_vectors' };

    if ( $params->{ 'sql_type' } eq 'count' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_count_neo_and_bsd' };
    }
    elsif ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_neo_and_bsd_vectors' };
    }

    $sql_qry = $sql_qry.' '.$sql->{ 'sql_neo_and_bsd_body' };

    if ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_grpby_neo_and_bsd_vectors' };
    }

    return $sql_qry;

}

sub sql_dna {
    my ( $self, $params, $sql ) = @_;

    my $sql_qry = $sql->{ 'sql_with' };

    if ( $params->{ 'sql_type' } eq 'count' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_count' };
    }
    elsif ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_dna' };
    }

    if ( $params->{ 'targeting_type' } eq 'single_targeted' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_body_final' }.' '.$sql->{ 'sql_where_dna' };
    }
    elsif ( $params->{ 'targeting_type' } eq 'double_targeted' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_body_final_pick' }.' '.$sql->{ 'sql_where_dna' };
    }

    if ( $params->{ 'use_resistance' } eq 't' ) {
        if (defined $params->{ 'resistance_type' } ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_where_resistance' };
        }
    }

    if ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_grpby_dna' };
    }

    return $sql_qry;

}

sub sql_dna_pairs {
    my ( $self, $params, $sql ) = @_;

    my $sql_qry = $sql->{ 'sql_with' };

    $sql_qry =  $sql_qry.' '.$sql->{ 'sql_with_neo' }.' '.$sql->{ 'sql_with_select_neo_and_bsd_dna' }.' '.$sql->{ 'sql_body_final_pick' }." AND c.resistance = 'neoR' ".$sql->{ 'sql_where_dna' }.' '.$sql->{ 'sql_sel_with_grpby_neo_and_bsd_dna' }.' '.$sql->{ 'sql_with_bsd' }.' '.$sql->{ 'sql_with_select_neo_and_bsd_dna' }.' '.$sql->{ 'sql_body_final_pick' }." AND c.resistance = 'blastR' ".$sql->{ 'sql_where_dna' }.' '.$sql->{ 'sql_sel_with_grpby_neo_and_bsd_dna' };

    if ( $params->{ 'sql_type' } eq 'count' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_count_neo_and_bsd' };
    }
    elsif ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_neo_and_bsd_dna' };
    }

    $sql_qry = $sql_qry.' '.$sql->{ 'sql_neo_and_bsd_body' };

    if ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_grpby_neo_and_bsd_dna' };
    }

    return $sql_qry;

}

sub sql_fep {
    my ( $self, $params, $sql ) = @_;

    my $sql_qry = $sql->{ 'sql_with' };

    if ( $params->{ 'sql_type' } eq 'count' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_count' };
    }
    elsif ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_fep' };
    }

    if ( $params->{ 'targeting_type' } eq 'single_targeted' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_body_final' }.' '.$sql->{ 'sql_where_dna' }.' '.$sql->{ 'sql_where_fep' };
    }
    elsif ( $params->{ 'targeting_type' } eq 'double_targeted' ) {
       $sql_qry = $sql_qry.' '.$sql->{ 'sql_body_final_pick' }.' '.$sql->{ 'sql_where_dna' }.' '.$sql->{ 'sql_where_fep' };
    }

    if ( $params->{ 'use_resistance' } eq 't' ) {
        if (defined $params->{ 'resistance_type' } ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_where_resistance' };
        }
    }

    if ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_grpby_fep' };
    }

DEBUG $sql_qry;

    return $sql_qry;

}

sub sql_sep {
    my ( $self, $params, $sql ) = @_;

    my $sql_qry = $sql->{ 'sql_with' };

    if ( $params->{ 'sql_type' } eq 'count' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_count' };
    }
    elsif ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_sep' };
    }

    $sql_qry = $sql_qry.' '.$sql->{ 'sql_body_final_pick' }.' '.$sql->{ 'sql_where_dna' }.' '.$sql->{ 'sql_where_sep' };

    if ( $params->{ 'sql_type' } eq 'select' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_grpby_sep' };
    }

    return $sql_qry;

}

sub sql_clones {
    my ( $self, $params, $sql ) = @_;

    my $sql_qry = $sql->{ 'sql_with' };

    if ( $params->{ 'sql_type' } eq 'count' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_count' };
    }
    elsif ( $params->{ 'sql_type' } eq 'select' ) {
        if ( $params->{ 'targeting_type' } eq 'single_targeted' ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_st_clones' };
        }
        elsif ( $params->{ 'targeting_type' } eq 'double_targeted' ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_dt_clones' };
        }
    }

    if ( $params->{ 'targeting_type' } eq 'single_targeted' ) {
       $sql_qry = $sql_qry.' '.$sql->{ 'sql_body_final' }.' '.$sql->{ 'sql_where_dna' }.' '.$sql->{ 'sql_where_clones' };
    }
    elsif ( $params->{ 'targeting_type' } eq 'double_targeted' ) {
        $sql_qry = $sql_qry.' '.$sql->{ 'sql_body_final_pick' }.' '.$sql->{ 'sql_where_dna' }.' '.$sql->{ 'sql_where_clones' };
    }

    if ( $params->{ 'sql_type' } eq 'select' ) {
        if ( $params->{ 'targeting_type' } eq 'single_targeted' ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_grpby_st_clones' };
        }
        elsif ( $params->{ 'targeting_type' } eq 'double_targeted' ) {
            $sql_qry = $sql_qry.' '.$sql->{ 'sql_sel_grpby_dt_clones' };
        }
    }

    return $sql_qry;

}
1;