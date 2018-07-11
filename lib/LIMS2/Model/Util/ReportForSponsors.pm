package LIMS2::Model::Util::ReportForSponsors;

use Moose;
use Hash::MoreUtils qw( slice_def );
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use LIMS2::Model::Util qw( sanitize_like_expr );
use LIMS2::Model::Util::CrisprESQCView qw(crispr_damage_type_for_ep_pick ep_pick_is_het);
use LIMS2::Model::Util::DesignTargets qw( design_target_report_for_genes );
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD );
use LIMS2::Model::Util::GenesForSponsor;

use List::Util qw(sum);
use List::MoreUtils qw( uniq );
use Log::Log4perl qw( :easy );
use namespace::autoclean;
use DateTime;
use Readonly;
use Try::Tiny;                              # Exception handling
use JSON qw( encode_json );
use Data::Dumper;

# Uncomment this to add time since last log entry to log output
#Log::Log4perl->easy_init( { level => 'DEBUG', layout => '%d [%P] %p %m (%R)%n' } );

extends qw( LIMS2::ReportGenerator );

# Rows on report view
# These crispr counts now work but sub reports do not
# 'Crispr Vectors Single',
# 'Crispr Vectors Paired',
# 'Crispr Electroporations',
Readonly my @ST_REPORT_CATEGORIES => (
    'Genes',
    'Active Genes',
    # 'Valid DNA',
    'Genes Electroporated',
    'Targeted Genes',
);

Readonly my @DT_REPORT_CATEGORIES => (
    'Genes',
    'Active Genes',
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

has sponsor_genes_instance => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Util::GenesForSponsor',
    lazy_build => 1
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

    my @sponsor_ids;

    foreach my $sponsor ( @$sponsor_ids_rs ) {
        my $sponsor_id = $sponsor->{ sponsor_id };
        DEBUG "Sponsor id found = ".$sponsor_id;

        $sponsor_id eq 'All' ? unshift( @sponsor_ids, $sponsor_id ) : push( @sponsor_ids, $sponsor_id );
    }

    return \@sponsor_ids;
}

has sponsor_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);


sub _build_sponsor_genes_instance {
    my $self = shift;

    my $sponsor_genes_instance = LIMS2::Model::Util::GenesForSponsor->new({
            model => $self->model,
            targeting_type => $self->targeting_type,
            species_id => $self->species
        });
    return $sponsor_genes_instance;
}

sub _build_sponsor_data {
    my $self = shift;
    my %sponsor_data;
    my @sponsor_ids = @{ $self->sponsors };

    foreach my $sponsor_id ( @sponsor_ids ) {
        DEBUG "Building data for sponsor id = ".$sponsor_id;
        $self->_build_sponsor_column_data( $sponsor_id, \%sponsor_data );
    }

    return \%sponsor_data;
}

sub _build_sponsor_column_data {
    my ( $self, $sponsor_id, $sponsor_data ) = @_;

    DEBUG 'Building column data for sponsor id = '.$sponsor_id.', targeting type = '.$self->targeting_type.' and species = '.$self->species;

    my $sponsor_gene_counts = $self->sponsor_genes_instance->get_sponsor_genes($sponsor_id);

    my $number_genes = scalar @{$sponsor_gene_counts->{genes}};

    DEBUG "number genes = ".$number_genes;

    if ( $number_genes > 0 ) {
        $self->_build_column_data( $sponsor_id, $sponsor_data, $number_genes );
    }

    return;
}

## no critic(ProhibitExcessComplexity)
sub _build_column_data {

    my ( $self, $sponsor_id, $sponsor_data, $number_genes ) = @_;

    DEBUG 'Fetching column data: sponsor = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', number genes = '.$number_genes;

    # --------- Genes -----------
    my $count_tgs = $number_genes;
    $sponsor_data->{'Genes'}{$sponsor_id} = $count_tgs;

=head
    # FIXME: This is not fully implemented yet
    # ------------ Crispr Vectors and Electroporations --------
    my $count_crispr_vectors_single = 0;
    if( $count_tgs > 0 ){
        $count_crispr_vectors_single = $self->crispr_vectors_single($sponsor_id, 'count');
    }
    $sponsor_data->{'Crispr Vectors Single'}{$sponsor_id} = $count_crispr_vectors_single;

    my $count_crispr_vectors_paired = 0;
    if( $count_tgs > 0 ){
        $count_crispr_vectors_paired = $self->crispr_vectors_paired($sponsor_id, 'count');
    }
    $sponsor_data->{'Crispr Vectors Paired'}{$sponsor_id} = $count_crispr_vectors_paired;

    my $count_crispr_eps = 0;
    if( $count_crispr_vectors_single or $count_crispr_vectors_paired){
        $count_crispr_eps = $self->crispr_electroporations($sponsor_id, 'count');
    }
    $sponsor_data->{'Crispr Electroporations'}{$sponsor_id} = $count_crispr_eps;
=cut

    # ------------ Vectors ---------------
    # only look if targeted genes found
    my $count_vectors = 0;
    if ( $count_tgs > 0 ) {
      $count_vectors = $self->vectors( $sponsor_id, 'count' );
    }
    $sponsor_data->{'Active Genes'}{$sponsor_id} = $count_vectors;

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
        # DNA is not being passed always, so we need to count eps anyways.
        # if ( $count_dna > 0 ) {
            $count_eps = $self->electroporations( $sponsor_id, 'count' );
        # }
        $sponsor_data->{'Genes Electroporated'}{$sponsor_id} = $count_eps;

        # only look if electroporations found
        my $count_clones = 0;
        if ( $count_eps > 0 ) {
            $count_clones = $self->accepted_clones_st( $sponsor_id, 'count' );
        }
        $sponsor_data->{'Targeted Genes'}{$sponsor_id} = $count_clones;

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
## use critic

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
    my ( $self, $uri ) = @_;

    DEBUG 'Generating report for '.$self->targeting_type.' projects for species '.$self->species;

    # build information for report
    my $columns   = $self->build_columns;
    my $data      = $self->sponsor_data;
    my $title     = $self->build_page_title;
    my $title_ii  = $self->build_page_title('II');

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
        'title_ii'       => $title_ii,
        'columns'        => $columns,
        'rows'           => $rows,
        'data'           => $data,
    );

    my $json_data = encode_json(\%return_params);
    $self->save_json_report($uri, $json_data, $self->species);

    return \%return_params;
}

sub build_page_title {
    my $self = shift;
    my $strategy = shift || 'I';

    # TODO: This date should relate to a timestamp indicating when summaries data was
    # last generated rather than just system date.
    my $dt = localtime time;

    return 'Pipeline ' . $strategy . ' Summary Report ('.$self->species.', '.$self->targeting_type.' projects) on ' . $dt;
};

# columns relate to project sponsors
sub build_columns {
    my $self = shift;

    my $sponsor_columns;
    push @{$sponsor_columns->{pipeline_ii}}, 'Stage';
    push @{$sponsor_columns->{pipeline_i}}, 'Stage';

    my @pipeline_ii_sponsors = @{$self->sponsor_genes_instance->pipeline_ii_sponsors};

    foreach my $sponsor (@{$self->sponsors}) {
        if (grep {$_ eq $sponsor} @pipeline_ii_sponsors) {
            push @{$sponsor_columns->{pipeline_ii}}, $sponsor;
        } else {
            push @{$sponsor_columns->{pipeline_i}}, $sponsor;
        }
    }

    return $sponsor_columns;
};

sub save_json_report {
    my $self = shift;
    my $uri = shift;
    my $json_data = shift;
    my $name = shift;

    my $cache_server;

    for ($uri) {
        if    (/^http:\/\/www.sanger.ac.uk\/htgt\/lims2\/$/) { $cache_server = 'production/'; }
        elsif (/http:\/\/www.sanger.ac.uk\/htgt\/lims2\/+staging\//) { $cache_server = 'staging/'; }
        elsif (/http:\/\/t87-dev.internal.sanger.ac.uk:(\d+)\//) { $cache_server = "$1/"; }
        else  { die 'Error finding path for cached sponsor report'; }
    }

    my $cached_file_name = '/opt/t87/local/report_cache/lims2_cache_fp_report/' . $cache_server . $name . '.json';

    open( my $json_fh, ">:encoding(UTF-8)", $cached_file_name ) or die "Can not open file: $!";
    print $json_fh $json_data;
    close ($json_fh);

    return;
}

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
        'Genes'                     => {
            'display_stage'         => 'Genes',
            'columns'               => [    'gene_id',
                                            'gene_symbol',
                                            'chromosome',
                                            'sponsors',
                                            # 'crispr_pairs',
                                            'crispr_wells',
                                            # 'crispr_vector_wells',
                                            # 'crispr_dna_wells',
                                            # 'accepted_crispr_dna_wells',
                                            'accepted_crispr_vector',
                                            # 'vector_designs',
                                            'vector_wells',
                                            'vector_pcr_passes',
                                            # 'targeting_vector_wells',
                                            # 'accepted_vector_wells',
                                            'passing_vector_wells',
                                            'electroporations',
                                            # 'colonies_picked',
                                            # 'targeted_clones',
                                            # 'recovery_class',
                                            # 'effort_concluded',

                                            'DNA_source_cell_line',
                                            'EP_cell_line',
                                            'experiment_ID',
                                            'requester',

                                            # 'total_colonies',

                                            'colonies_picked',
                                            'targeted_clones',

                                            'fs_count',
                                            'if_count',
                                            'wt_count',
                                            'ms_count',
                                            'nc_count',
                                            'ep_pick_het',

                                            'distrib_clones',

                                            'priority',
                                            'recovery_class',

                                            'ep_data',
                                        ],
            'display_columns'       => [    'gene id',
                                            'gene symbol',
                                            'chr',
                                            'sponsor(s)',
                                            # 'crispr pairs',
                                            'ordered crispr primers',
                                            # 'crispr vectors',
                                            # 'DNA crispr vectors',
                                            # 'DNA QC-passing crispr vectors',
                                            'crispr plasmids constructed',
                                            # 'vector designs',
                                            'ordered vector primers',
                                            'PCR-passing design oligos',
                                            # 'final vector clones',
                                            # 'QC-verified vectors',
                                            'donor vectors constructed',
                                            'electroporation of iPSCs',
                                            # 'iPSCs colonies picked',
                                            # 'homozygous targeted clones',
                                            # 'recovery_class',
                                            # 'effort concluded',

                                            'DNA source vector',
                                            'EP cell line',
                                            'experiment ID',
                                            'requester',

                                            # '# colonies',
                                            'iPSC colonies picked',
                                            'total genotyped clones',

                                            # '# colonies screened',

                                            '# frame-shift clones',
                                            '# in-frame clones',
                                            '# wt clones',
                                            '# mosaic clones',
                                            '# no-call clones',
                                            'het clones',

                                            'distributable clones',

                                            'priority',
                                            'info',
                                        ],
        },
        'Active Genes'       => {
            'display_stage'         => 'Active Genes',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well' ],
        },
        'Valid DNA'                 => {
            'display_stage'         => 'Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'parent_plate_name', 'parent_well_name', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'parent plate', 'parent well', 'plate', 'well', 'final QC seq', 'final pick QC seq' ],
        },
        'Genes Electroporated'      => {
            'display_stage'         => 'Genes Electroporated',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Targeted Genes'            => {
            'display_stage'         => 'Targeted Genes',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
    };

    if ($sponsor_id eq 'Cre Knockin' || $sponsor_id eq 'EUCOMMTools Recovery' || $sponsor_id eq 'MGP Recovery') {
        $st_rpt_flds->{'Genes'}->{'columns'} = ['gene_id',
                                            'gene_symbol',
                                            'sponsors',
                                            # 'crispr_pairs',
                                            'crispr_wells',
                                            # 'crispr_vector_wells',
                                            # 'crispr_dna_wells',
                                            # 'accepted_crispr_dna_wells',
                                            'accepted_crispr_vector',
                                            # 'vector_designs',
                                            'vector_wells',
                                            'vector_pcr_passes',
                                            # 'targeting_vector_wells',
                                            # 'accepted_vector_wells',
                                            'passing_vector_wells',
                                            'electroporations',
                                            'colonies_picked',
                                            'targeted_clones',
                                            'recovery_class',
                                            'priority',
                                            'effort_concluded',
                                        ];

        $st_rpt_flds->{'Genes'}->{'display_columns'} = [ 'gene id',
                                            'gene symbol',
                                            'sponsors',
                                            # 'crispr pairs',
                                            'ordered crisprs',
                                            # 'crispr vectors',
                                            # 'DNA crispr vectors',
                                            # 'DNA QC-passing crispr vectors',
                                            'crisprs constructed',
                                            # 'vector designs',
                                            'ordered targeting vectors',
                                            "PCR-passing design oligos",
                                            # 'final vector clones',
                                            # 'QC-verified vectors',
                                            'active genes',
                                            'electroporations',
                                            'colonies picked',
                                            'targeted clones',
                                            'recovery_class',
                                            'priority',
                                            'effort concluded',
                                        ];
    }

    # for double-targeted projects
    my $dt_rpt_flds = {
        'Genes'                     => {
            'display_stage'         => 'Genes',
            'columns'               => [    'gene_id',
                                            'gene_symbol',
                                            # 'crispr_pairs',
                                            # 'vector_designs',
                                            'vector_wells',
                                            # 'targeting_vector_wells',
                                            # 'accepted_vector_wells',
                                            'passing_vector_wells',
                                            'electroporations',
                                            'colonies_picked',
                                            'targeted_clones',
                                            'recovery_class',
                                            'priority',
                                            'effort_concluded',
                                        ],
            'display_columns'       => [    'gene id',
                                            'gene symbol',
                                            # 'crispr pairs',
                                            # 'vector designs',
                                            'design oligos',
                                            # 'final vector clones',
                                            # 'QC-verified vectors',
                                            'DNA QC-passing vectors',
                                            'electroporations',
                                            'colonies picked',
                                            'targeted clones',
                                            'recovery_class',
                                            'priority',
                                            'effort concluded',
                                        ],
        },
        'Active Genes'       => {
            'display_stage'         => 'Active Genes',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well' ],
        },
        'Vectors Neo and Bsd'       => {
            'display_stage'         => 'Vector pairs Neo and Bsd',
            'columns'               => [ 'project_id','design_id', 'design_gene_id', 'design_gene_symbol', 'cassettes_available' ],
            'display_columns'       => [ 'project id', 'design id', 'gene id', 'gene', 'cassette types found' ],
        },
        'Vectors Neo'               => {
            'display_stage'         => 'Neomycin-resistant Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well' ],
        },
        'Vectors Bsd'               => {
            'display_stage'         => 'Blasticidin-resistant Vectors',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well' ],
        },
        'Valid DNA'                 => {
            'display_stage'         => 'Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'parent_plate_name', 'parent_well_name', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'parent plate', 'parent well', 'plate', 'well', 'final QC seq', 'final pick QC seq' ],
        },
        'Valid DNA Neo and Bsd'     => {
            'display_stage'         => 'Valid DNA pairs Neo and Bsd',
            'columns'               => [ 'project_id','design_id', 'design_gene_id', 'design_gene_symbol', 'cassettes_available' ],
            'display_columns'       => [ 'project id', 'design id', 'gene id', 'gene', 'cassette types found' ],
        },
        'Valid DNA Neo'             => {
            'display_stage'         => 'Neomycin-resistant Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'parent_plate_name', 'parent_well_name', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'parent plate', 'parent well', 'plate', 'well', 'final QC seq', 'final pick QC seq' ],
        },
        'Valid DNA Bsd'             => {
            'display_stage'         => 'Blasticidin-resistant Valid DNA',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'parent_plate_name', 'parent_well_name', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'parent plate', 'parent well', 'plate', 'well', 'final QC seq', 'final pick QC seq' ],
        },
        'First Electroporations'    => {
            'display_stage'         => 'First Electroporations',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'First Electroporations Neo' => {
            'display_stage'         => 'First Electroporations Neo',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'First Electroporations Bsd' => {
            'display_stage'         => 'First Electroporations Bsd',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Accepted First ES Clones'  => {
            'display_stage'         => 'Accepted First ES Clones',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Second Electroporations'   => {
            'display_stage'         => 'Second Electroporations',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'order', 'plate_name', 'well_name',  'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'electroporation order', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Second Electroporations Neo'   => {
            'display_stage'         => 'Second Electroporations Neo',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Second Electroporations Bsd'   => {
            'display_stage'         => 'Second Electroporations Bsd',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
        },
        'Accepted Second ES Clones' => {
            'display_stage'         => 'Accepted Second ES Clones',
            'columns'               => [ 'design_gene_id', 'design_gene_symbol', 'cassette_name', 'cassette_promoter', 'cassette_resistance', 'plate_name', 'well_name', 'final_qc_seq_pass', 'final_pick_qc_seq_pass', 'dna_status_pass' ],
            'display_columns'       => [ 'gene id', 'gene', 'cassette', 'promoter', 'resistance', 'plate', 'well', 'final QC seq', 'final pick QC seq', 'DNA status' ],
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
         'Genes'                            => {
             'func'      => \&genes,
             'params'    => [ $self, $sponsor_id, $query_type ],
         },
        'Active Genes'               => {
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
        'Genes Electroporated'              => {
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
        'Targeted Genes'                    => {
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
        'Second Electroporations Neo'       => {
            'func'      => \&second_electroporations_with_resistance,
            'params'    => [ $self, $sponsor_id, 'neo', $query_type ],
        },
        'Second Electroporations Bsd'       => {
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

## no critic(ProhibitExcessComplexity)
sub genes {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG "Genes for: sponsor id = ".$sponsor_id." and targeting_type = ".$self->targeting_type.' and species = '.$self->species;

    # Cre Knockin and EUCOMMTools Recovery time out with the new damage counting method. old is being used until fix.
    if ($sponsor_id eq 'Cre Knockin' || $sponsor_id eq 'EUCOMMTools Recovery' || $sponsor_id eq 'Pathogens' || $sponsor_id eq 'Syboss' || $sponsor_id eq 'Core') {
        return genes_old( $self, $sponsor_id, $query_type );
    }

    # MGP Recovery needs a specific genes method. disabled now.
    if ($sponsor_id eq 'MGP Recovery') {
        return mgp_recovery_genes( $self, $sponsor_id, $query_type );
    }

    # fetch gene symbols and return modified results set for display
    my @genes_for_display;

    my $sponsor_gene_counts = $self->sponsor_genes_instance->get_sponsor_genes($sponsor_id);


    my @gene_list = @{$sponsor_gene_counts->{genes}};

    # Store list of designs to get crispr summary info for later
    my $designs_for_gene = {};
    my @all_design_ids;

    foreach my $gene_row ( @gene_list ) {
        my $gene_id = $gene_row;

        my $gene_info;

        # get the gene name, the good way. TODO for human genes
        try {
            $gene_info = $self->model->find_gene( {
                search_term => $gene_id,
                species     => $self->species,
            } );
        }
        catch {
            INFO 'Failed to fetch gene symbol for gene id : ' . $gene_id . ' and species : ' . $self->species;
        };

        # Now we grab this from the solr index
        my $gene_symbol = $gene_info->{'gene_symbol'};
        my $chromosome = $gene_info->{'chromosome'};

        my %search = ( design_gene_id => $gene_id );

        if ($self->species eq 'Human' || $sponsor_id eq 'Pathogen Group 2' || $sponsor_id eq 'Pathogen Group 3' ) {
            $search{'-or'} = [
                    { design_type => 'gibson' },
                    { design_type => 'gibson-deletion' },
                    { design_type => 'fusion-deletion' },
                ];
        }

        if ($sponsor_id eq 'Pathogen Group 1' || $sponsor_id eq 'EUCOMMTools Recovery' || $sponsor_id eq 'Barry Short Arm Recovery') {
            $search{'sponsor_id'} = $sponsor_id;
        }

        my $summary_rs = $self->model->schema->resultset("Summary")->search(
            { %search },
        );

        my @gene_projects = $self->model->schema->resultset('Project')->search({ gene_id => $gene_id, targeting_type => $self->targeting_type })->all;

        my @sponsors = uniq map { $_->sponsor_ids } @gene_projects;

        try {
            my $index = 0;
            $index++ until ( $index >= scalar @sponsors || $sponsors[$index] eq 'All' );
            splice(@sponsors, $index, 1);
        };

        my @sponsors_abbr = map { $self->model->schema->resultset('Sponsor')->find({ id => $_ })->abbr } @sponsors;
        my $sponsors_str = join  ( ';', @sponsors_abbr );

        my ($priority, $recovery_class, $effort_concluded);
        try {
            my @priority_array = map { $_->priority($sponsor_id) } @gene_projects;

            my $index = 0;
            $index++ until ( !defined $priority_array[$index] || $index >= scalar @priority_array );
            splice(@priority_array, $index, 1);

            $priority = shift @priority_array;

        };
        if (! $priority) {$priority = '-'}

        try {
            my @recovery_class_array = uniq map { $_->recovery_class->name } @gene_projects;
            $recovery_class = join ( '; ', @recovery_class_array );
        };
        if (! $recovery_class) {$recovery_class = '-'}

        try {
            my @effort_concluded_array = uniq map { $_->effort_concluded } @gene_projects;
            $effort_concluded = join ( '; ', @effort_concluded_array );
        };

        # design IDs list
        my @design_ids = map { $_->design_id } $summary_rs->all;
        @design_ids = uniq @design_ids;

        # if there are no designs, stop here
        if ( !scalar @design_ids ) {
            push @genes_for_display, {
                'gene_id'                => $gene_id,
                'gene_symbol'            => $gene_symbol,
                'chromosome'             => $chromosome,
                'sponsors'               => $sponsors_str ? $sponsors_str : '0',
                'recovery_class'         => $recovery_class ? $recovery_class : '0',
                'priority'               => $priority ? $priority : '0',
                'effort_concluded'       => $effort_concluded ? $effort_concluded : '0',
                'ep_data'                => [],
            };
            next;
        }


        foreach my $design_id (uniq @design_ids){
            $designs_for_gene->{$gene_id} ||= [];

            my $arrayref = $designs_for_gene->{$gene_id};
            push @$arrayref, $design_id;
            push @all_design_ids, $design_id;
        }

        # DESIGN wells
        my @design = $summary_rs->search(
            {   to_report => 't' },
            {
                columns => [ qw/design_plate_name design_well_name design_well_id/ ],
                distinct => 1
            }
        );
        my $design_count = scalar @design;

        my $pcr_passes;
        foreach my $well (@design) {

            my $well_id = $well->design_well_id;

            my ($l_pcr, $r_pcr) = ('', '');
            try{
                # my $well_id = $self->model->retrieve_well( { plate_name => $plate_name, well_name => $well_name } )->id;

                $l_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
                    well_id     => $well_id,
                    result_type_id => 'pcr_u',
                },{
                    select => [ 'result' ],
                })->result;

                $r_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
                    well_id     => $well_id,
                    result_type_id => 'pcr_d',
                },{
                    select => [ 'result' ],
                })->result;
            };
            # catch{
            #     DEBUG "No pcr status found for well " . $well_id;
            # };

            if ($l_pcr eq 'pass' && $r_pcr eq 'pass') {
                $pcr_passes++;
            }
        }

        # FINAL_PICK wells
        my @final_pick = $summary_rs->search(
            { final_pick_well_accepted => 't',
              to_report => 't' },
            {
                columns => [ qw/final_pick_plate_name final_pick_well_name final_pick_well_accepted/ ],
                distinct => 1
            }
        );
        my $final_pick_pass_count = scalar @final_pick;

        # my @final_pick_qc = $summary_rs->search(
        #     { final_pick_qc_seq_pass => 't',
        #       to_report => 't' },
        #     {
        #         columns => [ qw/final_pick_plate_name final_pick_well_name final_pick_qc_seq_pass/ ],
        #         distinct => 1
        #     }
        # );
        # my $final_pick_qc_pass_count = scalar @final_pick_qc;



        # # DNA wells
        # my @dna = $summary_rs->search(
        #     { dna_well_accepted => 't',
        #       to_report => 't' },
        #     {
        #         columns => [ qw/dna_plate_name dna_well_name/ ],
        #         distinct => 1
        #     }
        # );
        # my $dna_pass_count = scalar @dna;

        # EP wells
        my @ep = $summary_rs->search(
            {
                -or => [
                    { ep_well_id => { '!=', undef } },
                    { crispr_ep_well_id => { '!=', undef } },
                ],
                to_report => 't',
            },
            {
                columns => [ qw/experiments dna_template requester ep_plate_name ep_well_name crispr_ep_plate_name crispr_ep_well_name ep_well_id crispr_ep_well_id crispr_ep_well_cell_line/ ],
                distinct => 1
            }
        );
        my $ep_count = scalar @ep;

        my @ep_data;

        my $total_total_colonies = 0;
        my $total_ep_pick_count = 0;
        my $total_ep_pick_pass_count = 0;
        my $total_frameshift = 0;
        my $total_in_frame = 0;
        my $total_wild_type = 0;
        my $total_mosaic = 0;
        my $total_no_call = 0;
        my $total_distributable = 0;
        my $total_het;

        foreach my $curr_ep (@ep) {
            my %curr_ep_data;
            my $ep_id;
            if ($curr_ep->ep_well_id) {
                $ep_id = $curr_ep->ep_well_id;
            }
            else {
                $ep_id = $curr_ep->crispr_ep_well_id;
            }

            # dna_template is actually a foreign key so we need to use get_column
            # to get the value rather than the DNATemplate result object
            $curr_ep_data{'dna_template'} = $curr_ep->get_column('dna_template') // '-' ;
            $curr_ep_data{'requester'} = $curr_ep->get_column('requester') // '-' ;
            $curr_ep_data{'experiment'} = [ split ",", $curr_ep->experiments ];
            $curr_ep_data{'cell_line'} = $curr_ep->crispr_ep_well_cell_line;

            my $total_colonies = 0;
            # my $picked_colonies = 0;

            try {
                $total_colonies = $self->model->schema->resultset('WellColonyCount')->search({
                    well_id => $ep_id,
                    colony_count_type_id => 'total_colonies',
                } )->single->colony_count;

                # $picked_colonies = $self->model->schema->resultset('WellColonyCount')->search({
                #     well_id => $curr_ep->ep_well_id,
                #     colony_count_type_id => 'picked_colonies',
                # } )->single->colony_count;
            };

            $curr_ep_data{'total_colonies'} = $total_colonies;
            $total_total_colonies += $curr_ep_data{'total_colonies'};
            # $curr_ep_data{'picked_colonies'} = $picked_colonies;

            # EP_PICK wells
            my @ep_pick = $summary_rs->search(
                {
                    ep_pick_well_id => { '!=', undef },
                   -or => [
                        { ep_well_id => $ep_id },
                        { crispr_ep_well_id => $ep_id },
                    ],
                    to_report => 't',
                },{
                    columns => [ qw/ep_pick_plate_name ep_pick_well_name ep_pick_well_accepted ep_pick_well_id ep_pick_well_crispr_es_qc_well_call/ ],
                    distinct => 1
                }
            );

            $curr_ep_data{'ep_pick_count'} = scalar @ep_pick;
            $total_ep_pick_count += $curr_ep_data{'ep_pick_count'};
            # $curr_ep_data{'ep_pick_pass_count'} = 0;

            $curr_ep_data{'frameshift'} = 0;
            $curr_ep_data{'in-frame'} = 0;
            $curr_ep_data{'wild_type'} = 0;
            $curr_ep_data{'mosaic'} = 0;
            $curr_ep_data{'no-call'} = 0;

            $curr_ep_data{'distributable'} = 0;

            ## no critic(ProhibitDeepNests)

            foreach my $ep_pick (@ep_pick) {
                my $damage_call = $ep_pick->ep_pick_well_crispr_es_qc_well_call;

                if ($damage_call) {
                    $curr_ep_data{$damage_call}++;
                }
                else {
                    $damage_call = '';
                }

                my $is_het = ep_pick_is_het($self->model, $ep_pick->ep_pick_well_id, $chromosome, $damage_call);

                if ( defined $is_het) {
                    $curr_ep_data{'het'} += $is_het;
                }

            }
            ## use critic

            $curr_ep_data{'frameshift'} += $curr_ep_data{'splice_acceptor'} unless (!$curr_ep_data{'splice_acceptor'});
            $curr_ep_data{'ep_pick_pass_count'} = $curr_ep_data{'wild_type'} + $curr_ep_data{'in-frame'} + $curr_ep_data{'frameshift'} + $curr_ep_data{'mosaic'};
            $total_ep_pick_pass_count += $curr_ep_data{'ep_pick_pass_count'};

            $total_frameshift += $curr_ep_data{'frameshift'};
            $total_in_frame += $curr_ep_data{'in-frame'};
            $total_wild_type += $curr_ep_data{'wild_type'};
            $total_mosaic += $curr_ep_data{'mosaic'};
            $total_no_call += $curr_ep_data{'no-call'};

            if (defined $curr_ep_data{'het'} ) {
                $total_het += $curr_ep_data{'het'};
            } else {
                $curr_ep_data{'het'} = '-';
            }


            # PIQ wells
            my @piq = $summary_rs->search(
                {   piq_well_id => { '!=', undef },
                    piq_well_accepted=> 't',
                    -or => [
                        { ep_well_id => $ep_id },
                        { crispr_ep_well_id => $ep_id },
                    ],
                    to_report => 't' },
                {
                    select => [ qw/piq_well_id piq_plate_name piq_well_name piq_well_accepted/ ],
                    as => [ qw/piq_well_id piq_plate_name piq_well_name piq_well_accepted/ ],
                    distinct => 1
                }
            );

            push @piq, $summary_rs->search(
                {   ancestor_piq_well_id=> { '!=', undef },
                    ancestor_piq_well_accepted=> 't',
                    -or => [
                        { ep_well_id => $ep_id },
                        { crispr_ep_well_id => $ep_id },
                    ],
                    to_report => 't' },
                {
                    select => [ qw/ancestor_piq_well_id ancestor_piq_plate_name ancestor_piq_well_name ancestor_piq_well_accepted/ ],
                    as => [ qw/piq_well_id piq_plate_name piq_well_name piq_well_accepted/ ],
                    distinct => 1
                }
            );

            $curr_ep_data{'distributable'} = scalar @piq;

            $total_distributable += $curr_ep_data{'distributable'};


            if ($curr_ep_data{'ep_pick_pass_count'} == 0) {
                if ( $curr_ep_data{'frameshift'} == 0 ) { $curr_ep_data{'frameshift'} = '-' };
                if ( $curr_ep_data{'in-frame'} == 0 ) { $curr_ep_data{'in-frame'} = '-' };
                if ( $curr_ep_data{'wild_type'} == 0 ) { $curr_ep_data{'wild_type'} = '-' };
                if ( $curr_ep_data{'mosaic'} == 0 ) { $curr_ep_data{'mosaic'} = '-' };
                if ( $curr_ep_data{'no-call'} == 0 ) { $curr_ep_data{'no-call'} = '-' };
                if ( !defined $curr_ep_data{'het'} ) { $curr_ep_data{'het'} = '-' };
                if ( $curr_ep_data{'distributable'} == 0 ) { $curr_ep_data{'distributable'} = '-' };
            }

            push @ep_data, \%curr_ep_data;
        }

        if ( $total_ep_pick_pass_count == 0) {
            $total_ep_pick_pass_count = '';
            $total_frameshift = '';
            $total_in_frame = '';
            $total_wild_type = '';
            $total_mosaic = '';
            $total_no_call = '';
            $total_het = '';
            $total_distributable = '';
        }

        @ep_data =  sort {
                $b->{ 'distributable' }      <=> $a->{ 'distributable' }      ||
                $b->{ 'ep_pick_pass_count' } <=> $a->{ 'ep_pick_pass_count' } ||
                $b->{ 'ep_pick_count' }      <=> $a->{ 'ep_pick_count' }
        } @ep_data;

        my $toggle;
        if ($ep_count) {
            $toggle = 'y';
        }
        # push the data for the report
        push @genes_for_display, {
            'gene_id'                => $gene_id,
            'gene_symbol'            => $gene_symbol,
            'chromosome'             => $chromosome,
            'sponsors'               => $sponsors_str ? $sponsors_str : '0',

            # 'vector_wells'           => scalar @design_ids,

            'vector_wells'           => $design_count,
            'vector_pcr_passes'      => $pcr_passes,
            'passing_vector_wells'   => $final_pick_pass_count,
            # 'qc_passing_vector_wells' => $final_pick_qc_pass_count,
            'electroporations'       => $ep_count,

            'DNA_source_cell_line'   => $toggle,
            'EP_cell_line'           => $toggle,
            'experiment_ID'          => $toggle,
            'requester'              => $toggle,


            'colonies_picked'        => $total_ep_pick_count,
            'targeted_clones'        => $total_ep_pick_pass_count,
            'total_colonies'         => $total_total_colonies,
            'fs_count'               => $total_frameshift,
            'if_count'               => $total_in_frame,
            'wt_count'               => $total_wild_type,
            'ms_count'               => $total_mosaic,
            'nc_count'               => $total_no_call,
            'ep_pick_het'            => $total_het // '-',

            'distrib_clones'         => $total_distributable,

            'priority'               => $priority,
            'recovery_class'         => $recovery_class,
            'effort_concluded'       => $effort_concluded // '0',
            'ep_data'                => \@ep_data,

        };

    }

    # Only used in the single targeted report... for now
    if($self->targeting_type eq 'single_targeted'){
        # Get the crispr summary information for all designs found in previous gene loop
        # We do this after the main loop so we do not have to search for the designs for each gene again
        # DEBUG "Fetching crispr summary info for report";
        my $design_crispr_summary = $self->model->get_crispr_summaries_for_designs({ id_list => \@all_design_ids });
        # DEBUG "Adding crispr counts to gene data";
        foreach my $gene_data (@genes_for_display){
            add_crispr_well_counts_for_gene($gene_data, $designs_for_gene, $design_crispr_summary);
        }
        # DEBUG "crispr counts done";
    }




    my @sorted_genes_for_display =  sort {
          ( $b->{ 'distrib_clones' } || -1 )   <=> ( $a->{ 'distrib_clones' } || -1 )   ||
          ( $b->{ 'fs_count' } || -1 )         <=> ( $a->{ 'fs_count' } || -1 )         ||
          ( $b->{ 'ep_pick_het' } || -1 )      <=> ( $a->{ 'ep_pick_het' } || -1 )      ||
          ( $b->{ 'targeted_clones' } || -1 )  <=> ( $a->{ 'targeted_clones' } || -1 )  ||
            # $b->{ 'colonies_picked' }        <=> $a->{ 'colonies_picked' }            ||
          ( $b->{ 'electroporations' } || -1 ) <=> ( $a->{ 'electroporations' } || -1 ) ||
            # $b->{ 'qc_passing_vector_wells' } <=> $a->{ 'qc_passing_vector_wells' }   ||
          ( $b->{ 'passing_vector_wells' } || -1 ) <=> ( $a->{ 'passing_vector_wells' } || -1 )  ||
            # $b->{ 'vector_wells' }           <=> $a->{ 'vector_wells' }               ||
            # $b->{ 'vector_designs' }         <=> $a->{ 'vector_designs' }             ||
            $b->{ 'accepted_crispr_vector' }   <=> $a->{ 'accepted_crispr_vector' }     ||
            $b->{ 'crispr_wells' }             <=> $a->{ 'crispr_wells' }
            # $a->{ 'gene_symbol' }            cmp $b->{ 'gene_symbol' }
        } @genes_for_display;

    my @container;
    my @pipeline_ii_sponsors = @{$self->sponsor_genes_instance->pipeline_ii_sponsors};

    if ( grep {$_ eq $sponsor_id} @pipeline_ii_sponsors ) {
       foreach my $elem (@sorted_genes_for_display) {
           if ($elem->{accepted_crispr_vector} == 0) {
              push @container, $elem;
           }
       }
       return \@container;
    }

    return \@sorted_genes_for_display;
}
## use critic

sub add_crispr_well_counts_for_gene{
    my ($gene_data, $designs_for_gene, $design_crispr_summary) = @_;

    my $gene_id = $gene_data->{gene_id};
    my $crispr_count = 0;
    # my $crispr_vector_count = 0;
    # my $crispr_dna_count = 0;
    # my $crispr_dna_accepted_count = 0;
    # my $crispr_pair_accepted_count = 0;
    my $crispr_vector_accepted_count = 0;
    foreach my $design_id (@{ $designs_for_gene->{$gene_id} || []}){
        my $plated_crispr_summary = $design_crispr_summary->{$design_id}->{plated_crisprs};
        # my %has_accepted_dna;
        foreach my $crispr_id (keys %$plated_crispr_summary){
            my @crispr_well_ids = keys %{ $plated_crispr_summary->{$crispr_id} };
            $crispr_count += scalar( @crispr_well_ids );
            foreach my $crispr_well_id (@crispr_well_ids){

                # CRISPR_V well count
                my $vector_rs = $plated_crispr_summary->{$crispr_id}->{$crispr_well_id}->{CRISPR_V};
                # $crispr_vector_count += $vector_rs->count;
                my @accepted = grep { $_->is_accepted } $vector_rs->all;
                $crispr_vector_accepted_count += scalar(@accepted);

                # DNA well counts
                # my $dna_rs = $plated_crispr_summary->{$crispr_id}->{$crispr_well_id}->{DNA};
                # $crispr_dna_count += $dna_rs->count;
                # my @accepted = grep { $_->is_accepted } $dna_rs->all;
                # $crispr_dna_accepted_count += scalar(@accepted);

                # if(@accepted){
                #     $has_accepted_dna{$crispr_id} = 1;
                # }
            }
        }
        # Count pairs for this design which have accepted DNA for both left and right crisprs
        # my $crispr_pairs = $design_crispr_summary->{$design_id}->{plated_pairs} || {};
        # foreach my $pair_id (keys %$crispr_pairs){
        #     my $left_id = $crispr_pairs->{$pair_id}->{left_id};
        #     my $right_id = $crispr_pairs->{$pair_id}->{right_id};
        #     if ($has_accepted_dna{$left_id} and $has_accepted_dna{$right_id}){
        #         DEBUG "Crispr pair $pair_id accepted";
        #         $crispr_pair_accepted_count++;
        #     }
        # }
    }
    $gene_data->{crispr_wells} = $crispr_count;
    # $gene_data->{crispr_vector_wells} = $crispr_vector_count;
    # $gene_data->{crispr_dna_wells} = $crispr_dna_count;
    # $gene_data->{accepted_crispr_dna_wells} = $crispr_dna_accepted_count;
    # $gene_data->{accepted_crispr_pairs} = $crispr_pair_accepted_count;
    $gene_data->{accepted_crispr_vector} = $crispr_vector_accepted_count;

    return;
}

## no critic(ProhibitExcessComplexity)
sub genes_old {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG "Genes for: sponsor id = ".$sponsor_id." and targeting_type = ".$self->targeting_type.' and species = '.$self->species;

    my $sql_query = $self->create_sql_sel_targeted_genes( $sponsor_id, $self->targeting_type, $self->species );

    my $sql_results = $self->run_select_query( $sql_query );

    # fetch gene symbols and return modified results set for display
    my @genes_for_display;

    my @gene_list;
    foreach my $gene_row ( @$sql_results ) {
         unshift( @gene_list,  $gene_row->{ 'gene_id' });
    }

    # Store list of designs to get crispr summary info for later
    my $designs_for_gene = {};
    my @all_design_ids;


    foreach my $gene_row ( @$sql_results ) {
        my $gene_id = $gene_row->{ 'gene_id' };

        my $gene_info;
        # get the gene name, the good way. TODO for human genes
        try {
            $gene_info = $self->model->find_gene( {
                search_term => $gene_id,
                species     => $self->species,
                # show_all    => 1
            } );
        }
        catch {
            INFO 'Failed to fetch gene symbol for gene id : ' . $gene_id . ' and species : ' . $self->species;
        };

        # Now we grab this from the solr index
        my $gene_symbol = $gene_info->{'gene_symbol'};
        # my $design_count = $gene_info->{'design_count'} // '0';
        # my $crispr_pairs_count = $gene_info->{'crispr_pairs_count'} // '0';


        # get the plates
        my $sql =  <<"SQL_END";
SELECT design_id,
concat(design_plate_name, '_', design_well_name) AS DESIGN,
concat(int_plate_name, '_', int_well_name) AS INT,
concat(final_plate_name, '_', final_well_name, final_well_accepted) AS FINAL,
concat(dna_plate_name, '_', dna_well_name, dna_well_accepted) AS DNA,
concat(ep_plate_name, '_', ep_well_name) AS EP,
concat(crispr_ep_plate_name, '_', crispr_ep_well_name) AS CRISPR_EP,
concat(ep_pick_plate_name, '_', ep_pick_well_name, ep_pick_well_accepted) AS EP_PICK
FROM summaries where design_gene_id = '$gene_id'
SQL_END

        # project specific filtering
        ## no critic (ProhibitCascadingIfElse)
        my $targeting_profile;
        if ($self->species eq 'Human') {
            $sql .= " AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion');";
        }
        if ($sponsor_id eq 'Pathogen Group 2') {
            $sql .= " AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion');";
        }
        if ($sponsor_id eq 'Pathogen Group 3') {
            $sql .= " AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion');";
        }
        elsif ($sponsor_id eq 'Pathogen Group 1') {
            $sql .= " AND ( sponsor_id = 'Pathogen Group 1' );";
        }
        elsif ($sponsor_id eq 'EUCOMMTools Recovery') {
            $sql .= " AND ( sponsor_id = 'EUCOMMTools Recovery' );";
            $targeting_profile = 'ko_first';
        }
        elsif ($sponsor_id eq 'Barry Short Arm Recovery') {
            $sql .= " AND ( sponsor_id = 'Barry Short Arm Recovery' );";
            $targeting_profile = 'ko_first';
        }
        elsif ($sponsor_id eq 'MGP Recovery') {
            $sql .= " AND ( sponsor_id = 'MGP Recovery' );";
        }
        elsif ($sponsor_id eq 'Cre Knockin'){
            $targeting_profile = 'cre_knockin';
        }

        ## use critic

        # run the query
        my $results = $self->run_select_query( $sql );

        # get the plates into arrays
        my (@design, @int, @final_info, @dna_info, @ep, @ep_pick_info, @design_ids);
        foreach my $row (@$results) {
            push @design_ids, $row->{design_id};
            push (@int, $row->{int}) unless ($row->{int} eq '_');
            push (@design, $row->{design}) unless ($row->{design} eq '_');
            push (@final_info, $row->{final}) unless ($row->{final} eq '_');
            push (@dna_info, $row->{dna}) unless ($row->{dna} eq '_');
            push (@ep, $row->{ep}) unless ($row->{ep} eq '_');
            push (@ep, $row->{crispr_ep}) unless ($row->{crispr_ep} eq '_');
            push (@ep_pick_info, $row->{ep_pick}) unless ($row->{ep_pick} eq '_');
        }

        # DESIGN
        @design = uniq @design;

        my $pcr_passes;
        foreach my $well (@design) {

            my ($plate_name, $well_name ) = ('', '');
            if ( $well =~ m/^(.*?)_([a-z]\d\d)$/i ) {
                ($plate_name, $well_name ) = ($1, $2);
            }

            my ($l_pcr, $r_pcr) = ('', '');
            try{
                my $well_id = $self->model->retrieve_well( { plate_name => $plate_name, well_name => $well_name } )->id;

                $l_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
                    well_id     => $well_id,
                    result_type_id => 'pcr_u',
                },{
                    select => [ 'result' ],
                })->result;

                $r_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
                    well_id     => $well_id,
                    result_type_id => 'pcr_d',
                },{
                    select => [ 'result' ],
                })->result;
            };
            # catch{
            #     DEBUG "No pcr status found for well " . $well_name;
            # };

            if ($l_pcr eq 'pass' && $r_pcr eq 'pass') {
                $pcr_passes++;
            }
        }


        # Store design IDs to use in crispr summary query
        foreach my $design_id (uniq @design_ids){
            $designs_for_gene->{$gene_id} ||= [];

            my $arrayref = $designs_for_gene->{$gene_id};
            push @$arrayref, $design_id;
            push @all_design_ids, $design_id;
        }

        # FINAL / INT
        my ($final_count, $final_pass_count) = get_well_counts(\@final_info);

        my $sum = 0;
        @int = uniq @int;

        foreach my $well (@int) {
            $well =~ s/^(.*?)(_[a-z]\d\d)$/$1/i;

            my $plate_id = $self->model->retrieve_plate({
                name => $well,
            })->id;

            my $comment = '';

            try{
                $comment = $self->model->schema->resultset('PlateComment')->find({
                    plate_id     => $plate_id,
                    comment_text => { like => '% post-gateway wells planned for wells on plate ' . $well }
                },{
                    select => [ 'comment_text' ],
                })->comment_text;
            };
            # catch{
            #     DEBUG "No comment found for well " . $well;
            # };

            if ( $comment =~ m/(\d*) post-gateway wells planned for wells on plate / ) {
                $sum += $1;
            }
        }
        if ($sum) {
            $final_count = $sum;
        }

        # DNA
        my ($dna_count, $dna_pass_count) = get_well_counts(\@dna_info);

        # EP/CRISPR_EP
        @ep = uniq @ep;

        # EP_PICK
        my ($ep_pick_count, $ep_pick_pass_count) = get_well_counts(\@ep_pick_info);

        # push the data for the report
        my ($sponsors_str, $effort);
        my ($recovery_class, $priority, $effort_concluded);
        my $project_search = {
            gene_id => $gene_id,
            targeting_type => $self->targeting_type,
            species_id => $self->species,
        };
        if($targeting_profile){
            $project_search->{targeting_profile_id} = $targeting_profile;
        }
        $effort = $self->model->retrieve_project($project_search);

        $sponsors_str = join "; ", $effort->sponsor_ids;
        $recovery_class = $effort->recovery_class_name;
        $priority = $effort->priority;
        $effort_concluded = $effort->effort_concluded ? 'yes' : '';

        # push the data for the report
        push @genes_for_display, {
            'gene_id'                => $gene_id,
            'gene_symbol'            => $gene_symbol,
            'sponsors'               => $sponsors_str ? $sponsors_str : '0',
            # 'crispr_pairs'           => $crispr_pairs_count,
            # 'vector_designs'         => $design_count,
            'vector_wells'           => scalar @design,
            'vector_pcr_passes'      => $pcr_passes,
            # 'targeting_vector_wells' => $final_count,
            # 'accepted_vector_wells'  => $final_pass_count,
            'passing_vector_wells'   => $dna_pass_count,
            'electroporations'       => scalar @ep,
            'colonies_picked'        => $ep_pick_count,
            'targeted_clones'        => $ep_pick_pass_count,
            'recovery_class'         => $recovery_class ? $recovery_class : '0',
            'priority'               => $priority ? $priority : '0',
            'effort_concluded'       => $effort_concluded ? $effort_concluded : '0',
        };
    }

    # Only used in the single targeted report... for now
    if($self->targeting_type eq 'single_targeted'){
        # Get the crispr summary information for all designs found in previous gene loop
        # We do this after the main loop so we do not have to search for the designs for each gene again
        DEBUG "Fetching crispr summary info for report";
        my $design_crispr_summary = $self->model->get_crispr_summaries_for_designs({ id_list => \@all_design_ids });
        DEBUG "Adding crispr counts to gene data";
        foreach my $gene_data (@genes_for_display){
            add_crispr_well_counts_for_gene($gene_data, $designs_for_gene, $design_crispr_summary);
        }
        DEBUG "crispr counts done";
    }

    my @sorted_genes_for_display =  sort {
          ( $b->{ 'targeted_clones' } || -1 )      <=> ( $a->{ 'targeted_clones' } || -1 )       ||
          ( $b->{ 'colonies_picked' } || -1 )      <=> ( $a->{ 'colonies_picked' } || -1 )       ||
          ( $b->{ 'electroporations' } || -1 )     <=> ( $a->{ 'electroporations' } || -1 )      ||
          ( $b->{ 'passing_vector_wells' } || -1 ) <=> ( $a->{ 'passing_vector_wells' } || -1 )  ||
            # $b->{ 'accepted_vector_wells' } <=> $a->{ 'accepted_vector_wells' } ||
            $b->{ 'vector_wells' }          <=> $a->{ 'vector_wells' }          ||
            # $b->{ 'vector_designs' }        <=> $a->{ 'vector_designs' }        ||
            $b->{ 'accepted_crispr_vector' } <=> $a->{ 'accepted_crispr_vector' } ||
            $a->{ 'gene_symbol' }           cmp $b->{ 'gene_symbol' }
        } @genes_for_display;

    return \@sorted_genes_for_display;
}
## use critic

sub get_well_counts {
    my ($list) = @_;

    my (@well, @well_pass);
    foreach my $row ( @{$list} ) {
        if ( $row =~ m/(.*?)([^\d]*)$/ ) {
            my ($well_well, $well_well_pass) = ($1, $2);
            push (@well, $well_well);
            if ($well_well_pass eq 't') {
                push (@well_pass, $well_well);
            }
        }
    }
    @well = uniq @well;
    @well_pass = uniq @well_pass;

    return (scalar @well, scalar @well_pass);
}

sub mgp_recovery_genes {
    my ( $self, $sponsor_id, $query_type ) = @_;

    my $sql_query = $self->create_sql_sel_targeted_genes( $sponsor_id, $self->targeting_type, $self->species );

    my $sql_results = $self->run_select_query( $sql_query );

    # fetch gene symbols and return modified results set for display
    my @genes_for_display;

    my @gene_list;
    foreach my $gene_row ( @$sql_results ) {
         unshift( @gene_list,  $gene_row->{ 'gene_id' });
    }

    # Store list of designs to get crispr summary info for later
    my $designs_for_gene = {};
    my @all_design_ids;

    foreach my $gene_row ( @$sql_results ) {
        my $gene_id = $gene_row->{ 'gene_id' };

        my $gene_info;
        # get the gene name, the good way. TODO for human genes
        try {
            $gene_info = $self->model->find_gene( {
                search_term => $gene_id,
                species     => $self->species,
                # show_all    => 1
            } );
        }
        catch {
            INFO 'Failed to fetch gene symbol for gene id : ' . $gene_id . ' and species : ' . $self->species;
        };

        # Now we grab this from the solr index
        my $gene_symbol = $gene_info->{'gene_symbol'};

        # get crispr groups for this gene
        my @crispr_grp =  map { $_->id } $self->model->schema->resultset( 'CrisprGroup' )->search(
                    { 'gene_id' => $gene_id } );

        my @crispr_ids = ();

        # get the crisprs in the groups
        foreach my $crispr_group (@crispr_grp) {
            push @crispr_ids, map { $_->crispr_id }
                $self->model->schema->resultset( 'CrisprGroupCrispr' )->search( { 'crispr_group_id' => $crispr_group } );
        }

        # get crispr summaries for those crisprs
        my $summaries = $self->model->get_summaries_for_crisprs({ id_list => \@crispr_ids });

        # get the counts
        my $crispr_count = 0;
        my $crispr_vector_count = 0;

        foreach my $crispr_id (keys %$summaries){
            my @crispr_well_ids = keys %{ $summaries->{$crispr_id} };
            $crispr_count += scalar( @crispr_well_ids );
            foreach my $crispr_well_id (@crispr_well_ids){

                # CRISPR_V well count
                my $vector_rs = $summaries->{$crispr_id}->{$crispr_well_id}->{CRISPR_V};
                $crispr_vector_count += $vector_rs->count;
            }
        }

        # push the data for the report
        push @genes_for_display, {
            'gene_id'                => $gene_id,
            'gene_symbol'            => $gene_symbol,
            'crispr_wells'           => $crispr_count,
            'accepted_crispr_vector'  => $crispr_vector_count,
            'sponsors'               => '0',
            # 'crispr_pairs'           => $crispr_pairs_count,
            # 'vector_designs'         => $design_count,
            'vector_wells'           => '0',
            # 'vector_pcr_passes'      => $pcr_passes,
            # 'targeting_vector_wells' => $final_count,
            # 'accepted_vector_wells'  => $final_pass_count,
            'passing_vector_wells'   => '0',
            'electroporations'       => '0',
            'colonies_picked'        => '0',
            'targeted_clones'        => '0',
            'recovery_class'         => '0',
            # 'priority'               => '0',
            # 'effort_concluded'       => '0',
        };
    }

    my @sorted_genes_for_display =  sort {
            $b->{ 'targeted_clones' }       <=> $a->{ 'targeted_clones' }       ||
            $b->{ 'colonies_picked' }       <=> $a->{ 'colonies_picked' }       ||
            $b->{ 'electroporations' }      <=> $a->{ 'electroporations' }      ||
            $b->{ 'passing_vector_wells' }  <=> $a->{ 'passing_vector_wells' }  ||
            # $b->{ 'accepted_vector_wells' } <=> $a->{ 'accepted_vector_wells' } ||
            $b->{ 'vector_wells' }          <=> $a->{ 'vector_wells' }          ||
            # $b->{ 'vector_designs' }        <=> $a->{ 'vector_designs' }        ||
            $b->{ 'accepted_crispr_vector' } <=> $a->{ 'accepted_crispr_vector' } ||
            $b->{ 'crispr_wells' }          <=> $a->{ 'crispr_wells' }          ||
            $a->{ 'gene_symbol' }           cmp $b->{ 'gene_symbol' }
        } @genes_for_display;

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

sub crispr_vectors_single {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'Crispr Vectors Single: sponsor id = '.$sponsor_id.' , targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        if ( $self->targeting_type eq 'single_targeted' ) {
            $sql_query = $self->sql_count_st_crispr_vectors_single ( $sponsor_id );
        }
        elsif ( $self->targeting_type eq 'double_targeted' ) {
            die 'No sql query defined for double_targeted crispr vectors'
        }
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        if ( $self->targeting_type eq 'single_targeted' ) {
            $sql_query = $self->sql_select_st_crispr_vectors_single ( $sponsor_id );
        }
        elsif ( $self->targeting_type eq 'double_targeted' ) {
            die 'No sql query defined for double_targeted crispr vectors'
        }
        my $sql_results = $self->run_select_query( $sql_query );
        return $sql_results;
    }
}

sub crispr_vectors_paired {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'Crispr Vectors Paired: sponsor id = '.$sponsor_id.' , targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        if ( $self->targeting_type eq 'single_targeted' ) {
            $sql_query = $self->sql_count_st_crispr_vectors_paired ( $sponsor_id );
        }
        elsif ( $self->targeting_type eq 'double_targeted' ) {
            die 'No sql query defined for double_targeted crispr vectors'
        }
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        if ( $self->targeting_type eq 'single_targeted' ) {
            $sql_query = $self->sql_select_st_crispr_vectors_paired ( $sponsor_id );
        }
        elsif ( $self->targeting_type eq 'double_targeted' ) {
            die 'No sql query defined for double_targeted crispr vectors'
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
    # e.g. project id, design id, gene, resistance, promoter
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
        # multiple times if different cassettes have same resistance/promoter type
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
            DEBUG 'WARNING: No FINAL_PICK cassette resistance found for Neo and Bsd Vectors row for gene '.$row->{ 'design_gene_symbol' }.' id '.$row->{ 'design_gene_id' };
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
    # e.g. project id, design id, gene, resistance, promoter
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
        # multiple times if different cassettes have same resistance/promoter type
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

sub crispr_electroporations {
    my ( $self, $sponsor_id, $query_type ) = @_;

    DEBUG 'Crispr electroporations: sponsor id = '.$sponsor_id.', targeting_type = '.$self->targeting_type.', query type = '.$query_type.' and species = '.$self->species;

    if ( $query_type eq 'count' ) {
        my $count = 0;
        my $sql_query;
        $sql_query = $self->sql_count_crispr_eps ( $sponsor_id );
        $count = $self->run_count_query( $sql_query );
        return $count;
    }
    elsif ( $query_type eq 'select' ) {
        my $sql_query;
        $sql_query = $self->sql_select_crispr_electroporations ( $sponsor_id );
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
SELECT distinct(ps.sponsor_id)
FROM project_sponsors ps, projects pr
WHERE ps.project_id = pr.id
AND pr.species_id = '$species_id'
AND pr.targeting_type = '$targeting_type'
ORDER BY ps.sponsor_id
SQL_END

    return $sql_query;
}

# Set up SQL query to select targeting type and count genes for a sponsor id
sub create_sql_count_genes_for_a_sponsor {
    my ( $self, $sponsor_id, $targeting_type, $species_id ) = @_;

my $sql_query =  <<"SQL_END";
SELECT ps.sponsor_id, count(distinct(gene_id)) AS genes
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
AND p.targeting_type = '$targeting_type'
AND p.species_id = '$species_id'
GROUP BY ps.sponsor_id
SQL_END

    return $sql_query;
}

# SQL to select targeted genes for a specific sponsor and targeting type
sub create_sql_sel_targeted_genes {
    my ( $self, $sponsor_id, $targeting_type, $species_id ) = @_;

my $sql_query =  <<"SQL_END";
SELECT distinct(p.gene_id)
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
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

    my $sql_query;
    my $species_id = $self->species;

## no critic (ProhibitCascadingIfElse)
    my $condition = '';
    if ($self->species eq 'Human') {
       $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')"
    }
    if ($sponsor_id eq 'Pathogen Group 2') {
        $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')";
    }
    elsif ($sponsor_id eq 'Pathogen Group 1') {
        $condition = "AND ( s.sponsor_id = 'Pathogen Group 1' )";
    }
    elsif ($sponsor_id eq 'EUCOMMTools Recovery') {
        $condition = "AND ( s.sponsor_id = 'EUCOMMTools Recovery' )";
    }
    elsif ($sponsor_id eq 'Barry Short Arm Recovery') {
        $condition = "AND ( s.sponsor_id = 'Barry Short Arm Recovery' )";
    }
    elsif ($sponsor_id eq 'MGP Recovery') {
        $condition = " AND ( s.sponsor_id = 'MGP Recovery' )";
    }
## use critic

    if ($sponsor_id eq 'Cre Knockin') {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
AND s.final_pick_qc_seq_pass = true
SQL_END

    } else {


$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id, ps.sponsor_id, p.gene_id, p.targeting_type
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE s.final_pick_qc_seq_pass = true
$condition
SQL_END

    }

    return $sql_query;
}

# DNA
sub sql_count_st_dna {
    my ( $self, $sponsor_id ) = @_;

    my $sql_query;
    my $species_id = $self->species;

## no critic (ProhibitCascadingIfElse)
    my $condition = '';
    if ($self->species eq 'Human') {
       $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')"
    }
    if ($sponsor_id eq 'Pathogen Group 2') {
        $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')";
    }
    elsif ($sponsor_id eq 'Pathogen Group 1') {
        $condition = "AND ( s.sponsor_id = 'Pathogen Group 1' )";
    }
    elsif ($sponsor_id eq 'EUCOMMTools Recovery') {
        $condition = "AND ( s.sponsor_id = 'EUCOMMTools Recovery' )";
    }
    elsif ($sponsor_id eq 'Barry Short Arm Recovery') {
        $condition = "AND ( s.sponsor_id = 'Barry Short Arm Recovery' )";
    }
    elsif ($sponsor_id eq 'MGP Recovery') {
        $condition = " AND ( s.sponsor_id = 'MGP Recovery' )";
    }
## use critic

    if ($sponsor_id eq 'Cre Knockin') {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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

    } else {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id, ps.sponsor_id, p.gene_id, p.targeting_type
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE s.dna_well_accepted = true
$condition
SQL_END

    }

    return $sql_query;
}

# First electroporations
sub sql_count_st_eps {
    my ( $self, $sponsor_id ) = @_;

    my $sql_query;
    my $species_id = $self->species;

## no critic (ProhibitCascadingIfElse)
    my $condition = '';
    if ($self->species eq 'Human') {
       $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')"
    }
    if ($sponsor_id eq 'Pathogen Group 2') {
        $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')";
    }
    elsif ($sponsor_id eq 'Pathogen Group 1') {
        $condition = "AND ( s.sponsor_id = 'Pathogen Group 1' )";
    }
    elsif ($sponsor_id eq 'EUCOMMTools Recovery') {
        $condition = "AND ( s.sponsor_id = 'EUCOMMTools Recovery' )";
    }
    elsif ($sponsor_id eq 'Barry Short Arm Recovery') {
        $condition = "AND ( s.sponsor_id = 'Barry Short Arm Recovery' )";
    }
    elsif ($sponsor_id eq 'MGP Recovery') {
        $condition = " AND ( s.sponsor_id = 'MGP Recovery' )";
    }
## use critic

    if ($sponsor_id eq 'Cre Knockin') {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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

    } else {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id, ps.sponsor_id, p.gene_id, p.targeting_type
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE (s.ep_well_id > 0 OR s.crispr_ep_well_id > 0)
$condition
SQL_END

    }

    return $sql_query;
}

# Accepted clones
sub sql_count_st_accepted_clones {
    my ( $self, $sponsor_id ) = @_;

    my $sql_query;
    my $species_id = $self->species;

## no critic (ProhibitCascadingIfElse)
    my $condition = '';
    if ($self->species eq 'Human') {
       $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')"
    }
    if ($sponsor_id eq 'Pathogen Group 2') {
        $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')";
    }
    elsif ($sponsor_id eq 'Pathogen Group 1') {
        $condition = "AND ( s.sponsor_id = 'Pathogen Group 1' )";
    }
    elsif ($sponsor_id eq 'EUCOMMTools Recovery') {
        $condition = "AND ( s.sponsor_id = 'EUCOMMTools Recovery' )";
    }
    elsif ($sponsor_id eq 'Barry Short Arm Recovery') {
        $condition = "AND ( s.sponsor_id = 'Barry Short Arm Recovery' )";
    }
    elsif ($sponsor_id eq 'MGP Recovery') {
        $condition = " AND ( s.sponsor_id = 'MGP Recovery' )";
    }
## use critic

    if ($sponsor_id eq 'Cre Knockin') {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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

    } else {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id, ps.sponsor_id, p.gene_id, p.targeting_type
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT count(distinct(s.design_gene_id))
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
INNER JOIN crispr_es_qc_wells cw ON cw.well_id = s.ep_pick_well_id
INNER JOIN crispr_es_qc_runs cr ON cw.crispr_es_qc_run_id = cr.id
WHERE s.ep_pick_well_accepted = true
AND cw.crispr_damage_type_id = 'frameshift'
AND cw.accepted = true
AND cr.validated = true
$condition
SQL_END

    }

    return $sql_query;
}

# ---------------------------------------
# SINGLE-TARGETED SELECTS
# ---------------------------------------
# Vectors
sub sql_select_st_vectors {
    my ( $self, $sponsor_id ) = @_;

    my $sql_query;
    my $species_id = $self->species;

## no critic (ProhibitCascadingIfElse)
    my $condition = '';
    if ($self->species eq 'Human') {
       $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')"
    }
    if ($sponsor_id eq 'Pathogen Group 2') {
        $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')";
    }
    elsif ($sponsor_id eq 'Pathogen Group 1') {
        $condition = "AND ( s.sponsor_id = 'Pathogen Group 1' )";
    }
    elsif ($sponsor_id eq 'EUCOMMTools Recovery') {
        $condition = "AND ( s.sponsor_id = 'EUCOMMTools Recovery' )";
    }
    elsif ($sponsor_id eq 'Barry Short Arm Recovery') {
        $condition = "AND ( s.sponsor_id = 'Barry Short Arm Recovery' )";
    }
    elsif ($sponsor_id eq 'MGP Recovery') {
        $condition = " AND ( s.sponsor_id = 'MGP Recovery' )";
    }
## use critic

    if ($sponsor_id eq 'Cre Knockin') {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.final_pick_plate_name AS plate_name, s.final_pick_well_name AS well_name
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
AND s.final_pick_qc_seq_pass = true
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.final_pick_plate_name, s.final_pick_well_name
ORDER BY s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_plate_name, s.final_pick_well_name
SQL_END

    } else {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id, ps.sponsor_id, p.gene_id, p.targeting_type
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.final_pick_plate_name AS plate_name, s.final_pick_well_name AS well_name
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE s.final_pick_qc_seq_pass = true
$condition
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.final_pick_plate_name, s.final_pick_well_name
ORDER BY s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_plate_name, s.final_pick_well_name

SQL_END

    }

    return $sql_query;
}

# DNA
sub sql_select_st_dna {
    my ( $self, $sponsor_id ) = @_;

    my $sql_query;
    my $species_id = $self->species;

## no critic (ProhibitCascadingIfElse)
    my $condition = '';
    if ($self->species eq 'Human') {
       $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')"
    }
    if ($sponsor_id eq 'Pathogen Group 2') {
        $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')";
    }
    elsif ($sponsor_id eq 'Pathogen Group 1') {
        $condition = "AND ( s.sponsor_id = 'Pathogen Group 1' )";
    }
    elsif ($sponsor_id eq 'EUCOMMTools Recovery') {
        $condition = "AND ( s.sponsor_id = 'EUCOMMTools Recovery' )";
    }
    elsif ($sponsor_id eq 'Barry Short Arm Recovery') {
        $condition = "AND ( s.sponsor_id = 'Barry Short Arm Recovery' )";
    }
    elsif ($sponsor_id eq 'MGP Recovery') {
        $condition = " AND ( s.sponsor_id = 'MGP Recovery' )";
    }
## use critic

    if ($sponsor_id eq 'Cre Knockin') {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.final_pick_plate_name AS parent_plate_name, s.final_pick_well_name AS parent_well_name, s.dna_plate_name AS plate_name
, s.dna_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.final_pick_plate_name, s.final_pick_well_name, s.dna_plate_name, s.dna_well_name
, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_END

    } else {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id, ps.sponsor_id, p.gene_id, p.targeting_type
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.final_pick_plate_name AS parent_plate_name, s.final_pick_well_name AS parent_well_name, s.dna_plate_name AS plate_name
, s.dna_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE s.dna_status_pass = true
$condition
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.final_pick_plate_name, s.final_pick_well_name, s.dna_plate_name, s.dna_well_name
, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
ORDER BY s.design_gene_symbol, s.dna_plate_name, s.dna_well_name
SQL_END

    }

    return $sql_query;
}

# Electroporations
sub sql_select_st_electroporations {
    my ( $self, $sponsor_id ) = @_;

    my $sql_query;
    my $species_id = $self->species;

## no critic (ProhibitCascadingIfElse)
    my $condition = '';
    if ($self->species eq 'Human') {
       $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')"
    }
    if ($sponsor_id eq 'Pathogen Group 2') {
        $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')";
    }
    elsif ($sponsor_id eq 'Pathogen Group 1') {
        $condition = "AND ( s.sponsor_id = 'Pathogen Group 1' )";
    }
    elsif ($sponsor_id eq 'EUCOMMTools Recovery') {
        $condition = "AND ( s.sponsor_id = 'EUCOMMTools Recovery' )";
    }
    elsif ($sponsor_id eq 'Barry Short Arm Recovery') {
        $condition = "AND ( s.sponsor_id = 'Barry Short Arm Recovery' )";
    }
    elsif ($sponsor_id eq 'MGP Recovery') {
        $condition = " AND ( s.sponsor_id = 'MGP Recovery' )";
    }
## use critic

    if ($sponsor_id eq 'Cre Knockin') {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name AS plate_name, s.ep_well_name AS well_name
, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promoter
, s.final_pick_cassette_resistance AS cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name, s.final_pick_cassette_name
, s.final_pick_cassette_promoter, s.final_pick_cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_END

    } else {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id, ps.sponsor_id, p.gene_id, p.targeting_type
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, concat(s.ep_plate_name, s.crispr_ep_plate_name) AS plate_name, concat(s.ep_well_name, s.crispr_ep_well_name)  AS well_name
, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promoter
, s.final_pick_cassette_resistance AS cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE (s.ep_well_id > 0 OR s.crispr_ep_well_id > 0)
$condition
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.crispr_ep_plate_name, s.ep_well_name, s.crispr_ep_well_name, s.final_pick_cassette_name
, s.final_pick_cassette_promoter, s.final_pick_cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.ep_plate_name, s.ep_well_name
SQL_END

    }

    return $sql_query;
}

# Clones
sub sql_select_st_accepted_clones {
    my ( $self, $sponsor_id ) = @_;

    my $sql_query;
    my $species_id = $self->species;

## no critic (ProhibitCascadingIfElse)
    my $condition = '';
    if ($self->species eq 'Human') {
       $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')"
    }
    if ($sponsor_id eq 'Pathogen Group 2') {
        $condition = "AND ( design_type = 'gibson' OR design_type = 'gibson-deletion' OR design_type = 'fusion-deletion')";
    }
    elsif ($sponsor_id eq 'Pathogen Group 1') {
        $condition = "AND ( s.sponsor_id = 'Pathogen Group 1' )";
    }
    elsif ($sponsor_id eq 'EUCOMMTools Recovery') {
        $condition = "AND ( s.sponsor_id = 'EUCOMMTools Recovery' )";
    }
    elsif ($sponsor_id eq 'Barry Short Arm Recovery') {
        $condition = "AND ( s.sponsor_id = 'Barry Short Arm Recovery' )";
    }
    elsif ($sponsor_id eq 'MGP Recovery') {
        $condition = " AND ( s.sponsor_id = 'MGP Recovery' )";
    }
## use critic

    if ($sponsor_id eq 'Cre Knockin') {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id AS project_id,
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.ep_pick_plate_name AS plate_name, s.ep_pick_well_name AS well_name, s.final_qc_seq_pass
, s.final_pick_qc_seq_pass, s.dna_status_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.ep_pick_plate_name, s.ep_pick_well_name, s.final_qc_seq_pass
, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
SQL_END

    } else {

$sql_query =  <<"SQL_END";
WITH project_requests AS (
SELECT p.id, ps.sponsor_id, p.gene_id, p.targeting_type
FROM projects p, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = p.id
AND p.targeting_type = 'single_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.ep_pick_plate_name AS plate_name, s.ep_pick_well_name AS well_name, s.final_qc_seq_pass
, s.final_pick_qc_seq_pass, s.dna_status_pass
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE s.ep_pick_well_accepted = true
$condition
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.ep_pick_plate_name, s.ep_pick_well_name, s.final_qc_seq_pass
, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.ep_pick_plate_name, s.ep_pick_well_name
SQL_END

    }

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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
AND s.final_pick_qc_seq_pass = true
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
AND s.final_pick_qc_seq_pass = true
AND s.final_pick_cassette_resistance = 'neo'
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
AND s.final_pick_qc_seq_pass = true
AND s.final_pick_cassette_resistance = 'bsd'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
AND s.final_pick_qc_seq_pass = true
AND s.final_pick_cassette_resistance = '$resistance_type'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.final_pick_plate_name AS plate_name, s.final_pick_well_name AS well_name
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
AND s.final_pick_qc_seq_pass = true
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.final_pick_plate_name, s.final_pick_well_name
ORDER BY s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_plate_name, s.final_pick_well_name
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
AND s.final_pick_qc_seq_pass = true
AND s.final_pick_cassette_resistance = 'neo' GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
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
AND s.final_pick_qc_seq_pass = true
AND s.final_pick_cassette_resistance = 'bsd' GROUP by pr.project_id, s.design_id, s.design_gene_id, s.design_gene_symbol
)
 , vector_pairings AS (
SELECT nv.project_id, nv.design_id, nv.design_gene_id, nv.design_gene_symbol
FROM neo_vectors nv
INNER JOIN bsd_vectors bv ON bv.project_id = nv.project_id
AND bv.design_id = nv.design_id
GROUP BY nv.project_id, nv.design_id, nv.design_gene_id, nv.design_gene_symbol
)
SELECT vp.project_id, vp.design_id, vp.design_gene_id, vp.design_gene_symbol, s.final_pick_cassette_resistance
, s.final_pick_cassette_promoter
FROM summaries s
INNER JOIN vector_pairings vp ON s.design_id = vp.design_id
WHERE s.design_species_id = '$species_id'
AND s.final_pick_qc_seq_pass = true
GROUP BY vp.project_id, vp.design_id, vp.design_gene_id, vp.design_gene_symbol, s.final_pick_cassette_resistance
, s.final_pick_cassette_promoter
ORDER BY vp.design_gene_symbol, vp.project_id, vp.design_id, s.final_pick_cassette_resistance, s.final_pick_cassette_promoter
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.final_pick_plate_name AS plate_name, s.final_pick_well_name AS well_name
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
AND s.final_pick_qc_seq_pass = true
AND s.final_pick_cassette_resistance = '$resistance_type'
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.final_pick_plate_name, s.final_pick_well_name
ORDER BY s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_plate_name, s.final_pick_well_name
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.final_pick_plate_name AS parent_plate_name, s.final_pick_well_name AS parent_well_name, s.dna_plate_name AS plate_name
, s.dna_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.final_pick_plate_name, s.final_pick_well_name, s.dna_plate_name, s.dna_well_name
, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
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
SELECT vp.project_id, vp.design_id, vp.design_gene_id, vp.design_gene_symbol, s.final_pick_cassette_resistance
, s.final_pick_cassette_promoter
FROM summaries s
INNER JOIN vector_pairings vp ON s.design_id = vp.design_id
WHERE s.design_species_id = '$species_id'
AND s.dna_status_pass = true
GROUP BY vp.project_id, vp.design_id, vp.design_gene_id, vp.design_gene_symbol, s.final_pick_cassette_resistance
, s.final_pick_cassette_promoter
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.final_pick_plate_name AS parent_plate_name, s.final_pick_well_name AS parent_well_name, s.dna_plate_name AS plate_name
, s.dna_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.final_pick_plate_name, s.final_pick_well_name, s.dna_plate_name, s.dna_well_name
, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name AS plate_name, s.ep_well_name AS well_name
, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promoter
, s.final_pick_cassette_resistance AS cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name, s.final_pick_cassette_name
, s.final_pick_cassette_promoter, s.final_pick_cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
 SELECT s.design_gene_id, s.design_gene_symbol, s.ep_plate_name AS plate_name, s.ep_well_name AS well_name
 , s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promoter
 , s.final_pick_cassette_resistance AS cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.ep_plate_name, s.ep_well_name, s.final_pick_cassette_name
, s.final_pick_cassette_promoter, s.final_pick_cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.ep_pick_plate_name AS plate_name, s.ep_pick_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.ep_pick_plate_name, s.ep_pick_well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
, s.dna_status_pass
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_plate_name AS plate_name, s.sep_well_name AS well_name
, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promoter
, s.final_pick_cassette_resistance AS cassette_resistance, s.ep_well_id, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_plate_name, s.sep_well_name, s.final_pick_cassette_name
, s.final_pick_cassette_promoter, s.final_pick_cassette_resistance, s.ep_well_id, s.final_qc_seq_pass, s.final_pick_qc_seq_pass
, s.dna_status_pass
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.sep_plate_name AS plate_name, s.sep_well_name AS well_name
, s.final_pick_cassette_name AS cassette_name, s.final_pick_cassette_promoter AS cassette_promoter
, s.final_pick_cassette_resistance AS cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.sep_plate_name, s.sep_well_name, s.final_pick_cassette_name
, s.final_pick_cassette_promoter, s.final_pick_cassette_resistance, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
 ps.sponsor_id,
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
INNER JOIN targeting_profile_alleles pa ON pa.targeting_profile_id = p.targeting_profile_id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
JOIN project_sponsors ps ON ps.project_id = p.id
WHERE ps.sponsor_id = '$sponsor_id'
AND p.targeting_type = 'double_targeted'
AND p.species_id = '$species_id'
)
SELECT s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name AS cassette_name
, s.final_pick_cassette_promoter AS cassette_promoter, s.final_pick_cassette_resistance AS cassette_resistance
, s.sep_pick_plate_name AS plate_name, s.sep_pick_well_name AS well_name, s.final_qc_seq_pass, s.final_pick_qc_seq_pass, s.dna_status_pass
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
GROUP by s.design_gene_id, s.design_gene_symbol, s.final_pick_cassette_name, s.final_pick_cassette_promoter
, s.final_pick_cassette_resistance, s.sep_pick_plate_name, s.sep_pick_well_name, s.final_qc_seq_pass
, s.final_pick_qc_seq_pass, s.dna_status_pass
ORDER BY s.design_gene_symbol, s.sep_pick_plate_name, s.sep_pick_well_name
SQL_END

    return $sql_query;
}

#----------- Crispr Vector SQL ------------
#
#  FIXME: these queries do not check well_accepted_override
#
#-------------------------------------------
sub sql_count_st_crispr_vectors_single {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

my $sql_query =  <<"SQL_END";
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    -- Non-recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id in (
select pro.well_id from project_sponsors ps, projects pr, gene_design gd, experiments cd, process_crispr prc, crispr_pairs cp, process_output_well pro
where ps.sponsor_id='$sponsor_id'
and ps.project_id = pr.id
and pr.species_id='$species_id'
and pr.gene_id=gd.gene_id
and cd.design_id=gd.design_id
and cd.crispr_id=prc.crispr_id
and cd.deleted=false
and pro.process_id=prc.process_id
)
    UNION ALL
-- Recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT count(distinct w.input_well_id)
FROM well_hierarchy w, wells, plates
where w.output_well_id=wells.id
and wells.plate_id=plates.id
and plates.type_id='CRISPR_V'
and wells.accepted='true'
SQL_END
return $sql_query;
}

sub sql_select_st_crispr_vectors_single {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

my $sql_query =  <<"SQL_END";
-- Descendants by well_id
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    -- Non-recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id in (
select pro.well_id from project_sponsors ps, projects pr, gene_design gd, experiments cd, process_crispr prc, crispr_pairs cp, process_output_well pro
where ps.sponsor_id='$sponsor_id'
and ps.project_id = pr.id
and pr.species_id='$species_id'
and pr.gene_id=gd.gene_id
and cd.design_id=gd.design_id
and cd.crispr_id=prc.crispr_id
and cd.deleted=false
and pro.process_id=prc.process_id
)
    UNION ALL
-- Recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT distinct w.input_well_id
FROM well_hierarchy w, wells, plates
where w.output_well_id=wells.id
and wells.plate_id=plates.id
and plates.type_id='CRISPR_V'
and wells.accepted='true'
SQL_END
return $sql_query;
}

sub sql_count_st_crispr_vectors_paired {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

my $sql_query =  <<"SQL_END";
-- Descendants by well_id
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    -- Non-recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id in (
select pro.well_id from project_sponsors ps, projects pr, gene_design gd, experiments cd, process_crispr prc, crispr_pairs cp, process_output_well pro
where ps.sponsor_id='$sponsor_id'
and ps.project_id = pr.id
and pr.species_id='$species_id'
and pr.gene_id=gd.gene_id
and cd.design_id=gd.design_id
and cd.crispr_pair_id=cp.id
and cd.deleted=false
and( cp.left_crispr_id=prc.crispr_id or cp.right_crispr_id=prc.crispr_id)
and pro.process_id=prc.process_id
)
    UNION ALL
-- Recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT count(distinct w.input_well_id)
FROM well_hierarchy w, wells, plates
where w.output_well_id=wells.id
and wells.plate_id=plates.id
and plates.type_id='CRISPR_V'
and wells.accepted='true'
SQL_END
return $sql_query;
}

sub sql_select_st_crispr_vectors_paired {
    my ( $self, $sponsor_id ) = @_;

    my $species_id      = $self->species;

my $sql_query =  <<"SQL_END";
-- Descendants by well_id
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    -- Non-recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id in (
select pro.well_id from project_sponsors ps, projects pr, gene_design gd, experiments cd, process_crispr prc, crispr_pairs cp, process_output_well pro
where ps.sponsor_id='$sponsor_id'
and ps.project_id = pr.id
and pr.species_id='$species_id'
and pr.gene_id=gd.gene_id
and cd.design_id=gd.design_id
and cd.crispr_pair_id=cp.id
and cd.deleted=false
and( cp.left_crispr_id=prc.crispr_id or cp.right_crispr_id=prc.crispr_id)
and pro.process_id=prc.process_id
)
    UNION ALL
-- Recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT distinct w.input_well_id
FROM well_hierarchy w, wells, plates
where w.output_well_id=wells.id
and wells.plate_id=plates.id
and plates.type_id='CRISPR_V'
and wells.accepted='true'
SQL_END
return $sql_query;
}

sub sql_count_crispr_eps{
    my ($self, $sponsor_id) = @_;
    my $species_id = $self->species;

my $sql_query = <<"SQL_END";
select count(distinct s.design_gene_id) from project_sponsors ps, projects pr, summaries s
where ps.sponsor_id='$sponsor_id'
and ps.project_id = pr.id
and pr.species_id='$species_id'
and pr.gene_id=s.design_gene_id
and s.crispr_ep_well_accepted='true'
SQL_END
return $sql_query
}

sub sql_select_crispr_eps{
    my ($self, $sponsor_id) = @_;
    my $species_id = $self->species;

my $sql_query = <<"SQL_END";
select s.design_gene_id, s.design_gene_symbol, s.crispr_ep_well_cell_line, s.crispr_ep_well_nuclease
from project_sponsors ps, projects pr, summaries s
where ps.sponsor_id='$sponsor_id'
and ps.project_id = p.id
and pr.species_id='$species_id'
and pr.gene_id=s.design_gene_id
and s.crispr_ep_well_accepted='true'
SQL_END
return $sql_query
}

1;
