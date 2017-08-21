use utf8;
package LIMS2::Model::Schema::Result::CrisprPlateAppendsType;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprPlateAppendsType::VERSION = '0.469';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprPlateAppendsType

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

=head1 TABLE: C<crispr_plate_appends_type>

=cut

__PACKAGE__->table("crispr_plate_appends_type");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 crispr_plate_appends

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPlateAppend>

=cut

__PACKAGE__->has_many(
  "crispr_plate_appends",
  "LIMS2::Model::Schema::Result::CrisprPlateAppend",
  { "foreign.append_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-05-12 11:46:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6REjYbDRYXWGIDTGaCyv3w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
