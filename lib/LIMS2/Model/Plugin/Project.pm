package LIMS2::Model::Plugin::Project;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Project::VERSION = '0.273';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use TryCatch;
use LIMS2::Exception;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );



sub pspec_retrieve_project {
    return {
        sponsor_id           => { validate => 'non_empty_string' },
        gene_id              => { validate => 'non_empty_string' },
        targeting_type       => { validate => 'non_empty_string', optional => 1 } ,
        species_id           => { validate => 'existing_species' },
    };
}

sub retrieve_project {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_project );

    my $project = $self->retrieve( Project => { slice_def $validated_params, qw( id sponsor_id gene_id targeting_type species_id ) } );

    return $project;
}

sub pspec_retrieve_project_by_id {
    return {
        id => { validate => 'integer' },
    };
}

sub retrieve_project_by_id {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_project_by_id );

    my $project = $self->retrieve( Project => { slice_def $validated_params, qw( id sponsor_id gene_id targeting_type species_id ) } );

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

1;

__END__
