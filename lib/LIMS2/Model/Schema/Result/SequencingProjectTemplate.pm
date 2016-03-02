use utf8;
package LIMS2::Model::Schema::Result::SequencingProjectTemplate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::SequencingProjectTemplate::VERSION = '0.380';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::SequencingProjectTemplate

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

=head1 TABLE: C<sequencing_project_templates>

=cut

__PACKAGE__->table("sequencing_project_templates");

=head1 ACCESSORS

=head2 seq_project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 qc_template_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "seq_project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "qc_template_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 RELATIONS

=head2 qc_template

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcTemplate>

=cut

__PACKAGE__->belongs_to(
  "qc_template",
  "LIMS2::Model::Schema::Result::QcTemplate",
  { id => "qc_template_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 seq_project

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::SequencingProject>

=cut

__PACKAGE__->belongs_to(
  "seq_project",
  "LIMS2::Model::Schema::Result::SequencingProject",
  { id => "seq_project_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-10-05 16:17:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8aqAyUo2whTxES17pBbq8g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
