package LIMS2::WebApp::Controller::User::ExternalProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::ExternalProject::VERSION = '0.343';
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

    my $primer_rs = $c->model('Golgi')->schema->resultset('SequencingPrimerType')->search({ id => {'!=', undef} },{ distinct => 1});

    handle_primers($c, $primer_rs); #Fills the primer dropdown menu

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
    return;
}

sub view_sequencing_project :Path('/user/view_sequencing_project'){
    my ($self, $c) = @_;

    my $proj = $c->req->param('seq_id');
    my $key;

    if ($proj){
        $key = 'id';
    }
    else {
        $key = 'name';
        $proj = $c->req->param('seq_name');
    }

    my $seq_project = $c->model('Golgi')->schema->resultset('SequencingProject')->find({ $key => $proj})->{_column_data};

    my $size;
    if ($seq_project->{is_384}){
        $size = 384;
    }
    else{
        $size = 96;
    }

    if ($seq_project->{qc}){
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
    }

    my @primers;
    my $primer_rs = $c->model('Golgi')->schema->resultset('SequencingProjectPrimer')->search({ seq_project_id => $seq_project->{id}});

    handle_primers($c, $primer_rs);

    $c->stash->{seq_project} = ({
        abandoned           => $seq_project->{abandoned},
        available_results   => $seq_project->{available_results},
        id                  => $seq_project->{id},
        size                => $size,
        name                => $seq_project->{name},
        qc                  => $seq_project->{qc},
        sub_projects        => $seq_project->{sub_projects},
        primers             => \@primers,
    });

    return;
}

sub browse_sequencing_projects :Path('/user/browse_sequencing_projects'){
    my ($self, $c) = @_;
    #Will contain update status methods
    return;
}

sub check_params{
    my $c = shift;
    my $params = $c->req->params;

    #Only if QC is ticked, check for template id
    if($params->{qc}){
        unless ($params->{template_id}){
            $c->stash->{error_msg} = "Please select a QC template from the autocorrect.";
        }
    }

    #Sub-projects may only contain a positive integer
    unless ($params->{sub_projects} =~ m/^-?\d+$/) {
        $c->stash->{error_msg} = "Please enter a positive integer value into sub_projects.";
    }

    #Name may only contain A-Z, a-z, 0-9
    unless ($params->{project_name} =~ m/^[a-zA-Z0-9_]*$/) {
        $c->stash->{error_msg} = "Please enter a project name using only letters, numbers and underscores.";
    }

    #Check if name exists as old project in HTGT
    my $projects = search_seq_project_names($params->{project_name});
    #If not found, empty array reference is returned
    if (@{ $projects }) {
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
    });
    return $seq_plate;
}

sub handle_primers {
    my ($c, $primer_rs) = @_;
    my @primers;
    my $primer_name;

    while (my $primer = $primer_rs->next) {
        if ($primer->{_column_data}->{id}){
            $primer_name = $primer->{_column_data}->{id};
        }
        else {
            $primer_name = $primer->{_column_data}->{primer_id};
        }
        push(@primers, $primer_name);
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


sub retrieve_files{
    my ($self, $c, $primer) = @_;
    #LIMS2::Model::Util::SequencingProject::build_seq_data    
    return;
}
__PACKAGE__->meta->make_immutable;

1;
