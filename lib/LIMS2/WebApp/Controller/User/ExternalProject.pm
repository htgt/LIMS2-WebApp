package LIMS2::WebApp::Controller::User::ExternalProject;
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
    
    handle_primers($c); #Fills the primer dropdown menu

    my $project_name = $c->req->param('project_name');
    if ($project_name){
        check_params($c);
        if ($c->stash->{error_msg}){
            return;
        }
        my $seq_plate = create_ext_project($c);
        try {
            $c->model('Golgi')->create_sequencing_project($seq_plate);
        } catch {
            $c->stash->{error_msg} = "Error creating sequencing project: " . $_;
        };
        unless ( $c->stash->{error_msg} ) {
            $c->stash->{success_msg} = 'Successfully created sequencing project: ' . $c->req->param('project_name');
        }
    }
    return; 
}

sub view_sequencing_project :Path('/user/view_sequencing_project'){
    my ($self, $c) = @_;
    my $proj_id = $c->req->param('seq_id');
    my $seq_project = $c->model('Golgi')->schema->resultset('SequencingProject')->find({ id => $proj_id})->{_column_data};
    
    my $size;
    if ($seq_project->{is_384}){
        $size = 384;
    }
    else{
        $size = 96;
    }

    my $template_name = $c->model('Golgi')->schema->resultset('QcTemplate')->find(
        { 
            id => $seq_project->{qc_template_id}
        },
        {
            columns => [qw/ name /],
            distinct => 1,
        }
    )->{_column_data};
    
    my @primers = collect_primers($c, $proj_id);

    $c->stash->{seq_project} = ({
        abandoned           => $seq_project->{abandoned},
        available_results   => $seq_project->{available_results},
        id                  => $seq_project->{id},
        size                => $size,
        name                => $seq_project->{name},
        qc                  => $seq_project->{qc},
        qc_template         => $template_name->{name},
        sub_projects        => $seq_project->{sub_projects},
        primers             => \@primers,
    });

# my $something = LIMS2::Model::Util::SequencingProject::build_seq_data($self, $c);     
    return;
}

sub check_params{
    my $c = shift;
    my $params = $c->req->params;
    
    unless ($params->{template_id}){
        $c->stash->{error_msg} = "Please select a QC template from the autocorrect";
    }
    unless ($params->{sub_projects} =~ m/^-?\d+$/) {
        $c->stash->{error_msg} = "Please enter a positive integer value into sub_projects";
    }

    unless ($params->{project_name} =~ m/^[a-zA-Z0-9_]*$/) {
        $c->stash->{error_msg} = "Please enter a project name using only letters, numbers and underscores";
    }
    
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
    my ($c) = @_;
    my $crispr_rs = $c->model('Golgi')->schema->resultset('CrisprPrimerType')->search({ primer_name => {'!=', undef} },{ distinct => 1});
    my $geno_rs = $c->model('Golgi')->schema->resultset('GenotypingPrimerType')->search({ id => {'!=', undef} },{ distinct => 1});

    my @primers;
    @primers = extract_primers($geno_rs, @primers);
    @primers = extract_primers($crispr_rs, @primers);

    @primers = sort @primers;

    $c->stash->{primer_list} = \@primers;
    return;
}

sub extract_primers {
    my ($rs, @primer_array) = @_;
    my $primer_name;

    while (my $primer = $rs->next) {
        $primer_name = $primer->{_column_data};
        if ($primer->{_column_data}->{primer_name}){
            $primer_name = $primer->{_column_data}->{primer_name};
        }
        else {
            $primer_name = $primer->{_column_data}->{id};
        }
        push(@primer_array, $primer_name);
    }
    return @primer_array;
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
    
    my @filtered_values = uniq(@primer_values); #Remove duplicates

    return @filtered_values;
}

sub collect_primers {
    my ($c, $project_id) = @_;
    my @primers;
    my $schema = $c->model('Golgi')->schema;
    my $crispr_primers = $schema->resultset('SequencingProjectCrisprPrimer')->search({ seq_project_id => $project_id});
    my $geno_primers = $schema->resultset('SequencingProjectGenotypingPrimer')->search({ seq_project_id => $project_id});
    
    while (my $crispr = $crispr_primers->next){
        push @primers, $crispr->{_column_data}->{primer_id};
    }
    while (my $geno = $geno_primers->next){
        push @primers, $geno->{_column_data}->{primer_id};
    }

    return @primers;
}

sub retrieve_files{
    my ($self, $c, $primer) = @_;
    #LIMS2::Model::Util::SequencingProject::build_seq_data    
    return;
}
__PACKAGE__->meta->make_immutable;

1;
