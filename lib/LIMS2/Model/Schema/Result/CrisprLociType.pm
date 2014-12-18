use utf8;
package LIMS2::Model::Schema::Result::CrisprLociType;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprLociType::VERSION = '0.278';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprLociType

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

=head1 TABLE: C<crispr_loci_types>

=cut

__PACKAGE__->table("crispr_loci_types");

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

=head2 crispr_off_targets

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprOffTargets>

=cut

__PACKAGE__->has_many(
  "crispr_off_targets",
  "LIMS2::Model::Schema::Result::CrisprOffTargets",
  { "foreign.crispr_loci_type_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Crispr>

=cut

__PACKAGE__->has_many(
  "crisprs",
  "LIMS2::Model::Schema::Result::Crispr",
  { "foreign.crispr_loci_type_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zpk8Cmlf+Z/bZfa0aBFttw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
