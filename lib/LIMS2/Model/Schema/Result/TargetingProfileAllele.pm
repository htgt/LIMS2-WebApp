use utf8;
package LIMS2::Model::Schema::Result::TargetingProfileAllele;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::TargetingProfileAllele

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

=head1 TABLE: C<targeting_profile_alleles>

=cut

__PACKAGE__->table("targeting_profile_alleles");

=head1 ACCESSORS

=head2 targeting_profile_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 allele_type

  data_type: 'text'
  is_nullable: 0

=head2 cassette_function

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 mutation_type

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "targeting_profile_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "allele_type",
  { data_type => "text", is_nullable => 0 },
  "cassette_function",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "mutation_type",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</targeting_profile_id>

=item * L</allele_type>

=back

=cut

__PACKAGE__->set_primary_key("targeting_profile_id", "allele_type");

=head1 RELATIONS

=head2 cassette_function

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CassetteFunction>

=cut

__PACKAGE__->belongs_to(
  "cassette_function",
  "LIMS2::Model::Schema::Result::CassetteFunction",
  { id => "cassette_function" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 targeting_profile

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::TargetingProfile>

=cut

__PACKAGE__->belongs_to(
  "targeting_profile",
  "LIMS2::Model::Schema::Result::TargetingProfile",
  { id => "targeting_profile_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TzsXgzr7YphdSYaLxQEa7w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
