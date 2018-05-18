package LIMS2::Model::Plugin::Miseq;

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

sub pspec_create_primer_preset {
    return {
        name                => { validate => 'alphanumeric_string' },
        created_by          => { validate => 'existing_user_id' },
        genomic_threshold   => { validate => 'numeric' },
        gc                  => { validate => 'config_min_max' },
        mt                  => { validate => 'config_min_max' },
        primers             => { validate => 'primer_set' },
    };
}

sub create_primer_preset {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_primer_preset);
    my $current_preset = $self->schema->resultset('MiseqDesignPreset')->find({ name => $validated_params->{name} });

    if ($current_preset) {
        $self->throw( Validation => 'Preset ' . $validated_params->{name} . ' already exists' );
    }

    my $design_preset_params = {
        name        => $validated_params->{name},
        created_by  => $validated_params->{created_by},
        genomic_threshold => $validated_params->{genomic_threshold},
        min_gc      => $validated_params->{gc}->{min},
        max_gc      => $validated_params->{gc}->{max},
        opt_gc      => $validated_params->{gc}->{opt},
        min_mt      => $validated_params->{mt}->{min},
        max_mt      => $validated_params->{mt}->{max},
        opt_mt      => $validated_params->{mt}->{opt},
    };

    my $internal_preset_params = {
        internal        => 1,
        search_width    => $validated_params->{primers}->{miseq}->{widths}->{search},
        offset_width    => $validated_params->{primers}->{miseq}->{widths}->{offset},
        increment_value => $validated_params->{primers}->{miseq}->{widths}->{increment},
    };

    my $external_preset_params = {
        internal        => 0,
        search_width    => $validated_params->{primers}->{pcr}->{widths}->{search},
        offset_width    => $validated_params->{primers}->{pcr}->{widths}->{offset},
        increment_value => $validated_params->{primers}->{pcr}->{widths}->{increment},
    };

    my $design_preset;
    $self->txn_do(
        sub {
            try {
                $design_preset = $self->schema->resultset('MiseqDesignPreset')->create({
                    slice_def(
                        $design_preset_params,
                        qw( name created_by genomic_threshold min_gc max_gc opt_gc min_mt max_mt opt_mt )
                    )
                });

                $internal_preset_params->{preset_id} = $design_preset->id;
                $external_preset_params->{preset_id} = $design_preset->id;

                my $internal_preset = $self->schema->resultset('MiseqPrimerPreset')->create({
                    slice_def(
                        $internal_preset_params,
                        qw( preset_id internal search_width offset_width increment_value )
                    )
                });

                my $external_preset = $self->schema->resultset('MiseqPrimerPreset')->create({
                    slice_def(
                        $external_preset_params,
                        qw( preset_id internal search_width offset_width increment_value )
                    )
                });
            }
            catch {
                $self->throw( Validation => 'Error encounter while creating design preset: ' . $_ );
                $self->model('Golgi')->txn_rollback;
                return;
            };
        }
    );

    return $design_preset;
}

sub pspec_edit_primer_preset {
    return {
        name                => { validate => 'alphanumeric_string' },
        created_by          => { validate => 'existing_user_id' },
        genomic_threshold   => { validate => 'numeric' },
        gc                  => { validate => 'config_min_max' },
        mt                  => { validate => 'config_min_max' },
        primers             => { validate => 'primer_set' },
    };
}

sub edit_primer_preset {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_edit_primer_preset);
    my %preset_search;
    $preset_search{'me.name'} = $validated_params->{name};
    my $design_preset = $self->retrieve(MiseqDesignPreset => \%preset_search);
    my $preset_hash = $design_preset->as_hash;

    my $internal_preset = find_primer_params($self, $preset_hash->{primers}->{miseq}->{id});
    my $external_preset = find_primer_params($self, $preset_hash->{primers}->{pcr}->{id});

    my $preset;
    $preset->{name} = $validated_params->{name} || $preset_hash->{name};
    $preset->{genomic_threshold} = $validated_params->{genomic_threshold} || $preset_hash->{genomic_threshold};

    $preset->{min_gc} = $validated_params->{gc}->{min} || $preset_hash->{gc}->{min};
    $preset->{opt_gc} = $validated_params->{gc}->{opt} || $preset_hash->{gc}->{opt};
    $preset->{max_gc} = $validated_params->{gc}->{max} || $preset_hash->{gc}->{max};

    $preset->{min_mt} = $validated_params->{mt}->{min} || $preset_hash->{mt}->{min};
    $preset->{opt_mt} = $validated_params->{mt}->{opt} || $preset_hash->{mt}->{opt};
    $preset->{max_mt} = $validated_params->{mt}->{max} || $preset_hash->{mt}->{max};
    my $preset_update = $design_preset->update($preset);

    my $internal;
    $internal->{search_width} = $validated_params->{primers}->{miseq}->{widths}->{search} || $preset_hash->{primers}->{miseq}->{widths}->{search};
    $internal->{increment_value} = $validated_params->{primers}->{miseq}->{widths}->{increment} || $preset_hash->{primers}->{widths}->{miseq}->{increment};
    $internal->{offset_width} = $validated_params->{primers}->{miseq}->{widths}->{offset} || $preset_hash->{primers}->{miseq}->{widths}->{offset};
    my $internal_update = $internal_preset->update($internal);

    my $external;
    $external->{search_width} = $validated_params->{primers}->{pcr}->{widths}->{search} || $preset_hash->{primers}->{pcr}->{widths}->{search};
    $external->{increment_value} = $validated_params->{primers}->{pcr}->{widths}->{increment} || $preset_hash->{primers}->{pcr}->{widths}->{increment};
    $external->{offset_width} = $validated_params->{primers}->{pcr}->{widths}->{offset} || $preset_hash->{primers}->{pcr}->{widths}->{offset};
    my $external_update = $external_preset->update($external);

    return $preset_update;
}

sub find_primer_params {
    my ($self, $id) = @_;

    my %search = (
        'me.id'         => $id,
    );
    my $primer_preset = $self->retrieve(MiseqPrimerPreset => \%search);

    return $primer_preset;
}

1;
