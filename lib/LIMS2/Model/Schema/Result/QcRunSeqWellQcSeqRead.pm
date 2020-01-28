use utf8;
package LIMS2::Model::Schema::Result::QcRunSeqWellQcSeqRead;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcRunSeqWellQcSeqRead

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

=head1 TABLE: C<qc_run_seq_well_qc_seq_read>

=cut

__PACKAGE__->table("qc_run_seq_well_qc_seq_read");

=head1 ACCESSORS

=head2 qc_run_seq_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 qc_seq_read_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "qc_run_seq_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "qc_seq_read_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 RELATIONS

=head2 qc_run_seq_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcRunSeqWell>

=cut

__PACKAGE__->belongs_to(
  "qc_run_seq_well",
  "LIMS2::Model::Schema::Result::QcRunSeqWell",
  { id => "qc_run_seq_well_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 qc_seq_read

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcSeqRead>

=cut

__PACKAGE__->belongs_to(
  "qc_seq_read",
  "LIMS2::Model::Schema::Result::QcSeqRead",
  { id => "qc_seq_read_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b41mUHC+HXT7KBGz8dXBZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
