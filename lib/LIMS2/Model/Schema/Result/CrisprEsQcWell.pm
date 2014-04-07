use utf8;
package LIMS2::Model::Schema::Result::CrisprEsQcWell;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprEsQcWell

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

=head1 TABLE: C<crispr_es_qc_wells>

=cut

__PACKAGE__->table("crispr_es_qc_wells");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 crispr_es_qc_run_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 36

=head2 well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 fwd_read

  data_type: 'text'
  is_nullable: 0

=head2 rev_read

  data_type: 'text'
  is_nullable: 0

=head2 crispr_chr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 crispr_start

  data_type: 'integer'
  is_nullable: 0

=head2 crispr_end

  data_type: 'integer'
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 analysis_data

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "crispr_es_qc_run_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 36 },
  "well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "fwd_read",
  { data_type => "text", is_nullable => 0 },
  "rev_read",
  { data_type => "text", is_nullable => 0 },
  "crispr_chr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "crispr_start",
  { data_type => "integer", is_nullable => 0 },
  "crispr_end",
  { data_type => "integer", is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "analysis_data",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 crispr_chr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Chromosome>

=cut

__PACKAGE__->belongs_to(
  "crispr_chr",
  "LIMS2::Model::Schema::Result::Chromosome",
  { id => "crispr_chr_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 crispr_es_qc_run

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprEsQcRuns>

=cut

__PACKAGE__->belongs_to(
  "crispr_es_qc_run",
  "LIMS2::Model::Schema::Result::CrisprEsQcRuns",
  { id => "crispr_es_qc_run_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-04-07 11:32:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kHQazZbHHF8mQFv8Td/bJA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
