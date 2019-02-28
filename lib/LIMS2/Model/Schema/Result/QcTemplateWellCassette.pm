use utf8;
package LIMS2::Model::Schema::Result::QcTemplateWellCassette;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::QcTemplateWellCassette::VERSION = '0.529';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcTemplateWellCassette

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

=head1 TABLE: C<qc_template_well_cassette>

=cut

__PACKAGE__->table("qc_template_well_cassette");

=head1 ACCESSORS

=head2 qc_template_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cassette_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "qc_template_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cassette_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_template_well_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_template_well_id");

=head1 RELATIONS

=head2 cassette

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Cassette>

=cut

__PACKAGE__->belongs_to(
  "cassette",
  "LIMS2::Model::Schema::Result::Cassette",
  { id => "cassette_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_template_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWell>

=cut

__PACKAGE__->belongs_to(
  "qc_template_well",
  "LIMS2::Model::Schema::Result::QcTemplateWell",
  { id => "qc_template_well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JYuXYr0WdUuxUAST56ityQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
