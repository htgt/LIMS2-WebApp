package LIMS2::WebApp::Controller::User::Report::Gene;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::Report::Gene - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path( '/user/report/gene' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    $c->stash( template => "user/report/gene_report.tt" );

    my $gene_id = $c->request->param( 'gene_id' )
        or return;

    my $gene_info = $c->model('Golgi')->retrieve_gene( { gene => $gene_id } );

    my $mgi_accession_id = $gene_info->{mgi_accession_id}
        or $self->throw( MissingData => "Unable to determine MGI accesison id for $gene_id" );

    my $designs = $c->model('Golgi')->list_assigned_designs_for_gene( { gene_id => $mgi_accession_id } );

    my %wells;

    for my $design ( @{$designs} ) {
        for my $root_well ( map { $_->output_wells } $design->processes ) {
            my $descendants = $root_well->descendants->breadth_first_traversal( $root_well, 'out' );
            while ( my $well = $descendants->next ) {
                push @{ $wells{$well->plate->type_id} }, $well;
            }
        }
    }

    while ( my ( $k, $v ) = each %wells ) {
        $wells{$k} = [ sort { $a->created_at <=> $b->created_at } @{$v} ];
    }

    $c->stash(
        info    => $gene_info,
        designs => $designs,
        wells   => \%wells
    );

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
