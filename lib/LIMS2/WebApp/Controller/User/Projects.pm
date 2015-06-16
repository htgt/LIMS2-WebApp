package LIMS2::WebApp::Controller::User::Projects;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Projects::VERSION = '0.323';
}
## use critic

use Moose;
use LIMS2::WebApp::Pageset;
use Hash::MoreUtils qw( slice_def slice_exists);
use namespace::autoclean;
use Try::Tiny;
use List::MoreUtils qw( uniq );

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::Projects - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub manage_projects :Path('/user/manage_projects'){
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $species_id = $c->session->{selected_species};
    my $gene_id;
    if(my $gene = $c->req->param('gene')){
        $c->stash->{gene} = $gene;
        my $gene_info = try{ $c->model('Golgi')->find_gene( { search_term => $gene, species => $species_id } ) };
        if($gene_info){
            $gene_id = $gene_info->{gene_id};
        }
        else{
            $gene_id = $gene;
        }
    }

    # Store params common to search and create
    my $search = { species_id => $species_id };
    if($gene_id){
        $search->{gene_id} = $gene_id;
    }
    if(my $targ_type = $c->req->param('targeting_type')){
        $c->stash->{targeting_type} = $targ_type;
        $search->{targeting_type} = $targ_type;
    }
    if(my $targ_profile = $c->req->param('targeting_profile_id')){
        $c->stash->{targeting_profile_id} = $targ_profile;
        $search->{targeting_profile_id} = $targ_profile;
    }

    my @project_results;
    if($c->req->param('create_project')){
        # create project and redirect to view_project
        my $projects_rs = $c->model('Golgi')->schema->resultset('Project')->search( $search,
                          { order_by => 'id' });
        if($projects_rs == 0){
            # Create a new project
            if(my $sponsor = $c->req->param('sponsor')){
                $c->stash->{sponsor} = $sponsor;
                $search->{sponsors} = [ $sponsor ];
            }
            my $project;
            $c->model('Golgi')->txn_do(
                sub {
                    try{
                        $project = $c->model('Golgi')->create_project($search);
                        $c->flash->{success_msg} = "New project created";
                        $c->res->redirect( $c->uri_for('/user/view_project/',{ project_id => $project->id }) );
                    }
                    catch{
                        $c->model('Golgi')->txn_rollback;
                        $c->stash->{error_msg} = "Project creation failed with error: $_";
                    };
                }
            );
        }
        else{
            # Display matching projects and error message
            @project_results = $projects_rs->all;
            $c->stash->{error_msg} = "Project already exists (see list below)";
        }
    }
    elsif($c->req->param('search_projects')){
        # stash list of matching project IDs
        # display these as links on manage_projects page
        if(my $sponsor = $c->req->param('sponsor')){
            $c->stash->{sponsor} = $sponsor;
            $search->{'project_sponsors.sponsor_id'} = $sponsor;
        }

        my $projects_rs = $c->model('Golgi')->schema->resultset('Project')->search( $search,
                          {
                            order_by => 'id',
                            join => 'project_sponsors',
                            distinct => 1,
                        });
        @project_results = $projects_rs->all;
        unless(@project_results){
            $c->stash->{error_msg} = "No projects found";
        }
    }

    my @projects;
    foreach my $project (@project_results){
        my $info = $project->as_hash;
        my $gene_info = try{ $c->model('Golgi')->find_gene( {
            search_term => $project->gene_id,
            species => $species_id
        } ) };
        if($gene_info){
            $info->{gene_symbol} = $gene_info->{gene_symbol};
        }
        push @projects, $info;
    }
    $c->stash->{projects} = \@projects;

    my @sponsors = sort map { $_->id } $c->model('Golgi')->schema->resultset('Sponsor')->all;

    $c->stash->{sponsors} = \@sponsors;
    return;
}

sub view_project :Path('/user/view_project'){
    my ( $self, $c) = @_;

    $c->assert_user_roles('read');

    my $proj_id = $c->req->param('project_id');

    my $project = $c->model('Golgi')->retrieve_project_by_id({
            id => $proj_id,
        });

    my $gene_info = try{ $c->model('Golgi')->find_gene( {
        search_term => $project->gene_id,
        species => $project->species_id
    } ) };

    if($c->req->param('update_sponsors')){
        $c->assert_user_roles('edit');
        my @new_sponsors = $c->req->param('sponsors');
        $c->model('Golgi')->txn_do(
            sub {
                try{
                    $c->model('Golgi')->update_project_sponsors({
                        project_id => $project->id,
                        sponsor_list => \@new_sponsors,
                    });
                    $c->stash->{success_msg} = 'Project sponsor list updated';
                }
                catch {
                    $c->stash->{error_msg} = 'Error encountered while updating sponsor list: ' . $_;
                    $c->model('Golgi')->txn_rollback;
                };
            }
        );
    }

    if($c->req->param('add_experiment')){
        $c->assert_user_roles('edit');
        my $params = $c->req->params;
        delete $params->{add_experiment};
        try{
            my $experiment = $c->model('Golgi')->create_experiment($params);
            $c->stash->{success_msg} = 'Experiment created with ID '.$experiment->id;
        }
        catch{
            $c->stash->{error_msg} = 'Could not create experiment: '. $_;
        };
    }

    if(my $experiment_id = $c->req->param('delete_experiment')){
        $c->assert_user_roles('edit');
        try{
            $c->model('Golgi')->delete_experiment({ id => $experiment_id });
            $c->stash->{success_msg} = 'Deleted experiment with ID '.$experiment_id;
        }
        catch{
            $c->stash->{error_msg} = 'Could not delete experiment: '. $_;
        };
    }

    my @sponsors = sort map { $_->id } $c->model('Golgi')->schema->resultset('Sponsor')->search({
                       id => { '!=' => 'All' }
                   })->all;
    my @design_suggest = map { $_->design_id }
                             $c->model('Golgi')->schema->resultset('GeneDesign')->search({ gene_id => $project->gene_id });
    my @group_suggest = map { $_->id }
                            $c->model('Golgi')->schema->resultset('CrisprGroup')->search({ gene_id => $project->gene_id });

    $c->stash->{project} = $project->as_hash;
    if($gene_info->{gene_symbol}){
        $c->stash->{gene_symbol} = $gene_info->{gene_symbol};
    }
    $c->stash->{project_sponsors} = { map { $_ => 1 } $project->sponsor_ids };
    $c->stash->{all_sponsors} = \@sponsors;
    $c->stash->{experiments} = [ $project->experiments ];
    $c->stash->{design_suggest} = \@design_suggest;
    $c->stash->{group_suggest} = \@group_suggest;
    return;
}

=head2 index

=cut

sub index :Path( '/user/projects' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    my $species_id = $c->session->{selected_species};

    my @projects_rs =  $c->model('Golgi')->schema->resultset('Project')->search( {
            species_id  => $species_id,
        },
        {
            prefetch => [ 'project_sponsors' ]
        }
    );

    my @sponsors = sort { $a cmp $b } ( uniq map { $_->sponsor_ids } @projects_rs );

    try {
        my $index = 0;
        $index++ until ( $sponsors[$index] eq 'All' || $index >= scalar @sponsors );
        splice(@sponsors, $index, 1);
    };

    my $columns = ['id', 'gene_id', 'gene_symbol', 'sponsor', 'targeting type', 'concluded?', 'recovery class', 'recovery comment', 'priority'];

    $c->stash(
        sponsor_id       => \@sponsors,
        effort_concluded => ['true', 'false'],
        title            => 'Project Efforts',
        columns          => $columns,
    );

    return unless ( $params->{filter} && $params->{sponsor_id} );

    my $sel_sponsor = $params->{sponsor_id};

    my @projects = $c->model('Golgi')->schema->resultset('Project')->search( {
            'project_sponsors.sponsor_id'  => $sel_sponsor,
        },
        {
            prefetch => [ 'project_sponsors' ]
        }
    );

    my @project_genes = map { [
        $_->id,
        $_->gene_id,
        $c->model('Golgi')->find_gene( { species => $species_id, search_term => $_->gene_id } )->{gene_symbol},
        (join "/", $_->sponsor_ids),
        $_->targeting_type,
        $_->effort_concluded,
        $_->recovery_class_name // '',
        $_->recovery_comment // '',
        $_->priority // '',
    ] } @projects;


    my $recovery_classes =  [ map { $_->name } $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->search( {}, {order_by => { -asc => 'name' } }) ];

    my $priority_classes = ['low', 'medium', 'high'];

    $c->stash(
        sponsor_id       => \@sponsors,
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
                    $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->create({
                        name         => $new_class,
                        description  => $params->{new_recovery_class_description}
                    });

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
            $edit_class = { id => $retrieved_class->id, description => $retrieved_class->description, name => $retrieved_class->name };
            $c->stash( edit_class => $edit_class );

    }

    # the edit is to delete
    if ($edit_class && $params->{delete_recovery_class}) {

        $c->model('Golgi')->txn_do( sub {
            try {
                $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->find({ id => $edit_class->{id} })->delete;
                $c->model('Golgi')->schema->resultset('Project')->search({ recovery_class_id => $edit_class->{id} })->update_all({ recovery_class => undef });

                $c->flash( success_msg => "Deleted effort recovery class \"". $edit_class->{name} ."\"" );
            }
            catch {
                $c->model('Golgi')->schema->txn_rollback;
                $c->flash( error_msg => "Failed to delete effort recovery class \"". $edit_class->{name} ."\": $_" );
            }
        });

        $params->{delete_recovery_class} = '';
        return $c->response->redirect( $c->uri_for('/user/edit_recovery_classes' ) );

    }

    # the edit is to update
    if ($edit_class && $params->{update_recovery_class}) {

        $c->model('Golgi')->txn_do( sub {
            try {
                $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->find({ id => $edit_class->{id} })->update({
                    description => $params->{update_recovery_class_description},
                    name        => $params->{update_recovery_class_name}
                });

                $c->flash( success_msg => "Updated effort recovery class \"". $edit_class->{name} ."\"" );
            }
            catch {
                $c->model('Golgi')->schema->txn_rollback;
                $c->flash( error_msg => "Failed to update effort recovery class \"". $edit_class->{name} ."\": $_" );
            }
        });

        $params->{update_recovery_class} = '';
        return $c->response->redirect( $c->uri_for('/user/edit_recovery_classes' ) );

    }

    # get the current recovery classes for the table
    my $recovery_classes =  [ map { {id => $_->id, description => $_->description, name => $_->name } } $c->model('Golgi')->schema->resultset('ProjectRecoveryClass')->search( {}, {order_by => { -asc => 'name' } }) ];

    $c->stash(
       template    => 'user/projects/recovery_classes.tt',
       recovery_classes => $recovery_classes,
    );

    return;
}

sub update_project :Path( '/user/update_project' ) :Args(0) {
    my ($self, $c) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    my @report_params = qw(gene_id stage sponsor);

    my $project_id = $params->{id};

    unless($project_id){
        $c->flash( error_msg => "Could not update project - no project ID provided");
        return $c->response->redirect( $c->uri_for('/user/report/sync/RecoveryDetail',
                                      { slice_def $params, @report_params } ) );
    }

    my $failed = 0;
    $c->model('Golgi')->txn_do( sub {
        try{
            my $project_params = { slice_exists $params, qw(id recovery_class_id comment priority) };

            # Need to set the concluded flag here because
            # form will not submit concluded=>false when checkbox is unchecked
            if($params->{concluded}){
                $project_params->{concluded} = 1;
            }
            else{
                $project_params->{concluded} = 0;
            }

            $c->model('Golgi')->update_project($project_params);
        }
        catch{
            $failed = 1;
            $c->model('Golgi')->schema->txn_rollback;
            $c->flash( error_msg => "Could not update project - $_");
        }
    });

    unless($failed){
        $c->flash( success_msg => "Project $project_id was successfully updated");
    }

    return $c->response->redirect( $c->uri_for('/user/report/sync/RecoveryDetail',
                                      { slice_def $params, @report_params } ) );
}

=head1 AUTHOR

Team 87

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
