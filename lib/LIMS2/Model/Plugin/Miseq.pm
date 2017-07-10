package LIMS2::Model::Plugin::Miseq;

use strict;
use warnings FATAL => 'all';

use Moose::Role;

use Hash::MoreUtils qw( slice slice_def );
use Const::Fast;
use Try::Tiny;
use Log::Log4perl qw( :easy );
use namespace::autoclean;
use LIMS2::Model::Util::Miseq qw( miseq_plate_from_json );

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_miseq_plate {
    return {
        plate_id    => { validate => 'existing_plate_id' },
        is_384      => { validate => 'boolean' },
        run_id      => { optional => 1 },
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


sub pspec_create_miseq_well {
    return {
        well_id => { validate => 'integer' },
        status  => { validate => 'existing_miseq_status' },
    };
}

# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub create_miseq_well {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_miseq_well);

    my $miseq = $self->schema->resultset('MiseqWell')->create(
        {   slice_def(
                $validated_params,
                qw( well_id status )
            )
        }
    );

    $self->log->info('Created MiSEQ Well: ' . $miseq->id);

    return $miseq;
}

sub pspec_update_miseq_well {
    return {
        id      => { validate => 'existing_miseq_well' },
        well_id => { validate => 'existing_well_id' },
        status  => { validate => 'existing_miseq_status' },
    };
}

sub update_miseq_well {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_update_miseq_well);

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

sub upload_miseq_plate {
    my ($self, $c, $params) = @_;

    my $miseq = miseq_plate_from_json($self, $c, $params);

    return $miseq;
}

1;
