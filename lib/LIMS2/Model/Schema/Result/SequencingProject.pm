use utf8;
package LIMS2::Model::Schema::Result::SequencingProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::SequencingProject::VERSION = '0.351';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::SequencingProject

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

=head1 TABLE: C<sequencing_projects>

=cut

__PACKAGE__->table("sequencing_projects");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sequencing_projects_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 created_by_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 sub_projects

  data_type: 'integer'
  is_nullable: 0

=head2 qc

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 available_results

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 abandoned

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 is_384

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sequencing_projects_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "created_by_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "sub_projects",
  { data_type => "integer", is_nullable => 0 },
  "qc",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "available_results",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "abandoned",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "is_384",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 sequencing_project_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::SequencingProjectPrimer>

=cut

__PACKAGE__->has_many(
  "sequencing_project_primers",
  "LIMS2::Model::Schema::Result::SequencingProjectPrimer",
  { "foreign.seq_project_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sequencing_project_templates

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::SequencingProjectTemplate>

=cut

__PACKAGE__->has_many(
  "sequencing_project_templates",
  "LIMS2::Model::Schema::Result::SequencingProjectTemplate",
  { "foreign.seq_project_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-10-05 16:17:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cBwNx/xxXA6y6zPpOcPDSw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
