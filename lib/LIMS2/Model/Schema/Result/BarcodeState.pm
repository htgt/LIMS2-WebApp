use utf8;
package LIMS2::Model::Schema::Result::BarcodeState;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::BarcodeState::VERSION = '0.309';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::BarcodeState

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

=head1 TABLE: C<barcode_states>

=cut

__PACKAGE__->table("barcode_states");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 barcode_events_new_states

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BarcodeEvent>

=cut

__PACKAGE__->has_many(
  "barcode_events_new_states",
  "LIMS2::Model::Schema::Result::BarcodeEvent",
  { "foreign.new_state" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 barcode_events_old_states

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BarcodeEvent>

=cut

__PACKAGE__->has_many(
  "barcode_events_old_states",
  "LIMS2::Model::Schema::Result::BarcodeEvent",
  { "foreign.old_state" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_barcodes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellBarcode>

=cut

__PACKAGE__->has_many(
  "well_barcodes",
  "LIMS2::Model::Schema::Result::WellBarcode",
  { "foreign.barcode_state" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-10-06 15:08:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xzbtzIoHkGytJY0s/pIgLg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
