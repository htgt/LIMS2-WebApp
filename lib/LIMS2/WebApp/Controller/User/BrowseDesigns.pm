package LIMS2::WebApp::Controller::User::BrowseDesigns;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::BrowseDesigns::VERSION = '0.480';
}
## use critic

use Moose;
use TryCatch;
use Data::Dump 'pp';
use Const::Fast;
use LIMS2::Model::Constants qw( %UCSC_BLAT_DB );
use LIMS2::Model::Util::Crisprs qw( crisprs_for_design );
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::BrowseDesigns - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path( '/user/browse_designs' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    $c->stash(
        design_id => $c->request->param('design_id') || undef,
        gene_id   => $c->request->param('gene_id')   || undef,
        design_types => $c->model('Golgi')->c_list_design_types
    );

    return;
}

=head2 view_design

=cut

const my @DISPLAY_DESIGN => (
    [ 'Design id'               => 'id' ],
    [ 'Name'                    => 'name' ],
    [ 'Type'                    => 'type' ],
    [ 'Target transcript'       => 'target_transcript' ],
    [ 'Assigned to gene(s)'     => 'assigned_genes' ],
    [ 'Phase'                   => 'phase' ],
    [ 'Validated by annotation' => 'validated_by_annotation' ],
    [ 'Created by'              => 'created_by' ],
    [ 'Created at'              => 'created_at' ]
);

sub view_design : Path( '/user/view_design' ) : Args(0) {
    my ( $self, $c ) = @_;
    $c->assert_user_roles( 'read' );

    my $species_id = $c->request->param('species') || $c->session->{selected_species};
    my $design_id  = $c->request->param('design_id');
    $c->log->debug( "view design $design_id" );

    my $design;
    try {
        $design = $c->model('Golgi')->c_retrieve_design( { id => $design_id, species => $species_id } );
    }
    catch( LIMS2::Exception::Validation $e ) {
        $c->stash( error_msg => "Please enter a valid design id" );
        return $c->go('index');
    } catch( LIMS2::Exception::NotFound $e ) {
        $c->stash( error_msg => "Design $design_id not found" );
        return $c->go('index');
    }

    my $design_data = $design->as_hash;
    $design_data->{assigned_genes} = [ map { $_->{gene_symbol} . ' (' . $_->{gene_id} . ')' }
                      values %{ $c->model('Golgi')->find_genes( $species_id, $design_data->{assigned_genes} ) } ];

    $design_data->{assigned_genes} = join q{, }, @{ $design_data->{assigned_genes} || [] };

    my $ucsc_db = $UCSC_BLAT_DB{ lc( $species_id) };

    my ( $crisprs, $crispr_pairs, $crispr_groups ) = ( [], [], [] );
    # Only want to show the one linked crispr for nonsense designs
    if ( $design_data->{type} ne 'nonsense' ) {
        ( $crisprs, $crispr_pairs, $crispr_groups ) = crisprs_for_design( $c->model('Golgi'), $design );
    }
    my $design_attempt = $design->design_attempt;

    my $group_ids = join ", ", map { $_->id } @$crispr_groups;
    $c->log->debug("crispr groups found: $group_ids" );
    $c->stash(
        design         => $design_data,
        display_design => \@DISPLAY_DESIGN,
        species        => $species_id,
        ucsc_db        => $ucsc_db,
        crisprs        => [ map{ $_->as_hash } @{ $crisprs } ],
        crispr_pairs   => [ map{ $_->as_hash } @{ $crispr_pairs } ],
        crispr_groups  => [ map{ $_->as_hash } @{ $crispr_groups } ],
        design_attempt => $design_attempt ? $design_attempt->id : undef,
    );

    return;
}

=head2 design_ucsc_blat

Link to UCSC Blat page for the design oligos

=cut
sub design_ucsc_blat : Path( '/user/design_ucsc_blat' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $species_id = $c->request->param('species') || $c->session->{selected_species};
    my $design_id  = $c->request->param('design_id');

    my $design;
    try {
        $design = $c->model('Golgi')->c_retrieve_design( { id => $design_id, species => $species_id } )->as_hash;
    }
    catch( LIMS2::Exception::Validation $e ) {
        $c->stash( error_msg => "Please enter a valid design id" );
        return $c->go('index');
    } catch( LIMS2::Exception::NotFound $e ) {
        $c->stash( error_msg => "Design $design_id not found" );
        return $c->go('index');
    }

    my $ucsc_db = $UCSC_BLAT_DB{ lc($species_id) };

    $c->stash(
        design  => $design,
        species => $species_id,
        ucsc_db => $ucsc_db,
    );

    return;
}

=head2 list_designs

=cut
sub list_designs : Path( '/user/list_designs' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $params = $c->request->params;

    my $species_id = $params->{ species } || $c->session->{selected_species};
    my $gene_id    = $params->{ gene_id };

    #search the gene designs table. if we're generating a csv we need a much larger pagesize
    my ( $gene_designs, $pager ) = $c->model('Golgi')->c_search_gene_designs( {
        search_term => $gene_id,
        species     => $species_id,
        page        => $params->{ page },
        pagesize    => ( exists $params->{ csv } ) ? 1000 : $params->{ pagesize }
    } );

    #if we found anything in the search then just display the results to the user, no more searching required
    if ( @{ $gene_designs } ) {
        #if the user has requested a csv create and return it, otherwise continue as normal.
        if ( exists $params->{ csv } ) {
            my $filename = "${gene_id}_design_results.csv";

            $c->res->content_type('text/comma-separated-values');
            $c->res->header( 'Content-Disposition', qq[attachment; filename="$filename"] );

            $c->res->body( $self->_generate_designs_csv( $gene_designs, $c->uri_for( '/user/view_design' ) ) );

            return;
        }

        #get a pager and stash all the information
        my $pageset = LIMS2::WebApp::Pageset->new( {
                total_entries    => $pager->total_entries,
                entries_per_page => $pager->entries_per_page,
                current_page     => $pager->current_page,
                pages_per_set    => 5,
                mode             => 'slide',
                base_uri         => $c->uri_for( '/user/list_designs', $params )
        } );

        $c->stash( {
            search_term     => $gene_id,
            designs_by_gene => $gene_designs,
            pageset         => $pageset,
            template        => 'user/browsedesigns/list_designs_compact.tt'
        } );
        return;
    }

    #if a csv has been requested but we haven't already returned there is a problem.
    if ( exists $params->{ csv } ) {
        $c->stash( error_msg => "There was an error generating the CSV file." );
        return $c->go('index');
    }

    #if we didnt find anything in the GeneDesign table we'll need to get the mgi accession id:

    my $genes;

    try {
        #search the solr database for anything matching $gene_id (can be an mgi accession id, marker symbol)
        #which will return any matching mgi accession ids and marker symbols.
        $genes = $c->model('Golgi')->search_genes( { search_term => $gene_id, species => $species_id } );
    }
    catch( LIMS2::Exception::Validation $e ) {
        $c->stash( error_msg => "Please enter a valid gene identifier" );
        return $c->go('index');
    } catch( LIMS2::Exception::NotFound $e ) {
        $c->stash( error_msg => "Found no genes matching '$gene_id'" );
        return $c->go('index');
    }

    my $method;

    if ( $params->{ list_candidate_designs } ) {
        $method = 'c_list_candidate_designs_for_gene';
    }
    else {
        $method = 'c_list_assigned_designs_for_gene';
    }

    my %search_params = ( species => $species_id );

    my $type = $params->{ design_type };
    if ( $type and $type ne '-' ) {
        $search_params{type} = $type;
    }

    my ( @designs_by_gene, %seen );

    for my $g ( @{$genes} ) {
        next unless defined $g->{gene_id} and not $seen{ $g->{gene_id} }++;
        $c->log->debug("Fetching designs for $g->{gene_symbol}");
        $search_params{gene_id} = $g->{gene_id};
        my $designs = $c->model('Golgi')->$method( \%search_params );
        push @designs_by_gene, { %{$g}, designs => [ map { $_->as_hash(1) } @{$designs} ] };
    }

    $c->stash( designs_by_gene => \@designs_by_gene );

    return;
}

sub _generate_designs_csv {
    my ( $self, $gene_designs, $view_design_link ) = @_;

    my @csv_lines;

    push @csv_lines, join ",",
    (
        "Gene",
        "Design ID",
        "Oligos",
        "Location",
        "Created by",
        "Created at",
        "Design Link"
    );

    for my $gene_design ( @{ $gene_designs } ) {
        for my $design ( @{ $gene_design->{ designs } } ) {
            my $num_oligos = scalar @{ $design->{ oligos } };
            my $first_locus = (shift @{ $design->{ oligos } })->{ locus };
            my $chr_end  = (pop @{ $design->{ oligos } })->{ locus }{ chr_end };

            push @csv_lines, join ',',
            (
                $gene_design->{ gene_id },
                $design->{ id },
                $num_oligos,
                "Chr $first_locus->{ chr_name }: $first_locus->{ chr_start } - $chr_end",
                $design->{ created_by },
                $design->{ created_at },
                $view_design_link . "?design_id=" . $design->{ id },
            );
        }
    }

    return join "\n", @csv_lines;
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
