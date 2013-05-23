use utf8;
package LIMS2::Model::Schema::Result::CrisprOffTargets;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprOffTargets

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

=head1 TABLE: C<crispr_off_targets>

=cut

__PACKAGE__->table("crispr_off_targets");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispr_off_targets_id_seq'

=head2 crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 crispr_loci_type_id

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

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crispr_off_targets_id_seq",
  },
  "crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "crispr_loci_type_id",
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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 assembly

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Assembly>

=cut

__PACKAGE__->belongs_to(
  "assembly",
  "LIMS2::Model::Schema::Result::Assembly",
  { id => "assembly_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 chr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Chromosome>

=cut

__PACKAGE__->belongs_to(
  "chr",
  "LIMS2::Model::Schema::Result::Chromosome",
  { id => "chr_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 crispr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Crispr>

=cut

__PACKAGE__->belongs_to(
  "crispr",
  "LIMS2::Model::Schema::Result::Crispr",
  { id => "crispr_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 crispr_loci_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprLociType>

=cut

__PACKAGE__->belongs_to(
  "crispr_loci_type",
  "LIMS2::Model::Schema::Result::CrisprLociType",
  { id => "crispr_loci_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-05-22 13:42:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yB7Ryze6U1LtGpdsJqNqPA

sub as_hash {
    my $self = shift;

    return {
        assembly => $self->assembly_id,
        type     => $self->crispr_loci_type_id,
        build    => $self->build_id,
        chr_name => $self->chr->name,
        map { $_ => $self->$_ } qw( chr_start chr_end chr_strand )
    };
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
