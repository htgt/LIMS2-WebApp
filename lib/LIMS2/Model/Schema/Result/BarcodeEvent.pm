use utf8;
package LIMS2::Model::Schema::Result::BarcodeEvent;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::BarcodeEvent::VERSION = '0.346';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::BarcodeEvent

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

=head1 TABLE: C<barcode_events>

=cut

__PACKAGE__->table("barcode_events");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'barcode_events_id_seq'

=head2 barcode

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 old_state

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 new_state

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 old_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 new_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 created_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "barcode_events_id_seq",
  },
  "barcode",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "old_state",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "new_state",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "old_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "new_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "created_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 barcode

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::WellBarcode>

=cut

__PACKAGE__->belongs_to(
  "barcode",
  "LIMS2::Model::Schema::Result::WellBarcode",
  { barcode => "barcode" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 new_state

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::BarcodeState>

=cut

__PACKAGE__->belongs_to(
  "new_state",
  "LIMS2::Model::Schema::Result::BarcodeState",
  { id => "new_state" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 new_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "new_well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "new_well_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 old_state

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::BarcodeState>

=cut

__PACKAGE__->belongs_to(
  "old_state",
  "LIMS2::Model::Schema::Result::BarcodeState",
  { id => "old_state" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 old_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "old_well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "old_well_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-10-06 15:08:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9/F3r3tcKV9NZXgoimonFQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
