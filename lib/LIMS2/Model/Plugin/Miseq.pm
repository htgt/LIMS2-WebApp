package LIMS2::Model::Plugin::Miseq;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Miseq::VERSION = '0.479';
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
use LIMS2::Model::Util::Miseq qw( miseq_well_processes );

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_miseq_plate {
    return {
        plate_id    => { validate => 'existing_plate_id' },
        is_384      => { validate => 'boolean' },
        run_id      => { validate => 'integer', optional => 1 },
    };
}
# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub create_miseq_plate {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_miseq_plate);

    my $miseq = $self->schema->resultset('MiseqPlate')->create(
        {   slice_def(
                $validated_params,
                qw( plate_id is_384 run_id )
            )
        }
    );

    $self->log->info('Created MiSEQ Plate: ' . $miseq->id);

    return $miseq;
}

sub pspec_create_miseq_well_experiment {
    return {
        well_id         => { validate => 'existing_well_id' },
        miseq_exp_id    => { validate => 'existing_miseq_experiment' },
        classification  => { validate => 'existing_miseq_classification' },
        frameshifted    => { validate => 'boolean', optional => 1 },
        status          => { validate => 'existing_miseq_status', optional => 1, default => 'Plated'},
    };
}

# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub create_miseq_well_experiment {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_miseq_well_experiment);

    my $miseq = $self->schema->resultset('MiseqWellExperiment')->create(
        {   slice_def(
                $validated_params,
                qw( well_id miseq_exp_id classification frameshifted status )
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
        status          => { validate => 'existing_miseq_status', optional => 1 }
    };
}

sub update_miseq_well_experiment {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_update_miseq_well_experiment);

    my %search;
    $search{'me.id'} = $validated_params->{id};

    my $well = $self->retrieve( MiseqWellExperiment => \%search );
    my $hash_well = $well->as_hash;
    my $class;
    $class->{classification} = $validated_params->{classification} ? $validated_params->{classification} : $hash_well->{classification};
    $class->{miseq_exp_id} = $validated_params->{miseq_exp_id} ? $validated_params->{miseq_exp_id} : $hash_well->{miseq_exp_id};
    $class->{frameshifted} = $validated_params->{frameshifted} ? $validated_params->{frameshifted} : $hash_well->{frameshifted};
    $class->{status} = $validated_params->{status} ? $validated_params->{status} : $hash_well->{status};

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

sub pspec_update_miseq_experiment {
    return {
        id              => { validate => 'existing_miseq_experiment' },
        miseq_id        => { validate => 'existing_miseq_plate', optional => 1 },
        name            => { validate => 'non_empty_string', optional => 1 },
        gene            => { validate => 'non_empty_string', optional => 1 },
        mutation_reads  => { validate => 'integer', optional => 1 },
        total_reads     => { validate => 'integer', optional => 1 },
    };
}

sub update_miseq_experiment {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_update_miseq_experiment);

    my %search;
    $search{'me.id'} = $validated_params->{id};

    my $exp = $self->retrieve( MiseqExperiment => \%search );
    my $hash_well = $exp->as_hash;
    my $class;
    $class->{miseq_id} = $validated_params->{miseq_id} || $hash_well->{miseq_id};
    $class->{name} = $validated_params->{name} || $hash_well->{name};
    $class->{gene} = $validated_params->{gene} || $hash_well->{gene};
    $class->{mutation_reads} = $validated_params->{mutation_reads} || $hash_well->{nhej_count};
    $class->{total_reads} = $validated_params->{total_reads} || $hash_well->{read_count};
    $class->{old_miseq_id} = $hash_well->{old_miseq_id};
    my $update = $exp->update($class);

    return;
}

sub pspec_miseq_plate_creation_json {
    return {
        name            => { validate => 'plate_name' },
        data            => { validate => 'hashref' },
        large           => { validate => 'boolean' },
        user            => { validate => 'existing_user' },
        time            => { validate => 'date_time' },
        species         => { validate => 'existing_species' },
    };
}

sub miseq_plate_creation_json {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_miseq_plate_creation_json);

    my $lims_plate_data = {
        name        => $validated_params->{name},
        species     => $validated_params->{species},
        type        => 'MISEQ',
        created_by  => $validated_params->{user},
        created_at  => $validated_params->{time},
    };

    my $lims_plate = $self->create_plate($lims_plate_data);

    my $miseq_plate_data = {
        plate_id    => $lims_plate->id,
        is_384      => $validated_params->{large},
    };

    my $miseq_plate = $self->create_miseq_plate($miseq_plate_data);

    miseq_well_processes($self, $validated_params);

    return $miseq_plate;
}

1;
