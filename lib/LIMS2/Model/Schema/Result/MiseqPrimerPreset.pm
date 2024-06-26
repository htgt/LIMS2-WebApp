use utf8;
package LIMS2::Model::Schema::Result::MiseqPrimerPreset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqPrimerPreset

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

=head1 TABLE: C<miseq_primer_presets>

=cut

__PACKAGE__->table("miseq_primer_presets");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'miseq_primer_presets_id_seq'

=head2 preset_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 internal

  data_type: 'boolean'
  is_nullable: 0

=head2 search_width

  data_type: 'integer'
  is_nullable: 0

=head2 offset_width

  data_type: 'integer'
  is_nullable: 0

=head2 increment_value

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "miseq_primer_presets_id_seq",
  },
  "preset_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "internal",
  { data_type => "boolean", is_nullable => 0 },
  "search_width",
  { data_type => "integer", is_nullable => 0 },
  "offset_width",
  { data_type => "integer", is_nullable => 0 },
  "increment_value",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 preset

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqDesignPreset>

=cut

__PACKAGE__->belongs_to(
  "preset",
  "LIMS2::Model::Schema::Result::MiseqDesignPreset",
  { id => "preset_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JwW2i6EMa80U3FjKMOmvug

sub as_hash {
    my $self = shift;

    my %h = (
        id => $self->id,
        preset_id => $self->preset_id,
        internal => $self->internal,
        widths => {
            search => $self->search_width,
            offset => $self->offset_width,
            increment => $self->increment_value,
        },
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
