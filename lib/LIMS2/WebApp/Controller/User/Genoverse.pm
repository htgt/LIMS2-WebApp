package LIMS2::WebApp::Controller::User::Genoverse;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Genoverse::VERSION = '0.373';
}
## use critic


=head Genoverse Controller

The purpose of this controller is to launch the different Genoverse views.

The API calls for the different tracks are in the REST API folder in Browser.pm

=cut

use Moose;
use Try::Tiny;
use namespace::autoclean;

use LIMS2::Model::Util::GenoverseSupport qw(
        get_genotyping_primer_extent
        get_design_extent
        get_gene_extent
        );

BEGIN { extends 'Catalyst::Controller' };

with qw(
MooseX::Log::Log4perl
);

sub index : Path( '/user/browse_crisprs' ) : Args(0) {
    my ( $self, $c ) = @_;

    # TODO, add crispr search page here?

    return;
}
=head for genoverse browser
=cut

sub browse_crisprs : Path( '/user/browse_crisprs' ) : Args(0) {
        my ( $self, $c ) = @_;

        return;
    }

sub browse_crisprs_genoverse : Path( '/user/browse_crisprs_genoverse' ) : Args(0) {
        my ( $self, $c ) = @_;

        return;
    }

=head genoverse_browse_view
Given
    genome
    chromosome ID
    symbol
    gene_id
    exon_id
Renders
    genoverse_browse_view
With
    genome
    chromosome ID
    symbol
    gene_id
    exon_id
    exon_start (chromosome coordinates)
    exon_end (chromosome coordinates)
=cut

sub genoverse_browse_view : Path( '/user/genoverse_browse' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $exon_coords_rs = $c->model('Golgi')->schema->resultset('DesignTarget')->search(
        {
            'ensembl_exon_id' => $c->request->params->{'exon_id'},
        }
    );

    my $exon_coords = $exon_coords_rs->single;
    $c->stash(
        'genome'        => $c->request->params->{'genome'},
        'chromosome'    => $c->request->params->{'chromosome'},
        'gene_symbol'   => $c->request->params->{'symbol'},
        'gene_id'       => $c->request->params->{'gene_id'},
        'exon_id'       => $c->request->params->{'exon_id'},
        'exon_start'    => $exon_coords->chr_start,
        'exon_end'      => $exon_coords->chr_end,
        'view_single'   => $c->request->params->{'view_single'},
        'view_paired'   => $c->request->params->{'view_paired'},
    );

    return;
}

=head genoverse_crispr_primers_view

FIXME: This controller does not seem to work and there is no link to it anywhere in the LIMS2 app
Can it be removed or is it work in progres??

Undefined subroutine &LIMS2::Model::Util::GenoverseSupport::get_db_genotyping_primers_as_hash called at
lib/LIMS2/Model/Util/GenoverseSupport.pm line 47

=cut

sub genoverse_crispr_primers_view : Path( '/user/genoverse_crispr_primers' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $genotyping_primer_extent;
   try {
        $genotyping_primer_extent = get_genotyping_primer_extent(
            $c->model('Golgi'),
            $c->request->params,
            $c->session->{'selected_species'},
        );
    }
    catch {
       $c->stash( error_msg => $_->as_string );
    };
    if (! $genotyping_primer_extent ) {
        $c->stash( error_msg => 'LIMS2 needs a Gibson design with genotyping primers to display Genoverse view' );
    }
    else {
        $c->stash(
            'extent'  => $genotyping_primer_extent,
            'context' => $c->request->params,
        );
    }

return;
}

=head genoverse_primer_view

Use this to show extent by design plus genotyping primers, etc.


=cut

sub genoverse_primer_view : Path( '/user/genoverse_primer_view' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $design_extent;
   try {
        $design_extent = get_design_extent(
            $c->model('Golgi'),
            $c->request->params,
            $c->session->{'selected_species'},
        );
    }
    catch {
       $c->stash( error_msg => $_->as_string );
    };
    if (! $design_extent ) {
        $c->stash( error_msg => 'LIMS2 needs a design to display Genoverse design with primers view' );
    }
    else {
        $c->stash(
            'extent'  => $design_extent,
            'context' => $c->request->params,
        );
    }

    return;
}

=head genoverse_design_view

Use this to show a generic design extent based genoverse view - no primers

=cut

sub genoverse_design_view : Path( '/user/genoverse_design_view' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $design_extent;
   try {
        $design_extent = get_design_extent(
            $c->model('Golgi'),
            $c->request->params,
            $c->session->{'selected_species'},
        );
    }
    catch {
       $c->stash( error_msg => $_->as_string );
    };
    if (! $design_extent ) {
        $c->stash( error_msg => 'LIMS2 needs a design to display Genoverse view' );
    }
    else {
        $c->stash(
            'extent'  => $design_extent,
            'context' => $c->request->params,
        );
    }

    return;
}

=head genoverse_gene_view

Use this to show a generic gene extent based genoverse view - no primers

=cut

sub genoverse_gene_view : Path( '/user/genoverse_gene_view' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $gene_extent;
   try {
        $gene_extent = get_gene_extent(
            $c->model('Golgi'),
            $c->request->params,
            $c->session->{'selected_species'},
        );
    }
    catch {
       $c->stash( error_msg => $_->as_string );
    };
    if (! $gene_extent ) {
        $c->stash( error_msg => 'LIMS2 needs a gene id to display the Genoverse view' );
    }
    else {
        $c->stash(
            'extent'  => $gene_extent,
            'context' => $c->request->params,
        );
    }

    return;
}

1;
