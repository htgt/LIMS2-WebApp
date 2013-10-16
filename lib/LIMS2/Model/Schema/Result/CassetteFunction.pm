use utf8;
package LIMS2::Model::Schema::Result::CassetteFunction;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CassetteFunction::VERSION = '0.111';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CassetteFunction

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

=head1 TABLE: C<cassette_function>

=cut

__PACKAGE__->table("cassette_function");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 promoter

  data_type: 'boolean'
  is_nullable: 1

=head2 conditional

  data_type: 'boolean'
  is_nullable: 1

=head2 cre

  data_type: 'boolean'
  is_nullable: 1

=head2 well_has_cre

  data_type: 'boolean'
  is_nullable: 1

=head2 well_has_no_recombinase

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "promoter",
  { data_type => "boolean", is_nullable => 1 },
  "conditional",
  { data_type => "boolean", is_nullable => 1 },
  "cre",
  { data_type => "boolean", is_nullable => 1 },
  "well_has_cre",
  { data_type => "boolean", is_nullable => 1 },
  "well_has_no_recombinase",
  { data_type => "boolean", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 project_alleles

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProjectAllele>

=cut

__PACKAGE__->has_many(
  "project_alleles",
  "LIMS2::Model::Schema::Result::ProjectAllele",
  { "foreign.cassette_function" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-23 11:51:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vv9clLy/oDD7i4sJp8VIRA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
