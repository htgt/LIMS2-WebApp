use utf8;
package LIMS2::Model::Schema::Result::MiseqPlate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqPlate

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

=head1 TABLE: C<miseq_plate>

=cut

__PACKAGE__->table("miseq_plate");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'miseq_plate_id_seq'

=head2 plate_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 run_id

  data_type: 'integer'
  is_nullable: 1

=head2 is_384

  data_type: 'boolean'
  is_nullable: 0

=head2 results_available

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "miseq_plate_id_seq",
  },
  "plate_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "run_id",
  { data_type => "integer", is_nullable => 1 },
  "is_384",
  { data_type => "boolean", is_nullable => 0 },
  "results_available",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 miseq_experiments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::MiseqExperiment>

=cut

__PACKAGE__->has_many(
  "miseq_experiments",
  "LIMS2::Model::Schema::Result::MiseqExperiment",
  { "foreign.miseq_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plate

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "plate",
  "LIMS2::Model::Schema::Result::Plate",
  { id => "plate_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nM6esnU8m8MYgzyDpPjtgA

sub as_hash {
    my $self = shift;

    my %h = (
        id          => $self->id,
        plate_id    => $self->plate_id,
        384         => $self->is_384,
        name        => $self->plate->name,
        date        => $self->plate->created_at->datetime,
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
