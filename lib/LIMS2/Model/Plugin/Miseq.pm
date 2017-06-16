package LIMS2::Model::Plugin::Miseq;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Miseq::VERSION = '0.463';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;

use Hash::MoreUtils qw( slice slice_def );
use Const::Fast;
use Try::Tiny;
use Log::Log4perl qw( :easy );
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_miseq_plate_well {
    return {
        miseq_plate_id  => { validate => 'existing_miseq_plate' },
        illumina_index  => { validate => 'illumina_index_range' },
        status          => { validate => 'existing_miseq_status' },
    };
}

# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub create_miseq_plate_well {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_miseq_plate_well);

    my $miseq = $self->schema->resultset('MiseqProjectWell')->create(
        {   slice_def(
                $validated_params,
                qw( miseq_plate_id illumina_index status )
            )
        }
    );

    return;
}

sub pspec_update_miseq_plate_well {
    return {
        id      => { validate => 'existing_miseq_well' },
        status  => { validate => 'existing_miseq_status' },
    };
}

sub update_miseq_plate_well {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_update_miseq_plate_well);

    my %search;
    $search{'me.id'} = $validated_params->{id};

    my $status->{status} = $validated_params->{status};
    my $well = $self->retrieve( MiseqProjectWell => \%search );
    my $update = $well->update($status);

    return;
}

sub pspec_create_miseq_well_experiment {
    return {
        miseq_well_id   => { validate => 'existing_miseq_well' },
        miseq_exp_id    => { validate => 'existing_miseq_experiment' },
        classification  => { validate => 'existing_miseq_classification' },
        frameshifted    => { validate => 'boolean', optional => 1 },
    };
}

# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub create_miseq_well_experiment {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_miseq_well_experiment);

    my $miseq = $self->schema->resultset('MiseqProjectWellExp')->create(
        {   slice_def(
                $validated_params,
                qw( miseq_well_id miseq_exp_id classification frameshifted )
            )
        }
    );

    return;
}

sub pspec_update_miseq_well_experiment {
    return {
        id              => { validate => 'existing_miseq_well_exp' },
        miseq_exp_id    => { validate => 'existing_miseq_experiment', optional => 1 },
        classification  => { validate => 'existing_miseq_classification', optional => 1 },
        frameshifted    => { validate => 'boolean', optional => 1 },
    };
}

sub update_miseq_well_experiment {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_update_miseq_well_experiment);

    my %search;
    $search{'me.id'} = $validated_params->{id};

    my $well = $self->retrieve( MiseqProjectWellExp => \%search );
    my $hash_well = $well->as_hash;
    my $class;
    $class->{classification} = $validated_params->{classification} || $hash_well->{classification};
    $class->{miseq_exp_id} = $validated_params->{miseq_exp_id} || $hash_well->{experiment};
    $class->{frameshifted} = $validated_params->{frameshifted} || $hash_well->{frameshifted};
    my $update = $well->update($class);

    return;
}

sub pspec_create_miseq_experiment {
    return {
        miseq_id        => { validate => 'existing_miseq_plate' },
        name            => { validate => 'non_empty_string' },
        gene            => { validate => 'non_empty_string' },
        mutation_reads  => { validate => 'integer' },
        total_reads     => { validate => 'integer' },
    };
}

# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub create_miseq_experiment {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_miseq_experiment);

    my $miseq = $self->schema->resultset('MiseqExperiment')->create(
        {   slice_def(
                $validated_params,
                qw( miseq_id name gene mutation_reads total_reads )
            )
        }
    );

    return;
}

1;
