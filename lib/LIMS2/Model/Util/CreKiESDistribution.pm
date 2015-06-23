package LIMS2::Model::Util::CreKiESDistribution;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CreKiESDistribution::VERSION = '0.326';
}
## use critic


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
use Parse::BooleanLogic;

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

has curr_gene => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has curr_gene_summary => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has summary_gene_data => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
);

has report_data => (
    is  => 'rw',
    isa => 'Maybe[ArrayRef]',
);

has cre_ki_genes => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
    builder    => '_build_cre_ki_genes',
);

has dispatches => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

# kept as array so we check baskets in order
Readonly my @BASKET_NAMES => (
    'unrequested',
    'unrequested_vector_complete',
    'unrequested_has_clones',
    'awaiting_vectors',
    'awaiting_electroporation',
    'awaiting_primary_qc',
    'in_primary_qc',
    'failed_primary_qc_no_rem_clones',
    'awaiting_secondary_qc',
    'in_secondary_qc_1_clone',
    'in_secondary_qc_2_clones',
    'in_secondary_qc_3_clones',
    'in_secondary_qc_4_clones',
    'in_secondary_qc_5_clones',
    'in_secondary_qc_gt5_clones',
    'failed_secondary_qc_1_clone',
    'failed_secondary_qc_2_clones',
    'failed_secondary_qc_3_clones',
    'failed_secondary_qc_4_clones',
    'failed_secondary_qc_5_clones',
    'failed_secondary_qc_gt5_clones',
    'failed_secondary_qc_no_rem_clones',
    'awaiting_mi_attempts',
    'mi_attempts_aborted',
    'mi_attempts_in_progress',
    'mi_attempts_chimeras_obtained',
    'mi_attempts_glt_achieved',
    'missing_from_lims2',
);

# logic strings for determination of baskets
Readonly my %BASKET_LOGIC_STRINGS => {
    'unrequested'                           => 'has_lims2_data AND not_has_imits_data AND not_has_acpt_final_picks AND not_has_clones',
    'unrequested_vector_complete'           => 'has_lims2_data AND not_has_imits_data AND has_acpt_final_picks AND not_has_clones',
    'unrequested_has_clones'                => 'has_lims2_data AND not_has_imits_data AND has_clones',
    'awaiting_vectors'                      => 'has_lims2_data AND has_imits_data AND not_has_acpt_final_picks AND not_has_clones AND not_has_piqs AND not_has_mi_attempts',
    'awaiting_electroporation'              => 'has_lims2_data AND has_imits_data AND has_acpt_final_picks AND not_has_clones AND not_has_piqs AND not_has_mi_attempts',
    'awaiting_primary_qc'                   => 'has_lims2_data AND has_imits_data AND has_clones AND not_has_acpt_clones AND not_has_primary_qc_data AND not_has_piqs AND not_has_mi_attempts',
    'in_primary_qc'                         => 'has_lims2_data AND has_imits_data AND has_clones AND not_has_acpt_clones AND has_clones_missing_primary_qc_data AND not_has_piqs AND not_has_mi_attempts',
    'failed_primary_qc_no_rem_clones'       => 'has_lims2_data AND has_imits_data AND has_clones AND not_has_acpt_clones AND has_all_clones_failed_primary_qc AND not_has_piqs AND not_has_mi_attempts',
    'awaiting_secondary_qc'                 => 'has_lims2_data AND has_imits_data AND has_acpt_clones AND not_has_piqs AND not_has_mi_attempts',
    'in_secondary_qc_1_clone'               => 'has_lims2_data AND has_imits_data AND has_1_acpt_clone AND has_piqs AND not_has_secondary_qc_data AND not_has_mi_attempts',
    'in_secondary_qc_2_clones'              => 'has_lims2_data AND has_imits_data AND has_2_acpt_clones AND has_piqs AND not_has_secondary_qc_data AND not_has_mi_attempts',
    'in_secondary_qc_3_clones'              => 'has_lims2_data AND has_imits_data AND has_3_acpt_clones AND has_piqs AND not_has_secondary_qc_data AND not_has_mi_attempts',
    'in_secondary_qc_4_clones'              => 'has_lims2_data AND has_imits_data AND has_4_acpt_clones AND has_piqs AND not_has_secondary_qc_data AND not_has_mi_attempts',
    'in_secondary_qc_5_clones'              => 'has_lims2_data AND has_imits_data AND has_5_acpt_clones AND has_piqs AND not_has_secondary_qc_data AND not_has_mi_attempts',
    'in_secondary_qc_gt5_clones'            => 'has_lims2_data AND has_imits_data AND has_gt5_acpt_clones AND has_piqs AND not_has_secondary_qc_data AND not_has_mi_attempts',
    'failed_secondary_qc_1_clone'           => 'has_lims2_data AND has_imits_data AND has_clones AND has_piqs AND not_has_acpt_piqs AND has_1_failed_piq AND not_has_mi_attempts',
    'failed_secondary_qc_2_clones'          => 'has_lims2_data AND has_imits_data AND has_clones AND has_piqs AND not_has_acpt_piqs AND has_2_failed_piqs AND not_has_mi_attempts',
    'failed_secondary_qc_3_clones'          => 'has_lims2_data AND has_imits_data AND has_clones AND has_piqs AND not_has_acpt_piqs AND has_3_failed_piqs AND not_has_mi_attempts',
    'failed_secondary_qc_4_clones'          => 'has_lims2_data AND has_imits_data AND has_clones AND has_piqs AND not_has_acpt_piqs AND has_4_failed_piqs AND not_has_mi_attempts',
    'failed_secondary_qc_5_clones'          => 'has_lims2_data AND has_imits_data AND has_clones AND has_piqs AND not_has_acpt_piqs AND has_5_failed_piqs AND not_has_mi_attempts',
    'failed_secondary_qc_gt5_clones'        => 'has_lims2_data AND has_imits_data AND has_clones AND has_piqs AND not_has_acpt_piqs AND has_gt5_failed_piqs AND not_has_mi_attempts',
    'failed_secondary_qc_no_rem_clones'     => 'has_lims2_data AND has_imits_data AND has_clones AND has_piqs AND not_has_acpt_piqs AND has_all_clones_failed_secondary_qc AND not_has_mi_attempts',
    'awaiting_mi_attempts'                  => 'has_lims2_data AND has_imits_data AND has_piqs AND has_acpt_piqs AND not_has_mi_attempts',
    'mi_attempts_aborted'                   => 'has_lims2_data AND has_imits_data AND has_mi_attempts AND not_has_actv_mi_attempts AND has_aborted_mi_attempts',
    'mi_attempts_in_progress'               => 'has_lims2_data AND has_imits_data AND has_mi_attempts AND has_actv_mi_attempts AND not_has_actv_mi_attempts_type_chr AND not_has_actv_mi_attempts_type_gtc',
    'mi_attempts_chimeras_obtained'         => 'has_lims2_data AND has_imits_data AND has_mi_attempts AND has_actv_mi_attempts AND has_actv_mi_attempts_type_chr AND not_has_actv_mi_attempts_type_gtc',
    'mi_attempts_glt_achieved'              => 'has_lims2_data AND has_imits_data AND has_mi_attempts AND has_actv_mi_attempts AND has_actv_mi_attempts_type_gtc',
    'missing_from_lims2'                    => 'not_has_lims2_data AND has_imits_data',
};

sub BUILD {
    my ( $self ) = @_;
    return;
}

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

    # add any missing gene symbols where not in LIMS2 or iMits
    $self->_fetch_gene_symbols_where_missing( $cre_ki_genes );

    # print ( Dumper ( $cre_ki_genes ) );

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

=head2 _build_dispatches

build dispatches table for determining gene basket

=cut
sub _build_dispatches {
    my ( $self ) = @_;

    my $dispatches = {
        'has_lims2_data'                         => sub { $self->_has_lims2_data },
        'not_has_lims2_data'                     => sub { !$self->_has_lims2_data },
        'has_imits_data'                         => sub { $self->_has_imits_data },
        'not_has_imits_data'                     => sub { !$self->_has_imits_data },

        'has_acpt_final_picks'                   => sub { $self->_has_acpt_final_picks },
        'not_has_acpt_final_picks'               => sub { !$self->_has_acpt_final_picks },

        'has_clones'                             => sub { $self->_has_clones },
        'not_has_clones'                         => sub { !$self->_has_clones },
        'has_primary_qc_data'                    => sub { $self->_has_primary_qc_data },
        'not_has_primary_qc_data'                => sub { !$self->_has_primary_qc_data },
        'has_clones_missing_primary_qc_data'     => sub { $self->_has_clones_missing_primary_qc_data },
        'has_all_clones_failed_primary_qc'       => sub { $self->_has_all_clones_failed_primary_qc },

        'has_acpt_clones'                        => sub { $self->_has_acpt_clones },
        'not_has_acpt_clones'                    => sub { !$self->_has_acpt_clones },
        'has_1_acpt_clone'                       => sub { $self->_has_1_acpt_clone },
        'has_2_acpt_clones'                      => sub { $self->_has_2_acpt_clones },
        'has_3_acpt_clones'                      => sub { $self->_has_3_acpt_clones },
        'has_4_acpt_clones'                      => sub { $self->_has_4_acpt_clones },
        'has_5_acpt_clones'                      => sub { $self->_has_5_acpt_clones },
        'has_gt5_acpt_clones'                    => sub { $self->_has_gt5_acpt_clones },

        'has_piqs'                               => sub { $self->_has_piqs },
        'not_has_piqs'                           => sub { !$self->_has_piqs },
        'has_acpt_piqs'                          => sub { $self->_has_acpt_piqs },
        'not_has_acpt_piqs'                      => sub { !$self->_has_acpt_piqs },
        'has_secondary_qc_data'                  => sub { $self->_has_secondary_qc_data },
        'not_has_secondary_qc_data'              => sub { !$self->_has_secondary_qc_data },

        'has_1_failed_piq'                       => sub { $self->_has_1_failed_piq },
        'has_2_failed_piqs'                      => sub { $self->_has_2_failed_piqs },
        'has_3_failed_piqs'                      => sub { $self->_has_3_failed_piqs },
        'has_4_failed_piqs'                      => sub { $self->_has_4_failed_piqs },
        'has_5_failed_piqs'                      => sub { $self->_has_5_failed_piqs },
        'has_gt5_failed_piqs'                    => sub { $self->_has_gt5_failed_piqs },

        'has_all_clones_failed_secondary_qc'     => sub { $self->_has_all_clones_failed_secondary_qc },

        'has_actv_mi_plans'                      => sub { $self->_has_actv_mi_plans },
        'not_has_actv_mi_plans'                  => sub { !$self->_has_actv_mi_plans },
        'has_aborted_mi_attempts'                => sub { $self->_has_has_aborted_mi_attempts },
        'has_mi_attempts'                        => sub { $self->_has_mi_attempts },
        'not_has_mi_attempts'                    => sub { !$self->_has_mi_attempts },
        'has_actv_mi_attempts'                   => sub { $self->_has_actv_mi_attempts },
        'not_has_actv_mi_attempts'               => sub { !$self->_has_actv_mi_attempts },
        'has_actv_mi_attempts_type_chr'          => sub { $self->_has_actv_mi_attempts_type_chr },
        'not_has_actv_mi_attempts_type_chr'      => sub { !$self->_has_actv_mi_attempts_type_chr },
        'has_actv_mi_attempts_type_gtc'          => sub { $self->_has_actv_mi_attempts_type_gtc },
        'not_has_actv_mi_attempts_type_gtc'      => sub { !$self->_has_actv_mi_attempts_type_gtc },

        'unrequested'                            => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_unrequested' }++; },
        'unrequested_vector_complete'            => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_unrequested_vector_complete' }++; },
        'unrequested_has_clones'                 => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_unrequested_has_clones' }++; },
        'awaiting_vectors'                       => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_awaiting_vectors' }++; },
        'awaiting_electroporation'               => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_awaiting_electroporation' }++; },
        'awaiting_primary_qc'                    => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_awaiting_primary_qc' }++; },
        'in_primary_qc'                          => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_in_primary_qc' }++; },
        'failed_primary_qc_no_rem_clones'        => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_failed_primary_qc_no_rem_clones' }++; },
        'awaiting_secondary_qc'                  => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_awaiting_secondary_qc' }++; },
        'in_secondary_qc_1_clone'                => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_in_secondary_qc_1_clone' }++; },
        'in_secondary_qc_2_clones'               => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_in_secondary_qc_2_clones' }++; },
        'in_secondary_qc_3_clones'               => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_in_secondary_qc_3_clones' }++; },
        'in_secondary_qc_4_clones'               => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_in_secondary_qc_4_clones' }++; },
        'in_secondary_qc_5_clones'               => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_in_secondary_qc_5_clones' }++; },
        'in_secondary_qc_gt5_clones'             => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_in_secondary_qc_gt5_clones' }++; },
        'failed_secondary_qc_1_clone'            => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_failed_secondary_qc_1_clone' }++; },
        'failed_secondary_qc_2_clones'           => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_failed_secondary_qc_2_clones' }++; },
        'failed_secondary_qc_3_clones'           => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_failed_secondary_qc_3_clones' }++; },
        'failed_secondary_qc_4_clones'           => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_failed_secondary_qc_4_clones' }++; },
        'failed_secondary_qc_5_clones'           => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_failed_secondary_qc_5_clones' }++; },
        'failed_secondary_qc_gt5_clones'         => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_failed_secondary_qc_gt5_clones' }++; },
        'failed_secondary_qc_no_rem_clones'      => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_failed_secondary_qc_no_rem_clones' }++; },
        'awaiting_mi_attempts'                   => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_awaiting_mi_attempts' }++; },
        'mi_attempts_in_progress'                => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_mi_attempts_in_progress' }++; },
        'mi_attempts_aborted'                    => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_mi_attempts_aborted' }++; },
        'mi_attempts_chimeras_obtained'          => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_mi_attempts_chimeras_obtained' }++; },
        'mi_attempts_glt_achieved'               => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_mi_attempts_glt_achieved' }++; },
        'unrecognised_type'                      => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_unrecognised_type' }++; },
        'missing_from_lims2'                     => sub { my $centre_name = shift; $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_missing_from_lims2' }++; },
    };

    return $dispatches;
}

=head2 generate_report_data

generate report data for overview summary report

=cut
sub generate_summary_report_data {
    my ( $self ) = @_;
    my @report_data = ();
    $self->report_data( undef );

    $self->_summarise_cre_ki_data();

    # Transfer the information for each production centre into the report array, one row per production centre
    # NB. includes 'Unassigned' and 'Multiple Centres'

    #need to sort the centres in an order, multis and unassigned last
    my @sorted_overall_production_centres = sort {
        if ($a eq 'Unassigned' || ( $a eq 'Multiple Centres' && $b ne 'Unassigned' ) ) {
            return 1;
        }
        elsif ($b eq 'Unassigned' || ( $b eq 'Multiple Centres' && $a ne 'Unassigned' ) ) {
            return -1;
        }
        else {
            return $a cmp $b;
        }
    } keys %{ $self->cre_ki_genes->{ 'overall_production_centres' } };

    # build the row for the report
    foreach my $prod_centre_name ( @sorted_overall_production_centres ) {
        $self->_generate_summary_report_row( $prod_centre_name, \@report_data );
    }

    $self->report_data( \@report_data );

    return;
}

=head2 _generate_summary_report_row

generate row for summary report

=cut
sub _generate_summary_report_row {
    my ( $self, $prod_centre_name, $report_data ) = @_;

    my $curr_counter_set = \%{ $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $prod_centre_name } };

    # don't use the row if it's empty
    unless ( $curr_counter_set->{ 'count_genes_total' } == 0 ) {

        # fetch counts for current basket
        my @curr_basket_counts;
        foreach my $basket_name ( @BASKET_NAMES ) {
            push ( @curr_basket_counts, $curr_counter_set->{ 'count_'.$basket_name } );
        }

        # add row into report data array
        push @{ $report_data }, [
            $prod_centre_name,
            $curr_counter_set->{ 'count_genes_total' },
            @curr_basket_counts,
            $curr_counter_set->{ 'count_unrecognised_type' },
        ];
    }

    return;
}

=head2 generate_genes_report_data

generate report data for genes version of report

=cut
sub generate_genes_report_data {
    my ( $self ) = @_;
    my @report_data = ();
    $self->report_data( undef );

    $self->_summarise_cre_ki_data();

    #need to sort the centres in an order, multis and unassigned last
    my @sorted_overall_production_centres = sort {
        if ($a eq 'Unassigned' || ( $a eq 'Multiple Centres' && $b ne 'Unassigned' ) ) {
            return 1;
        }
        elsif ($b eq 'Unassigned' || ( $b eq 'Multiple Centres' && $a ne 'Unassigned' ) ) {
            return -1;
        }
        else {
            return $a cmp $b;
        }
    } keys %{ $self->cre_ki_genes->{ 'overall_production_centres' } };

    # build the row for the report
    foreach my $prod_centre_name ( @sorted_overall_production_centres ) {
        $self->_generate_gene_report_row( $prod_centre_name, \@report_data );
    }

    $self->report_data( \@report_data );

    return;
}

=head2 _generate_gene_report_row

generate row for gene report

=cut
sub _generate_gene_report_row {
    my ( $self, $prod_centre_name, $report_data ) = @_;

    my @baskets = ( @BASKET_NAMES );
    push ( @baskets, 'unrecognised' );

    # for each set of genes create the row
    foreach my $basket_name ( @baskets ) {
        my $curr_basket = \%{ $self->summary_gene_data->{ $prod_centre_name }->{ $basket_name } };

        # skip if no genes in this partition
        unless ( defined $curr_basket->{ 'count_genes' } ) { next; }

        # print "$prod_centre_name $basket_name genes count: ".$curr_basket->{ 'count_genes' }."\n";

        unless ( ( $curr_basket->{ 'count_genes' } ) > 0 ) { next; }

        # add row to report array for each gene
        foreach my $mgi_gene_id ( sort keys %{ $curr_basket->{ 'genes' } } ) {
            my $curr_gene = $self->cre_ki_genes->{ 'genes' }->{ $mgi_gene_id };
            push @{ $report_data }, [
                $prod_centre_name,
                $curr_gene->{ 'production_centre_priorities_list' },
                $basket_name,
                $curr_basket->{ 'genes' }->{ $mgi_gene_id }->{ 'mgi_accession_id' },
                $curr_gene->{ 'marker_symbol' },
                $curr_gene->{ 'accepted_final_pick_wells_list' },
                $curr_gene->{ 'accepted_ep_pick_wells_list' },
                $curr_gene->{ 'failed_ep_pick_wells_list' },
                $curr_gene->{ 'accepted_clone_secondary_qc_passed_list' },
                $curr_gene->{ 'accepted_clone_secondary_qc_failed_list' },
                $curr_gene->{ 'mi_attempts_abt_clones_list' },
                $curr_gene->{ 'mi_attempts_mip_clones_list' },
                $curr_gene->{ 'mi_attempts_chr_clones_list' },
                $curr_gene->{ 'mi_attempts_gtc_clones_list' },
            ];
        }
    }

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
        my $mgi_gene_id = $cre_proj_row->{ 'mgi_gene_id' };
        $cre_ki_genes->{ 'genes' }->{ $mgi_gene_id }->{ 'lims2_project_db_id' } = $cre_proj_row->{ 'lims2_project_db_id' };

        # initialise gene counters
        my $curr_gene_hash = \% { $cre_ki_genes->{ 'genes' }->{ $mgi_gene_id } };
        $self->_initialise_curr_gene_lims2_counters($curr_gene_hash);
        $curr_gene_hash->{ 'has_lims2_data' } = 1;
        $self->_initialise_curr_gene_imits_counters($curr_gene_hash);
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

    # transfer information from the flat sql result into the main genes hash
    foreach my $row ( @{ $sql_result_lims2_summary_data } ) {
        my $mgi_gene_id = $row->{ 'design_gene_id' };
        if ( defined $row->{ 'design_gene_symbol' } ) { $cre_ki_genes->{ 'genes' }->{ $mgi_gene_id }->{ 'marker_symbol' } = $row->{ 'design_gene_symbol' } };

        # add vector information
        if ( defined $row->{ 'final_pick_well_ident' } ) {
            my $final_pick_well_ident = $row->{ 'final_pick_well_ident' };
            $cre_ki_genes->{ 'genes' }->{ $mgi_gene_id }->{ 'vectors' }->{ $final_pick_well_ident }->{ 'final_pick_well_db_id' }    = $row->{ 'final_pick_well_db_id' };
            $cre_ki_genes->{ 'genes' }->{ $mgi_gene_id }->{ 'vectors' }->{ $final_pick_well_ident }->{ 'final_pick_well_accepted' } = $row->{ 'final_pick_well_accepted' };
        }
        # add clone information
        if( defined $row->{ 'ep_pick_well_ident' } ) {
            my $ep_pick_well_ident = $row->{ 'ep_pick_well_ident' };
            $cre_ki_genes->{ 'genes' }->{ $mgi_gene_id }->{ 'clones' }->{ $ep_pick_well_ident }->{ 'ep_pick_well_db_id' } = $row->{ 'ep_pick_well_db_id' };

            my $ep_pick_well = \% { $cre_ki_genes->{ 'genes' }->{ $mgi_gene_id }->{ 'clones' }->{ $ep_pick_well_ident } };
            $ep_pick_well->{ 'clone_accepted' }          = $row->{ 'clone_accepted' };
            $ep_pick_well->{ 'final_pick_well_ident' }   = $row->{ 'final_pick_well_ident' };
            $ep_pick_well->{ 'vector_cassette_name' }    = $row->{ 'vector_cassette_name' };
            $ep_pick_well->{ 'vector_backbone_name' }    = $row->{ 'vector_backbone_name' };

            # add freezer wells information
            if( defined $row->{ 'fp_well_ident' } ) {
                my $fp_well_ident = $row->{ 'fp_well_ident' };
                $ep_pick_well->{ 'freezer_wells' }->{ $fp_well_ident }->{ 'fp_well_accepted' } = $row->{ 'fp_well_accepted' };
                my $fp_well = \% { $ep_pick_well->{ 'freezer_wells' }->{ $fp_well_ident } };

                # add piq wells information
                if( defined $row->{ 'piq_well_ident' } ) {
                    my $piq_well_ident = $row->{ 'piq_well_ident' };
                    $fp_well->{ 'piq_wells' }->{ $piq_well_ident }->{ 'piq_well_accepted' } = $row->{ 'piq_well_accepted' };

                    my $piq_well = \% { $fp_well->{ 'piq_wells' }->{ $piq_well_ident } };
                    if ( defined $row->{ 'piq_well_db_id' } ) {
                        $piq_well->{ 'piq_well_db_id' } = $row->{ 'piq_well_db_id' };
                    }
                }
            }
        }
    }

    return;
}

=head2 add_lims2_counts

cycle through hash adding LIMS2 counts

=cut
sub _add_lims2_counts {
    my ( $self, $cre_ki_genes ) = @_;

    foreach my $mgi_gene_id ( sort keys %{ $cre_ki_genes->{ 'genes' } } ) {
        my $curr_gene_hash = \% { $cre_ki_genes->{ 'genes' }->{ $mgi_gene_id } };

        $self->_initialise_current_gene_well_ident_lists( $curr_gene_hash );

        if ( exists $curr_gene_hash->{ 'vectors' } ) {
            # add vector counts
            $self->_add_current_gene_final_pick_counts( $curr_gene_hash );
        }

        unless ( exists $curr_gene_hash->{ 'clones' } ) { next; }

        my $curr_gene_clones_hash = \% { $curr_gene_hash->{ 'clones' } };

        # cycle through the ep pick clones
        foreach my $clone_well_ident ( sort keys %{ $curr_gene_clones_hash } ) {
            $curr_gene_hash->{ 'count_lims2_ep_pick_wells_total' }++;

            # check for well accepted
            my $curr_clone_hash = \% { $curr_gene_clones_hash->{ $clone_well_ident } };
            if ( $curr_clone_hash->{ 'clone_accepted' } == 1 ) {
                push ( @{ $curr_gene_hash->{ 'accepted_ep_pick_wells_array' } }, $clone_well_ident );
                $curr_gene_hash->{ 'count_lims2_ep_pick_wells_accepted' }++;
            }

            # check for QC data
            $curr_clone_hash->{ 'has_qc_data' } = $self->_well_has_qc_data( $curr_clone_hash->{ 'ep_pick_well_db_id' } );
            if ( $curr_clone_hash->{ 'has_qc_data' } ) {
                $curr_gene_hash->{ 'count_lims2_ep_pick_wells_with_qc_data' }++;

                # failed if NOT accepted and has qc data
                if ( $curr_clone_hash->{ 'clone_accepted' } == 0 ) {
                    push ( @{ $curr_gene_hash->{ 'failed_ep_pick_wells_array' } }, $clone_well_ident );
                    $curr_gene_hash->{ 'count_lims2_ep_pick_wells_failed' }++;
                }
            }

             # cycle through all the freezer wells for each accepted clone (if any)
            foreach my $fp_well_ident ( sort keys %{ $curr_clone_hash->{ 'freezer_wells' } } ) {
                $curr_gene_hash->{ 'count_lims2_freezer_wells' }++;
                push ( @{ $curr_gene_hash->{ 'fp_wells_array' } }, $fp_well_ident );
                my $curr_fp_well_hash = \%{ $curr_clone_hash->{ 'freezer_wells' }->{ $fp_well_ident } };

                unless ( exists $curr_fp_well_hash->{ 'piq_wells' } ) { next; }
                # add PIQ counts
                $self->_add_current_gene_piq_counts( $curr_gene_hash, $clone_well_ident, $curr_fp_well_hash );
            }
        }

        # add lists of well ids into gene hash
        $self->_create_current_gene_well_ident_lists( $curr_gene_hash );
    }

    return;
}

=head2 _add_current_gene_final_pick_counts

add final pick counts

=cut
sub _add_current_gene_final_pick_counts {
    my ( $self, $curr_gene_hash ) = @_;

    my $curr_gene_hash_vectors = \% { $curr_gene_hash->{ 'vectors' } };
    # cycle through the final pick vectors
    foreach my $vector_well_ident ( sort keys %{ $curr_gene_hash_vectors } ) {
        $curr_gene_hash->{ 'count_lims2_final_picks_total' }++;
        if ( $curr_gene_hash_vectors->{ $vector_well_ident }->{ 'final_pick_well_accepted' } == 1 ) {
            push ( @{ $curr_gene_hash->{ 'accepted_final_pick_wells_array' } }, $vector_well_ident );
            $curr_gene_hash->{ 'count_lims2_final_picks_accepted' }++;
        }
    }

    return;

}

=head2 _add_current_gene_piq_counts

add piq counts

=cut
sub _add_current_gene_piq_counts {
    my ( $self, $curr_gene_hash, $clone_well_ident, $curr_fp_well_hash ) = @_;

    my $curr_gene_piqs_hash = \% { $curr_fp_well_hash->{ 'piq_wells' } };
    # cycle through all the PIQ wells for each freezer well (if any)
    foreach my $piq_well_ident ( sort keys %{ $curr_gene_piqs_hash } ) {
        $curr_gene_hash->{ 'count_lims2_piq_wells_total' }++;
        push ( @{ $curr_gene_hash->{ 'piq_wells_array' } }, $piq_well_ident );

        my $curr_piq_well_hash = \% { $curr_gene_piqs_hash->{ $piq_well_ident } };
        # check for well accepted
        if ( $curr_piq_well_hash->{ 'piq_well_accepted' } == 1 ) {
            push ( @{ $curr_gene_hash->{ 'accepted_clone_secondary_qc_passed_array' } }, $clone_well_ident );
            $curr_gene_hash->{ 'count_lims2_piq_wells_accepted' }++;
        }

        # check for PIQ QC data
        $curr_piq_well_hash->{ 'has_qc_data' } = $self->_well_has_qc_data( $curr_piq_well_hash->{ 'piq_well_db_id' } );
        if ( $curr_piq_well_hash->{ 'has_qc_data' } ) {
            $curr_gene_hash->{ 'count_lims2_piq_wells_with_qc_data' }++;

            # failed if NOT accepted and PIQ has qc data
            if ( $curr_piq_well_hash->{ 'piq_well_accepted' } == 0 ) {
                push ( @{ $curr_gene_hash->{ 'accepted_clone_secondary_qc_failed_array' } }, $clone_well_ident );
                $curr_gene_hash->{ 'count_lims2_piq_wells_failed' }++;
            }
        }
    }

    return;
}

=head2 _initialise_current_gene_well_ident_lists

initialise various well ident strings for current gene

=cut
sub _initialise_current_gene_well_ident_lists {
    my ( $self, $curr_gene_hash ) = @_;

    # add lists of well ids into gene hash
    $curr_gene_hash->{ 'accepted_final_pick_wells_array' }          = [];
    $curr_gene_hash->{ 'accepted_ep_pick_wells_array' }             = [];
    $curr_gene_hash->{ 'failed_ep_pick_wells_array' }               = [];
    $curr_gene_hash->{ 'fp_wells_array' }                           = [];
    $curr_gene_hash->{ 'piq_wells_array' }                          = [];
    $curr_gene_hash->{ 'accepted_clone_secondary_qc_passed_array' } = [];
    $curr_gene_hash->{ 'accepted_clone_secondary_qc_failed_array' } = [];

    return;
}

=head2 _create_current_gene_well_ident_lists

create various well ident strings for current gene

=cut
sub _create_current_gene_well_ident_lists {
    my ( $self, $curr_gene_hash ) = @_;

    # add lists of well ids into gene hash
    $curr_gene_hash->{ 'accepted_final_pick_wells_list' }          = join ( ' ', @{ $curr_gene_hash->{ 'accepted_final_pick_wells_array' } } );
    $curr_gene_hash->{ 'accepted_ep_pick_wells_list' }             = join ( ' ', @{ $curr_gene_hash->{ 'accepted_ep_pick_wells_array' } } );
    $curr_gene_hash->{ 'failed_ep_pick_wells_list' }               = join ( ' ', @{ $curr_gene_hash->{ 'failed_ep_pick_wells_array' } } );
    $curr_gene_hash->{ 'fp_wells_list' }                           = join ( ' ', @{ $curr_gene_hash->{ 'fp_wells_array' } } );
    $curr_gene_hash->{ 'piq_wells_list' }                          = join ( ' ', @{ $curr_gene_hash->{ 'piq_wells_array' } } );
    $curr_gene_hash->{ 'accepted_clone_secondary_qc_passed_list' } = join ( ' ', @{ $curr_gene_hash->{ 'accepted_clone_secondary_qc_passed_array' } } );
    $curr_gene_hash->{ 'accepted_clone_secondary_qc_failed_list' } = join ( ' ', @{ $curr_gene_hash->{ 'accepted_clone_secondary_qc_failed_array' } } );

    return;
}

=head2 _initialise_curr_gene_lims2_and_imits_counters

initialise the lims2 and imits counters

=cut
sub _initialise_curr_gene_lims2_counters {
    my ( $self, $curr_gene ) = @_;

    # initialise the lims2 counters
    $curr_gene->{ 'has_lims2_data' }                            = 0;

    $curr_gene->{ 'count_lims2_final_picks_total' }             = 0;
    $curr_gene->{ 'count_lims2_final_picks_accepted' }          = 0;

    $curr_gene->{ 'count_lims2_ep_pick_wells_total' }           = 0;
    $curr_gene->{ 'count_lims2_ep_pick_wells_accepted' }        = 0;
    $curr_gene->{ 'count_lims2_ep_pick_wells_failed' }          = 0;
    $curr_gene->{ 'count_lims2_ep_pick_wells_with_qc_data' }    = 0;

    $curr_gene->{ 'count_lims2_freezer_wells' }                 = 0;

    $curr_gene->{ 'count_lims2_piq_wells_total' }               = 0;
    $curr_gene->{ 'count_lims2_piq_wells_accepted' }            = 0;
    $curr_gene->{ 'count_lims2_piq_wells_failed' }              = 0;
    $curr_gene->{ 'count_lims2_piq_wells_with_qc_data' }        = 0;

    return;
}

sub _initialise_curr_gene_imits_counters {
    my ( $self, $curr_gene ) = @_;
    # initialise the imits counters
    $curr_gene->{ 'has_imits_data' }                            = 0;

    # ( 0 = unassigned, 1 = row for centre, 2+ = multi-centre )
    $curr_gene->{ 'count_imits_production_centres' }            = 0;

    $curr_gene->{ 'count_imits_mi_plans_total' }                = 0;
    $curr_gene->{ 'count_imits_mi_plans_active' }               = 0;

    $curr_gene->{ 'count_imits_mi_attempts_total' }             = 0;
    $curr_gene->{ 'count_imits_mi_attempts_active' }            = 0;
    $curr_gene->{ 'count_imits_mi_attempts_glt_achieved' }      = 0;
    $curr_gene->{ 'count_imits_mi_attempts_chimeras_obtained' } = 0;
    $curr_gene->{ 'count_imits_mi_attempts_in_progress' }       = 0;
    $curr_gene->{ 'count_imits_mi_attempts_aborted' }           = 0;

    return;
}

=head2 fetch_imits_cre_ki_data

select Cre Ki data by gene from imits database

=cut
sub _fetch_imits_cre_ki_data {
    my ( $self ) = @_;

    my $dbh = $self->_connect_to_imits();

    my $sql = _sql_select_imits_data();

    my $imits_results = $dbh->selectall_arrayref($sql, { Slice => {} } );

    # reformat the iMits results into a new hash
    my $imits_data = {};

    $imits_data->{ 'overall_production_centres' } = { 'Unassigned' => 1, 'Multiple Centres' => 1, };

    foreach my $imits_row ( @{ $imits_results } ) {
        my $row_gene_id = $imits_row->{ 'mgi_accession_id' };
        if ( defined $imits_row->{ 'marker_symbol' } ) { $imits_data->{ 'genes' }->{ $row_gene_id }->{ 'marker_symbol' } = $imits_row->{ 'marker_symbol' } };

        my $imits_gene_hash = \%{ $imits_data->{ 'genes' }->{ $row_gene_id } };
        my $row_plan_db_id = $imits_row->{ 'plan_db_id' };
        # will always have a plan of what will be attempted, need to know if plan(s) active
        $imits_gene_hash->{ 'mi_plans' }->{ $row_plan_db_id }->{ 'is_plan_active' } = $imits_row->{ 'is_plan_active' };

        my $imits_data_plan = \%{ $imits_gene_hash->{ 'mi_plans' }->{ $row_plan_db_id } };
        my $plan_prod_centre_name = $imits_row->{ 'production_centre_name' };
        my $plan_priority         = $imits_row->{ 'plan_priority' };
        $imits_data_plan->{ 'production_centre_name' } = $plan_prod_centre_name;
        $imits_data_plan->{ 'plan_priority' }          = $plan_priority;

        # build the list of unique production centres
        $imits_data->{ 'overall_production_centres' }->{ $plan_prod_centre_name }                           = 1;
        $imits_gene_hash->{ 'production_centres' }->{ $plan_prod_centre_name }                              = 1;
        $imits_gene_hash->{ 'production_centre_priorities' }->{ $plan_prod_centre_name.'-'.$plan_priority } = 1;

        # optionally will there may be physical attempts at creating the mouse, add these to hash
        if ( defined $imits_row->{ 'mi_attempt_db_id' } && defined $imits_row->{ 'es_cell_name' } ) {
            my $row_mi_attempt_db_id = $imits_row->{ 'mi_attempt_db_id' };
            my $row_es_cell_name     = $imits_row->{ 'es_cell_name' };

            $imits_gene_hash->{ 'clones' }->{ $row_es_cell_name }->{ 'mi_attempts' }->{ $row_mi_attempt_db_id }->{ 'consortia_name' } = $imits_row->{ 'consortia_name' };

            my $imits_data_mi_attempt = \%{ $imits_gene_hash->{ 'clones' }->{ $row_es_cell_name }->{ 'mi_attempts' }->{ $row_mi_attempt_db_id } };
            $imits_data_mi_attempt->{ 'is_attempt_active' }       = $imits_row->{ 'is_attempt_active' };
            $imits_data_mi_attempt->{ 'plan_db_id' }              = $imits_row->{ 'plan_db_id' };
            $imits_data_mi_attempt->{ 'colony_name' }             = $imits_row->{ 'colony_name' };
            $imits_data_mi_attempt->{ 'plan_priority' }           = $plan_priority;
            $imits_data_mi_attempt->{ 'production_centre_name' }  = $plan_prod_centre_name;
            $imits_data_mi_attempt->{ 'status_code' }             = $imits_row->{ 'status_code' };
            $imits_data_mi_attempt->{ 'status_name' }             = $imits_row->{ 'status_name' };
        }
    }

    return $imits_data;
}

=head2 _connect_to_imits

create connection to imits

=cut
sub _connect_to_imits {
    my ( $self ) = @_;

    my $dbname   = $self->imits_config->{ 'imits_connection' }->{ 'dbname' };
    my $host     = $self->imits_config->{ 'imits_connection' }->{ 'host' };
    my $port     = $self->imits_config->{ 'imits_connection' }->{ 'port' };
    my $username = $self->imits_config->{ 'imits_connection' }->{ 'username' };
    my $password = $self->imits_config->{ 'imits_connection' }->{ 'password' };

    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port;", "$username", "$password");

    return $dbh;
}

=head2 fuse_lims2_and_imits_data

join together the LIMS2 and imits gene data

=cut
sub _fuse_lims2_and_imits_data {
    my ( $self, $cre_ki_genes, $imits_cre_ki_data  ) = @_;

    $cre_ki_genes->{ 'overall_production_centres' } = $imits_cre_ki_data->{ 'overall_production_centres' };

    # Now we can fuse the two reports, by merging the output from (lims2) onto the output from (iMits) by gene.
    foreach my $imits_gene_id ( sort keys %{ $imits_cre_ki_data->{ 'genes' } } ) {

        # check for whether lims2 knows about this gene, if not set base counters
        unless ( exists $cre_ki_genes->{ 'genes' }->{ $imits_gene_id } ) {
            $self->_initialise_cre_gene_where_only_in_imits( $cre_ki_genes, $imits_gene_id );
        }

        my $curr_gene_hash   = \%{ $cre_ki_genes->{ 'genes' }->{ $imits_gene_id } };
        my $imits_gene_hash  = \%{ $imits_cre_ki_data->{ 'genes' }->{ $imits_gene_id } };

        # add imits data into the lims2 hash at clone level, adding counters at gene level
        $curr_gene_hash->{ 'has_imits_data' } = 1;

        # check marker symbol
        unless ( defined $curr_gene_hash->{ 'marker_symbol' } ) {
            if ( defined $imits_gene_hash->{ 'marker_symbol' } ) {
                $curr_gene_hash->{ 'marker_symbol' } = $imits_gene_hash->{ 'marker_symbol' };
            }
        };

        # if gene has mi_plans
        if ( exists $imits_gene_hash->{ 'mi_plans' } ) {
            $self->_fuse_imits_plan_data( $curr_gene_hash, $imits_gene_hash );
        }

        # create text for display from production centres hash
        $curr_gene_hash->{ 'production_centres' }           = $imits_gene_hash->{ 'production_centres' };
        $curr_gene_hash->{ 'production_centre_priorities' } = $imits_gene_hash->{ 'production_centre_priorities' };
        $self->_create_production_centres_display_lists( $curr_gene_hash );

        my @mi_attempt_gtc_clones_array;
        my @mi_attempt_chr_clones_array;
        my @mi_attempt_mip_clones_array;
        my @mi_attempt_abt_clones_array;

        # for each clone
        foreach my $imits_clone_id ( sort keys %{ $imits_gene_hash->{ 'clones' } } ) {
            my $imits_clone_hash = \%{ $imits_gene_hash->{ 'clones' }->{ $imits_clone_id } };
            # check if clone has mi attempts
            if ( exists $imits_clone_hash->{ 'mi_attempts' } ) {
                # copy mi_attempts across
                $curr_gene_hash->{ 'clones' }->{ $imits_clone_id }->{ 'mi_attempts' } = $imits_clone_hash->{ 'mi_attempts' };
                # check each attempt
                foreach my $mi_attempt_db_id ( sort keys %{ $imits_clone_hash->{ 'mi_attempts' } } ) {
                    $curr_gene_hash->{ 'count_imits_mi_attempts_total' }++;
                    my $imits_mi_attempt                  = \%{ $imits_clone_hash->{ 'mi_attempts' }->{ $mi_attempt_db_id } };
                    my $curr_mi_attempt_status            = $imits_mi_attempt->{ 'status_code' } // '';
                    my $curr_mi_attempt_is_active         = $imits_mi_attempt->{ 'is_attempt_active' } // '';
                    my $curr_mi_attempt_prod_centre       = $imits_mi_attempt->{ 'production_centre_name' } // '';
                    my $curr_mi_attempt_colony_name       = $imits_mi_attempt->{ 'colony_name' } // '';

                    # to be active attempt must be active and not aborted
                    if ( $curr_mi_attempt_status eq 'gtc' && $curr_mi_attempt_is_active) {
                        push ( @mi_attempt_gtc_clones_array, ( $curr_mi_attempt_prod_centre.'-'.$imits_clone_id.'--'.$curr_mi_attempt_colony_name ) );
                        $curr_gene_hash->{ 'count_imits_mi_attempts_glt_achieved' }++;
                        $curr_gene_hash->{ 'count_imits_mi_attempts_active' }++;
                    }
                    elsif ( $curr_mi_attempt_status eq 'chr' && $curr_mi_attempt_is_active ) {
                        push ( @mi_attempt_chr_clones_array, ( $curr_mi_attempt_prod_centre.'-'.$imits_clone_id.'--'.$curr_mi_attempt_colony_name ) );
                        $curr_gene_hash->{ 'count_imits_mi_attempts_chimeras_obtained' }++;
                        $curr_gene_hash->{ 'count_imits_mi_attempts_active' }++;
                    }
                    elsif ( $curr_mi_attempt_status eq 'mip' && $curr_mi_attempt_is_active ) {
                        push ( @mi_attempt_mip_clones_array, ( $curr_mi_attempt_prod_centre.'-'.$imits_clone_id.'--'.$curr_mi_attempt_colony_name ) );
                        $curr_gene_hash->{ 'count_imits_mi_attempts_in_progress' }++;
                        $curr_gene_hash->{ 'count_imits_mi_attempts_active' }++;
                    }
                    else {
                        # NB. counting all 'abt' status or 'inactive' attempts as aborted
                        push ( @mi_attempt_abt_clones_array, ( $curr_mi_attempt_prod_centre.'-'.$imits_clone_id.'--'.$curr_mi_attempt_colony_name ) );
                        $curr_gene_hash->{ 'count_imits_mi_attempts_aborted' }++;
                    }
                }
            }
        }

        if ( @mi_attempt_gtc_clones_array ) { $curr_gene_hash->{ 'mi_attempts_gtc_clones_list' }    = join ( ' ', @mi_attempt_gtc_clones_array ) };
        if ( @mi_attempt_chr_clones_array ) { $curr_gene_hash->{ 'mi_attempts_chr_clones_list' }    = join ( ' ', @mi_attempt_chr_clones_array ) };
        if ( @mi_attempt_mip_clones_array ) { $curr_gene_hash->{ 'mi_attempts_mip_clones_list' }    = join ( ' ', @mi_attempt_mip_clones_array ) };
        if ( @mi_attempt_abt_clones_array ) { $curr_gene_hash->{ 'mi_attempts_abt_clones_list' }    = join ( ' ', @mi_attempt_abt_clones_array ) };
    }

    return;
}

=head2 _fuse_imits_plan_data

incorporate imits plan data into current gene hash

=cut
sub _fuse_imits_plan_data {
    my ( $self, $curr_gene_hash, $imits_gene_hash ) = @_;

    # copy mi_plans across
    my $imits_gene_plans = \%{ $imits_gene_hash->{ 'mi_plans' } };
    $curr_gene_hash->{ 'mi_plans' } = $imits_gene_plans;
    # for each plan increment counters
    foreach my $imits_plan_id ( sort keys %{ $imits_gene_plans } ) {
        $curr_gene_hash->{ 'count_imits_mi_plans_total' }++;
        my $is_current_plan_active = $imits_gene_plans->{ $imits_plan_id }->{ 'is_plan_active' };
        # TODO: check for an aborted status here?
        if ( $is_current_plan_active ) {
            $curr_gene_hash->{ 'count_imits_mi_plans_active' }++;
        }
    }

    return;
}

=head2 initialise_cre_gene_where_only_in_imits

initialise counters for an imits gene record that does not exist in LIMS2

=cut
sub _initialise_cre_gene_where_only_in_imits {
    my ( $self, $cre_ki_genes, $imits_gene_id ) = @_;

    my $cre_gene = \%{ $cre_ki_genes->{ 'genes' }->{ $imits_gene_id } };

    $self->_initialise_curr_gene_lims2_counters( $cre_gene );

    return;
}

=head2 _create_production_centres_display_lists

create text for display from production centres hashes

=cut
sub _create_production_centres_display_lists {
    my ( $self, $curr_gene_hash ) = @_;

    # production centres
    my @production_centres_list;
    foreach my $prod_centre ( sort keys %{ $curr_gene_hash->{ 'production_centres' } } ) {
        push ( @production_centres_list, $prod_centre );
    }
    $curr_gene_hash->{ 'count_imits_production_centres' }        = scalar @production_centres_list;

    if ( @production_centres_list ) {
        $curr_gene_hash->{ 'production_centres_list' }           = join ( ' ', @production_centres_list );
    };

    # plan priorities
    my @production_centre_priorities_list;
    foreach my $priority ( sort keys %{ $curr_gene_hash->{ 'production_centre_priorities' } } ) {
        push ( @production_centre_priorities_list, $priority );
    }
    if ( @production_centre_priorities_list ) {
        $curr_gene_hash->{ 'production_centre_priorities_list' } = join ( ' ', @production_centre_priorities_list );
    }

    return;
}

=head2 _fetch_gene_symbols_where_missing

fetch the gene symbols where missing in the main hash

=cut
sub _fetch_gene_symbols_where_missing {
    my ( $self, $cre_ki_genes ) = @_;

    foreach my $mgi_gene_id ( sort keys %{ $cre_ki_genes->{ 'genes' } } ) {
        my $curr_gene_hash = \% { $cre_ki_genes->{ 'genes' }->{ $mgi_gene_id } };

        unless ( $curr_gene_hash->{ 'marker_symbol' } ) {
            $curr_gene_hash->{ 'marker_symbol' }= $self->model->find_gene({
                species => $self->species,
                search_term => $mgi_gene_id
            })->{'gene_symbol'};
        }
    }

    return;
}

=head2 summarise_cre_ki_data

summarise the data for reporting

=cut
sub _summarise_cre_ki_data {
    my ( $self ) = @_;

    # initialise the data array
    $self->_initialise_overall_summary_report_data();

    # cycle through all the genes in the main cre ki hash
    foreach my $mgi_gene_id ( sort keys %{ $self->cre_ki_genes->{ 'genes' } } ) {
    	# summarise the data for the current gene
    	$self->_summarise_current_cre_ki_gene( $mgi_gene_id );

        # before incrementing counters decide which production centre grouping to count it in
        my $centre_name = $self->_determine_centre_grouping_for_gene( $mgi_gene_id );

        # determine in which basket the gene belongs
    	$self->_determine_basket_current_cre_ki_gene ( $mgi_gene_id, $centre_name );

        $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $centre_name }->{ 'count_genes_total' }++;

        # add current gene summary to hash for detailed report
        $self->_add_current_gene_summary_to_genes_summary_hash();
    }

    return;
}

=head2 initialise_summarised_data_hash

initialise the data hash for the summary counts

=cut
sub _initialise_overall_summary_report_data {
	my ( $self ) = @_;

    my %summarised_data = (
        'count_genes_total'                       => 0,
        'count_unrecognised_type'                 => 0,
    );

    foreach my $basket_name ( @BASKET_NAMES ) {
       $summarised_data{ ( 'count_'.$basket_name ) } = 0;
    }

    # print 'overall production centres:'."\n";
    # print ( Dumper ( $self->cre_ki_genes->{ 'overall_production_centres' } ) );

    # initialise the counters in each production centre grouping
    foreach my $prod_centre_name ( sort keys %{ $self->cre_ki_genes->{ 'overall_production_centres' } } ) {
        $self->cre_ki_genes->{ 'summary_counts' }->{ 'report' }->{ $prod_centre_name } = { %summarised_data };
    }

    # print 'initialise summary counters:'."\n";
    # print ( Dumper ( $self->cre_ki_genes->{ 'summary_counts' } ) );

    return;
}

=head2 _summarise_current_cre_ki_gene

initialise the data hash for the gene summary counts

=cut
sub _summarise_current_cre_ki_gene {
	my ( $self, $mgi_gene_id ) = @_;

	$self->curr_gene_summary( {} );

    $self->curr_gene( \%{ $self->cre_ki_genes->{ 'genes' }->{ $mgi_gene_id } } );

	my $curr_gene_summary = {
		'mgi_accession_id'                   => $mgi_gene_id,
        'production_centre_grouping'         => $self->curr_gene->{ 'production_centre_grouping' },
		'basket'                             => '',
	};

    $self->curr_gene_summary( $curr_gene_summary );

	return;
}

=head2 _determine_basket_current_cre_ki_gene

check gene against basket logic strings to determine how far along in pipeline this gene is

=cut
sub _determine_basket_current_cre_ki_gene {
	my ( $self, $mgi_gene_id, $centre_name ) = @_;

    my $basket_names         = \@BASKET_NAMES;
    my $basket_logic_strings = \%BASKET_LOGIC_STRINGS;

    # print "BASKET TESTS FOR GENE: $mgi_gene_id \n";

    # try each basket in order
    foreach my $basket_name ( @{ $basket_names } ) {
        # fetch the logic string
        my $curr_basket_logic_string = $basket_logic_strings->{ $basket_name };

        # print "BASKET being tested: $basket_name \n";
        # print "LOGIC: $curr_basket_logic_string \n";

        # run the boolean tests in the logic string
        if ( $self->_test_basket_logic_string( $curr_basket_logic_string ) ) {

            # identified the basket, record in main cre ki hash and in current gene summary
            $self->cre_ki_genes->{ 'genes' }->{ $mgi_gene_id }->{ 'basket' } = $basket_name;
            $self->curr_gene_summary->{ 'basket' }                           = $basket_name;

            # print "BASKET identified as <".$basket_name."> \n";
            # print '---------------------------------------'."\n";

            # call basket-specific method to increment counters
            return $self->dispatches->{ $basket_name }->( $centre_name );
        }
    }

    # if reach here then assign as unrecognised basket
    my $default_basket_name = 'unrecognised_type';
    $self->cre_ki_genes->{ 'genes' }->{ $mgi_gene_id }->{ 'basket' } = $default_basket_name;
    $self->curr_gene_summary->{ 'basket' }                           = $default_basket_name;
    return $self->dispatches->{ $default_basket_name }->( $centre_name );
}

=head2 _determine_centre_grouping_for_gene

the summary report has a row per production centre, or multiple if many, or unassigned if none

=cut
sub _determine_centre_grouping_for_gene {
    my ( $self, $mgi_gene_id ) = @_;

    my $centre_name = 'Unassigned';

    my $curr_gene_hash   = \%{ $self->cre_ki_genes->{ 'genes' }->{ $mgi_gene_id } };
    if ( exists $curr_gene_hash->{ 'count_imits_production_centres' } ) {
        my $count_centres    = $curr_gene_hash->{ 'count_imits_production_centres' };
        # zero in the count defaults to 'unassigned'
        if ( $count_centres == 1 ) {
            # use the production centre name e.g. WTSI
            $centre_name = $curr_gene_hash->{ 'production_centres_list' };
        }
        elsif ( $count_centres > 1 ) {
            $centre_name = 'Multiple Centres';
        }
    }

    $curr_gene_hash->{ 'production_centre_grouping' } = $centre_name;
    $self->curr_gene_summary->{ 'production_centre_grouping' } = $centre_name;

    return $centre_name;
}

=head2 _add_current_gene_summary_to_genes_summary_hash

add the current gene summary into the genes summary hash

=cut
sub _add_current_gene_summary_to_genes_summary_hash{
    my ( $self ) = @_;

    # check gene summary report attribute exists and initialise if not
    # unless( defined $self->summary_gene_data ) { $self->_initialise_summary_gene_data(); }
    unless( defined $self->summary_gene_data ) { $self->summary_gene_data( {} ); }

    # store the current gene summary by production centre grouping then by basket then by gene id so genes are grouped
    my $curr_prod_centre_grouping  = $self->curr_gene_summary->{ 'production_centre_grouping' };
    my $curr_basket                = $self->curr_gene_summary->{ 'basket' };
    my $curr_mgi_accession_id      = $self->curr_gene_summary->{ 'mgi_accession_id' };

    $self->summary_gene_data->{ $curr_prod_centre_grouping }->{ $curr_basket }->{ 'genes' }->{ $curr_mgi_accession_id } = $self->curr_gene_summary;
    $self->summary_gene_data->{ $curr_prod_centre_grouping }->{ $curr_basket }->{ 'count_genes' }++;

    return;
}

=head2 _test_basket_logic_string

test the basket logic string to see if there is a match

=cut
sub _test_basket_logic_string {
    my ( $self, $logic_string ) = @_;

    LIMS2::Exception->throw( "basket logic test: no logic string defined" ) unless ( defined $logic_string && $logic_string ne '' );

    # have the parser interpret and test the logic string
    my $parser = Parse::BooleanLogic->new();
    my $tree   = $parser->as_array( $logic_string );

    my $callback = sub {
        my $self    = pop;
        my $operand = $_[0]->{ 'operand' };

        # print 'OPERAND = <' . $operand . '>' . "\n";

        my $method  = $self->dispatches->{ $operand };
        my $operand_result = $method->();

        # if ( $operand_result ) { print "OPERAND RESULT: True \n"; }
        # else { print "OPERAND RESULT: False \n"; }

        return $operand_result;
    };

    my $result = $parser->solve( $tree, $callback, $self );

    # if ( $result ) { print "LOGIC RESULT: True \n"; }
    # else { print "LOGIC RESULT: False \n"; }

    return $result;
}

=head2 _has_lims2_data

test if current gene has lims2 data

=cut
sub _has_lims2_data {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'has_lims2_data' } ) { return 0; }

    if ( $self->curr_gene->{ 'has_lims2_data' } ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_imits_data

test if current gene has imits data

=cut
sub _has_imits_data {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'has_imits_data' } ) { return 0; }

    if ( $self->curr_gene->{ 'has_imits_data' } ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_acpt_final_picks

test if current gene has accepted final piq wells

=cut
sub _has_acpt_final_picks {
     my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_final_picks_accepted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_final_picks_accepted' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}


=head2 _has_piqs

test if current gene has piq wells

=cut
sub _has_piqs {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_total' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_total' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_clones

test if current gene has any clones

=cut
sub _has_clones {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_total' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_total' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_acpt_clones

test if current gene has accepted clones

=cut
sub _has_acpt_clones {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_primary_qc_data

test if current gene has primary qc data

=cut
sub _has_primary_qc_data {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_with_qc_data' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_with_qc_data' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}


=head2 _has_clones_missing_primary_qc_data

test if current gene has clones missing primary qc data

=cut
sub _has_clones_missing_primary_qc_data {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_total' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_with_qc_data' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_total' } > $self->curr_gene->{ 'count_lims2_ep_pick_wells_with_qc_data' } ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_all_clones_failed_primary_qc

test if current gene has all clones failed primary qc data

=cut
sub _has_all_clones_failed_primary_qc {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_total' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_with_qc_data' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }

    unless ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_total' } > 0 ) { return 0; }
    unless ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_with_qc_data' } > 0 ) { return 0; }
    unless ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_with_qc_data' } >= $self->curr_gene->{ 'count_lims2_ep_pick_wells_total' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } == 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_1_acpt_clone

test if current gene has 1 accepted clone

=cut
sub _has_1_acpt_clone {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } == 1 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_2_acpt_clone

test if current gene has 2 accepted clones

=cut
sub _has_2_acpt_clones {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } == 2 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_3_acpt_clone

test if current gene has 3 accepted clones

=cut
sub _has_3_acpt_clones {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } == 3 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_4_acpt_clone

test if current gene has 4 accepted clones

=cut
sub _has_4_acpt_clones {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } == 4 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_5_acpt_clone

test if current gene has 5 accepted clones

=cut
sub _has_5_acpt_clones {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } == 5 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_gt5_acpt_clones

test if current gene has more than 5 accepted clones

=cut
sub _has_gt5_acpt_clones {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } > 5 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_secondary_qc_data

test if current gene has piq qc data

=cut
sub _has_secondary_qc_data {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_with_qc_data' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_with_qc_data' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_acpt_piqs

test if current gene has accepted PIQs

=cut
sub _has_acpt_piqs {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_accepted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_accepted' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_1_failed_piq

test if current gene has 1 failed PIQ

=cut
sub _has_1_failed_piq {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    unless ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } > 0 ) { return 0; }
    unless ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } > $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } == 1 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_2_failed_piqs

test if current gene has 2 failed PIQs

=cut
sub _has_2_failed_piqs {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    unless ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } > 0 ) { return 0; }
    unless ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } > $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } == 2 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_3_failed_piqs

test if current gene has 3 failed PIQs

=cut
sub _has_3_failed_piqs {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    unless ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } > 0 ) { return 0; }
    unless ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } > $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } == 3 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_4_failed_piqs

test if current gene has 4 failed PIQs

=cut
sub _has_4_failed_piqs {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    unless ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } > 0 ) { return 0; }
    unless ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } > $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } == 4 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_5_failed_piqs

test if current gene has 5 failed PIQs

=cut
sub _has_5_failed_piqs {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    unless ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } > 0 ) { return 0; }
    unless ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } > $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } == 5 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_gt5_failed_piqs

test if current gene has greater than 5 failed PIQs

=cut
sub _has_gt5_failed_piqs {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    unless ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } > 0 ) { return 0; }
    unless ( $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } > $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } > 5 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_all_clones_failed_secondary_qc

test if current gene has all of its clones failed secondary QC

=cut
sub _has_all_clones_failed_secondary_qc {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) { return 0; }
    unless ( defined $self->curr_gene->{ 'count_lims2_piq_wells_failed' } ) { return 0; }

    unless ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } > 0 ) { return 0; }

    if ( $self->curr_gene->{ 'count_lims2_piq_wells_failed' } >= $self->curr_gene->{ 'count_lims2_ep_pick_wells_accepted' } ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_actv_mi_plans

test if current gene has active mi plans

=cut
sub _has_actv_mi_plans {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_imits_mi_plans_active' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_imits_mi_plans_active' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_mi_attempts

test if current gene has mi attempts

=cut
sub _has_mi_attempts {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_imits_mi_attempts_total' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_imits_mi_attempts_total' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_actv_mi_attempts

test if current gene has active mi attempts

=cut
sub _has_actv_mi_attempts {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_imits_mi_attempts_active' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_imits_mi_attempts_active' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_has_aborted_mi_attempts

test if current gene has aborted MI attempts

=cut
sub _has_has_aborted_mi_attempts {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_imits_mi_attempts_aborted' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_imits_mi_attempts_aborted' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_actv_mi_attempts_type_chr

test if current gene has active mi attempts type chimeras obtained

=cut
sub _has_actv_mi_attempts_type_chr {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_imits_mi_attempts_chimeras_obtained' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_imits_mi_attempts_chimeras_obtained' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _has_actv_mi_attempts_type_gtc

test if current gene has active mi attempts type germline transmission achieved

=cut
sub _has_actv_mi_attempts_type_gtc {
    my ( $self ) = @_;

    unless ( defined $self->curr_gene->{ 'count_imits_mi_attempts_glt_achieved' } ) { return 0; }

    if ( $self->curr_gene->{ 'count_imits_mi_attempts_glt_achieved' } > 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _initialise_summary_gene_data

initialise the summary gene data hash by basket name

=cut
# sub _initialise_summary_gene_data{
#     my ( $self ) = @_;

#     # hash of summarised gene counts, partitioned by basket
#     my %summary_gene_hash = (
#         'unrecognised_type'                 => { 'count_genes' => 0, },
#     );

#     foreach my $basket_name ( @BASKET_NAMES ) {
#        $summary_gene_hash{ $basket_name }   = { 'count_genes' => 0, };
#     }

#     $self->summary_gene_data( { %summary_gene_hash } );

#     return;
# }

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
FROM projects, project_sponsors ps
WHERE ps.sponsor_id = '$sponsor_id'
AND ps.project_id = projects.id
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
JOIN project_sponsors ps
WHERE ps.sponsor_id   = '$sponsor_id'
AND p.targeting_type = 'single_targeted'
AND p.species_id     = '$species_id'
)
SELECT pr.project_id
, pr.htgt_project_id
, s.design_id
, s.design_name
, s.design_type
, s.design_phase
, (s.design_plate_name || '_' || s.design_well_name) AS design_well_ident
, s.design_gene_id
, s.design_gene_symbol
, (s.int_plate_name || '_' || s.int_well_name) AS int_well_ident
, s.int_well_id AS int_well_db_id
, s.final_pick_cassette_name AS vector_cassette_name
, s.final_pick_cassette_promoter AS vector_cassette_promotor
, s.final_pick_backbone_name AS vector_backbone_name
, (s.final_pick_plate_name || '_' || s.final_pick_well_name) AS final_pick_well_ident
, s.final_pick_well_id AS final_pick_well_db_id
, s.final_pick_well_accepted
, (s.ep_pick_plate_name || '_' || s.ep_pick_well_name) AS ep_pick_well_ident
, s.ep_pick_well_id AS ep_pick_well_db_id
, s.ep_pick_well_accepted AS clone_accepted
, (s.fp_plate_name || '_' || s.fp_well_name) AS fp_well_ident
, s.fp_well_id AS fp_well_db_id
, s.fp_well_accepted
, (s.piq_plate_name || '_' || s.piq_well_name) AS piq_well_ident
, s.piq_well_id AS piq_well_db_id
, s.piq_well_accepted
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
AND s.final_pick_well_id > 0
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
, s.final_pick_well_accepted
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
, genes.marker_symbol
, genes.mgi_accession_id
, mi_plans.id AS plan_db_id
, mi_plans.is_active AS is_plan_active
, mi_plan_priorities.name AS plan_priority
, mi_attempts.id AS mi_attempt_db_id
, targ_rep_es_cells.name AS es_cell_name
, mi_attempt_statuses.code AS status_code
, mi_attempt_statuses.name AS status_name
, mi_attempts.is_active AS is_attempt_active
, mi_attempts.colony_name
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
, mi_attempts.colony_name
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
