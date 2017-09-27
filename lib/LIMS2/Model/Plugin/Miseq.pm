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

sub pspec_create_miseq_well {
    return {
        plate_id    => { validate => 'existing_plate_id'},
        well_name   => { validate => 'well_name' },
    };
}

sub create_miseq_well {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_miseq_well);

    my $well_params = {

    };

    $self->create_well($well_params);

    return;
}

=head 

sub pspec_create_well {
    return {
        plate_name   => { validate => 'existing_plate_name' },
        well_name    => { validate => 'well_name', rename => 'name' },
        accepted     => { validate => 'boolean', optional => 1 },
        process_data => { validate => 'hashref' },
        created_by => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    };
}

=cut

1;
