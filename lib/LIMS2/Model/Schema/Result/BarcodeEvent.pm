use utf8;
package LIMS2::Model::Schema::Result::BarcodeEvent;

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

=head2 old_well_name

  data_type: 'text'
  is_nullable: 1

=head2 new_well_name

  data_type: 'text'
  is_nullable: 1

=head2 old_plate_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 new_plate_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

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
  "old_well_name",
  { data_type => "text", is_nullable => 1 },
  "new_well_name",
  { data_type => "text", is_nullable => 1 },
  "old_plate_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "new_plate_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "barcode",
  "LIMS2::Model::Schema::Result::Well",
  { barcode => "barcode" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 new_plate

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "new_plate",
  "LIMS2::Model::Schema::Result::Plate",
  { id => "new_plate_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
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
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 old_plate

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "old_plate",
  "LIMS2::Model::Schema::Result::Plate",
  { id => "old_plate_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
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
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wPeHyuRUxvjGdW/4+wrBZg


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub old_well_as_str{
    my $self = shift;
    my $name = "";
    if($self->old_plate){
      $name = $self->old_plate->name."_".$self->old_well_name;
    }
    return $name;
}

sub new_well_as_str{
    my $self = shift;
    my $name = "";
    if($self->new_plate){
      $name = $self->new_plate->name."_".$self->new_well_name;
    }
    return $name;
}

__PACKAGE__->meta->make_immutable;
1;
