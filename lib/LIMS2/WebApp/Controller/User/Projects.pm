package LIMS2::WebApp::Controller::User::Projects;
use Moose;
use LIMS2::WebApp::Pageset;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::Projects - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path( '/user/projects' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    my $species_id = $c->session->{selected_species};

    my @sponsors_rs =  $c->model('Golgi')->schema->resultset('Project')->search( {
            species_id  => $species_id
        },{
            columns     => [ qw/sponsor_id/ ],
            distinct    => 1
        }
    );

    my @sponsors =  map { $_->sponsor_id } @sponsors_rs;

    my $columns = ['id', 'gene_id', 'gene_symbol', 'sponsor', 'targeting type', 'concluded?', 'recovery class', 'recovery comment', 'priority'];

    my $sel_sponsor;

    $c->stash(
        sponsor_id => [ map { $_->sponsor_id } @sponsors_rs ],
        effort_concluded => ['true', 'false'],
        title           => 'Project Efforts',
        columns         => $columns,
        sel_sponsor      => $sel_sponsor,
    );


    return unless ( $params->{filter} || $params->{show_all} );

    if ($params->{show_all}) {
        $params->{sponsor_id} = '';
    }

    my $search = {
        species_id => $species_id,
    };

    if ($params->{sponsor_id}) {
        $search->{sponsor_id} = $params->{sponsor_id};
        $sel_sponsor = $params->{sponsor_id};
    }

    my @projects_rs =  $c->model('Golgi')->schema->resultset('Project')->search( $search , {order_by => { -asc => 'gene_id' } });


    my @project_genes = map { [
        $_->id,
        $_->gene_id,
        $c->model('Golgi')->find_gene( { species => $species_id, search_term => $_->gene_id } )->{gene_symbol},
        $_->sponsor_id,
        $_->targeting_type,
        $_->effort_concluded,
        $_->recovery_class // '',
        $_->recovery_comment // '',
        $_->priority // '',
    ] } @projects_rs;


    my $recovery_classes = ['class1', 'class2', 'class3'];
    my $priority_classes = ['low', 'medium', 'high'];

    $c->stash(
        sponsor_id       => [ map { $_->sponsor_id } @sponsors_rs ],
        effort_concluded => ['true', 'false'],
        title            => 'Project Efforts',
        columns          => $columns,
        data             => \@project_genes,
        get_grid         => 1,
        sel_sponsor      => $sel_sponsor,
        recovery_classes => $recovery_classes,
        priority_classes => $priority_classes,
    );

    return;
}


=head1 AUTHOR

Team 87

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
