use utf8;
package LIMS2::Model::Schema::Result::DesignAmplicon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::DesignAmplicon

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

=head1 TABLE: C<design_amplicons>

=cut

__PACKAGE__->table("design_amplicons");

=head1 ACCESSORS

=head2 design_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 amplicon_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "design_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "amplicon_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</amplicon_id>

=back

=cut

__PACKAGE__->set_primary_key("amplicon_id");

=head1 RELATIONS

=head2 amplicon

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Amplicon>

=cut

__PACKAGE__->belongs_to(
  "amplicon",
  "LIMS2::Model::Schema::Result::Amplicon",
  { id => "amplicon_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "LIMS2::Model::Schema::Result::Design",
  { id => "design_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-28 08:29:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dzqdYO5nV5jGJ/EF67hmpA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
