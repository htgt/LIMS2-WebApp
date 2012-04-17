use utf8;
package LIMS2::Model::Schema::Result::QcRunSequencingProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcRunSequencingProject

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

=head1 TABLE: C<qc_run_sequencing_project>

=cut

__PACKAGE__->table("qc_run_sequencing_project");

=head1 ACCESSORS

=head2 qc_run_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 36

=head2 qc_sequencing_project

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "qc_run_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 36 },
  "qc_sequencing_project",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_run_id>

=item * L</qc_sequencing_project>

=back

=cut

__PACKAGE__->set_primary_key("qc_run_id", "qc_sequencing_project");

=head1 RELATIONS

=head2 qc_run

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcRuns>

=cut

__PACKAGE__->belongs_to(
  "qc_run",
  "LIMS2::Model::Schema::Result::QcRuns",
  { id => "qc_run_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_sequencing_project_rel

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcSequencingProject>

=cut

__PACKAGE__->belongs_to(
  "qc_sequencing_project_rel",
  "LIMS2::Model::Schema::Result::QcSequencingProject",
  { name => "qc_sequencing_project" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2012-04-13 11:34:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LsMp+lMBuFfCvJsAZFpBww


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
