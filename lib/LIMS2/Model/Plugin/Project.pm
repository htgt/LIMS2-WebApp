package LIMS2::Model::Plugin::Project;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Project::VERSION = '0.431';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def slice_exists);
use TryCatch;
use LIMS2::Exception;
use namespace::autoclean;
use List::MoreUtils qw(uniq);
use Data::Dumper;

requires qw( schema check_params throw retrieve log trace );

sub pspec_retrieve_sponsor {
    return { id => { validate => 'non_empty_string'} };
}

sub retrieve_sponsor {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_sponsor);

    my $sponsor = $self->retrieve( Sponsor => $validated_params );

    return $sponsor;
}

sub cell_line_id_for{
    my ( $self, $cell_line_name ) = @_;

    my %search = ( name => $cell_line_name );
    my $cell_line = $self->schema->resultset('CellLine')->find( \%search )
        or $self->throw(
        NotFound => {
            entity_class  => 'CellLine',
            search_params => \%search
        }
        );

    return $cell_line->id;
}

sub pspec_retrieve_project {
    return {
        gene_id              => { validate => 'non_empty_string' },
        targeting_type       => { validate => 'non_empty_string', optional => 1 } ,
        species_id           => { validate => 'existing_species' },
        cell_line            => {
            validate    => 'existing_cell_line',
            post_filter => 'cell_line_id_for',
            rename      => 'cell_line_id',
            optional    => 1,
        },
        targeting_profile_id => { validate => 'non_empty_string', optional => 1 },
        sponsor_id           => { validate => 'non_empty_string', optional => 1 },
    };
}

sub retrieve_project {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_project );

    my $search_params = {
        slice_def $validated_params, qw( id gene_id targeting_type species_id targeting_profile_id cell_line_id)
    };

    my $project;
    if(my $sponsor_id = $validated_params->{sponsor_id}){
        my $sponsor = $self->retrieve_sponsor({ id => $sponsor_id });
        $project = $sponsor->projects->find( $search_params );
    }
    else{
        $project = $self->retrieve( Project => $search_params );
    }

    return $project;
}

sub pspec_retrieve_project_by_id {
    return {
        id => { validate => 'integer' },
    };
}

sub retrieve_project_by_id {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_project_by_id , ignore_unknown => 1);

    my $project = $self->retrieve( Project => { id => $validated_params->{id} } );

    return $project;
}

sub toggle_concluded_flag {
    my ( $self, $params ) = @_;

    my $project = $self->retrieve_project_by_id($params);

    if ($project->effort_concluded) {
        $project->update( { effort_concluded => 0 } );
    } else {
        $project->update( { effort_concluded => 1 } );
    };

    return $project;
}

sub pspec_retrieve_recovery_class{
    return {
        id           => { validate => 'integer', optional => 1 },
        name         => { validate => 'non_empty_string', optional => 1 },
        REQUIRE_SOME => { name_or_id => [ 1, qw( name id ) ] },
    };
}

sub retrieve_recovery_class{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_recovery_class );

    my $recovery_class = $self->retrieve( ProjectRecoveryClass => $validated_params );
    return $recovery_class;
}

sub set_recovery_class {
    my ( $self, $params ) = @_;

    my $project = $self->retrieve_project_by_id($params);

    $project->update( { recovery_class => $params->{recovery_class} } );

    return $project;
}

sub set_recovery_comment {
    my ( $self, $params ) = @_;

    my $project = $self->retrieve_project_by_id($params);

    $project->update( { recovery_comment => $params->{recovery_comment} } );

    return $project;
}

# sponsors_priority should be a hashref of sponsor_ids to the priority they have placed on this project
sub _pspec_update_project{
    return {
        id                => { validate => 'integer' },
        concluded         => { validate => 'boolean', optional => 1, rename => 'effort_concluded' },
        recovery_class_id => { validate => 'existing_recovery_class', optional => 1 },
        comment           => { optional => 1, rename => 'recovery_comment' },
        sponsors_priority => { optional => 1 },
        MISSING_OPTIONAL_VALID => 1,
    };
}

sub update_project {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_update_project);

    my $project = $self->retrieve_project_by_id($validated_params);

    my $update_params = {slice_exists $validated_params, qw(effort_concluded recovery_class_id recovery_comment )};

    $project->update( $update_params );

    if(defined (my $sponsors_priority = $validated_params->{sponsors_priority}) ){
        foreach my $sponsor_id (keys %$sponsors_priority){
            $self->update_or_create_project_sponsor({
                project_id => $validated_params->{id},
                sponsor_id => $sponsor_id,
                priority   => $sponsors_priority->{$sponsor_id},
            });
        }
    }

    return $project;
}

sub _pspec_create_project{
    return {
        gene_id           => { validate => 'non_empty_string' },
        targeting_type    => { validate => 'non_empty_string' },
        species_id        => { validate => 'existing_species' },
        cell_line_id      => { validate => 'integer', optional => 1 },
        targeting_profile_id => { validate => 'non_empty_string', optional => 1},
        htgt_project_id   => { validate => 'integer', optional => 1},
        effort_concluded  => { validate => 'boolean', optional => 1},
        recovery_comment  => { validate => 'non_empty_string', optional => 1 },
        sponsors_priority => { optional => 1 },
        recovery_class_id => { validate => 'existing_recovery_class', optional => 1 },
    };
}

sub create_project {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_project);

    my $sponsors_priority = delete $validated_params->{sponsors_priority};

    my $project = $self->schema->resultset('Project')->create($validated_params);

    foreach my $sponsor(keys %{ $sponsors_priority || {} }){
        $self->update_or_create_project_sponsor({
            project_id => $project->id,
            sponsor_id => $sponsor,
            priority   => $sponsors_priority->{$sponsor},
        });
    }

    return $project;
}

sub delete_project{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_project_by_id);

    my $project = $self->retrieve_project_by_id({ id => $validated_params->{id} });
    $project->delete_related('project_sponsors');
    return $project->delete;
}

sub _pspec_update_project_sponsors{
    return {
        project_id        => { validate => 'integer' },
        sponsors_priority => { optional => 1 },
        MISSING_OPTIONAL_VALID => 1,
    };
}

## NB: This method deletes all existing project-sponsor links and replaces
## them with the sponsors provided in sponsor_list
## This is because it is used by a  web form where users can unselect sponsors to remove them
## If you just want to add to the list of existing sponsors use update_or_create_project_sponsor
sub update_project_sponsors{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_update_project_sponsors);
    my $project = $self->retrieve_project_by_id({ id => $validated_params->{project_id} });

    $project->delete_related('project_sponsors');

    foreach my $sponsor(keys %{ $validated_params->{sponsors_priority} || {} }){
        $self->update_or_create_project_sponsor({
            project_id => $project->id,
            sponsor_id => $sponsor,
            priority   => $validated_params->{sponsors_priority}->{$sponsor},
        });
    }

    return $project;
}

sub _pspec_retrieve_project_sponsor{
    return {
        project_id => { validate => 'integer' },
        sponsor_id => { validate => 'existing_sponsor' },
    }
}

sub retrieve_project_sponsor{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, $self->_pspec_retrieve_project_sponsor);

    return $self->retrieve( ProjectSponsor => $validated_params );
}

sub _pspec_update_create_project_sponsor{
    return {
        project_id => { validate => 'integer' },
        sponsor_id => { validate => 'existing_sponsor' },
        priority   => { validate => 'non_empty_string', optional => 1 },
        MISSING_OPTIONAL_VALID => 1,
    }
}

sub update_or_create_project_sponsor{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, $self->_pspec_update_create_project_sponsor);

    my $project_sponsor = $self->schema->resultset('ProjectSponsor')->find({
        project_id => $validated_params->{project_id},
        sponsor_id => $validated_params->{sponsor_id},
    });

    if($project_sponsor){
        if($project_sponsor->priority ne $validated_params->{priority}){
            $$project_sponsor->update({ priority => $validated_params->{priority} });
        }
    }
    else{
        $project_sponsor = $self->schema->resultset('ProjectSponsor')->create($validated_params);
    }

    $self->_add_sponsor_all_if_appropriate($project_sponsor->project);

    return $project_sponsor;
}

sub _pspec_retrieve_experiment{
    return {
        id              => { validate => 'integer', optional => 1 },
        design_id       => { validate => 'existing_design_id', optional => 1 },
        crispr_id       => { validate => 'existing_crispr_id', optional => 1 },
        crispr_pair_id  => { validate => 'existing_crispr_pair_id', optional => 1},
        crispr_group_id => { validate => 'existing_crispr_group_id', optional => 1},
        gene_id         => { validate => 'non_empty_string', optional => 1 },
        REQUIRE_SOME    => { id_or_design_or_crisprs => [ 1, qw( id design_id crispr_id crispr_pair_id crispr_group_id ) ] },
        MISSING_OPTIONAL_VALID => 1,
    }
}

sub retrieve_experiment{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_retrieve_experiment);
    my $experiment = $self->retrieve('Experiment', $validated_params);
    return $experiment;
}

sub _pspec_create_experiment{
    return {
        gene_id         => { validate => 'non_empty_string' },
        design_id       => { validate => 'existing_design_id', optional => 1 },
        crispr_id       => { validate => 'existing_crispr_id', optional => 1 },
        crispr_pair_id  => { validate => 'existing_crispr_pair_id', optional => 1},
        crispr_group_id => { validate => 'existing_crispr_group_id', optional => 1},
        plated          => { validate => 'boolean', default => 0 },
        REQUIRE_SOME    => { design_or_crisprs => [ 1, qw( design_id crispr_id crispr_pair_id crispr_group_id ) ] },
    }
}

sub create_experiment{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_experiment);

    my $search_params = {
        gene_id   => $validated_params->{gene_id},
        design_id => ($validated_params->{design_id} // undef),
        crispr_id => ($validated_params->{crispr_id} // undef),
        crispr_pair_id => ($validated_params->{crispr_pair_id} // undef),
        crispr_group_id => ($validated_params->{crispr_group_id} // undef),
    };
    my $experiment;
    try{
        $experiment = $self->retrieve_experiment($search_params);
    };

    if($experiment){
        if($experiment->deleted){
            # Un-delete the existing experiment
            $experiment->update({ deleted => 0});
        }
        else{
            die "Experiment already exists with id ".$experiment->id."\n";
        }
    }
    else{
        $experiment = $self->schema->resultset('Experiment')->create($validated_params);
    }
    return $experiment;
}

sub delete_experiment{
    my ($self,$params) = @_;

    my $experiment = $self->retrieve_experiment($params);
    $experiment->update({ deleted => 1});
    return;
}

sub _add_sponsor_all_if_appropriate{
    my ($self, $project) = @_;

    return unless $project;

    # Only do this for Human
    return unless $project->species_id eq 'Human';

    my @sponsors = map { $_->sponsor_id } $project->project_sponsors;

    return unless @sponsors;

    if (@sponsors == 1 and $sponsors[0] eq 'Transfacs'){
        # We don't add the All sponsor
        # All == All except Transfacs
    }
    else{
        # Add All unless we already have it
        unless(grep { $_ eq 'All'} @sponsors){
            $self->schema->resultset('ProjectSponsor')->create({
                sponsor_id => 'All',
                project_id => $project->id,
            });
        }
    }
    return;
}

1;

__END__
