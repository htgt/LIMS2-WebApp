use utf8;
package LIMS2::Model::Schema::Result::QcTestResultAlignRegion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcTestResultAlignRegion

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

=head1 TABLE: C<qc_test_result_align_regions>

=cut

__PACKAGE__->table("qc_test_result_align_regions");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 length

  data_type: 'integer'
  is_nullable: 0

=head2 match_count

  data_type: 'integer'
  is_nullable: 0

=head2 query_str

  data_type: 'text'
  is_nullable: 0

=head2 target_str

  data_type: 'text'
  is_nullable: 0

=head2 match_str

  data_type: 'text'
  is_nullable: 0

=head2 pass

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "length",
  { data_type => "integer", is_nullable => 0 },
  "match_count",
  { data_type => "integer", is_nullable => 0 },
  "query_str",
  { data_type => "text", is_nullable => 0 },
  "target_str",
  { data_type => "text", is_nullable => 0 },
  "match_str",
  { data_type => "text", is_nullable => 0 },
  "pass",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 RELATIONS

=head2 id

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcTestResultAlignment>

=cut

__PACKAGE__->belongs_to(
  "id",
  "LIMS2::Model::Schema::Result::QcTestResultAlignment",
  { id => "id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2012-04-13 11:34:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+geUct8PyiSE6t7q1X2/Ng


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
