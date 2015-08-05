use utf8;
package LIMS2::Model::Schema::Result::QcSeqProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::QcSeqProject::VERSION = '0.331';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcSeqProject

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

=head1 TABLE: C<qc_seq_projects>

=cut

__PACKAGE__->table("qc_seq_projects");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 species_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 qc_run_seq_projects

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcRunSeqProject>

=cut

__PACKAGE__->has_many(
  "qc_run_seq_projects",
  "LIMS2::Model::Schema::Result::QcRunSeqProject",
  { "foreign.qc_seq_project_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_seq_reads

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcSeqRead>

=cut

__PACKAGE__->has_many(
  "qc_seq_reads",
  "LIMS2::Model::Schema::Result::QcSeqRead",
  { "foreign.qc_seq_project_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 species

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "species",
  "LIMS2::Model::Schema::Result::Species",
  { id => "species_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_runs

Type: many_to_many

Composing rels: L</qc_run_seq_projects> -> qc_run

=cut

__PACKAGE__->many_to_many("qc_runs", "qc_run_seq_projects", "qc_run");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jFzzq3YClZ06tBnSbNU2vQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
