package LIMS2::Model::Util::ReportForSponsors;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::ReportForSponsors::VERSION = '0.076';
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
Readonly my @ST_REPORT_CATEGORIES => (
    'Targeted Genes',
    'Vectors',
    'Valid DNA',
    'Electroporations',
    'Accepted ES Clones',
);

Readonly my @DT_REPORT_CATEGORIES => (
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
    'Accepted First ES Clones',
    'Second Electroporations',
    'Second Electroporations Neo',
    'Second Electroporations Bsd',
    'Accepted Second ES Clones',
);

has model => (
    is         => 'ro',
    isa        => 'LIMS2::Model',
    required   => 1,
);

has species => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

has targeting_type => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
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

    # select sponsors for the selected species that have projects
    my $sponsor_ids_rs = $self->select_sponsors_with_projects( );

    ### $sponsor_ids_rs

    my @sponsor_ids;

    foreach my $sponsor ( @$sponsor_ids_rs ) {
       my $sponsor_id = $sponsor->{ id };
       DEBUG "Sponsor id found = ".$sponsor_id;
       push( @sponsor_ids, $sponsor_id );
    }

    DEBUG "Sponsors = ";
    ### @sponsor_ids

    return [ @sponsor_ids ];

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

    DEBUG "Sponsor ids:";
    ### @sponsor_ids

    foreach my $sponsor_id ( @sponsor_ids ) {
        DEBUG "Building data for sponsor id = ".$sponsor_id;
        $self->_build_sponsor_column_data( $sponsor_id, \%sponsor_data );
    }

    return \%sponsor_data;
}

sub _build_sponsor_column_data {
    my ( $self, $sponsor_id, $sponsor_data ) = @_;

    DEBUG 'Building column data for sponsor id = '.$sponsor_id.', targeting type = '.$self->targeting_type.' and species = '.$self->species;

    # select how many genes this sponsor is targeting
    my $sponsor_gene_counts = $self->select_sponsor_genes( $sponsor_id );

    # NB sponsor may have both single and double targeted projects
    foreach my $sponsor_genes ( @$sponsor_gene_counts ) {

        my $number_genes = $sponsor_genes->{ genes };

        DEBUG "number genes = ".$number_genes;

        if ( $number_genes > 0 ) {
            $self->_build_column_data( $sponsor_id, $sponsor_data, $number_genes );
        }
    }

    return;
}

sub _build_column_data {

    my ( $self, $sponsor_id, $sponsor_data, $number_genes ) = @_;

    DEBUG 'Fetching column data: sponsor = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', number genes = '.$number_genes;

    # --------- Targeted Genes -----------
    my $count_tgs = $number_genes;
    $sponsor_data->{'Targeted Genes'}{$sponsor_id} = $count_tgs;

    # ------------ Vectors ---------------
    # only look if targeted genes found
    my $count_vectors = 0;
    if ( $count_tgs > 0 ) {
      $count_vectors = $self->vectors( $sponsor_id, 'count' );
    }
    $sponsor_data->{'Vectors'}{$sponsor_id} = $count_vectors;

    if ( $self->targeting_type eq 'double_targeted' ) {

        # only look if vectors found
        my $count_pairs_neo_bsd_vectors = 0;
        my $count_neo_vectors = 0;
        my $count_blast_vectors = 0;

        if ( $count_vectors > 0 ) {
          $count_pairs_neo_bsd_vectors = $self->vector_pairs_neo_and_bsd( $sponsor_id, 'count' );

          $count_neo_vectors = $self->vectors_with_resistance( $sponsor_id, 'neo' , 'count');
          $count_blast_vectors = $self->vectors_with_resistance( $sponsor_id, 'bsd', 'count' );
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
      $count_dna = $self->dna( $sponsor_id, 'count' );
    }
    $sponsor_data->{'Valid DNA'}{$sponsor_id} = $count_dna;

    if ( $self->targeting_type eq 'double_targeted' ) {
        # only look if DNA found
        my $count_pairs_neo_bsd_dna = 0;
        my $count_neo_dna = 0;
        my $count_blast_dna = 0;

        if ( $count_dna > 0 ) {
            $count_pairs_neo_bsd_dna = $self->dna_pairs_neo_and_bsd( $sponsor_id, 'count' );
            $count_neo_dna = $self->dna_with_resistance( $sponsor_id, 'neo', 'count' );
            $count_blast_dna = $self->dna_with_resistance( $sponsor_id, 'bsd', 'count' );
        }
        $sponsor_data->{'Valid DNA Neo and Bsd'}{$sponsor_id} = $count_pairs_neo_bsd_dna;
        $sponsor_data->{'Valid DNA Neo'}{$sponsor_id} = $count_neo_dna;
        $sponsor_data->{'Valid DNA Bsd'}{$sponsor_id} = $count_blast_dna;
    }
    else {
        $sponsor_data->{'Valid DNA Neo and Bsd'}{$sponsor_id} = -1;
        $sponsor_data->{'Valid DNA Neo'}{$sponsor_id}         = -1;
        $sponsor_data->{'Valid DNA Bsd'}{$sponsor_id}         = -1;
    }

    # ---------- Electroporations and Clones-----------
    # only look if dna found
    my $count_eps = 0;

    if ($self->targeting_type eq 'single_targeted' ) {
        if ( $count_dna > 0 ) {
            $count_eps = $self->electroporations( $sponsor_id, 'count' );
        }
        $sponsor_data->{'Electroporations'}{$sponsor_id} = $count_eps;

        # only look if electroporations found
        my $count_clones = 0;
        if ( $count_eps > 0 ) {
            $count_clones = $self->accepted_clones_st( $sponsor_id, 'count' );
        }
        $sponsor_data->{'Accepted ES Clones'}{$sponsor_id} = $count_clones;

        $sponsor_data->{'First Electroporations'}{$sponsor_id}      = -1;
        $sponsor_data->{'First Electroporations Neo'}{$sponsor_id}  = -1;
        $sponsor_data->{'First Electroporations Bsd'}{$sponsor_id}  = -1;
        $sponsor_data->{'Accepted First ES Clones'}{$sponsor_id}    = -1;
        $sponsor_data->{'Second Electroporations'}{$sponsor_id}     = -1;
        $sponsor_data->{'Second Electroporations Neo'}{$sponsor_id} = -1;
        $sponsor_data->{'Second Electroporations Bsd'}{$sponsor_id} = -1;
        $sponsor_data->{'Accepted Second ES Clones'}{$sponsor_id}   = -1;
    }
    elsif ( $self->targeting_type eq 'double_targeted' ) {

        if ( $count_dna > 0 ) {
            $count_eps = $self->first_electroporations( $sponsor_id, 'count' );
        }
        $sponsor_data->{'First Electroporations'}{$sponsor_id} = $count_eps;

        # only look if electroporations found
        my $count_neo_eps = 0;
        my $count_blast_eps = 0;
        if ( $count_eps > 0 ) {
          $count_neo_eps = $self->first_electroporations_with_resistance( $sponsor_id, 'neo', 'count' );
          $count_blast_eps = $self->first_electroporations_with_resistance( $sponsor_id, 'bsd', 'count' );
        }
        $sponsor_data->{'First Electroporations Neo'}{$sponsor_id} = $count_neo_eps;
        $sponsor_data->{'First Electroporations Bsd'}{$sponsor_id} = $count_blast_eps;

        # only look if electroporations found
        my $count_first_clones = 0;
        if ( $count_eps > 0 ) {
            $count_first_clones = $self->accepted_clones_first_ep( $sponsor_id, 'count' );
        }
        $sponsor_data->{'Accepted First ES Clones'}{$sponsor_id} = $count_first_clones;

        # only look if electroporations found
        my $count_second_eps = 0;
        my $count_second_eps_neo = 0;
        my $count_second_eps_bsd = 0;

        if ( $count_eps > 0 ) {
          $count_second_eps = $self->second_electroporations( $sponsor_id, 'count' );
          $count_second_eps_neo = $self->second_electroporations_with_resistance( $sponsor_id, 'neo', 'count' );
          $count_second_eps_bsd = $self->second_electroporations_with_resistance( $sponsor_id, 'bsd', 'count' );
        }
        $sponsor_data->{'Second Electroporations'}{$sponsor_id} = $count_second_eps;
        $sponsor_data->{'Second Electroporations Neo'}{$sponsor_id} = $count_second_eps_neo;
        $sponsor_data->{'Second Electroporations Bsd'}{$sponsor_id} = $count_second_eps_bsd;

        # only look if second electroporations found
        my $count_second_clones = 0;
        if ( $count_second_eps > 0 ) {
            $count_second_clones = $self->accepted_clones_second_ep( $sponsor_id, 'count' );
        }
        $sponsor_data->{'Accepted Second ES Clones'}{$sponsor_id} = $count_second_clones;
    }

    return;
}

sub select_sponsors_with_projects {
    my ( $self ) = @_;

    DEBUG 'Selecting sponsors with '.$self->targeting_type.' projects where species = '.$self->species;

    my $sql_results;

    my $sql_query = $self->create_sql_select_sponsors_with_projects( $self->species, $self->targeting_type );

    $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

sub select_sponsor_genes {
    my ( $self, $sponsor_id ) = @_;

    DEBUG "Selecting genes for sponsor id = ".$sponsor_id.' and targeting type = '.$self->targeting_type.' and species '.$self->species;

    my $sql_results;

    my $sql_query = $self->create_sql_count_genes_for_a_sponsor( $sponsor_id, $self->targeting_type, $self->species );

    $sql_results = $self->run_select_query( $sql_query );

    return $sql_results;
}

# Generate front page report matrix
sub generate_top_level_report_for_sponsors {
    my ( $self ) = @_;

    DEBUG 'Generating report for '.$self->targeting_type.' projects for species '.$self->species;

    # build information for report
    my $columns = $self->build_columns;
    my $data    = $self->sponsor_data;
    my $title   = $self->build_page_title;

    my $rows;
    if ( $self->targeting_type eq 'single_targeted' ) {
        $rows = \@ST_REPORT_CATEGORIES;
    }
    elsif ( $self->targeting_type eq 'double_targeted' ) {
        $rows = \@DT_REPORT_CATEGORIES;
    }

    my $report_id;
    if ( defined $data && keys %{ $data } ) {
        $report_id = 'SponsRep';
    }

    my %return_params = (
        'report_id'      => $report_id,
        'title'          => $title,
        'columns'        => $columns,
        'rows'           => $rows,
        'data'           => $data,
    );

    return \%return_params;
}

sub build_page_title {
    my $self = shift;

    # TODO: This date should relate to a timestamp indicating when summaries data was
    # last generated rather than just system date.
    my $dt = DateTime->now();

    return 'Pipeline Summary Report ('.$self->species.', '.$self->targeting_type.' projects) on ' . $dt->dmy;
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
    my ($self, $sponsor_id, $stage) = @_;

    # reports differ based on combination of targeting type and stage
    my $data = $self->_build_sub_report_data($sponsor_id, $stage);

    # for single-targeted projects
    my $st_rpt_flds = {
        'Targeted Genes'                    => {
            'display_stage'         => 'Targeted genes',
            'columns'               => [ 'gene_id', 'gene_symbol' ],
            'display_columns'       => [ 'gene id', 'gene symbol' ],
        },
        'Vectors'                           => {
            'display_stage'         => 'Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor' ],
        },
        'Valid DNA'                         => {
            'display_stage'         => 'Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'parent_plate_name', 'parent_well_name', 'plate_name', 'well_name', 'final_qc_seq_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'parent plate', 'parent well', 'plate', 'well', 'final QC seq' ],
        },
        'Electroporations'            => {
            'display_stage'         => 'Electroporations',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name', 'final_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well', 'final QC seq', 'DNA status' ],
        },
        'Accepted ES Clones'                => {
            'display_stage'         => 'Accepted ES Clones',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name', 'final_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well', 'final QC seq', 'DNA status' ],
        },
    };

    # for double-targeted projects
    my $dt_rpt_flds = {
        'Targeted Genes'            => {
            'display_stage'         => 'Targeted genes',
            'columns'               => [ 'gene_id', 'gene_symbol' ],
            'display_columns'       => [ 'gene id', 'gene' ],
        },
        'Vectors'                   => {
            'display_stage'         => 'Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well' ],
        },
        'Vectors Neo and Bsd'       => {
            'display_stage'         => 'Vector pairs Neo and Bsd',
            'columns'               => [ 'project_id','design_id', 'design_gene_id', 'design_gene_symbol', 'cassettes_available' ],
            'display_columns'       => [ 'project id', 'design id', 'gene id', 'gene', 'cassette types found' ],
        },
        'Vectors Neo'               => {
            'display_stage'         => 'Neomycin-resistant Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well' ],
        },
        'Vectors Bsd'               => {
            'display_stage'         => 'Blasticidin-resistant Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well' ],
        },
        'Valid DNA'                 => {
            'display_stage'         => 'Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'parent_plate_name', 'parent_well_name', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'parent plate', 'parent well', 'plate', 'well', 'final QC seq', 'final pick QC seq' ],
        },
        'Valid DNA Neo and Bsd'     => {
            'display_stage'         => 'Valid DNA pairs Neo and Bsd',
            'columns'               => [ 'project_id','design_id', 'design_gene_id', 'design_gene_symbol', 'cassettes_available' ],
            'display_columns'       => [ 'project id', 'design id', 'gene id', 'gene', 'cassette types found' ],
        },
        'Valid DNA Neo'             => {
            'display_stage'         => 'Neomycin-resistant Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'parent_plate_name', 'parent_well_name', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'parent plate', 'parent well', 'plate', 'well', 'final QC seq', 'final pick QC seq' ],
        },
        'Valid DNA Bsd'             => {
            'display_stage'         => 'Blasticidin-resistant Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'parent_plate_name', 'parent_well_name', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'parent plate', 'parent well', 'plate', 'well', 'final QC seq', 'final pick QC seq' ],
        },
        'First Electroporations'    => {
            'display_stage'         => 'First Electroporations',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'First Electroporations Neo' => {
            'display_stage'         => 'First Electroporations Neo',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'First Electroporations Bsd' => {
            'display_stage'         => 'First Electroporations Bsd',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Accepted First ES Clones'  => {
            'display_stage'         => 'Accepted First ES Clones',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Second Electroporations'   => {
            'display_stage'         => 'Second Electroporations',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'cassette_resistance', 'order', 'plate_name', 'well_name',  'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'resistance', 'electroporation order', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Second Electroporations Neo'   => {
            'display_stage'         => 'Second Electroporations Neo',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Second Electroporations Bsd'   => {
            'display_stage'         => 'Second Electroporations Bsd',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Accepted Second ES Clones' => {
            'display_stage'         => 'Accepted Second ES Clones',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promotor', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promotor', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
    };

    my ($columns, $display_columns, $display_targeting_type, $display_stage);

    if ( $self->targeting_type eq 'single_targeted' ) {
        $display_targeting_type     = 'single-targeted';
        $display_stage              = $st_rpt_flds->{ $stage }->{ 'display_stage' };
        $columns                    = $st_rpt_flds->{ $stage }->{ 'columns' };
        $display_columns            = $st_rpt_flds->{ $stage }->{ 'display_columns' };
    }
    elsif ( $self->targeting_type eq 'double_targeted' ) {
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
    my ($self, $sponsor_id, $stage) = @_;

    DEBUG 'Building sub-summary report for sponsor = '.$sponsor_id.', stage = '.$stage.', targeting_type = '.$self->targeting_type.' and species = '.$self->species;

    my $query_type = 'select';
    my $sub_report_data;

    # dispatch table
    my $rep_for_stg = {
         'Targeted Genes'                    => {
             'func'      => \&genes,
             'params'    => [ $self, $sponsor_id, $query_type ],
         },
        'Vectors'                           => {
            'func'      => \&vectors,
            'params'    => [ $self, $sponsor_id, $query_type ],
        },
        'Vectors Neo and Bsd'               => {
            'func'      => \&vector_pairs_neo_and_bsd,
            'params'    => [ $self, $sponsor_id, $query_type ],
        },
        'Vectors Neo'                       => {
            'func'      => \&vectors_with_resistance,
            'params'    => [ $self, $sponsor_id, 'neo', $query_type ],
        },
        'Vectors Bsd'                       => {
            'func'      => \&vectors_with_resistance,
            'params'    => [ $self, $sponsor_id, 'bsd', $query_type ],
        },
        'Valid DNA'                         => {
            'func'      => \&dna,
            'params'    => [ $self, $sponsor_id, $query_type ],
        },
        'Valid DNA Neo and Bsd'             => {
            'func'      => \&dna_pairs_neo_and_bsd,
            'params'    => [ $self, $sponsor_id, $query_type ],
        },
        'Valid DNA Neo'                     => {
            'func'      => \&dna_with_resistance,
            'params'    => [ $self, $sponsor_id, 'neo', $query_type ],
        },
        'Valid DNA Bsd'                     => {
            'func'      => \&dna_with_resistance,
            'params'    => [ $self, $sponsor_id, 'bsd', $query_type ],
        },
        'Electroporations'                  => {
            'func'      => \&electroporations,
            'params'    => [ $self, $sponsor_id, $query_type ],
        },
        'First Electroporations'            => {
            'func'      => \&first_electroporations,
            'params'    => [ $self, $sponsor_id, $query_type ],
        },
        'First Electroporations Neo'        => {
            'func'      => \&first_electroporations_with_resistance,
            'params'    => [ $self, $sponsor_id, 'neo', $query_type ],
        },
        'First Electroporations Bsd'        => {
            'func'      => \&first_electroporations_with_resistance,
            'params'    => [ $self, $sponsor_id, 'bsd', $query_type ],
        },
        'Accepted ES Clones'                => {
            'func'      => \&accepted_clones_st,
            'params'    => [ $self, $sponsor_id, $query_type ],
        },
        'Accepted First ES Clones'          => {
            'func'      => \&accepted_clones_first_ep,
            'params'    => [ $self, $sponsor_id, $query_type ],
        },
        'Second Electroporations'           => {
            'func'      => \&second_electroporations,
            'params'    => [ $self, $sponsor_id, $query_type ],
        },
        'Second Electroporations Neo'           => {
            'func'      => \&second_electroporations_with_resistance,
            'params'    => [ $self, $sponsor_id, 'neo', $query_type ],
        },
        'Second Electroporations Bsd'           => {
            'func'      => \&second_electroporations_with_resistance,
            'params'    => [ $self, $sponsor_id, 'bsd', $query_type ],
        },
        'Accepted Second ES Clones'         => {
            'func'      => \&accepted_clones_second_ep,
            'params'    => [ $self, $sponsor_id, $query_type ],
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
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG "Genes for: sponsor id = ".$sponsor_id." and targeting_type = ".$self->targeting_type.' and species = '.$self->species;

    my $sql_query = $self->create_sql_sel_targeted_genes( $sponsor_id, $self->targeting_type, $self->species );

    #DEBUG "sql query = ".$sql_query;

    my $sql_results = $self->run_select_query( $sql_query );

    # fetch gene symbols and return modified results set for display
    my @genes_for_display;

    foreach my $gene_row ( @$sql_results ) {
        my $gene_id = $gene_row->{ 'gene_id' };

        my $gene_symbol = $self->model->retrieve_gene( { 'search_term' => $gene_id,  'species' => $self->species } )->{gene_symbol};

        push @genes_for_display, { 'gene_id' => $gene_id, 'gene_symbol' => $gene_symbol };
    }

    # sort the array by gene symbol
    my @sorted_genes_for_display =  sort { $a->{ 'gene_symbol' } cmp $b-> { 'gene_symbol' } } @genes_for_display;

    return \@sorted_genes_for_display;
}

sub vectors {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'Vectors: sponsor id = '.$sponsor_id.' , targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        if ( $self->targeting_type eq 'single_targeted' ) {
            $sql_query = $self->sql_count_st_vectors ( $sponsor_id );
        }
        elsif ( $self->targeting_type eq 'double_targeted' ) {
            $sql_query = $self->sql_count_dt_vectors ( $sponsor_id );
        }
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        if ( $self->targeting_type eq 'single_targeted' ) {
            $sql_query = $self->sql_select_st_vectors ( $sponsor_id );
        }
        elsif ( $self->targeting_type eq 'double_targeted' ) {
            $sql_query = $self->sql_select_dt_vectors ( $sponsor_id );
        }
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub vector_pairs_neo_and_bsd {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'Vector pairs: sponsor id = '.$sponsor_id.' and targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_vectors_neo_and_bsd ( $sponsor_id );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_vectors_neo_bsd ( $sponsor_id );
        my $sql_results = $self->run_select_query( $sql_query );

        my $return_results = $self->refactor_vector_pairs_data( $sql_results );

        return $return_results;
    }
}

sub refactor_vector_pairs_data {
    my ( $self, $sql_results ) = @_;

    # now have a resultset with multiple rows per gene, one per combination of
    # neo/bsd and promoter/promoterless
    # e.g. project id, design id, gene, resistance, promotor
    # 232   40416   Akt2    bsd  1
    # 232   40416   Akt2    neo    0
    # 232   40416   Akt2    neo    1

    # convert this into single row per gene for display, shows types cassettes available:
    # e.g. project id, design id, gene, cassettes_available
    # 232   40416   Akt2   bsd P, neo P, neo PL

    my @return_results;

    my %row_building = (
        'have_bsd_promoter'     => 0,
        'have_bsd_promoterless' => 0,
        'have_neo_promoter'     => 0,
        'have_neo_promoterless' => 0,
    );

    my $count_rows = 0;

    # cycle through resultset
    foreach my $row ( @$sql_results ) {
        if ( defined $row_building{ 'project_id' } ) {

            # compare to last row stored, if different write line to output
            if ( ($row->{ 'project_id' } != $row_building{ 'project_id' } ) && ( $row->{ 'design_id' } != $row_building{ 'design_id' } ) && ( $row->{ 'design_gene_id' } ne $row_building{ 'gene_id' } ) ) {

                # create cassettes available string and store row in output array
                $self->write_row_to_vector_pairs_data( \@return_results, \%row_building );

                $count_rows++;

                # initialise new row
                $row_building{ 'project_id' }            = $row->{ 'project_id' };
                $row_building{ 'design_id' }             = $row->{ 'design_id' };
                $row_building{ 'gene_id' }               = $row->{ 'design_gene_id' };
                $row_building{ 'gene_symbol' }           = $row->{ 'design_gene_symbol' };

                $row_building{ 'have_bsd_promoter' }     = 0;
                $row_building{ 'have_bsd_promoterless' } = 0;
                $row_building{ 'have_neo_promoter' }     = 0;
                $row_building{ 'have_neo_promoterless' } = 0;
            }
        }
        else {
            # first time: set the stored variable values
            $row_building{ 'project_id' }            = $row->{ 'project_id' };
            $row_building{ 'design_id' }             = $row->{ 'design_id' };
            $row_building{ 'gene_id' }               = $row->{ 'design_gene_id' };
            $row_building{ 'gene_symbol' }           = $row->{ 'design_gene_symbol' };
        }

        # update flags according to current row (NB same flag may be triggered
        # multiple times if different cassettes have same resistance/promotor type
        if( defined $row->{ 'final_cassette_resistance' } ) {
            if ( ($row->{ 'final_cassette_resistance' } eq 'bsd') && ($row->{ 'final_cassette_promoter' } == 1 ) ) {
               $row_building{ 'have_bsd_promoter' } = 1;
            }
            if ( ($row->{ 'final_cassette_resistance' } eq 'bsd') && ($row->{ 'final_cassette_promoter' } == 0 ) ) {
               $row_building{ 'have_bsd_promoterless' } = 1;
            }
            if ( ($row->{ 'final_cassette_resistance' } eq 'neo') && ($row->{ 'final_cassette_promoter' } == 1 ) ) {
               $row_building{ 'have_neo_promoter' } = 1;
            }
            if ( ($row->{ 'final_cassette_resistance' } eq 'neo') && ($row->{ 'final_cassette_promoter' } == 0 ) ) {
               $row_building{ 'have_neo_promoterless' } = 1;
            }
        }
        else {
            DEBUG 'WARNING: No FINAL cassette resistance found for Neo and Bsd Vectors row for gene '.$row->{ 'design_gene_symbol' }.' id '.$row->{ 'design_gene_id' };
        }
    }

    # if have a last row write it
    if ( defined $row_building{ 'project_id' } && $row_building{ 'project_id' } > 0 ) {

        # store last row into results array
        $self->write_row_to_vector_pairs_data( \@return_results, \%row_building );

        $count_rows++;
    }

    DEBUG 'Vectors Neo and Bsd rows created = '.$count_rows;

    return \@return_results;

}

sub write_row_to_vector_pairs_data {
    my ( $self, $return_results, $row_building ) = @_;

    # Build up cassettes available string depending on flags
    my $cass_avail;

	if ( $row_building->{ 'have_bsd_promoter' } )     { $cass_avail .= 'bsd P, '; }
	if ( $row_building->{ 'have_bsd_promoterless' } ) { $cass_avail .= 'bsd PL, '; }
	if ( $row_building->{ 'have_neo_promoter' } )     { $cass_avail .= 'neo P, '; }
	if ( $row_building->{ 'have_neo_promoterless' } ) { $cass_avail .= 'neo PL'; }

	if ((substr $cass_avail,-2,2) eq ', ') { chop $cass_avail;chop $cass_avail; }

    # Push new hash row to output array
	push @$return_results, { 'project_id' => $row_building->{ 'project_id' }, 'design_id' => $row_building->{ 'design_id' }, 'design_gene_id' => $row_building->{ 'gene_id' }, 'design_gene_symbol' => $row_building->{ 'gene_symbol' }, 'cassettes_available' => $cass_avail };

    # delete contents of the row building hash
    for (keys %$row_building)
    {
        delete $row_building->{$_};
    }

	return $return_results;
}

sub vectors_with_resistance {
    my ( $self, $sponsor_id, $resistance_type, $query_type ) = @_;

    DEBUG 'Vectors with resistance: sponsor id = '.$sponsor_id.' and targeting_type = '.$self->targeting_type.', resistance =  '.$resistance_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_vectors_with_resistance ( $sponsor_id, $resistance_type );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_vectors_with_resistance ( $sponsor_id, $resistance_type );
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub dna {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'DNA: sponsor id = '.$sponsor_id.' and targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        if ( $self->targeting_type eq 'single_targeted' ) {
            $sql_query = $self->sql_count_st_dna ( $sponsor_id );
        }
        elsif ( $self->targeting_type eq 'double_targeted' ) {
            $sql_query = $self->sql_count_dt_dna ( $sponsor_id );
        }
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        if ( $self->targeting_type eq 'single_targeted' ) {
            $sql_query = $self->sql_select_st_dna ( $sponsor_id );
        }
        elsif ( $self->targeting_type eq 'double_targeted' ) {
            $sql_query = $self->sql_select_dt_dna ( $sponsor_id );
        }
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub dna_pairs_neo_and_bsd {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'DNA pairs neo and bsd: sponsor id = '.$sponsor_id.' and targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_dna_neo_and_bsd ( $sponsor_id );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_dna_neo_bsd ( $sponsor_id );
        my $sql_results = $self->run_select_query( $sql_query );

        my $return_results = $self->refactor_dna_pairs_data( $sql_results );

        return $return_results;
    }
}

sub refactor_dna_pairs_data {
    my ( $self, $sql_results ) = @_;

    # now have a resultset with multiple rows per gene, one per combination of
    # neo/bsd and promoter/promoterless
    # e.g. project id, design id, gene, resistance, promotor
    # 232   40416   Akt2    bsd  1
    # 232   40416   Akt2    neo    0
    # 232   40416   Akt2    neo    1

    # convert this into single row per gene for display, shows types cassettes available:
    # e.g. project id, design id, gene, cassettes_available
    # 232   40416   Akt2   bsd P, neo P, neo PL

    my @return_results;

    my %row_building = (
        'have_bsd_promoter'     => 0,
        'have_bsd_promoterless' => 0,
        'have_neo_promoter'     => 0,
        'have_neo_promoterless' => 0,
    );

    my $count_rows = 0;

    # cycle through resultset
    foreach my $row ( @$sql_results ) {
        if ( defined $row_building{ 'project_id' } ) {

            # compare to last row stored, if different write line to output
            if ( ($row->{ 'project_id' } != $row_building{ 'project_id' } ) && ( $row->{ 'design_id' } != $row_building{ 'design_id' } ) && ( $row->{ 'design_gene_id' } ne $row_building{ 'gene_id' } ) ) {

                # create cassettes available string and store row in output array
                $self->write_row_to_vector_pairs_data( \@return_results, \%row_building );

                $count_rows++;

                # initialise new row
                $row_building{ 'project_id' }            = $row->{ 'project_id' };
                $row_building{ 'design_id' }             = $row->{ 'design_id' };
                $row_building{ 'gene_id' }               = $row->{ 'design_gene_id' };
                $row_building{ 'gene_symbol' }           = $row->{ 'design_gene_symbol' };

                $row_building{ 'have_bsd_promoter' }     = 0;
                $row_building{ 'have_bsd_promoterless' } = 0;
                $row_building{ 'have_neo_promoter' }     = 0;
                $row_building{ 'have_neo_promoterless' } = 0;
            }
        }
        else {
            # first time: set the stored variable values
            $row_building{ 'project_id' }            = $row->{ 'project_id' };
            $row_building{ 'design_id' }             = $row->{ 'design_id' };
            $row_building{ 'gene_id' }               = $row->{ 'design_gene_id' };
            $row_building{ 'gene_symbol' }           = $row->{ 'design_gene_symbol' };
        }

        # update flags according to current row (NB same flag may be triggered
        # multiple times if different cassettes have same resistance/promotor type
        if( defined $row->{ 'final_pick_cassette_resistance' } ) {
            if ( ($row->{ 'final_pick_cassette_resistance' } eq 'bsd') && ($row->{ 'final_pick_cassette_promoter' } == 1 ) ) {
               $row_building{ 'have_bsd_promoter' } = 1;
            }
            if ( ($row->{ 'final_pick_cassette_resistance' } eq 'bsd') && ($row->{ 'final_pick_cassette_promoter' } == 0 ) ) {
               $row_building{ 'have_bsd_promoterless' } = 1;
            }
            if ( ($row->{ 'final_pick_cassette_resistance' } eq 'neo') && ($row->{ 'final_pick_cassette_promoter' } == 1 ) ) {
               $row_building{ 'have_neo_promoter' } = 1;
            }
            if ( ($row->{ 'final_pick_cassette_resistance' } eq 'neo') && ($row->{ 'final_pick_cassette_promoter' } == 0 ) ) {
               $row_building{ 'have_neo_promoterless' } = 1;
            }
        }
        else {
            DEBUG 'WARNING: No FINAL_PICK cassette resistance found for Neo and Bsd DNA row for gene '.$row->{ 'design_gene_symbol' }.' id '.$row->{ 'design_gene_id' };
        }
    }

    # if have a last row write it
    if ( defined $row_building{ 'project_id' } && $row_building{ 'project_id' } > 0 ) {

        # store last row into results array
        $self->write_row_to_vector_pairs_data( \@return_results, \%row_building );

        $count_rows++;
    }

    DEBUG 'Vectors Neo and Bsd rows created = '.$count_rows;

    return \@return_results;

}

sub write_row_to_dna_pairs_data {
    my ( $self, $return_results, $row_building ) = @_;

    # Build up cassettes available string depending on flags
    my $cass_avail;

	if ( $row_building->{ 'have_bsd_promoter' } )     { $cass_avail .= 'bsd P, '; }
	if ( $row_building->{ 'have_bsd_promoterless' } ) { $cass_avail .= 'bsd PL, '; }
	if ( $row_building->{ 'have_neo_promoter' } )     { $cass_avail .= 'neo P, '; }
	if ( $row_building->{ 'have_neo_promoterless' } ) { $cass_avail .= 'neo PL'; }

	if ((substr $cass_avail,-2,2) eq ', ') { chop $cass_avail;chop $cass_avail; }

    # Push new hash row to output array
	push @$return_results, { 'project_id' => $row_building->{ 'project_id' }, 'design_id' => $row_building->{ 'design_id' }, 'design_gene_id' => $row_building->{ 'gene_id' }, 'design_gene_symbol' => $row_building->{ 'gene_symbol' }, 'cassettes_available' => $cass_avail };

    # delete contents of the row building hash
    for (keys %$row_building)
    {
        delete $row_building->{$_};
    }

	return $return_results;
}

sub dna_with_resistance {
    my ( $self, $sponsor_id, $resistance_type, $query_type ) = @_;

    DEBUG 'DNA with resistance: sponsor id = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', resistance '.$resistance_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_dna_with_resistance ( $sponsor_id, $resistance_type );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_dna_with_resistance ( $sponsor_id, $resistance_type );
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub electroporations {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'First electroporations: sponsor id = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_st_eps ( $sponsor_id );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_st_electroporations ( $sponsor_id );
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub first_electroporations {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'First electroporations: sponsor id = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_first_eps ( $sponsor_id );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_first_eps ( $sponsor_id );
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub first_electroporations_with_resistance {
    my ( $self, $sponsor_id, $resistance_type, $query_type ) = @_;

    DEBUG 'First electroporations with resistance: sponsor id = '.$sponsor_id.', resistance '.$resistance_type.', targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_first_eps_with_resistance ( $sponsor_id, $resistance_type );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_first_eps_with_resistance ( $sponsor_id, $resistance_type );
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub second_electroporations {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'Second electroporations: sponsor id = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_second_eps ( $sponsor_id );
        $count = $self->run_count_query( $sql_query );
        return $count;

    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_second_eps ( $sponsor_id );
        my $sql_results = $self->run_select_query( $sql_query );

        # cycle through resultset
        foreach my $row ( @$sql_results ) {
            my $cur_ep_well_id       = $row->{ 'ep_well_id' };
            if ( defined $cur_ep_well_id && $cur_ep_well_id > 0 ) {
                $row->{ 'order' } = 'first';
            }
            else {
                $row->{ 'order' } = 'second';
            }
        }

        return $sql_results;
    }
}

sub second_electroporations_with_resistance {
    my ( $self, $sponsor_id, $resistance_type, $query_type ) = @_;

    DEBUG 'Second electroporations with resistance: sponsor id = '.$sponsor_id.', resistance '.$resistance_type.', targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_second_eps_with_resistance ( $sponsor_id, $resistance_type );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_second_eps_with_resistance ( $sponsor_id, $resistance_type );
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub accepted_clones_st {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'Accepted clones: sponsor id = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_st_accepted_clones ( $sponsor_id );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_st_accepted_clones ( $sponsor_id );
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub accepted_clones_first_ep {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'Accepted clones: sponsor id = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_first_accepted_clones ( $sponsor_id );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_first_accepted_clones ( $sponsor_id );
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub accepted_clones_second_ep {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'Accepted second allele clones: sponsor id = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_dt_second_accepted_clones( $sponsor_id );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_dt_second_accepted_clones( $sponsor_id );
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
sub create_sql_select_sponsors_with_projects {
    my ( $self, $species_id, $targeting_type ) = @_;

my $sql_query =  <<"SQL_END";
SELECT distinct(s.id)
FROM sponsors s
JOIN projects pr ON pr.sponsor_id = s.id
WHERE pr.species_id = '$species_id'
AND pr.targeting_type = '$targeting_type'
ORDER BY s.id
SQL_END

    return $sql_query;
}

# Set up SQL query to select targeting type and count genes for a sponsor id
sub create_sql_count_genes_for_a_sponsor {
    my ( $self, $sponsor_id, $targeting_type, $species_id ) = @_;

my $sql_query =  <<"SQL_END";
SELECT p.sponsor_id, count(distinct(gene_id)) AS genes
FROM projects p
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = '$targeting_type'
AND p.species_id = '$species_id'
GROUP BY p.sponsor_id
SQL_END

    return $sql_query;
}

# SQL to select targeted genes for a specific sponsor and targeting type
sub create_sql_sel_targeted_genes {
    my ( $self, $sponsor_id, $targeting_type, $species_id ) = @_;

my $sql_query =  <<"SQL_END";
SELECT distinct(p.gene_id)
FROM projects p
WHERE p.sponsor_id = '$sponsor_id'
AND p.targeting_type = '$targeting_type'
AND p.species_id = '$species_id'
ORDER BY p.gene_id
SQL_END

    return $sql_query;
}

# -----------------------------
# SINGLE-TARGETED COUNTS
# -----------------------------
# Vectors
sub sql_count_st_vectors {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.final_qc_seq_pass = true
SQL_END

    return $sql_query;
}

# DNA
sub sql_count_st_dna {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.dna_status_pass = true
SQL_END

    return $sql_query;
}

# First electroporations
sub sql_count_st_eps {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.ep_well_id > 0
SQL_END

    return $sql_query;
}

# Accepted clones
sub sql_count_st_accepted_clones {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.ep_pick_well_accepted = true
SQL_END

    return $sql_query;
}

# ---------------------------------------
# SINGLE-TARGETED SELECTS
# ---------------------------------------
# Vectors
sub sql_select_st_vectors {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_cassette_name AS cassette_name, s.final_cassette_promoter AS cassette_promotor, s.final_plate_name AS plate_name, s.final_well_name AS well_name
FROM summaries s
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
AND s.final_qc_seq_pass = true
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_cassette_name, s.final_cassette_promoter, s.final_plate_name, s.final_well_name
ORDER BY s.design_gene_symbol, s.final_cassette_name, s.final_plate_name, s.final_well_name
SQL_END

    return $sql_query;
}

# DNA
sub sql_select_st_dna {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_cassette_name AS cassette_name, s.final_cassette_promoter AS cassette_promotor, s.final_plate_name AS parent_plate_name, s.final_well_name AS parent_well_name, s.dna_plate_name AS plate_name, s.dna_well_name AS well_name, s.final_qc_seq_pass
FROM summaries s
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
AND s.dna_status_pass = true
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_cassette_name, s.final_cassette_promoter, s.final_plate_name, s.final_well_name, s.dna_plate_name, s.dna_well_name, s.final_qc_seq_pass
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_END

    return $sql_query;
}

# Electroporations
sub sql_select_st_electroporations {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name AS plate_name, s.ep_well_name AS well_name, s.final_cassette_name AS cassette_name, s.final_cassette_promoter AS cassette_promotor, s.final_qc_seq_pass, s.dna_status_pass
FROM summaries s
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
AND s.ep_well_id > 0
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name, s.final_cassette_name, s.final_cassette_promoter, s.final_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_END

    return $sql_query;
}

# Clones
sub sql_select_st_accepted_clones {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_cassette_name AS cassette_name, s.final_cassette_promoter AS cassette_promotor, s.ep_pick_plate_name AS plate_name, s.ep_pick_well_name AS well_name, s.final_qc_seq_pass, s.dna_status_pass
FROM summaries s
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
AND s.ep_pick_well_accepted = true
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_cassette_name, s.final_cassette_promoter, s.ep_pick_plate_name, s.ep_pick_well_name, s.final_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
SQL_END

    return $sql_query;
}

# ---------------------------------------
# DOUBLE-TARGETED COUNTS
# ---------------------------------------
# Vectors
sub sql_count_dt_vectors {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.final_qc_seq_pass = true
SQL_END

    return $sql_query;
}

# Vector pairs
sub sql_count_dt_vectors_neo_and_bsd {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
 , neo_vectors AS (
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
FROM summaries s
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
AND s.final_qc_seq_pass = true
AND s.final_cassette_resistance = 'neo' 
GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
)
, bsd_vectors AS (
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
FROM summaries s
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
AND s.final_qc_seq_pass = true
AND s.final_cassette_resistance = 'bsd'
GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
)
SELECT count(distinct(nv.design_gene_id))
FROM neo_vectors nv
INNER JOIN bsd_vectors bv ON bv.project_id = nv.project_id
AND bv.design_id = nv.design_id
SQL_END

    return $sql_query;
}

# Vectors with resistance
sub sql_count_dt_vectors_with_resistance {
    my ( $self, $sponsor_id, $resistance_type ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.final_qc_seq_pass = true
AND s.final_cassette_resistance = '$resistance_type'
SQL_END

    return $sql_query;
}

# DNA
sub sql_count_dt_dna {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.dna_status_pass = true
SQL_END

    return $sql_query;
}

# DNA pairs neo and bsd
sub sql_count_dt_dna_neo_and_bsd {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
 , neo_vectors AS (
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
FROM summaries s
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
AND s.final_pick_cassette_resistance = 'neo' AND s.dna_status_pass = true
GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
)
, bsd_vectors AS (
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
FROM summaries s
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
AND s.final_pick_cassette_resistance = 'bsd' 
AND s.dna_status_pass = true
GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
)
SELECT count(distinct(nv.design_gene_id))
FROM neo_vectors nv
INNER JOIN bsd_vectors bv ON bv.project_id = nv.project_id
AND bv.design_id = nv.design_id
SQL_END

    return $sql_query;
}

# DNA with resistance
sub sql_count_dt_dna_with_resistance {
    my ( $self, $sponsor_id, $resistance_type ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.dna_status_pass = true
AND s.final_pick_cassette_resistance = '$resistance_type'
SQL_END

    return $sql_query;
}

# First electroporations
sub sql_count_dt_first_eps {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.ep_well_id > 0
SQL_END

    return $sql_query;
}

# First electroporations with resistance
sub sql_count_dt_first_eps_with_resistance {
    my ( $self, $sponsor_id, $resistance_type ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.ep_well_id > 0
AND s.final_pick_cassette_resistance = '$resistance_type'
SQL_END

    return $sql_query;
}

# Accepted first clones
sub sql_count_dt_first_accepted_clones {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.ep_pick_well_accepted = true
SQL_END

    return $sql_query;
}

#Second electroporations
sub sql_count_dt_second_eps {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.sep_well_id > 0
SQL_END

    return $sql_query;
}

# Second electroporations with resistance
sub sql_count_dt_second_eps_with_resistance {
    my ( $self, $sponsor_id, $resistance_type ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.sep_well_id > 0
AND s.ep_well_id IS NULL AND s.final_pick_cassette_resistance = '$resistance_type'
SQL_END

    return $sql_query;
}

# Accepted second allele clones
sub sql_count_dt_second_accepted_clones {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
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
AND s.sep_pick_well_accepted = true
SQL_END

    return $sql_query;
}

# ---------------------------------------
# DOUBLE-TARGETED SELECTS
# ---------------------------------------
# Vectors
sub sql_select_dt_vectors {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_cassette_name AS cassette_name, s.final_cassette_promoter AS cassette_promotor, s.final_plate_name AS plate_name, s.final_well_name AS well_name
FROM summaries s
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
AND s.final_qc_seq_pass = true
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_cassette_name, s.final_cassette_promoter, s.final_plate_name, s.final_well_name
ORDER BY s.design_gene_symbol, s.final_cassette_name, s.final_plate_name, s.final_well_name
SQL_END

    return $sql_query;
}

# Vector pairs
sub sql_select_dt_vectors_neo_bsd {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
, neo_vectors AS (
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
FROM summaries s
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
AND s.final_qc_seq_pass = true
AND s.final_cassette_resistance = 'neo' GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
)
, bsd_vectors AS (
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
FROM summaries s
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
AND s.final_qc_seq_pass = true
AND s.final_cassette_resistance = 'bsd' GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
)
 , vector_pairings AS (
SELECT nv.project_id, nv.design_id, nv.design_gene_id, nv.design_gene_symbol
FROM neo_vectors nv
INNER JOIN bsd_vectors bv ON bv.project_id = nv.project_id
AND bv.design_id = nv.design_id
GROUP BY nv.project_id, nv.design_id, nv.design_gene_id, nv.design_gene_symbol
)
SELECT vp.project_id, vp.design_id, vp.design_gene_id, vp.design_gene_symbol, s.final_cassette_resistance, s.final_cassette_promoter
FROM summaries s
INNER JOIN vector_pairings vp ON s.design_id = vp.design_id
WHERE s.design_species_id = '$species_id'
AND s.final_qc_seq_pass = true
GROUP BY vp.project_id, vp.design_id, vp.design_gene_id, vp.design_gene_symbol, s.final_cassette_resistance, s.final_cassette_promoter
ORDER BY vp.design_gene_symbol, vp.project_id, vp.design_id, s.final_cassette_resistance, s.final_cassette_promoter
SQL_END

    return $sql_query;
}

# Vectors with resistance
sub sql_select_dt_vectors_with_resistance {
    my ( $self, $sponsor_id, $resistance_type ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_cassette_name AS cassette_name, s.final_cassette_promoter AS cassette_promotor, s.final_plate_name AS plate_name, s.final_well_name AS well_name
FROM summaries s
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
AND s.final_qc_seq_pass = true
AND s.final_cassette_resistance = '$resistance_type'
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_cassette_name, s.final_cassette_promoter, s.final_plate_name, s.final_well_name
ORDER BY s.design_gene_symbol, s.final_cassette_name, s.final_plate_name, s.final_well_name
SQL_END

    return $sql_query;
}

# DNA
sub sql_select_dt_dna {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promotor, s.final_pick_plate_name AS parent_plate_name, s.final_pick_well_name AS parent_well_name, s.dna_plate_name AS plate_name, s.dna_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
FROM summaries s
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
AND s.dna_status_pass = true
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter, s.final_pick_plate_name, s.final_pick_well_name, s.dna_plate_name, s.dna_well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_END

    return $sql_query;
}

# DNA pairs
sub sql_select_dt_dna_neo_bsd {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
, neo_vectors AS (
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
FROM summaries s
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
AND s.final_pick_cassette_resistance = 'neo' 
AND s.dna_status_pass = true
GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
)
, bsd_vectors AS (
SELECT pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
FROM summaries s
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
AND s.final_pick_cassette_resistance = 'bsd' 
AND s.dna_status_pass = true
GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
)
, vector_pairings AS (
SELECT nv.project_id, nv.design_id, nv.design_gene_id, nv.design_gene_symbol
FROM neo_vectors nv
INNER JOIN bsd_vectors bv ON bv.project_id = nv.project_id
AND bv.design_id = nv.design_id
GROUP BY nv.project_id, nv.design_id, nv.design_gene_id, nv.design_gene_symbol
)
SELECT vp.project_id, vp.design_id, vp.design_gene_id, vp.design_gene_symbol, s.final_pick_cassette_resistance, s.final_pick_cassette_promoter
FROM summaries s
INNER JOIN vector_pairings vp ON s.design_id = vp.design_id
WHERE s.design_species_id = '$species_id'
AND s.dna_status_pass = true
GROUP BY vp.project_id, vp.design_id, vp.design_gene_id, vp.design_gene_symbol, s.final_pick_cassette_resistance, s.final_pick_cassette_promoter
ORDER BY vp.design_gene_symbol, vp.project_id, vp.design_id, s.final_pick_cassette_resistance, s.final_pick_cassette_promoter
SQL_END

    return $sql_query;
}

# DNA with resistance
sub sql_select_dt_dna_with_resistance {
    my ( $self, $sponsor_id, $resistance_type ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promotor, s.final_pick_plate_name AS parent_plate_name, s.final_pick_well_name AS parent_well_name, s.dna_plate_name AS plate_name, s.dna_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
FROM summaries s
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
AND s.dna_status_pass = true
AND s.final_pick_cassette_resistance = '$resistance_type'
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter, s.final_pick_plate_name, s.final_pick_well_name, s.dna_plate_name, s.dna_well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_END

    return $sql_query;
}

# First electroporations
sub sql_select_dt_first_eps {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name AS plate_name, s.ep_well_name AS well_name, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promotor, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
FROM summaries s
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
AND s.ep_well_id > 0
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name, s.final_pick_cassette_name, s.final_pick_cassette_promoter, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_END

    return $sql_query;
}

# First electroporations with resistance
sub sql_select_dt_first_eps_with_resistance {
    my ( $self, $sponsor_id, $resistance_type ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
 SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name AS plate_name, s.ep_well_name AS well_name, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promotor, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
FROM summaries s
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
AND s.ep_well_id > 0
AND s.final_pick_cassette_resistance = '$resistance_type'
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name, s.final_pick_cassette_name, s.final_pick_cassette_promoter, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_END

    return $sql_query;
}

# Accepted first clones
sub sql_select_dt_first_accepted_clones {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promotor, s.ep_pick_plate_name AS plate_name, s.ep_pick_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
FROM summaries s
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
AND s.ep_pick_well_accepted = true
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter, s.ep_pick_plate_name, s.ep_pick_well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
SQL_END

    return $sql_query;
}

# Second electroportions
sub sql_select_dt_second_eps {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_plate_name AS plate_name, s.sep_well_name AS well_name, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promotor, s.final_pick_cassette_resistance AS cassette_resistance, s.ep_well_id, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
FROM summaries s
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
AND s.sep_well_id > 0
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_plate_name, s.sep_well_name, s.final_pick_cassette_name, s.final_pick_cassette_promoter, s.final_pick_cassette_resistance, s.ep_well_id, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.sep_plate_name, s.sep_well_name, s.ep_well_id
SQL_END

    return $sql_query;
}

# Second electroporations with resistance
sub sql_select_dt_second_eps_with_resistance {
    my ( $self, $sponsor_id, $resistance_type ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_plate_name AS plate_name, s.sep_well_name AS well_name, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promotor, s.final_pick_cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
FROM summaries s
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
AND s.sep_well_id > 0
AND s.ep_well_id IS NULL AND s.final_pick_cassette_resistance = '$resistance_type'
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_plate_name, s.sep_well_name, s.final_pick_cassette_name, s.final_pick_cassette_promoter, s.final_pick_cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.sep_plate_name, s.sep_well_name
SQL_END

    return $sql_query;
}

# Accepted second clones
sub sql_select_dt_second_accepted_clones {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

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
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promotor, s.sep_pick_plate_name AS plate_name, s.sep_pick_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
FROM summaries s
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
AND s.sep_pick_well_accepted = true
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter, s.sep_pick_plate_name, s.sep_pick_well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.sep_pick_plate_name, s.sep_pick_well_name
SQL_END

    return $sql_query;
}


1;