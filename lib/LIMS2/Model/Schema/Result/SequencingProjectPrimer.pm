use utf8;
package LIMS2::Model::Schema::Result::SequencingProjectPrimer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::SequencingProjectPrimer

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

=head1 TABLE: C<sequencing_project_primers>

=cut

__PACKAGE__->table("sequencing_project_primers");

=head1 ACCESSORS

=head2 seq_project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 primer_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "seq_project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "primer_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 RELATIONS

=head2 primer

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::SequencingPrimerType>

=cut

__PACKAGE__->belongs_to(
  "primer",
  "LIMS2::Model::Schema::Result::SequencingPrimerType",
  { id => "primer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 seq_project

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::SequencingProject>

=cut

__PACKAGE__->belongs_to(
  "seq_project",
  "LIMS2::Model::Schema::Result::SequencingProject",
  { id => "seq_project_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FCdtf0tpqmCRnCYesHVFFw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
