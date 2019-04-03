package LIMS2::WebApp::Controller::User::ExternalProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::ExternalProject::VERSION = '0.532';
}
## use critic

use strict;
use warnings;

use Moose;
use Hash::MoreUtils qw( slice_def slice_exists);
use namespace::autoclean;
use Try::Tiny;
use List::MoreUtils qw( uniq );
use Data::Dumper;
use HTGT::QC::Util::CreateSuggestedQcPlateMap qw(search_seq_project_names);
use LIMS2::Model;
#use LIMS2::Model::Util::SequencingProject qw( build_seq_data build_xlsx_file );

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::ExternalProjects - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub external_project :Path('/user/external_project'){
    my ( $self, $c ) = @_;
    my $secondary_rs = $c->model('Golgi')->schema->resultset('SequencingPrimerType')->search({ id => {'!=', undef} },{ distinct => 1});

    handle_primers($c, $secondary_rs); #Fills the primer dropdown menu
    my $project_name = $c->req->param('project_name');
    if ($project_name){
        check_params($c);
        my $seq_plate = create_ext_project($c);
        if ($c->stash->{error_msg}){
            return;
        }
        try {
            $c->model('Golgi')->create_sequencing_project($seq_plate);
        } catch {
            $c->stash->{error_msg} = "Error creating sequencing project: " . $_;
        };
        unless ( $c->stash->{error_msg} ) {
            my $success_entry = $c->model('Golgi')->schema->resultset('SequencingProject')->find({ name => $project_name })->{_column_data};
            $c->stash->{success_msg} = 'Successfully created sequencing project: ' . $project_name . ' with id: ' . $success_entry->{id};
            $c->stash->{project_id} = $success_entry->{id};
        }
    }
    elsif ($c->req->param('create_project')) {
        $c->stash->{error_msg} = "Please enter a project name and add a primer";
    }
    return;
}

sub view_sequencing_project :Path('/user/view_sequencing_project'){
    my ($self, $c) = @_;

    my $proj = $c->req->param('seq_id');

    my $seq_project;
    try {
        $seq_project = $c->model('Golgi')->schema->resultset('SequencingProject')->find({ id => $proj})->{_column_data};
    } catch {
        $c->stash->{error_msg} = "Error retrieving sequencing project data. " . $_;
        return;
    };

    unless ($seq_project) {
        $c->stash->{error_msg} = "Sequencing project id not found: " . $proj;
        return;
    }

    my $size;
    if ($seq_project->{is_384}){
        $size = 384;
    }
    else{
        $size = 96;
    }

    if ($seq_project->{qc}){
        try{
            my $template_id = $c->model('Golgi')->schema->resultset('SequencingProjectTemplate')->find({ seq_project_id => $seq_project->{id} })->{_column_data};

            my $template_name = $c->model('Golgi')->schema->resultset('QcTemplate')->find(
                {
                    id => $template_id->{qc_template_id}
                },
                {
                    columns => [qw/ name /],
                    distinct => 1,
                }
            )->{_column_data};
            $c->stash->{qc} = ({ qc_template => $template_name->{name} });
        };
    }

    my @primers;
    my $secondary_rs = $c->model('Golgi')->schema->resultset('SequencingProjectPrimer')->search({ seq_project_id => $seq_project->{id}});

    handle_primers($c, $secondary_rs);

    my $user_id = $seq_project->{created_by_id};
    my $user_rs = $c->model('Golgi')->schema->resultset('User')->find({ id => $user_id})->{_column_data};

    $c->stash->{seq_project} = ({
        abandoned           => $seq_project->{abandoned},
        available_results   => $seq_project->{available_results},
        id                  => $seq_project->{id},
        size                => $size,
        name                => $seq_project->{name},
        qc                  => $seq_project->{qc},
        sub_projects        => $seq_project->{sub_projects},
        primers             => \@primers,
        user                => $user_rs->{name},
    });

    return;
}


sub browse_sequencing_projects :Path('/user/browse_sequencing_projects'){
    my ($self, $c) = @_;
    my $secondary_rs = $c->model('Golgi')->schema->resultset('SequencingPrimerType')->search({ id => {'!=', undef} },{ distinct => 1});

    #Create recently added list
    my $recent = $c->model('Golgi')->schema->resultset('SequencingProject')->search(
        { },
        {
            rows => 15,
            order_by => {-desc => 'created_at'},
        }
    );

    my @results;

    while (my $focus = $recent->next) {
        push(@results, $focus->as_hash);
    }
    $c->stash->{recent_results} = \@results;

    handle_primers($c, $secondary_rs);

    if ($c->req->params){
        search_results($self, $c);
    }

    return;
}

sub check_params{
    my $c = shift;
    my $params = $c->req->params;

    #Sub-projects may only contain a positive integer
    unless ($params->{sub_projects} =~ m/^\d+$/) {
        $c->stash->{error_msg} = "Please enter a positive integer value into sub_projects.";
    }

    if ($params->{qc}) {
        unless ($params->{qc_type} eq 'Crispr') {
            unless ($params->{template_id}) {
                $c->stash->{error_msg} = "Please enter a QC template.";
            }
        }
    }

    #Name may only contain A-Z, a-z, 0-9
    unless ($params->{project_name} =~ m/^[a-zA-Z0-9_]*$/) {
        $c->stash->{error_msg} = "Please enter a project name using only letters, numbers and underscores.";
    }

    #Check if name exists as old project in HTGT
    my $projects = search_seq_project_names($params->{project_name});
    if ( grep { /^$params->{project_name}$/ } @{ $projects }  ) {
        $c->stash->{error_msg} = $params->{project_name} . " already exists as an old project name. Please enter an unique name.";
    }

    return;
}

sub create_ext_project {
    my $c = shift;
    my $params = $c->req->params;

    if ($params->{'qc'}){
        $params->{'qc'} = 1;
    }
    else {
        $params->{'qc'} = 0;
    }
    if ($params->{'large_well'}){
        $params->{'large_well'} = 1;
    }
    else {
        $params->{'large_well'} = 0;
    }
    my $subs = $params->{sub_projects};
    if ($subs == 0) {
        $subs = 1;
    }
    my @primers = match_primers($c, $params);

    my $seq_plate = ({
        name            => $params->{'project_name'},
        template        => $params->{'template_id'},
        sub_projects    => $subs,
        qc              => $params->{'qc'},
        user_id         => $c->session->{__user}->{id},
        is_384          => $params->{'large_well'},
        primers         => \@primers,
        qc_type         => $params->{'qc_type'},
    });
    return $seq_plate;
}

sub handle_primers {
    my ($c, $secondary_rs) = @_;
    my @primers;
    my $secondary_name;

    while (my $secondary = $secondary_rs->next) {
        if ($secondary->{_column_data}->{id}){
            $secondary_name = $secondary->{_column_data}->{id};
        }
        else {
            $secondary_name = $secondary->{_column_data}->{primer_id};
        }
        push(@primers, $secondary_name);
    }
    @primers = sort { "\L$a" cmp "\L$b" } @primers;
    $c->stash->{primer_list} = \@primers;
    return;
}

sub match_primers {
    my ($c, $params) = @_;

    my @primer_values;
    foreach my $key (keys %{ $params }){
        if (grep {/primer\d/} $key){
            #If the key contains 'primer' followed by a number e.g. primer1, primer2, primer4
            push @primer_values, $params->{$key};
        }
    }
    #check for a primer
    unless (@primer_values) {
        $c->stash->{error_msg} = "Please add a primer to the project.";
        return;
    }

    my @filtered_values = uniq(@primer_values); #Remove duplicates

    return @filtered_values;
}

sub update_status {
    my ($c, $id, $abandoned) = @_;
    my $bool;

    if ($abandoned eq 'Yes'){
        $bool = 1;
    }
    else {
        $bool = 0;
    }
    my $update = ({
        id          => $id,
        abandoned   => $bool,
    });
    try {
        $c->model('Golgi')->update_sequencing_project($update);
    } catch {
        $c->stash->{error_msg} = "Error creating sequencing project: " . $_;
    };
    return;
}

sub search_results {
    my ($self, $c) = @_;
    my $name = $c->req->param('seq_name');
    my $primer_req = $c->req->param('dd_primer');
    $name = lc $name;

    my $primary_rs;
    my $table;
    my $column;
    if ($name) {
       $primary_rs = $c->model('Golgi')->schema->resultset('SequencingProject')->search({
            'lower(name)' => {'like', "%".$name."%"},
        },
        {
            distinct => 1,
            columns => [qw/
                id
                name
            /],
        }
        );
        retrieve_results($c, $primary_rs,'SequencingProjectPrimer','seq_project_id', 'id');
    }
    elsif ($primer_req) {
        $primary_rs = $c->model('Golgi')->schema->resultset('SequencingProjectPrimer')->search({ primer_id => $primer_req });
        retrieve_results($c, $primary_rs,'SequencingProject','id', 'seq_project_id');
    }


    return;
}

sub retrieve_results {
    my ($c, $primary_rs, $table, $column, $result_column) = @_;

    my @results;
    while (my $primary = $primary_rs->next) {
        my $primary_cd = $primary->{_column_data};
        my $secondary_rs = $c->model('Golgi')->schema->resultset($table)->search({ $column => $primary_cd->{$result_column} });

        if ($table eq 'SequencingProjectPrimer')
        {
            my @primers;
            while (my $primer_rs = $secondary_rs->next){
                push @primers, $primer_rs->{_column_data}->{primer_id};
            }
            my $primer_concat = join(', ', @primers);
            @results = store_result($primer_concat, $primary_cd, @results);
        }
        else {
            while (my $project_rs = $secondary_rs->next){
                my $project_cd = $project_rs->{_column_data};
                @results = store_result($primary_cd->{primer_id}, $project_cd, @results);

            }
        }
    }
    my @sorted =  sort { $a->{name} cmp $b->{name} } @results;
    if (@results) {
        $c->stash(
            results => \@sorted,
        );
    }
    else {
         $c->stash->{info_msg} = "No sequencing projects were found.";
    }
    return;
}

sub store_result {
    my ($primer, $project, @results) = @_;
    my $result = ({
        primer      => $primer,
        id          => $project->{id},
        name        => $project->{name},
    });

    push @results, $result;

    return @results;
}


__PACKAGE__->meta->make_immutable;

1;
