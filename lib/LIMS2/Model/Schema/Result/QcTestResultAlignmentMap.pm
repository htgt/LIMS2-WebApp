use utf8;
package LIMS2::Model::Schema::Result::QcTestResultAlignmentMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcTestResultAlignmentMap

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

=head1 TABLE: C<qc_test_result_alignment_map>

=cut

__PACKAGE__->table("qc_test_result_alignment_map");

=head1 ACCESSORS

=head2 qc_test_result_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 qc_test_result_alignment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "qc_test_result_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "qc_test_result_alignment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_test_result_id>

=item * L</qc_test_result_alignment_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_test_result_id", "qc_test_result_alignment_id");

=head1 RELATIONS

=head2 qc_test_result

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcTestResult>

=cut

__PACKAGE__->belongs_to(
  "qc_test_result",
  "LIMS2::Model::Schema::Result::QcTestResult",
  { id => "qc_test_result_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_test_result_alignment

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcTestResultAlignment>

=cut

__PACKAGE__->belongs_to(
  "qc_test_result_alignment",
  "LIMS2::Model::Schema::Result::QcTestResultAlignment",
  { id => "qc_test_result_alignment_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2012-04-13 11:34:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tIP1Oi08ng/+Y/V10kTRKQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
