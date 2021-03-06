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
use Data::Dumper;
use LIMS2::Model::Util::CrispressoSubmission qw/get_eps_for_plate/;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_crispr_submission{
    return {
        miseq_well_exp_id   => { validate => 'existing_miseq_well_exp'          },
        crispr              => { validate => 'non_empty_string', optional => 1  },
    };
}

sub create_crispr_submission{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_crispr_submission);

    $self->schema->resultset('CrispressoSubmission')->create(
           { slice_def(
                   $validated_params,
                   qw(miseq_well_exp_id crispr)
               )
           }
       );
       #$self->log->info('Created crispresso submission entry');
    return;

}

sub pspec_update_crispr_submission{
    return {
        miseq_well_exp_id   => { validate => 'existing_miseq_well_exp'          },
        crispr              => { validate => 'non_empty_string', optional => 1  },
    };
}

sub update_crispr_submission{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_update_crispr_submission);

    my %search;
    $search{'me.miseq_well_exp_id'} = $validated_params->{miseq_well_exp_id};

    my $sub_rs = $self->retrieve( CrispressoSubmission => \%search );

    my $sub_hash = $sub_rs->as_hash;
    my $crispr_sub;
    $crispr_sub->{miseq_well_exp_id} = check_undef($validated_params->{miseq_well_exp_id}, $sub_hash->{miseq_well_exp_id});
    $crispr_sub->{crispr} = check_undef( $validated_params->{crispr}, $sub_hash->{crispr});
    $crispr_sub->{date_stamp} = gmtime();

    $sub_rs->update($crispr_sub);

    $self->log->info('Updated Crispresso Submission: ' . $sub_rs->id);

    return $sub_rs;
}

sub pspec_create_indel_distribution_graph{
    return {
        id                              => { validate => 'existing_miseq_well_exp'          },
        indel_size_distribution_graph   => { validate => 'non_empty_string', optional => 1  }
    };
}

sub create_indel_distribution_graph{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_indel_distribution_graph);

    $self->schema->resultset('IndelDistributionGraph')->create(
           { slice_def(
                   $validated_params,
                   qw( id indel_size_distribution_graph )
               )
           }
       );
       #$self->log->info('Created Indel Distribution Graph for miseq well experiment ');
    return;

}

sub pspec_create_miseq_alleles_frequency{
    return  {
        miseq_well_experiment_id  =>  { validate => 'existing_miseq_well_exp'                       },
        aligned_sequence          =>  { validate => 'sequencing_result'                             },
        quality_score             =>  { validate => 'phred_string', optional => 1                   },
        reference_sequence        =>  { validate => 'sequencing_result', optional => 1              },
        nhej                      =>  { validate => 'boolean_string'                                },
        unmodified                =>  { validate => 'boolean_string'                                },
        hdr                       =>  { validate => 'boolean_string'                                },
        n_deleted                 =>  { validate => 'integer'                                       },
        n_inserted                =>  { validate => 'integer'                                       },
        n_mutated                 =>  { validate => 'integer'                                       },
        n_reads                   =>  { validate => 'integer'                                       }
    };
}

sub create_miseq_alleles_frequency {
    my ($self, $params) = @_;
    my $validated_params = $self->check_params($params, pspec_create_miseq_alleles_frequency);
    my $miseq_frequency = $self->schema->resultset('MiseqAllelesFrequency')->create({
        slice_def (
            $validated_params,
            qw( miseq_well_experiment_id aligned_sequence reference_sequence quality_score nhej unmodified hdr n_deleted n_inserted n_mutated n_reads)
        )
    });

    $self->log->info('Created Miseq allele frequency: ' . $miseq_frequency->id);

    return $miseq_frequency;
}

sub pspec_update_miseq_alleles_frequency {
    return {
        id                          => { validate => 'existing_miseq_alleles_frequency' },
        miseq_well_experiment_id    => { validate => 'existing_miseq_well_exp', optional => 1 },
        aligned_sequence            => { validate => 'sequencing_result', optional => 1 },
        nhej                        => { validate => 'boolean_string', optional => 1 },
        unmodified                  => { validate => 'boolean_string', optional => 1 },
        hdr                         => { validate => 'boolean_string', optional => 1 },
        n_deleted                   => { validate => 'integer' },
        n_inserted                  => { validate => 'integer' },
        n_mutated                   => { validate => 'integer' },
        n_reads                     => { validate => 'integer' },
        reference_sequence          => { validate => 'sequencing_result', optional => 1 },
        quality_score               => { validate => 'phred_string', optional => 1 },
    };
}

sub update_miseq_alleles_frequency {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_update_miseq_alleles_frequency);

    my %search;
    $search{'me.id'} = $validated_params->{id};

    my $freq = $self->retrieve( MiseqAllelesFrequency => \%search );

    my $hash_freq = $freq->as_hash;
    my $allele;
    $allele->{id} = check_undef($validated_params->{id}, $hash_freq->{id});
    $allele->{aligned_sequence} = check_undef( $validated_params->{aligned_sequence}, $hash_freq->{aligned_sequence});
    $allele->{miseq_well_experiment_id} = check_undef($validated_params->{miseq_well_experiment_id}, $hash_freq->{miseq_well_experiment_id});
    $allele->{nhej} = check_undef($validated_params->{nhej}, $hash_freq->{nhej});
    $allele->{unmodified} = check_undef($validated_params->{unmodified}, $hash_freq->{unmodified});
    $allele->{hdr} = check_undef($validated_params->{hdr}, $hash_freq->{hdr});
    $allele->{n_deleted} = check_undef($validated_params->{n_deleted}, $hash_freq->{n_deleted});
    $allele->{n_inserted} = check_undef($validated_params->{n_inserted}, $hash_freq->{n_inserted});
    $allele->{n_mutated} = check_undef($validated_params->{n_mutated}, $hash_freq->{n_mutated});
    $allele->{n_reads} = check_undef($validated_params->{n_reads}, $hash_freq->{n_reads});
    $allele->{reference_sequence} = check_undef($validated_params->{reference_sequence}, $hash_freq->{reference_sequence});
    $allele->{quality_score} = check_undef($validated_params->{quality_score}, $hash_freq->{quality_score});

    $freq->update($allele);

    $self->log->info('Updated Miseq allele frequency: ' . $allele->{id});

    return $freq;
}

sub pspec_create_indel_histogram {
    return  {
        miseq_well_experiment_id    => { validate => 'existing_miseq_well_exp'  },
        indel_size                  => { validate => 'integer'                  },
        frequency                   => { validate => 'integer'                  }
    };
}

sub create_indel_histogram {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_create_indel_histogram);

    my $entry = $self->schema->resultset('IndelHistogram')->create({
        slice_def(
            $validated_params,
            qw( miseq_well_experiment_id indel_size frequency )
        )
    });

    $self->log->info('Created indel entry: ' . $entry->id);

    return $entry;
}

sub pspec_update_indel_histogram {
    return  {
        id                          => { validate => 'existing_indel_histogram'                 },
        miseq_well_experiment_id    => { validate => 'existing_miseq_well_exp', optional => 1   },
        indel_size                  => { validate => 'integer', optional => 1                   },
        frequency                   => { validate => 'integer'                                  }
    };
}

sub update_indel_histogram {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_update_indel_histogram);

    my %search;
    $search{'me.id'} = $validated_params->{id};

    my $histo = $self->retrieve( IndelHistogram => \%search );
    my $histo_hash = $histo->as_hash;

    my $histo_record;
    $histo_record->{id} = check_undef($validated_params->{id}, $histo_hash->{id});
    $histo_record->{miseq_well_experiment_id} = check_undef( $validated_params->{miseq_well_experiment_id}, $histo_hash->{well_exp_id});
    $histo_record->{indel_size} = check_undef($validated_params->{indel_size}, $histo_hash->{indel_size});
    $histo_record->{frequency} = check_undef($validated_params->{frequency}, $histo_hash->{frequency});

    $histo->update($histo_record);
    $self->log->info('Updating indel entry: ' . $histo->id);

    return $histo;
}

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
        total_reads     => { validate => 'integer', optional => 1},
        nhej_reads      => { validate => 'integer', optional => 1},
        hdr_reads       => { validate => 'integer', optional => 1},
        mixed_reads     => { validate => 'integer', optional => 1},
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
                qw( well_id miseq_exp_id classification frameshifted status total_reads nhej_reads hdr_reads mixed_reads)
            )
        }
    );
    return $miseq;
}

sub pspec_update_miseq_well_experiment {
    return {
        id                              => { validate => 'existing_miseq_well_exp' },
        miseq_exp_id                    => { validate => 'existing_miseq_experiment', optional => 1 },
        classification                  => { validate => 'existing_miseq_classification', optional => 1 },
        frameshifted                    => { validate => 'boolean', optional => 1 },
        status                          => { validate => 'existing_miseq_status', optional => 1 },
        well_id                         => { validate => 'existing_well_id', optional => 1 },
        nhej_reads                      => { validate => 'integer', optional => 1 },
        total_reads                     => { validate => 'integer', optional => 1 },
        hdr_reads                       => { validate => 'integer', optional => 1 },
        mixed_reads                     => { validate => 'integer', optional => 1 },
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
    $class->{id} = check_undef($validated_params->{id}, $hash_well->{id});
    $class->{classification} =check_undef( $validated_params->{classification}, $hash_well->{classification});
    $class->{miseq_exp_id} = check_undef($validated_params->{miseq_exp_id}, $hash_well->{miseq_exp_id});
    $class->{frameshifted} = check_undef($validated_params->{frameshifted}, $hash_well->{frameshifted});
    $class->{status} = check_undef($validated_params->{status}, $hash_well->{status});
    $class->{total_reads} = check_undef($validated_params->{total_reads}, $hash_well->{total_reads});
    $class->{nhej_reads} = check_undef($validated_params->{nhej_reads}, $hash_well->{nhej_reads});
    $class->{hdr_reads} = check_undef($validated_params->{hdr_reads}, $hash_well->{hdr_reads});
    $class->{mixed_reads} = check_undef($validated_params->{mixed_reads}, $hash_well->{mixed_reads});
    $well->update($class);

    return;
}

sub pspec_create_miseq_experiment {
    return {
        miseq_id        => { validate => 'existing_miseq_plate' },
        name            => { validate => 'non_empty_string' },
        gene            => { validate => 'non_empty_string' },
        nhej_reads      => { validate => 'integer', optional => 1 },
        parent_plate_id => { validate => 'existing_plate_id', optional => 1 },
        experiment_id   => { validate => 'existing_experiment_id', optional => 1 },
        total_reads     => { validate => 'integer', optional => 1 },
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
                qw( miseq_id name experiment_id parent_plate_id gene nhej_reads total_reads )
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
        nhej_reads      => { validate => 'integer', optional => 1 },
        experiment_id   => { validate => 'existing_experiment_id', optional => 1 },
        parent_plate_id => { validate => 'existing_plate_id', optional => 1 },
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
    $class->{miseq_id} =  check_undef( $validated_params->{miseq_id}, $hash_well->{miseq_id} );
    $class->{name} =  check_undef( $validated_params->{name}, $hash_well->{name} );
    $class->{gene} =  check_undef( $validated_params->{gene}, $hash_well->{gene} );
    $class->{nhej_reads} = check_undef( $validated_params->{nhej_reads}, $hash_well->{nhej_count} );
    $class->{total_reads} = check_undef( $validated_params->{total_reads}, $hash_well->{read_count} );

    $class->{experiment_id} = $validated_params->{experiment_id} || $hash_well->{experiment_id};
    $class->{parent_plate_id} = $validated_params->{parent_plate_id} || $hash_well->{parent_plate_id};
    $class->{old_miseq_id} = $hash_well->{old_miseq_id};

    my $update = $exp->update($class);

    return $update;
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

    miseq_experiment_inheritance($self, $miseq_plate, $validated_params);

    return $miseq_plate;
}

sub miseq_experiment_inheritance {
    my ($self, $miseq_plate, $params) = @_;

    my $experiments = _construct_miseq_exps($self, $miseq_plate->id, $params);
    foreach my $experiment (values %{ $experiments }) {
        $self->create_miseq_experiment($experiment);
    }

    return;
}

sub _construct_miseq_exps {
    my ($self, $miseq_plate_id, $params) = @_;

    my $experiments;
    foreach my $parent (keys %{ $params->{data} }) {
        my $parent_plate = $self->schema->resultset('Plate')->find({ name => $parent });
        my $eps = get_eps_for_plate($self, $parent_plate->id);
        foreach my $ep (keys %{ $eps }) {
            my $ep_data = $eps->{$ep};
            my $exp_name = $parent . '_' . $ep_data->{gene};
            $experiments->{$exp_name} = {
                name                => $exp_name,
                experiment_id       => $ep_data->{exp_id},
                gene                => $ep_data->{gene},
                parent_plate_id     => $parent_plate->id,
                miseq_id            => $miseq_plate_id,
            };
        }
    }

    return $experiments;
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
        id                  => { validate => 'existing_preset_id' },
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
    $preset_search{'me.id'} = $validated_params->{id};
    my $design_preset = $self->retrieve(MiseqDesignPreset => \%preset_search);
    my $preset_hash = $design_preset->as_hash;

    my $internal_preset = find_primer_params($self, $preset_hash->{primers}->{miseq}->{id});
    my $external_preset = find_primer_params($self, $preset_hash->{primers}->{pcr}->{id});

    my $preset;
    $preset->{name} = $validated_params->{name} || $preset_hash->{name};
    $preset->{genomic_threshold} = $validated_params->{genomic_threshold} || $preset_hash->{genomic_threshold};
    $preset = update_preset_limits($preset, $validated_params, $preset_hash, 'gc');
    $preset = update_preset_limits($preset, $validated_params, $preset_hash, 'mt');
    my $preset_update = $design_preset->update($preset);

    my $internal = update_primer_limits($validated_params, $preset_hash, 'miseq');
    my $internal_update = $internal_preset->update($internal);

    my $external = update_primer_limits($validated_params, $preset_hash, 'pcr');
    my $external_update = $external_preset->update($external);

    return $preset_update;
}

sub pspec_update_hdr_template {
    return {
        id  => { validate => 'existing_design_id', rename => 'design_id' },
        seq => { validate => 'dna_seq', rename => 'template' },
    };
}

sub update_hdr_template {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, pspec_update_hdr_template);

    my $hdr_rc = $self->schema->resultset('HdrTemplate')->find({ design_id => $validated_params->{design_id} });

    if ($hdr_rc) {
        $hdr_rc = $hdr_rc->update($validated_params);
    } else {
        $hdr_rc = $self->schema->resultset('HdrTemplate')->create({
            slice_def(
                $validated_params,
                qw( design_id template )
            )
        });
    }

    return $hdr_rc;
}

sub find_primer_params {
    my ($self, $id) = @_;

    my %search = (
        'me.id' => $id,
    );
    my $primer_preset = $self->retrieve(MiseqPrimerPreset => \%search);

    return $primer_preset;
}

sub update_preset_limits {
    my ($preset, $validated, $reference, $sect) = @_;

    my @limits = qw(min opt max);
    foreach my $limit (@limits) {
        my $key_name = $limit . '_' . $sect;
        $preset->{$key_name} = preset_param($validated, $reference, $sect, $limit);
    }

    return $preset;
}

sub preset_param {
    my ($validated, $reference, $section, $param) = @_;

    return $validated->{$section}->{$param} || $reference->{$section}->{$param};
}

sub update_primer_limits {
    my ($validated, $reference, $sect) = @_;

    my $primer;
    my %limits = (
        search      => 'width',
        increment   => 'value',
        offset      => 'width'
    );

    foreach my $limit (keys %limits) {
        my $key_name = $limit . '_' . $limits{$limit};
        $primer->{$key_name} = primer_param($validated, $reference, $sect, $limit);
    }

    return $primer;
}

sub primer_param {
    my ($validated, $reference, $section, $param) = @_;

    return $validated->{primers}->{$section}->{widths}->{$param} || $reference->{primers}->{$section}->{widths}->{$param};
}

sub check_undef{
    my ($updated, $existing) = @_;
    if (defined $updated){
           return $updated;
    }
    else{
        if(defined $existing){
            return $existing;
        }
    }
    return "0";
}


1;
