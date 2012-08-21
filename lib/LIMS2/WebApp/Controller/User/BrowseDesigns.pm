package LIMS2::WebApp::Controller::User::BrowseDesigns;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::BrowseDesigns::VERSION = '0.013';
}
## use critic

use Moose;
use TryCatch;
use Data::Dump 'pp';
use Const::Fast;
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
        design_types => $c->model('Golgi')->list_design_types
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

    my $design;
    try {
        $design = $c->model('Golgi')->retrieve_design( { id => $design_id, species => $species_id } )->as_hash;
    }
    catch( LIMS2::Exception::Validation $e ) {
        $c->stash( error_msg => "Please enter a valid design id" );
        return $c->go('index');
    } catch( LIMS2::Exception::NotFound $e ) {
        $c->stash( error_msg => "Design $design_id not found" );
        return $c->go('index');
    }

    $design->{assigned_genes} = join q{, }, @{ $design->{assigned_genes} || [] };

    $c->log->debug( "Design: " . pp $design );

    $c->stash(
        design         => $design,
        display_design => \@DISPLAY_DESIGN
    );

    return;
}

=head2 list_designs

=cut

sub list_designs : Path( '/user/list_designs' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $species_id = $c->request->param('species') || $c->session->{selected_species};
    my $gene_id    = $c->request->param('gene_id');

    my $genes;

    try {
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

    if ( $c->request->param('list_candidate_designs') ) {
        $method = 'list_candidate_designs_for_gene';
    }
    else {
        $method = 'list_assigned_designs_for_gene';
    }

    my %search_params = ( species => $species_id );

    my $type = $c->request->param('design_type');
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

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
