package LIMS2::WebApp::Controller::User::Projects;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Projects::VERSION = '0.257';
}
## use critic

use Moose;
use LIMS2::WebApp::Pageset;
use namespace::autoclean;
use Try::Tiny;

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


    my $recovery_classes =  [ map { $_->id } $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->search( {}, {order_by => { -asc => 'id' } }) ];

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

sub edit_recovery_classes :Path( '/user/edit_recovery_classes' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    if ($params->{add_recovery_class} && $params->{new_recovery_class}) {

        my $new_class = $params->{new_recovery_class};
        $new_class =~ s/^\s+|\s+$//g;

        if ($new_class) {
            $c->model('Golgi')->txn_do( sub {
                try {
                    $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->create({ id => $new_class, description  => $params->{new_recovery_class_description} });
                    $c->flash( success_msg => "Added effort recovery class \"$new_class\"" );
                }
                catch {
                    $c->model('Golgi')->schema->txn_rollback;
                    $c->flash( error_msg => "Failed to add effort recovery class \"$new_class\": $_" );
                }
            });

            $params->{add_recovery_class} = '';
            return $c->response->redirect( $c->uri_for('/user/edit_recovery_classes') );
        }
    }

    my $recovery_classes =  [ map { {id => $_->id, description => $_->description} } $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->search( {}, {order_by => { -asc => 'id' } }) ];

    $c->stash(
       template    => 'user/projects/recovery_classes.tt',
       recovery_classes => $recovery_classes,
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
