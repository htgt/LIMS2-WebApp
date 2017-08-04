use utf8;
package LIMS2::Model::Schema::Result::DesignOligoType;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::DesignOligoType::VERSION = '0.467';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::DesignOligoType

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

=head1 TABLE: C<design_oligo_types>

=cut

__PACKAGE__->table("design_oligo_types");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns("id", { data_type => "text", is_nullable => 0 });

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 design_oligo_appends

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::DesignOligoAppend>

=cut

__PACKAGE__->has_many(
  "design_oligo_appends",
  "LIMS2::Model::Schema::Result::DesignOligoAppend",
  { "foreign.design_oligo_type_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_oligos

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::DesignOligo>

=cut

__PACKAGE__->has_many(
  "design_oligos",
  "LIMS2::Model::Schema::Result::DesignOligo",
  { "foreign.design_oligo_type_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-01-05 14:00:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mryQnVtugVg7PP9p2jmO4Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
