package LIMS2::Model::Util::CreKiESDistribution;

use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::CreKiESDistribution

=head1 DESCRIPTION

Generate the data for a report showing the summary of ES Distribution
for the Cre Knockin projects

=cut

use Moose;
use Try::Tiny;
use List::MoreUtils qw( any part );
use namespace::autoclean;
use Log::Log4perl qw( :easy );
use Readonly;
# use Deep::Hash::Utils qw(reach slurp nest deepvalue);

use Data::Dumper;

with qw( MooseX::Log::Log4perl );

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has imits_config => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_build_imits_config',
);

has summaried_data => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has curr_gene_summary => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has summarised_data_by_basket_and_gene => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
);

has report_data => (
    is  => 'rw',
    isa => 'ArrayRef',
);

has cre_ki_genes => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    builder    => '_build_cre_ki_genes',
);

Readonly my @BASKET_NAMES => (
    'unrequested',
    'unpicked_no_clones',
    'unpicked_no_piqs',
    'picked_1_clone',
    'picked_2_clones',
    'picked_3_clones',
    'picked_4_clones',
    'picked_5_clones',
    'picked_gt5_clones',
    'qc_failed_no_mi_attempts',
    'qc_passed_no_mi_attempts',
    'in_progress_active_mi_attempts',
    'failed_in_mouse_production',
    'unrecognised_type missing_from_lims2',
);

=head2 build_cre_ki_genes

create hash of data from lims2 and imits

=cut
sub _build_cre_ki_genes {
    my ( $self ) = @_;
    my $cre_ki_genes = {};

    $self->_fetch_lims2_cre_knockin_projects( $cre_ki_genes );

	# now add the summaries table data for all the cre genes that have any LIMS2 data
	$self->_add_lims2_data( $cre_ki_genes );

	# now we have the lims2 data we need to total up various counts
	$self->_add_lims2_counts( $cre_ki_genes );

	# now link to iMits and add in the iMits data
	my $imits_cre_ki_genes = $self->_fetch_imits_cre_ki_data();

	# now fuse the two datasets, by merging the output from iMits onto the output from Lims2 by gene
	$self->_fuse_lims2_and_imits_data( $cre_ki_genes, $imits_cre_ki_genes );

    return $cre_ki_genes;
}

=head2 _build_imits_config

connection config details for running SQL queries against imits

=cut
sub _build_imits_config {
    my ( $self ) = @_;

    my $conf_parser = Config::Scoped->new(
        file     => $ENV{LIMS2_IMITS_CONN_CONFIG},
        warnings => { permissions => 'off' }
    );

    my $imits_config = $conf_parser->parse;

    return $imits_config;
}

=head2 generate_report_data

generate report data for overview summary report

=cut
sub generate_summary_report_data {
    my ( $self ) = @_;
    my @report_data;

    $self->_summarise_cre_ki_data();

    push @report_data, [
    	$self->summaried_data->{ 'count_genes_total' },
        $self->summaried_data->{ 'count_unrequested_total' },
        $self->summaried_data->{ 'count_unpicked_total' },
        $self->summaried_data->{ 'count_unpicked_no_piqs_total' },
        $self->summaried_data->{ 'count_unpicked_no_clones_total' },
        $self->summaried_data->{ 'count_picked_total' },
        $self->summaried_data->{ 'count_picked_1_clone_total' },
        $self->summaried_data->{ 'count_picked_2_clones_total' },
        $self->summaried_data->{ 'count_picked_3_clones_total' },
        $self->summaried_data->{ 'count_picked_4_clones_total' },
        $self->summaried_data->{ 'count_picked_5_clones_total' },
        $self->summaried_data->{ 'count_picked_gt5_clones_total' },
        $self->summaried_data->{ 'count_qc_passes_no_mis_total' },
        $self->summaried_data->{ 'count_qc_fails_all_piqd_clones' },
        $self->summaried_data->{ 'count_in_progress_active_mis_total' },
        $self->summaried_data->{ 'count_failed_mp_total' },
    ];

    $self->report_data( \@report_data );

    return;
}

=head2 generate_genes_report_data

generate report data for genes version of report

=cut
sub generate_genes_report_data {
    my ( $self ) = @_;
    my @report_data;

    $self->_summarise_cre_ki_data();

    foreach my $basket_name ( @BASKET_NAMES ) {
        my $curr_basket = \%{ $self->summarised_data_by_basket_and_gene->{ $basket_name } };

        unless (defined $curr_basket->{ 'count_genes' } ) { next; }
        my $curr_count_genes = $curr_basket->{ 'count_genes' };

        unless ( $curr_count_genes > 0 ) { next; }
        foreach my $gene_id ( sort keys %{ $curr_basket->{ 'genes' } } ) {
            my $curr_gene = $curr_basket->{ 'genes' }->{ $gene_id };
            push @report_data, [
                $basket_name,
                $curr_gene->{ 'mgi_accession_id' },
                $curr_gene->{ 'marker_symbol' },
                $curr_gene->{ 'accepted_clones_at_wtsi' },                
                $curr_gene->{ 'accepted_clone_piq_wells_at_wtsi' },
                $curr_gene->{ 'accepted_clones_qc_passed_at_wtsi' },
                $curr_gene->{ 'plans_summary' },
            ];
        }
    }

    $self->report_data( \@report_data );

    return;
}

=head2 fetch_lims2_cre_knockin_projects

fetch list of Cre Knockin genes from LIMS2 projects table

=cut
sub _fetch_lims2_cre_knockin_projects {
    my ( $self, $cre_ki_genes ) = @_;

    my $sql_query_lims2_cre_projects    = $self->_sql_select_lims2_cre_project_genes();
    my $sql_result_lims2_cre_genes      = $self->_run_select_query( $sql_query_lims2_cre_projects );

    foreach my $cre_proj_row ( @{ $sql_result_lims2_cre_genes } ) {
        $cre_ki_genes->{ $cre_proj_row->{ 'mgi_gene_id' } }->{ 'lims2_project_db_id' } = $cre_proj_row->{ 'lims2_project_db_id' };
    }

    return;
}

=head2 add_lims2_data

select information from LIMS2 summaries table

=cut
sub _add_lims2_data {
    my ( $self, $cre_ki_genes ) = @_;

    my $sql_query_lims2_summary_data =  $self->_sql_select_lims2_summaries_data();
    my $sql_result_lims2_summary_data = $self->_run_select_query( $sql_query_lims2_summary_data );

    # my @piq_well_db_ids = ();

    # transfer information from the flat sql result into the main genes hash
    foreach my $row ( @{ $sql_result_lims2_summary_data } ) {
        my $gene_id = $row->{ 'design_gene_id' };
        $cre_ki_genes->{ $gene_id }->{ 'gene_symbol' } = $row->{ 'design_gene_symbol' };

        my $ep_pick_well_id = $row->{ 'ep_pick_well_id' };
        $cre_ki_genes->{ $gene_id }->{ 'clones' }->{ $ep_pick_well_id } = $cre_ki_genes->{ $gene_id }->{ 'clones' }->{ $ep_pick_well_id };

        my $ep_pick_well = \% { $cre_ki_genes->{ $gene_id }->{ 'clones' }->{ $ep_pick_well_id } };
        $ep_pick_well->{ 'clone_accepted' }       = $row->{ 'clone_accepted' };
        $ep_pick_well->{ 'final_pick_well_id' }   = $row->{ 'final_pick_well_id' };
        $ep_pick_well->{ 'vector_cassette_name' } = $row->{ 'vector_cassette_name' };
        $ep_pick_well->{ 'vector_backbone_name' } = $row->{ 'vector_backbone_name' };

        if( defined $row->{ 'fp_well_id' } ) {
            my $fp_well_id = $row->{ 'fp_well_id' };
            $ep_pick_well->{ 'freezer_wells' }->{ $fp_well_id }->{ 'fp_well_accepted' } = $row->{ 'fp_well_accepted' };
            my $fp_well = \% { $ep_pick_well->{ 'freezer_wells' }->{ $fp_well_id } };

            if( defined $row->{ 'piq_well_id' } ) {
                my $piq_well_id = $row->{ 'piq_well_id' };
                $fp_well->{ 'piq_wells' }->{ $piq_well_id }->{ 'piq_well_accepted' } = $row->{ 'piq_well_accepted' };

                my $piq_well = \% { $fp_well->{ 'piq_wells' }->{ $piq_well_id } };
                if ( defined $row->{ 'piq_well_db_id' } ) {
                    $piq_well->{ 'piq_well_db_id' } = $row->{ 'piq_well_db_id' };
                
                    # the piq well ids are collected and sent to allele determination to check for genotyping passes
                    # push( @piq_well_db_ids, $piq_well_db_id );
                }
            }
        }
    }

    # $self->_add_lims2_piq_genotyping_pass_data( $cre_ki_genes, \@piq_well_db_ids );

    return;
}

=head2 add_lims2_piq_genotyping_pass_data

run allele determination code against data to get genotyping QC pass information

=cut
## no critic ( Subroutines::ProhibitExcessComplexity )
# sub _add_lims2_piq_genotyping_pass_data {
#     my ( $self, $cre_ki_genes, $piq_well_db_ids ) = @_;

#     # fetch genotyping data for list of PIQ well ids
#     my $piq_AD = LIMS2::Model::Util::AlleleDetermination->new( 'model' => $self->model, 'species' => $self->species );
#     my $piq_AD_results = $piq_AD->determine_allele_types_for_well_ids( $piq_well_db_ids );

#     # convert piq_AD_results into a hash
#     my $piq_AD_results_hash = {};
#     foreach my $piq_well ( @{ $piq_AD_results } ) {
#         my $well_db_id = $piq_well->{ 'id' };
#         $piq_AD_results_hash->{ $well_db_id } = $piq_well;
#     }

#     foreach my $mgi_gene_id ( sort keys %{ $cre_ki_genes } ) {
#         if ( exists $cre_ki_genes->{ $mgi_gene_id }->{ 'clones' } ) {
#         	foreach my $clone_well_id ( sort keys %{ $cre_ki_genes->{ $mgi_gene_id }->{ 'clones' } } ) {
#                 if ( exists $cre_ki_genes->{ $mgi_gene_id }->{ 'clones' }->{ $clone_well_id }->{ 'freezer_wells' } ) {
#                     foreach my $fp_well_id ( sort keys %{ $cre_ki_genes->{ $mgi_gene_id }->{ 'clones' }->{ $clone_well_id }->{ 'freezer_wells' } } ) {
#                         if ( exists $cre_ki_genes->{ $mgi_gene_id }->{ 'clones' }->{ $clone_well_id }->{ 'freezer_wells' }->{ $fp_well_id }->{ 'piq_wells' } ) {
#                             foreach my $piq_well_id ( sort keys %{ $cre_ki_genes->{ $mgi_gene_id }->{ 'clones' }->{ $clone_well_id }->{ 'freezer_wells' }->{ $fp_well_id }->{ 'piq_wells' } } ) {
#                                 # add in genotyping data if exists in piq_results hash
#                                 my $curr_piq_well_db_id = $cre_ki_genes->{ $mgi_gene_id }->{ 'clones' }->{ $clone_well_id }->{ 'freezer_wells' }->{ $fp_well_id }->{ 'piq_wells' }->{ $piq_well_id }->{ 'piq_well_db_id' };
#                                 if ( exists $piq_AD_results_hash->{ $curr_piq_well_db_id } ) {
#                                     $cre_ki_genes->{ $mgi_gene_id }->{ 'clones' }->{ $clone_well_id }->{ 'freezer_wells' }->{ $fp_well_id }->{ 'piq_wells' }->{ $piq_well_id }->{ 'genotyping_results' } = $piq_AD_results_hash->{ $curr_piq_well_db_id };
#                                 }
#                             }
#                         }
#                     }
#                 }
#             }
#         }
#     }

#     return;
# }
## use critic

=head2 add_lims2_counts

cycle through hash adding LIMS2 counts

=cut
## no critic ( Subroutines::ProhibitExcessComplexity )
sub _add_lims2_counts {
    my ( $self, $cre_ki_genes ) = @_;

    foreach my $mgi_gene_id ( sort keys %{ $cre_ki_genes } ) {
        my $count_lims2_clones_total = 0;
        my $count_lims2_clones_accepted = 0;
        my $count_lims2_freezer_wells = 0;
        my $count_lims2_piq_wells = 0;
        my $count_lims2_piq_wells_accepted = 0;
        my $count_lims2_piq_has_qc_data = 0;
        my @ep_pick_well_ids_array;
        my @fp_well_ids_array;
        my @piq_well_ids_array;
        my @qc_passed_clones_array;

        my $curr_gene = \% { $cre_ki_genes->{ $mgi_gene_id } };

        if ( exists $curr_gene->{ 'clones' } ) {
            my $curr_gene_clones = \% { $curr_gene->{ 'clones' } };

            foreach my $clone_well_id ( sort keys %{ $curr_gene_clones } ) {
                $count_lims2_clones_total++;
                if ( $curr_gene_clones->{ $clone_well_id }->{ 'clone_accepted' } ) {
                    $count_lims2_clones_accepted++;
                    push ( @ep_pick_well_ids_array, $clone_well_id );
                    # add to concatenated lists of freezer and piq wells

                    my $curr_clone = \% { $curr_gene_clones->{ $clone_well_id } };

                     # cycle through all the freezer wells for each accepted clone (if any)
                    foreach my $fp_well_id ( sort keys %{ $curr_clone->{ 'freezer_wells' } } ) {
                        $count_lims2_freezer_wells++;
                        push ( @fp_well_ids_array, $fp_well_id );

                        my $curr_fp_well = \%{ $curr_clone->{ 'freezer_wells' }->{ $fp_well_id } };

                        # cycle through all the PIQ wells for each freezer well (if any)
                        foreach my $piq_well_id ( sort keys %{ $curr_fp_well->{ 'piq_wells' } } ) {
                            $count_lims2_piq_wells++;
                            push ( @piq_well_ids_array, $piq_well_id );

                            my $curr_piq_well = \% { $curr_fp_well->{ 'piq_wells' }->{ $piq_well_id } };

                            # if ( exists $curr_piq_well->{ 'genotyping_results' } ) {
                            #     my $piq_genotyping_pass = $curr_piq_well->{ 'genotyping_results' }->{ 'genotyping_pass' };
                            #     my $well_has_qc_data = $curr_piq_well->{ 'genotyping_results' }->{ 'has_qc_data' };

                            #     if ( defined $piq_genotyping_pass && $piq_genotyping_pass ne 'fail' && $piq_genotyping_pass ne '' ) { 
                            #     	push ( @qc_passed_clones_array, $clone_well_id );
                            #     	$count_lims2_piq_wells_accepted++;
                            #     }
                            #     if ( defined $well_has_qc_data && $well_has_qc_data == 1 ) { $count_lims2_piq_has_qc_data++; }
                            # }
                            if ( $curr_piq_well->{ 'piq_well_accepted' } == 1 ) {
                                
                                push ( @qc_passed_clones_array, $clone_well_id );
                                $count_lims2_piq_wells_accepted++;
                            }

                            $curr_piq_well->{ 'has_qc_data' } = $self->_well_has_qc_data( $curr_piq_well->{ 'piq_well_db_id' } );
                            if ( $curr_piq_well->{ 'has_qc_data' } ) {
                                $count_lims2_piq_has_qc_data++;
                            }
                        }
                    }
                }
            }
        }

        # add counts and well lists into hash
        $curr_gene->{ 'has_lims2_data' } = 1;
        $curr_gene->{ 'count_lims2_clones_total' }          = $count_lims2_clones_total;
        $curr_gene->{ 'count_lims2_clones_accepted' }       = $count_lims2_clones_accepted;
        $curr_gene->{ 'count_lims2_freezer_wells' }         = $count_lims2_freezer_wells;
        $curr_gene->{ 'count_lims2_piq_wells' }             = $count_lims2_piq_wells;
        $curr_gene->{ 'count_lims2_piq_wells_accepted' }    = $count_lims2_piq_wells_accepted;
        $curr_gene->{ 'count_lims2_piq_has_qc_data' }       = $count_lims2_piq_has_qc_data;

        # add lists of well ids into hash
        if ( @ep_pick_well_ids_array ) { $curr_gene->{ 'accepted_clones_list' }          = join ( ' : ', @ep_pick_well_ids_array ) };
        if ( @fp_well_ids_array ) { $curr_gene->{ 'accepted_clone_fp_wells_list' }       = join ( ' : ', @fp_well_ids_array ) };
        if ( @piq_well_ids_array ) { $curr_gene->{ 'accepted_clone_piq_wells_list' }     = join ( ' : ', @piq_well_ids_array ) };
        if ( @qc_passed_clones_array ) { $curr_gene->{ 'accepted_clone_qc_passed_list' } = join ( ' : ', @qc_passed_clones_array ) };

        # these counters set to zero for now and incremented when imits data added
        $curr_gene->{ 'has_imits_data' }                    = 0;
        $curr_gene->{ 'count_mi_plans_total' }              = 0;
        $curr_gene->{ 'count_mi_plans_active' }             = 0;
        $curr_gene->{ 'count_mi_attempts_total' }           = 0;
        $curr_gene->{ 'count_mi_attempts_active' }          = 0;
    }

    return;
}
## use critic

=head2 fetch_imits_cre_ki_data

select Cre Ki data by gene from imits database

=cut
sub _fetch_imits_cre_ki_data {
    my ( $self ) = @_;

    my $dbname   = $self->imits_config->{ 'imits_connection' }->{ 'dbname' };
    my $host     = $self->imits_config->{ 'imits_connection' }->{ 'host' };
    my $port     = $self->imits_config->{ 'imits_connection' }->{ 'port' };
    my $username = $self->imits_config->{ 'imits_connection' }->{ 'username' };
    my $password = $self->imits_config->{ 'imits_connection' }->{ 'password' };

    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port;", "$username", "$password");

    my $sql = _sql_select_imits_data();

    my $imits_results = $dbh->selectall_arrayref($sql, { Slice => {} } );

    # reformat the iMits results into a new hash
    my $imits_data = {};

    foreach my $imits_row ( @{ $imits_results } ) {
        my $row_gene_id = $imits_row->{ 'gene_mgi_id' };
        $imits_data->{ $row_gene_id }->{ 'gene_marker_symbol' } = $imits_row->{ 'gene_marker_symbol' };

        my $imits_data_gene = \%{ $imits_data->{ $row_gene_id } };
        my $row_plan_db_id = $imits_row->{ 'plan_db_id' };
        # will always have a plan of what will be attempted, need to know if plan(s) active
        $imits_data_gene->{ 'mi_plans' }->{ $row_plan_db_id }->{ 'is_plan_active' } = $imits_row->{ 'is_plan_active' };

        my $imits_data_plan = \%{ $imits_data_gene->{ 'mi_plans' }->{ $row_plan_db_id } };
        $imits_data_plan->{ 'production_centre_name' } = $imits_row->{ 'production_centre_name' };
        $imits_data_plan->{ 'plan_priority' }          = $imits_row->{ 'plan_priority' };

        # optionally will there may be physical attempts at creating the mouse, add these to hash
        if ( defined $imits_row->{ 'mi_attempt_db_id' } && defined $imits_row->{ 'es_cell_name' } ) {
            my $row_mi_attempt_db_id = $imits_row->{ 'mi_attempt_db_id' };
            my $row_es_cell_name     = $imits_row->{ 'es_cell_name' };

            $imits_data_gene->{ 'clones' }->{ $row_es_cell_name }->{ 'mi_attempts' }->{ $row_mi_attempt_db_id }->{ 'consortia_name' } = $imits_row->{ 'consortia_name' };

            my $imits_data_mi_attempt = \%{ $imits_data_gene->{ 'clones' }->{ $row_es_cell_name }->{ 'mi_attempts' }->{ $row_mi_attempt_db_id } };
            $imits_data_mi_attempt->{ 'is_attempt_active' }       = $imits_row->{ 'is_attempt_active' };
            $imits_data_mi_attempt->{ 'plan_priority' }           = $imits_row->{ 'plan_priority' };
            $imits_data_mi_attempt->{ 'production_centre_name' }  = $imits_row->{ 'production_centre_name' };
            $imits_data_mi_attempt->{ 'status_code' }             = $imits_row->{ 'status_code' };
            $imits_data_mi_attempt->{ 'status_name' }             = $imits_row->{ 'status_name' };
        }
    }

    return $imits_data;
}

=head2 fuse_lims2_and_imits_data

join together the LIMS2 and imits gene data

=cut
sub _fuse_lims2_and_imits_data {
    my ( $self, $cre_ki_genes, $imits_cre_ki_data  ) = @_;

    # Now we can fuse the two reports, by merging the output from (lims2) onto the output from (iMits) by gene.
    foreach my $imits_gene_id ( sort keys %{ $imits_cre_ki_data } ) {
        # add imits data into the lims2 hash at clone level, adding counters at gene level
        my $count_mi_plans_total     = 0;
        my $count_mi_plans_active    = 0;
        my $count_mi_attempts_total  = 0;
        my $count_mi_attempts_active = 0; # status not aborted and is_attempt_active true

        # check for whether lims2 knows about this gene, if not set base counters
        if ( !exists $cre_ki_genes->{ $imits_gene_id } ) {
            $self->_initialise_cre_gene_where_only_in_imits( $cre_ki_genes, $imits_gene_id );
        }

        my $cre_ki_gene = \%{ $cre_ki_genes->{ $imits_gene_id } };
        my $imits_gene = \%{ $imits_cre_ki_data->{ $imits_gene_id } };

        # if gene has mi_plans
        if ( exists $imits_gene->{ 'mi_plans' } ) {
            # copy mi_plans across
            my $imits_gene_plans = \%{ $imits_gene->{ 'mi_plans' } };
            $cre_ki_gene->{ 'mi_plans' } = $imits_gene_plans;

            # for each plan increment counters
            foreach my $imits_plan_id ( sort keys %{ $imits_gene_plans } ) {
                $count_mi_plans_total++;
                my $is_current_plan_active = $imits_gene_plans->{ $imits_plan_id }->{ 'is_plan_active' };
                # TODO: check for an aborted status here?
                if ( $is_current_plan_active ) {
                    $count_mi_plans_active++;
                }
            }
        }

        # for each clone
        foreach my $imits_clone_id ( sort keys %{ $imits_gene->{ 'clones' } } ) {
            my $imits_clone = \%{ $imits_gene->{ 'clones' }->{ $imits_clone_id } };

            # check if clone has mi attempts
            if ( exists $imits_clone->{ 'mi_attempts' } ) {
                # copy mi_attempts across
                $cre_ki_gene->{ 'clones' }->{ $imits_clone_id }->{ 'mi_attempts' } = $imits_clone->{ 'mi_attempts' };

                # check each attempt
                foreach my $mi_attempt_db_id ( sort keys %{ $imits_clone->{ 'mi_attempts' } } ) {
                    $count_mi_attempts_total++;
                    my $imits_mi_attempt = \%{ $imits_clone->{ 'mi_attempts' }->{ $mi_attempt_db_id } };
                    my $curr_mi_attempt_status            = $imits_mi_attempt->{ 'status_code' };
                    my $curr_mi_attempt_is_attempt_active = $imits_mi_attempt->{ 'is_attempt_active' };
                    # to be active attempt must be active and not aborted
                    if ( $curr_mi_attempt_is_attempt_active && $curr_mi_attempt_status ne 'abt' ) {
                        $count_mi_attempts_active++;
                    }
                }
            }
        }
        $cre_ki_gene->{ 'has_imits_data' } = 1;
        $cre_ki_gene->{ 'count_mi_plans_total' } = $count_mi_plans_total;
        $cre_ki_gene->{ 'count_mi_plans_active' } = $count_mi_plans_active;
        $cre_ki_gene->{ 'count_mi_attempts_total' } = $count_mi_attempts_total;
        $cre_ki_gene->{ 'count_mi_attempts_active' } = $count_mi_attempts_active;
    }

    return;
}

=head2 initialise_cre_gene_where_only_in_imits

initialise counters for an imits gene record that does not exist in LIMS2

=cut
sub _initialise_cre_gene_where_only_in_imits {
    my ( $self, $cre_ki_genes, $imits_gene_id ) = @_;

    $cre_ki_genes->{ $imits_gene_id }->{ 'has_lims2_data' } = 0;
    my $cre_gene = \%{ $cre_ki_genes->{ $imits_gene_id } };
    $cre_gene->{ 'count_lims2_clones_total' }               = 0;
    $cre_gene->{ 'count_lims2_clones_accepted' }            = 0;
    $cre_gene->{ 'count_lims2_freezer_wells' }              = 0;
    $cre_gene->{ 'count_lims2_piq_wells' }                  = 0;
    $cre_gene->{ 'count_lims2_piq_wells_accepted' }         = 0;
    $cre_gene->{ 'count_lims2_piq_has_qc_data' }            = 0;

    return;
}

=head2 summarise_cre_ki_data

summarise the data for reporting

=cut
sub _summarise_cre_ki_data {
    my ( $self ) = @_;

    $self->_initialise_summaried_data_hash();

    foreach my $mgi_gene_id ( sort keys %{ $self->cre_ki_genes } ) {
    	$self->summaried_data->{ 'count_genes_total' }++;

    	$self->_initialise_curr_gene_summary( $mgi_gene_id );
    	$self->_summarise_cre_ki_data_current_gene ( $mgi_gene_id );

    	# DEBUG ( 'Gene: <' . $mgi_gene_id . '> ' . Dumper ( $self->curr_gene_summary ) );

        # add current gene summary to hash for detailed report
        $self->_add_to_summary_data_by_gene();
    }

    return;
}

=head2 initialise_summaried_data_hash

initialise the data hash for the summary counts

=cut
sub _initialise_summaried_data_hash {
	my ( $self ) = @_;

    # foreach my $prod_centre ( [ qw( WTSI Monterotondo  ) ] )
    my $summaried_data = {
    	'count_genes_total'                  => 0,
        'count_only_in_imits'                => 0,
        'count_unrecognized_type'            => 0,
        'count_unpicked_total'               => 0,
        'count_unpicked_no_piqs_total'       => 0,
        'count_unpicked_no_clones_total'     => 0,
        'count_picked_total'                 => 0,
        'count_picked_1_clone_total'         => 0,
        'count_picked_2_clones_total'        => 0,
        'count_picked_3_clones_total'        => 0,
        'count_picked_4_clones_total'        => 0,
        'count_picked_5_clones_total'        => 0,
        'count_picked_gt5_clones_total'      => 0,
        'count_qc_passes_no_mis_total'       => 0,
        'count_qc_fails_all_piqd_clones'     => 0,
        'count_failed_mp_total'              => 0,
        'count_unrequested_total'            => 0,
        'count_in_progress_active_mis_total' => 0,
    };

    $self->summaried_data( $summaried_data );

    return;
}

=head2 _initialise_curr_gene_summary

initialise the data hash for the gene summary counts

=cut
sub _initialise_curr_gene_summary {
	my ( $self, $mgi_gene_id ) = @_;

	$self->curr_gene_summary( {} );

    my $curr_gene = \%{ $self->cre_ki_genes->{ $mgi_gene_id } };

	my $curr_gene_summary = {
		'mgi_accession_id'                   => $mgi_gene_id,		
		'has_imits_data'                     => $curr_gene->{ 'has_imits_data' },
		'has_lims2_data'                     => $curr_gene->{ 'has_lims2_data' },
		'basket'                             => '',
	};

    $self->curr_gene_summary( $curr_gene_summary );

    $self->_initialise_curr_gene_summary_lims2_data( $curr_gene );
    $self->_initialise_curr_gene_summary_imits_data( $curr_gene );	

	return;
}

=head2 _initialise_curr_gene_summary_lims2_data

initialise the data hash for the gene summary counts with lims2 data

=cut
sub _initialise_curr_gene_summary_lims2_data {
    my ( $self, $curr_gene  ) = @_;

    # add LIMS2 data fields
    if ( $self->curr_gene_summary->{ 'has_lims2_data' } ) {
        $self->curr_gene_summary->{ 'marker_symbol' }                      = $curr_gene->{ 'gene_symbol' };
        $self->curr_gene_summary->{ 'accepted_clones_at_wtsi' }            = $curr_gene->{ 'accepted_clones_list' };
        $self->curr_gene_summary->{ 'accepted_clones_qc_passed_at_wtsi' }  = $curr_gene->{ 'accepted_clone_qc_passed_list' };
        $self->curr_gene_summary->{ 'accepted_clone_piq_wells_at_wtsi' }   = $curr_gene->{ 'accepted_clone_piq_wells_list' };    
        $self->curr_gene_summary->{ 'count_lims2_clones_total' }           = $curr_gene->{ 'count_lims2_clones_total' };
        $self->curr_gene_summary->{ 'count_lims2_clones_accepted' }        = $curr_gene->{ 'count_lims2_clones_accepted' };
        $self->curr_gene_summary->{ 'count_lims2_freezer_wells' }          = $curr_gene->{ 'count_lims2_freezer_wells' };        
        $self->curr_gene_summary->{ 'count_lims2_piq_wells_accepted' }     = $curr_gene->{ 'count_lims2_piq_wells_accepted' };
        $self->curr_gene_summary->{ 'count_lims2_piq_has_qc_data' }        = $curr_gene->{ 'count_lims2_piq_has_qc_data' };
        $self->curr_gene_summary->{ 'count_lims2_piq_wells' }              = $curr_gene->{ 'count_lims2_piq_wells' };
    }
    else {
        $self->curr_gene_summary->{ 'marker_symbol' }                      = '';
        $self->curr_gene_summary->{ 'accepted_clones_at_wtsi' }            = '';
        $self->curr_gene_summary->{ 'accepted_clones_qc_passed_at_wtsi' }  = '';
        $self->curr_gene_summary->{ 'accepted_clone_piq_wells_at_wtsi' }   = '';
        $self->curr_gene_summary->{ 'count_lims2_clones_total' }           = 0;
        $self->curr_gene_summary->{ 'count_lims2_clones_accepted' }        = 0;
        $self->curr_gene_summary->{ 'count_lims2_freezer_wells' }          = 0;
        $self->curr_gene_summary->{ 'count_lims2_piq_wells_accepted' }     = 0;
        $self->curr_gene_summary->{ 'count_lims2_piq_has_qc_data' }        = 0;
        $self->curr_gene_summary->{ 'count_lims2_piq_wells' }              = 0;
    }

    return;
}

=head2 _initialise_curr_gene_summary_imits_data

initialise the data hash for the gene summary counts with imits data

=cut
sub _initialise_curr_gene_summary_imits_data {
    my ( $self, $curr_gene  ) = @_;

    # add Imits data fields
    if ( $self->curr_gene_summary->{ 'has_imits_data' } ) {
        $self->curr_gene_summary->{ 'count_mi_plans' }                     = $curr_gene->{ 'count_mi_plans_total' };
        $self->curr_gene_summary->{ 'count_mi_plans_active' }              = $curr_gene->{ 'count_mi_plans_active' };
        $self->curr_gene_summary->{ 'count_mi_attempts' }                  = $curr_gene->{ 'count_mi_attempts_total' };
        $self->curr_gene_summary->{ 'count_mi_attempts_active' }           = $curr_gene->{ 'count_mi_attempts_active' };
        
        my @plans_array;
        foreach my $plan_id ( sort keys %{ $curr_gene->{ 'mi_plans' } } ) {
            my $curr_plan = $curr_gene->{ 'mi_plans' }->{ $plan_id };
            push ( @plans_array, ( $curr_plan->{ 'production_centre_name' } . '_' . $plan_id . '_' . $curr_plan->{ 'plan_priority' } ) );
        }
        $self->curr_gene_summary->{ 'plans_summary' }                      = join ( ' : ', @plans_array );
    }
    else {
        $self->curr_gene_summary->{ 'count_mi_plans' }                     = 0;
        $self->curr_gene_summary->{ 'count_mi_plans_active' }              = 0;
        $self->curr_gene_summary->{ 'count_mi_attempts' }                  = 0;
        $self->curr_gene_summary->{ 'count_mi_attempts_active' }           = 0;
        $self->curr_gene_summary->{ 'plans_summary' }                      = '';
    }

    return;
}

=head2 _summarise_cre_ki_data_current_gene

summarise the information for the current gene

=cut
sub _summarise_cre_ki_data_current_gene {
	my ( $self, $mgi_gene_id ) = @_;

    if ( $self->curr_gene_summary->{ 'has_lims2_data' } ) {
        if ( $self->curr_gene_summary->{ 'has_imits_data' } ) {
            if ( $self->curr_gene_summary->{ 'count_mi_plans_active' } > 0 ) {
                if ( $self->curr_gene_summary->{ 'count_mi_attempts' } > 0 ) {
                    if ( $self->curr_gene_summary->{ 'count_mi_attempts_active' } == 0 ) {
                    	$self->_basket_failed_in_mouse_production( $mgi_gene_id );                        	
                    }
                    else {
                    	$self->_basket_in_progress( $mgi_gene_id );
                    }
                }
                else {
                    if ( $self->curr_gene_summary->{ 'count_lims2_piq_wells' } > 0 ) {
                        if ( $self->curr_gene_summary->{ 'count_lims2_clones_accepted' } > 0 ) {
                            if ( $self->curr_gene_summary->{ 'count_lims2_piq_has_qc_data' } > 0 ) {
                                if ( $self->curr_gene_summary->{ 'count_lims2_piq_wells_accepted' } > 0 ) {
                                	$self->_basket_qc_passed( $mgi_gene_id );
                                }
                                else {
                                	$self->_basket_qc_failed( $mgi_gene_id );
                                }
                            }
                            else {
                            	$self->_basket_picked( $mgi_gene_id );
                            }
                        }
                        else {
                        	$self->_basket_unrecognized_type( $mgi_gene_id, 'mi_plans_active, no mi_attempts, piq_wells, no accepted clones' );
                        }
                    }
                    else {
                    	$self->_basket_unpicked( $mgi_gene_id );
                    }
                }
            }
            else {
                $self->_basket_unrecognized_type( $mgi_gene_id, 'no mi_plans_active' );
            }
        }
        else {
        	$self->_basket_unrequested( $mgi_gene_id );
        }
    }
    else {
    	$self->_basket_missing_lims2( $mgi_gene_id );
    }

	return;
}

# sub _gene_has_lims2_data {
#     my ( $self ) = @_;


#     return;
# }

sub _basket_failed_in_mouse_production {
	my ( $self, $mgi_gene_id ) = @_;

    # Failed in Mouse production. These have mi_attempts, but no active ones. (all should have PIQ data but this is incidental).
    my $txt = 'failed_in_mouse_production';
    $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
    $self->curr_gene_summary->{ 'basket' }              = $txt;
    $self->summaried_data->{ 'count_failed_mp_total' }++;

	return;
}

sub _basket_in_progress {
	my ( $self, $mgi_gene_id ) = @_;

    # In progress i.e. active attempts
    my $txt = 'in_progress_active_mi_attempts';
    $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
    $self->curr_gene_summary->{ 'basket' }              = $txt;
    $self->summaried_data->{ 'count_in_progress_active_mis_total' }++;

	return;
}

sub _basket_qc_passed {
	my ( $self, $mgi_gene_id ) = @_;

	# Have at least one PIQ QC pass but no MI attempts
    my $txt = 'qc_passed_no_mi_attempts';
    $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
    $self->curr_gene_summary->{ 'basket' }              = $txt;
    $self->summaried_data->{ 'count_qc_passes_no_mis_total' }++;

	return;
}

sub _basket_qc_failed {
	my ( $self, $mgi_gene_id ) = @_;

	# All PIQ QC has failed and no MI attempts
	my $txt = 'qc_failed_no_mi_attempts';
    $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
    $self->curr_gene_summary->{ 'basket' }              = $txt;
    $self->summaried_data->{ 'count_qc_fails_all_piqd_clones' }++;

	return;
}

sub _basket_picked {
	my ( $self, $mgi_gene_id ) = @_;

    # Picked. These have an active plan in iMits but no mi_attempts, in lims2 there are clones but no pass or fail data for the PIQ ie. waiting on the lab.
    my $txt = '';
    if ( $self->curr_gene_summary->{ 'count_lims2_clones_accepted' } == 1 ) {
    	$txt = 'picked_1_clone';
        $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
        $self->summaried_data->{ 'count_picked_1_clone_total' }++;
    }
    elsif ( $self->curr_gene_summary->{ 'count_lims2_clones_accepted' } == 2 ) {
    	$txt = 'picked_2_clones';
        $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
        $self->summaried_data->{ 'count_picked_2_clones_total' }++;
    }
    elsif ( $self->curr_gene_summary->{ 'count_lims2_clones_accepted' } == 3 ) {
    	$txt = 'picked_3_clones';
        $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
        $self->summaried_data->{ 'count_picked_3_clones_total' }++;
    }
    elsif ( $self->curr_gene_summary->{ 'count_lims2_clones_accepted' } == 4 ) {
    	$txt = 'picked_4_clones';
        $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
        $self->summaried_data->{ 'count_picked_4_clones_total' }++;
    }
    elsif ( $self->curr_gene_summary->{ 'count_lims2_clones_accepted' } == 5 ) {
    	$txt = 'picked_5_clones';
        $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
        $self->summaried_data->{ 'count_picked_5_clones_total' }++;
    }
    else {
    	$txt = 'picked_gt5_clones';
        $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
        $self->summaried_data->{ 'count_picked_gt5_clones_total' }++;
    }
    $self->curr_gene_summary->{ 'basket' }              = $txt;
    $self->summaried_data->{ 'count_picked_total' }++;

	return;
}

sub _basket_unpicked {
	my ( $self, $mgi_gene_id ) = @_;

	my $txt = '';
    if( $self->curr_gene_summary->{ 'count_lims2_clones_accepted' } > 0 ) {
        # (1b) Unpicked_no_piqs. These have an active plan in iMits but no mi_attempts, they have clones but no PIQ data from lims2.
        $txt = 'unpicked_no_piqs';
        $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
        $self->summaried_data->{ 'count_unpicked_no_piqs_total' }++;
    }
    else {
        # (1a) Unpicked_no_clones. These have an active plan in iMits but no mi_attempts, and no clones or PIQ data from lims2.
        $txt = 'unpicked_no_clones';
        $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
        $self->summaried_data->{ 'count_unpicked_no_clones_total' }++;
    }
    $self->curr_gene_summary->{ 'basket' }                  = $txt;
    $self->summaried_data->{ 'count_unpicked_total' }++;

	return;
}

sub _basket_unrecognized_type {
	my ( $self, $mgi_gene_id, $msg ) = @_;

	# Unrecognised combination
	my $txt = 'unrecognised_type';
	$self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
    $self->curr_gene_summary->{ 'basket' }              = $txt;
    $self->summaried_data->{ 'count_unrecognized_type' }++;

    WARN 'Unrecognised type <' . $msg . '>, gene ID = ' . $mgi_gene_id;

	return;
}

sub _basket_unrequested {
	my ( $self, $mgi_gene_id ) = @_;

    # (d) Unrequested. These have no data coming from iMITS whatsover, but DO have data in LIMS2 i.e. in the project list. Useful to know if there are accepted clones and piq'd clones too.
    my $txt = 'unrequested';
    $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
    $self->curr_gene_summary->{ 'basket' }              = $txt;
    $self->summaried_data->{ 'count_unrequested_total' }++;

	return;
}

sub _basket_missing_lims2 {
	my ( $self, $mgi_gene_id ) = @_;

    # these are missing from LIMS2. i.e. missing CreKI projects in LIMS2
    my $txt = 'missing_from_lims2';
    $self->curr_gene_summary->{ 'basket' }              = $txt;
    $self->cre_ki_genes->{ $mgi_gene_id }->{ 'basket' } = $txt;
    $self->summaried_data->{ 'count_only_in_imits' }++;

    WARN 'Gene in imits but missing in LIMS2, gene ID = ' . $mgi_gene_id;

	return;
}

sub _add_to_summary_data_by_gene{
    my ( $self ) = @_;

    unless( defined $self->summarised_data_by_basket_and_gene ) { $self->_initialise_summarised_data_by_basket_and_gene(); }

    my $curr_basket = $self->curr_gene_summary->{ 'basket' };
    my $curr_gene_mgi_id = $self->curr_gene_summary->{ 'mgi_accession_id' };

    $self->summarised_data_by_basket_and_gene->{ $curr_basket }->{ 'genes' }->{ $curr_gene_mgi_id } = $self->curr_gene_summary;
    $self->summarised_data_by_basket_and_gene->{ $curr_basket }->{ 'count_genes' }++;
    return;
}

sub _initialise_summarised_data_by_basket_and_gene{
    my ( $self ) = @_;

    # hash of summarised gene counts, partitioned by basket
    my $summary_gene_hash = {
        'failed_in_mouse_production'      => { 'count_genes' => 0, },
        'in_progress_active_mi_attempts'  => { 'count_genes' => 0, },
        'qc_passed_no_mi_attempts'        => { 'count_genes' => 0, },
        'qc_failed_no_mi_attempts'        => { 'count_genes' => 0, },
        'picked_1_clone'                  => { 'count_genes' => 0, },
        'picked_2_clones'                 => { 'count_genes' => 0, },
        'picked_3_clones'                 => { 'count_genes' => 0, },
        'picked_4_clones'                 => { 'count_genes' => 0, },
        'picked_5_clones'                 => { 'count_genes' => 0, },
        'picked_gt5_clones'               => { 'count_genes' => 0, },
        'unpicked_no_piqs'                => { 'count_genes' => 0, },
        'unpicked_no_clones'              => { 'count_genes' => 0, },
        'unrequested'                     => { 'count_genes' => 0, },
        'unrecognised_type'               => { 'count_genes' => 0, },
        'missing_from_lims2'              => { 'count_genes' => 0, },
    };

    $self->summarised_data_by_basket_and_gene( $summary_gene_hash );

    return;
}

=head2 _well_has_qc_data

check whether well has any QC data

=cut
sub _well_has_qc_data {
    my ( $self, $well_id ) = @_;

    my $has_qc_data = 0;

    try {
        my $sql_query = $self->_create_sql_select_qc_data( $well_id );
        my $sql_results = $self->_run_select_query($sql_query);
        if ( defined $sql_results && (scalar @{ $sql_results } ) > 0 ) {
            $has_qc_data = 1;
        }
    }
    catch {
        my $exception_message = $_;
        LIMS2::Exception->throw("Failed has_qc_data check. Exception: $exception_message");
    };

    return $has_qc_data;
}

=head2 run_select_query

generic method to run a sql query

=cut
sub _run_select_query {
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

=head2 sql_select_lims2_cre_project_genes

creates the sql query for selecting LIMS2 Cre Ki projects

=cut
sub _sql_select_lims2_cre_project_genes {
    my ( $self ) = @_;

    my $species = $self->species;
    my $sponsor_id = 'Cre Knockin';

my $sql_query =  <<"SQL_END";
SELECT projects.gene_id AS mgi_gene_id, projects.id AS lims2_project_db_id
FROM projects
WHERE projects.sponsor_id = '$sponsor_id'
AND projects.species_id = '$species'
ORDER BY projects.gene_id
SQL_END

    return $sql_query;
}

=head2 sql_select_lims2_summaries_data

creates the sql query for selecting LIMS2 Cre Ki gene data

=cut
sub _sql_select_lims2_summaries_data {
    my ( $self ) = @_;

    my $species_id = $self->species;
    my $sponsor_id = 'Cre Knockin';

my $sql_query =  <<"SQL_END";
WITH cre_project_requests AS (
SELECT p.id AS project_id,
 p.htgt_project_id,
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
WHERE p.sponsor_id   = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
AND p.species_id     = '$species_id'
)
SELECT pr.project_id
, pr.htgt_project_id
, s.design_id
, s.design_name
, s.design_type
, s.design_phase
, (s.design_plate_name || '_' || s.design_well_name) AS design_well_id
, s.design_gene_id
, s.design_gene_symbol
, (s.int_plate_name || '_' || s.int_well_name) AS int_well_id
, s.int_well_id AS int_well_db_id
, s.final_pick_cassette_name AS vector_cassette_name
, s.final_pick_cassette_promoter AS vector_cassette_promotor
, s.final_pick_backbone_name AS vector_backbone_name
, (s.final_pick_plate_name || '_' || s.final_pick_well_name) AS final_pick_well_id
, s.final_pick_well_id AS final_pick_well_db_id
, (s.ep_pick_plate_name || '_' || s.ep_pick_well_name) AS ep_pick_well_id
, s.ep_pick_well_id AS ep_pick_well_db_id
, s.ep_pick_well_accepted AS clone_accepted
, (s.fp_plate_name || '_' || s.fp_well_name) AS fp_well_id
, s.fp_well_id AS fp_well_db_id
, s.fp_well_accepted AS fp_well_accepted
, (s.piq_plate_name || '_' || s.piq_well_name) AS piq_well_id
, s.piq_well_id AS piq_well_db_id
, s.piq_well_accepted AS piq_well_accepted
FROM summaries s
INNER JOIN cre_project_requests pr ON s.design_gene_id = pr.gene_id
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
AND s.ep_pick_well_id > 0
GROUP by pr.project_id
, pr.htgt_project_id
, s.design_id
, s.design_name
, s.design_type
, s.design_phase
, (s.design_plate_name || '_' || s.design_well_name)
, s.design_gene_id
, s.design_gene_symbol
, (s.int_plate_name || '_' || s.int_well_name)
, s.int_well_id
, s.final_pick_cassette_name
, s.final_pick_cassette_promoter
, s.final_pick_backbone_name
, (s.final_pick_plate_name || '_' || s.final_pick_well_name)
, s.final_pick_well_id
, (s.ep_pick_plate_name || '_' || s.ep_pick_well_name)
, s.ep_pick_well_id
, s.ep_pick_well_accepted
, (s.fp_plate_name || '_' || s.fp_well_name)
, s.fp_well_id
, s.fp_well_accepted
, (s.piq_plate_name || '_' || s.piq_well_name)
, s.piq_well_id
, s.piq_well_accepted
ORDER BY
s.design_gene_id
, (s.final_pick_plate_name || '_' || s.final_pick_well_name)
, (s.ep_pick_plate_name || '_' || s.ep_pick_well_name)
, (s.fp_plate_name || '_' || s.fp_well_name)
, (s.piq_plate_name || '_' || s.piq_well_name)
SQL_END

    return $sql_query;
}

=head2 sql_select_imits_data

creates the sql query for selecting imits Cre Ki gene data

=cut
sub _sql_select_imits_data {
    my ( $self ) = @_;

    my $pipelines_name = 'EUCOMMToolsCre';

	my $sql_query =  <<"SQL_END";
SELECT consortia.name AS consortia_name
, centres.name AS production_centre_name
, genes.marker_symbol AS gene_marker_symbol
, genes.mgi_accession_id AS gene_mgi_id
, mi_plans.id AS plan_db_id
, mi_plans.is_active AS is_plan_active
, mi_plan_priorities.name AS plan_priority
, mi_attempts.id AS mi_attempt_db_id
, targ_rep_es_cells.name AS es_cell_name
, mi_attempt_statuses.code AS status_code
, mi_attempt_statuses.name AS status_name
, mi_attempts.is_active AS is_attempt_active
FROM mi_plans
JOIN genes on genes.id = mi_plans.gene_id
JOIN consortia on consortia.id = mi_plans.consortium_id
JOIN centres on centres.id = mi_plans.production_centre_id
JOIN mi_plan_priorities on mi_plan_priorities.id = mi_plans.priority_id
LEFT OUTER JOIN mi_attempts on mi_attempts.mi_plan_id = mi_plans.id
LEFT OUTER JOIN mi_attempt_statuses on mi_attempt_statuses.id = mi_attempts.status_id
LEFT OUTER JOIN targ_rep_es_cells on targ_rep_es_cells.id = mi_attempts.es_cell_id
LEFT OUTER JOIN targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_es_cells.pipeline_id
WHERE consortia.name = '$pipelines_name'
AND ( CASE 
WHEN targ_rep_es_cells.name IS NOT NULL THEN targ_rep_pipelines.name = '$pipelines_name' 
ELSE targ_rep_es_cells.name IS NULL 
END )
GROUP BY consortia.name
, centres.name
, genes.marker_symbol
, genes.mgi_accession_id
, mi_plans.id
, mi_plans.is_active
, mi_plan_priorities.name
, mi_attempts.id
, targ_rep_es_cells.name
, mi_attempt_statuses.code
, mi_attempt_statuses.name
, mi_attempts.is_active
ORDER BY consortia.name
, centres.name
, genes.marker_symbol
, mi_plans.id
, mi_attempts.id
SQL_END

    return $sql_query;
}

sub _create_sql_select_qc_data {
    my ( $self, $well_id ) = @_;

    my $sql_query = <<"SQL_END";
SELECT well_id, genotyping_result_type_id
FROM well_genotyping_results
WHERE well_id = $well_id
SQL_END

    return $sql_query;
}

1;

__END__
