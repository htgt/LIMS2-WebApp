package LIMS2::WebApp::Controller::User::Projects;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Projects::VERSION = '0.271';
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
            species_id  => $species_id,
            sponsor_id => { '!=', 'All' }
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

    my $search;

    if ($params->{show_all} && $species_id eq 'Human') {
        $params->{sponsor_id} = '';
        $search = {
            species_id => $species_id,
            sponsor_id => { -not_in => [ 'All', 'Transfacs'] },
        };
    } else {
        $search = {
            species_id => $species_id,
        };
    }

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

sub edit_recovery_classes :Path( '/user/edit_recovery_classes' ) Chained('/') CaptureArgs(1) {
    my ( $self, $c, $edit_class) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    # adding new recovery class
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

    # is a recovery class being edited?
    if ($edit_class) {

            my $retrieved_class = $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->find( {id => $edit_class} );
            $edit_class = { id => $retrieved_class->id, description => $retrieved_class->description };
            $c->stash( edit_class => $edit_class );

    }

    # the edit is to delete
    if ($edit_class && $params->{delete_recovery_class}) {

        $c->model('Golgi')->txn_do( sub {
            try {
                $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->find({ id => $edit_class->{id} })->delete;
                $c->model('Golgi')->schema->resultset('Project')->search({ recovery_class => $edit_class->{id} })->update_all({ recovery_class => undef });

                $c->flash( success_msg => "Deleted effort recovery class \"". $edit_class->{id} ."\"" );
            }
            catch {
                $c->model('Golgi')->schema->txn_rollback;
                $c->flash( error_msg => "Failed to delete effort recovery class \"". $edit_class->{id} ."\": $_" );
            }
        });

        $params->{delete_recovery_class} = '';
        return $c->response->redirect( $c->uri_for('/user/edit_recovery_classes' ) );

    }

    # the edit is to update
    if ($edit_class && $params->{update_recovery_class}) {

        $c->model('Golgi')->txn_do( sub {
            try {
                $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->find({ id => $edit_class->{id} })->update({ id => $params->{update_recovery_class_id}, description => $params->{update_recovery_class_description} });
                $c->model('Golgi')->schema->resultset('Project')->search({ recovery_class => $edit_class->{id} })->update_all({ recovery_class => $params->{update_recovery_class_id} });

                $c->flash( success_msg => "Updated effort recovery class \"". $edit_class->{id} ."\"" );
            }
            catch {
                $c->model('Golgi')->schema->txn_rollback;
                $c->flash( error_msg => "Failed to update effort recovery class \"". $edit_class->{id} ."\": $_" );
            }
        });

        $params->{update_recovery_class} = '';
        return $c->response->redirect( $c->uri_for('/user/edit_recovery_classes' ) );

    }

    # get the current recovery classes for the table
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
