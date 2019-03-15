use utf8;
package LIMS2::Model::Schema::Result::FpPickingList;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::FpPickingList::VERSION = '0.531';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::FpPickingList

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

=head1 TABLE: C<fp_picking_list>

=cut

__PACKAGE__->table("fp_picking_list");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'fp_picking_list_id_seq'

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

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
    sequence          => "fp_picking_list_id_seq",
  },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
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

=head2 fp_picking_list_well_barcodes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::FpPickingListWellBarcode>

=cut

__PACKAGE__->has_many(
  "fp_picking_list_well_barcodes",
  "LIMS2::Model::Schema::Result::FpPickingListWellBarcode",
  { "foreign.fp_picking_list_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-10-27 10:58:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jl3GsgdoWbGcVbrvgQ8goQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
sub well_barcodes{
    my ($self) = @_;
    my @well_barcodes = map { $_->well_barcode } $self->fp_picking_list_well_barcodes;
    return @well_barcodes;
}

sub picked_well_barcodes{
    my ($self) = @_;
    my $picked_rs = $self->search_related('fp_picking_list_well_barcodes',{
        picked => 1,
    });
    return map { $_->well_barcode } $picked_rs->all;
}

__PACKAGE__->meta->make_immutable;
1;
