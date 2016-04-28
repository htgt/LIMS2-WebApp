package LIMS2::WebApp::Controller::User::DesignTargets;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::DesignTargets::VERSION = '0.397';
}
## use critic

use Moose;
use LIMS2::Model::Util::DesignTargets qw( design_target_report_for_genes );
use LIMS2::Model::Util::Crisprs qw( crispr_pick );
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD );
use Try::Tiny;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::DesignTargets - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path('/user/design_target_gene_search') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    $c->stash(
        genes => $c->request->param('genes') || undef,
    );

    return;
}

sub gene_report : Path('/user/design_target_report') {
    my ( $self, $c, $gene ) = @_;

    $c->assert_user_roles( 'read' );
    my $species = $c->session->{selected_species};
    my $build   = $DEFAULT_SPECIES_BUILD{ lc($species) };

    # if no gene specified run report against all genes from that species projects
    if ( !$c->request->param('genes') && !$gene ) {
        my @gene_ids = $c->model('Golgi')->schema->resultset('Project')->search_rs(
            { species_id => $species },
            {   columns  => [qw(gene_id)],
                distinct => 1
            }
        )->get_column('gene_id')->all;

        $gene = join("\n", @gene_ids);
    }

    my %report_parameters = (
        type                 => $c->request->param('report_type') || 'standard',
        off_target_algorithm => $c->request->param('off_target_algorithm') || 'exhaustive',
        crispr_types         => $c->request->param('crispr_types') || 'pair',
        filter               => $c->request->param('filter') || 0,
    );

    my ( $design_targets_data, $search_terms ) = design_target_report_for_genes(
        $c->model('Golgi')->schema,
        $c->request->param('genes') || $gene,
        $c->session->{selected_species},
        $build,
        \%report_parameters,
    );

    unless ( @{ $design_targets_data } ) {
        $c->stash( error_msg => "No design targets found matching search terms" );
    }

    if ( $report_parameters{type} eq 'simple' ) {
        $c->stash( template => 'user/designtargets/simple_gene_report.tt');
    }
    else{
        if ( $report_parameters{crispr_types} eq 'single' ) {
            $c->stash( template => 'user/designtargets/gene_report_single_crisprs.tt');
        }
        elsif ( $report_parameters{crispr_types} eq 'pair' ) {
            $c->stash( template => 'user/designtargets/gene_report_crispr_pairs.tt');
        }
        elsif ( $report_parameters{crispr_types} eq 'group' ) {
            $c->stash( template => 'user/designtargets/gene_report_crispr_groups.tt');
        }
    }

    my $default_assembly = $c->model('Golgi')->schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $species } )->assembly_id;

    $c->stash(
        design_targets_data => $design_targets_data,
        genes               => $c->request->param('genes') || $gene,
        search_terms        => $search_terms,
        species             => $species,
        assembly            => $default_assembly,
        build               => $build,
        params              => \%report_parameters,
    );

    return;
}

sub design_target_report_crispr_pick : Path('/user/design_target_report_crispr_pick') : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    try {
        my $logs = crispr_pick(
            $c->model('Golgi'),
            $c->request->params,
            $c->session->{selected_species},
        );
        $c->stash->{logs} = $logs;
    }
    catch {
        $c->flash( error_msg => "Something went wrong: " . $_ );
    };

    return;
}

__PACKAGE__->meta->make_immutable;

1;
