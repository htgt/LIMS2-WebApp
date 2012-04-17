use utf8;
package LIMS2::Model::Schema::Result::QcTestResultAlignment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcTestResultAlignment

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

=head1 TABLE: C<qc_test_result_alignments>

=cut

__PACKAGE__->table("qc_test_result_alignments");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'qc_test_result_alignments_id_seq'

=head2 qc_seq_read_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 primer_name

  data_type: 'text'
  is_nullable: 0

=head2 query_start

  data_type: 'integer'
  is_nullable: 0

=head2 query_end

  data_type: 'integer'
  is_nullable: 0

=head2 query_strand

  data_type: 'integer'
  is_nullable: 0

=head2 target_start

  data_type: 'integer'
  is_nullable: 0

=head2 target_end

  data_type: 'integer'
  is_nullable: 0

=head2 target_strand

  data_type: 'integer'
  is_nullable: 0

=head2 score

  data_type: 'integer'
  is_nullable: 0

=head2 pass

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 features

  data_type: 'text'
  is_nullable: 0

=head2 cigar

  data_type: 'text'
  is_nullable: 0

=head2 op_str

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "qc_test_result_alignments_id_seq",
  },
  "qc_seq_read_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "primer_name",
  { data_type => "text", is_nullable => 0 },
  "query_start",
  { data_type => "integer", is_nullable => 0 },
  "query_end",
  { data_type => "integer", is_nullable => 0 },
  "query_strand",
  { data_type => "integer", is_nullable => 0 },
  "target_start",
  { data_type => "integer", is_nullable => 0 },
  "target_end",
  { data_type => "integer", is_nullable => 0 },
  "target_strand",
  { data_type => "integer", is_nullable => 0 },
  "score",
  { data_type => "integer", is_nullable => 0 },
  "pass",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "features",
  { data_type => "text", is_nullable => 0 },
  "cigar",
  { data_type => "text", is_nullable => 0 },
  "op_str",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 qc_seq_read

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcSeqRead>

=cut

__PACKAGE__->belongs_to(
  "qc_seq_read",
  "LIMS2::Model::Schema::Result::QcSeqRead",
  { id => "qc_seq_read_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_test_result_align_regions

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTestResultAlignRegion>

=cut

__PACKAGE__->has_many(
  "qc_test_result_align_regions",
  "LIMS2::Model::Schema::Result::QcTestResultAlignRegion",
  { "foreign.id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_test_result_alignment_maps

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTestResultAlignmentMap>

=cut

__PACKAGE__->has_many(
  "qc_test_result_alignment_maps",
  "LIMS2::Model::Schema::Result::QcTestResultAlignmentMap",
  { "foreign.qc_test_result_alignment_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2012-04-13 11:34:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F3OxP2I3S3+BVp+ZJZsYwA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
