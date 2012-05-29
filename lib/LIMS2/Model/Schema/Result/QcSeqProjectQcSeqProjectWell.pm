use utf8;

package LIMS2::Model::Schema::Result::QcSeqProjectQcSeqProjectWell;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::QcSeqProjectQcSeqProjectWell::VERSION = '0.002';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcSeqProjectQcSeqProjectWell

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

=head1 TABLE: C<qc_seq_project_qc_seq_project_well>

=cut

__PACKAGE__->table("qc_seq_project_qc_seq_project_well");

=head1 ACCESSORS

=head2 qc_seq_project_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 qc_seq_project_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "qc_seq_project_id",      { data_type => "text",    is_foreign_key => 1, is_nullable => 0 },
    "qc_seq_project_well_id", { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_seq_project_id>

=item * L</qc_seq_project_well_id>

=back

=cut

__PACKAGE__->set_primary_key( "qc_seq_project_id", "qc_seq_project_well_id" );

=head1 RELATIONS

=head2 qc_seq_project

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcSeqProject>

=cut

__PACKAGE__->belongs_to(
    "qc_seq_project",
    "LIMS2::Model::Schema::Result::QcSeqProject",
    { id            => "qc_seq_project_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_seq_project_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcSeqProjectWell>

=cut

__PACKAGE__->belongs_to(
    "qc_seq_project_well",
    "LIMS2::Model::Schema::Result::QcSeqProjectWell",
    { id            => "qc_seq_project_well_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-05-23 12:23:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PEr3NmifvNYUH700xvlKEw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
