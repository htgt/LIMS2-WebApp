use utf8;
package LIMS2::Model::Schema::Result::DesignTarget;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::DesignTarget

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

=head1 TABLE: C<design_targets>

=cut

__PACKAGE__->table("design_targets");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'design_targets_id_seq'

=head2 marker_symbol

  data_type: 'text'
  is_nullable: 1

=head2 ensembl_gene_id

  data_type: 'text'
  is_nullable: 0

=head2 ensembl_exon_id

  data_type: 'text'
  is_nullable: 0

=head2 exon_size

  data_type: 'integer'
  is_nullable: 0

=head2 exon_rank

  data_type: 'integer'
  is_nullable: 1

=head2 canonical_transcript

  data_type: 'text'
  is_nullable: 1

=head2 species_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 assembly_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 build_id

  data_type: 'integer'
  is_nullable: 0

=head2 chr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 chr_start

  data_type: 'integer'
  is_nullable: 0

=head2 chr_end

  data_type: 'integer'
  is_nullable: 0

=head2 chr_strand

  data_type: 'integer'
  is_nullable: 0

=head2 automatically_picked

  data_type: 'boolean'
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 gene_id

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "design_targets_id_seq",
  },
  "marker_symbol",
  { data_type => "text", is_nullable => 1 },
  "ensembl_gene_id",
  { data_type => "text", is_nullable => 0 },
  "ensembl_exon_id",
  { data_type => "text", is_nullable => 0 },
  "exon_size",
  { data_type => "integer", is_nullable => 0 },
  "exon_rank",
  { data_type => "integer", is_nullable => 1 },
  "canonical_transcript",
  { data_type => "text", is_nullable => 1 },
  "species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "assembly_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "build_id",
  { data_type => "integer", is_nullable => 0 },
  "chr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "chr_start",
  { data_type => "integer", is_nullable => 0 },
  "chr_end",
  { data_type => "integer", is_nullable => 0 },
  "chr_strand",
  { data_type => "integer", is_nullable => 0 },
  "automatically_picked",
  { data_type => "boolean", is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "gene_id",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<design_targets_unique_target>

=over 4

=item * L</ensembl_exon_id>

=item * L</build_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "design_targets_unique_target",
  ["ensembl_exon_id", "build_id"],
);

=head1 RELATIONS

=head2 assembly

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Assembly>

=cut

__PACKAGE__->belongs_to(
  "assembly",
  "LIMS2::Model::Schema::Result::Assembly",
  { id => "assembly_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 chr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Chromosome>

=cut

__PACKAGE__->belongs_to(
  "chr",
  "LIMS2::Model::Schema::Result::Chromosome",
  { id => "chr_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 species

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "species",
  "LIMS2::Model::Schema::Result::Species",
  { id => "species_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OyKMQ5sp20Q+tU4CKMoBuA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
