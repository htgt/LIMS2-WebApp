use utf8;
package LIMS2::Model::Schema::Result::QcSeqProjectWell;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcSeqProjectWell

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

=head1 TABLE: C<qc_seq_project_wells>

=cut

__PACKAGE__->table("qc_seq_project_wells");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'qc_seq_project_wells_id_seq'

=head2 qc_seq_project_name

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 plate_name

  data_type: 'text'
  is_nullable: 0

=head2 well_name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "qc_seq_project_wells_id_seq",
  },
  "qc_seq_project_name",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "plate_name",
  { data_type => "text", is_nullable => 0 },
  "well_name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<qc_seq_project_wells_qc_seq_project_name_plate_name_well_na_key>

=over 4

=item * L</qc_seq_project_name>

=item * L</plate_name>

=item * L</well_name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "qc_seq_project_wells_qc_seq_project_name_plate_name_well_na_key",
  ["qc_seq_project_name", "plate_name", "well_name"],
);

=head1 RELATIONS

=head2 qc_seq_project_name

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcSeqProject>

=cut

__PACKAGE__->belongs_to(
  "qc_seq_project_name",
  "LIMS2::Model::Schema::Result::QcSeqProject",
  { name => "qc_seq_project_name" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_seqs_reads

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcSeqRead>

=cut

__PACKAGE__->has_many(
  "qc_seqs_reads",
  "LIMS2::Model::Schema::Result::QcSeqRead",
  { "foreign.qc_seq_project_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_test_results

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTestResult>

=cut

__PACKAGE__->has_many(
  "qc_test_results",
  "LIMS2::Model::Schema::Result::QcTestResult",
  { "foreign.qc_seq_project_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-05-10 09:34:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cljQWUS9E/IlZPHFYwvNuA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
