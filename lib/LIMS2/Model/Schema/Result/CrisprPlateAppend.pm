use utf8;
package LIMS2::Model::Schema::Result::CrisprPlateAppend;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprPlateAppend::VERSION = '0.507';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprPlateAppend

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

=head1 TABLE: C<crispr_plate_appends>

=cut

__PACKAGE__->table("crispr_plate_appends");

=head1 ACCESSORS

=head2 plate_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 append_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "plate_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "append_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</plate_id>

=back

=cut

__PACKAGE__->set_primary_key("plate_id");

=head1 RELATIONS

=head2 append

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprPlateAppendsType>

=cut

__PACKAGE__->belongs_to(
  "append",
  "LIMS2::Model::Schema::Result::CrisprPlateAppendsType",
  { id => "append_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 plate

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "plate",
  "LIMS2::Model::Schema::Result::Plate",
  { id => "plate_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-05-12 11:46:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wVoEVmegWYKe9Vkje7zdjQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
