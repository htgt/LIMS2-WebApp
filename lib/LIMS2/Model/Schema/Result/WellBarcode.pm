use utf8;
package LIMS2::Model::Schema::Result::WellBarcode;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::WellBarcode::VERSION = '0.318';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::WellBarcode

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

=head1 TABLE: C<well_barcodes>

=cut

__PACKAGE__->table("well_barcodes");

=head1 ACCESSORS

=head2 well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 barcode

  data_type: 'varchar'
  is_nullable: 0
  size: 40

=head2 barcode_state

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 root_piq_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "barcode",
  { data_type => "varchar", is_nullable => 0, size => 40 },
  "barcode_state",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "root_piq_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</well_id>

=back

=cut

__PACKAGE__->set_primary_key("well_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<well_barcodes_barcode_key>

=over 4

=item * L</barcode>

=back

=cut

__PACKAGE__->add_unique_constraint("well_barcodes_barcode_key", ["barcode"]);

=head1 RELATIONS

=head2 barcode_events

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BarcodeEvent>

=cut

__PACKAGE__->has_many(
  "barcode_events",
  "LIMS2::Model::Schema::Result::BarcodeEvent",
  { "foreign.barcode" => "self.barcode" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 barcode_state

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::BarcodeState>

=cut

__PACKAGE__->belongs_to(
  "barcode_state",
  "LIMS2::Model::Schema::Result::BarcodeState",
  { id => "barcode_state" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 fp_picking_list_well_barcodes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::FpPickingListWellBarcode>

=cut

__PACKAGE__->has_many(
  "fp_picking_list_well_barcodes",
  "LIMS2::Model::Schema::Result::FpPickingListWellBarcode",
  { "foreign.well_barcode" => "self.barcode" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 root_piq_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "root_piq_well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "root_piq_well_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-10-27 10:58:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yturBr4xEPgf+sCdt1wRZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

# Find most recent event for the barcode.
# If state is provided find the most recent event which *changed* the state to the one specified
sub most_recent_event{
    my ($self, $state) = @_;

    my $search_criteria = {};

    if($state){
        $search_criteria = {
            new_state => $state,
            old_state => {'!=' => $state }
        };
    }

    my $event = $self->search_related('barcode_events',
        $search_criteria,
        {
            order_by => { -desc => [qw/created_at/] }
        }
    )->first;

    return $event;
}

__PACKAGE__->meta->make_immutable;
1;
