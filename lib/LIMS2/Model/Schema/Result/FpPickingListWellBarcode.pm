use utf8;
package LIMS2::Model::Schema::Result::FpPickingListWellBarcode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::FpPickingListWellBarcode

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

=head1 TABLE: C<fp_picking_list_well_barcode>

=cut

__PACKAGE__->table("fp_picking_list_well_barcode");

=head1 ACCESSORS

=head2 fp_picking_list_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 well_barcode

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 picked

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "fp_picking_list_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "well_barcode",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "picked",
  { data_type => "boolean", is_nullable => 1 },
);

=head1 RELATIONS

=head2 fp_picking_list

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::FpPickingList>

=cut

__PACKAGE__->belongs_to(
  "fp_picking_list",
  "LIMS2::Model::Schema::Result::FpPickingList",
  { id => "fp_picking_list_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 well_barcode

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::WellBarcode>

=cut

__PACKAGE__->belongs_to(
  "well_barcode",
  "LIMS2::Model::Schema::Result::WellBarcode",
  { barcode => "well_barcode" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-10-27 10:58:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q4aAQIfj/BXPK3Pwf/9cuQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
