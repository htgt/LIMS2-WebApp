use utf8;
package LIMS2::Model::Schema::Result::MiseqAllelesFrequency;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqAllelesFrequency

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<miseq_alleles_frequency>

=cut

__PACKAGE__->table("miseq_alleles_frequency");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'miseq_alleles_frequency_id_seq'

=head2 miseq_well_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 aligned_sequence

  data_type: 'text'
  is_nullable: 1

=head2 nhej

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 unmodified

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 hdr

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 n_deleted

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 n_inserted

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 n_mutated

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 n_reads

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "miseq_alleles_frequency_id_seq",
  },
  "miseq_well_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "aligned_sequence",
  { data_type => "text", is_nullable => 1 },
  "nhej",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "unmodified",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "hdr",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "n_deleted",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "n_inserted",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "n_mutated",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "n_reads",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 miseq_well_experiment

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqWellExperiment>

=cut

__PACKAGE__->belongs_to(
  "miseq_well_experiment",
  "LIMS2::Model::Schema::Result::MiseqWellExperiment",
  { id => "miseq_well_experiment_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2019-03-28 09:21:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3oJN6zRym1XOvWWiq/9uBA

use Try::Tiny;

sub as_hash {
    my $self = shift;

    my %h = (
        id                          => $self->id,
        miseq_well_experiment_id    => $self->miseq_well_experiment_id,
        aligned_sequence            => $self->aligned_sequence,
        nhej                        => $self->nhej,
        unmodified                  => $self->unmodified,
        hdr                         => $self->hdr,
        n_deleted                   => $self->n_deleted,
        n_inserted                  => $self->n_inserted,
        n_mutated                   => $self->n_mutated, #TODO delete after migration
        n_reads                     => $self->n_reads,
    );

    return \%h;
}

sub reference_sequence {
    my $self = shift;

    my $ref;
    try {
        $ref = $self->reference_sequence;
    };

    return $ref;
}

sub quality_score {
    my $self = shift;

    my $quality;
    try {
        $quality = $self->quality_score;
    };

    return $quality;
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
