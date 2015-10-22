package LIMS2::Model::Plugin::Project;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Project::VERSION = '0.347';
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

sub pspec_retrieve_project {
    return {
        gene_id              => { validate => 'non_empty_string' },
        targeting_type       => { validate => 'non_empty_string', optional => 1 } ,
        species_id           => { validate => 'existing_species' },
        targeting_profile_id => { validate => 'non_empty_string', optional => 1 },
        sponsor_id           => { validate => 'non_empty_string', optional => 1 },
    };
}

sub retrieve_project {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_project );

    my $search_params = {
        slice_def $validated_params, qw( id gene_id targeting_type species_id targeting_profile_id)
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

sub _pspec_update_project{
    return {
        id             => { validate => 'integer' },
        concluded      => { validate => 'boolean', optional => 1, rename => 'effort_concluded' },
        recovery_class_id => { validate => 'existing_recovery_class', optional => 1 },
        comment        => { optional => 1, rename => 'recovery_comment' },
        priority       => { optional => 1 },
        MISSING_OPTIONAL_VALID => 1,
    };
}

sub update_project {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_update_project);

    my $project = $self->retrieve_project_by_id($validated_params);

    my $update_params = {slice_exists $validated_params, qw(effort_concluded recovery_class_id recovery_comment priority)};

    $project->update( $update_params );

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
        priority          => { validate => 'non_empty_string', optional => 1 },
        recovery_class_id => { validate => 'existing_recovery_class', optional => 1 },
        sponsors          => { validate => 'existing_sponsor', optional => 1 },
    };
}

sub create_project {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_project);

    my $sponsors = delete $validated_params->{sponsors};
    $sponsors = $self->_add_sponsor_all_if_appropriate($sponsors,$validated_params->{species_id});

    my $project = $self->schema->resultset('Project')->create($validated_params);

    foreach my $sponsor(@$sponsors){
        $self->add_project_sponsor({
            project_id => $project->id,
            sponsor_id => $sponsor,
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

sub _pspec_add_project_sponsor{
    return {
        project_id => { validate => 'integer' },
        sponsor_id => { validate => 'existing_sponsor' },
    };
}

sub add_project_sponsor{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_add_project_sponsor);

    my $project_sponsor_link = $self->schema->resultset('ProjectSponsor')->create($validated_params);

    return $project_sponsor_link;
}

sub _pspec_update_project_sponsors{
    return {
        project_id => { validate => 'integer' },
        sponsor_list => { validate => 'existing_sponsor', optional => 1 },
        MISSING_OPTIONAL_VALID => 1,
    };
}

## NB: This method deletes all existing project-sponsor links and replaces
## them with the sponsors provided in sponsor_list
## If you just want to add to the list of existing sponsors use add_project_sponsor
sub update_project_sponsors{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_update_project_sponsors);
    my $project = $self->retrieve_project_by_id({ id => $validated_params->{project_id} });

    $project->delete_related('project_sponsors');

    my $sponsors = $self->_add_sponsor_all_if_appropriate( $validated_params->{sponsor_list}, $project->species_id );
    foreach my $sponsor (@{ $sponsors }){
        $self->schema->resultset('ProjectSponsor')->create({
            project_id => $project->id,
            sponsor_id => $sponsor,
        });
    }
    return $project;
}

sub _pspec_retrieve_experiment{
    return {
        id => { validate => 'integer' },
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
        REQUIRE_SOME    => { design_or_crisprs => [ 1, qw( design_id crispr_id crispr_pair_id crispr_group_id ) ] },
    }
}

sub create_experiment{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->_pspec_create_experiment);

    my $experiment  = $self->schema->resultset('Experiment')->create($validated_params);
    return $experiment;
}

sub delete_experiment{
    my ($self,$params) = @_;

    my $experiment = $self->retrieve_experiment($params);
    $experiment->delete;
    return;
}

sub _add_sponsor_all_if_appropriate{
    my ($self, $sponsor_list, $species) = @_;

    return unless $sponsor_list;

    # Only do this for Human
    return $sponsor_list unless $species eq 'Human';

    my @sponsors = @{ $sponsor_list  };
    return [] unless(@sponsors);

    if (@sponsors == 1 and $sponsors[0] eq 'Transfacs'){
        # We don't add the All sponsor
        # All == All except Transfacs
    }
    else{
        push @sponsors, "All";
    }

    # Unique it before return in case "All" was already on list
    return [ uniq @sponsors ];
}

1;

__END__
