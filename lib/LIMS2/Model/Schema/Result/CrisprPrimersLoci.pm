use utf8;
package LIMS2::Model::Schema::Result::CrisprPrimersLoci;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprPrimersLoci::VERSION = '0.482';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprPrimersLoci

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

=head1 TABLE: C<crispr_primers_loci>

=cut

__PACKAGE__->table("crispr_primers_loci");

=head1 ACCESSORS

=head2 crispr_oligo_id

  data_type: 'integer'
  is_nullable: 0

=head2 assembly_id

  data_type: 'text'
  is_foreign_key: 1
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
  "crispr_oligo_id",
  { data_type => "integer", is_nullable => 0 },
  "assembly_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
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

=item * L</crispr_oligo_id>

=item * L</assembly_id>

=back

=cut

__PACKAGE__->set_primary_key("crispr_oligo_id", "assembly_id");

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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-07-04 08:54:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OWL0dF4e5OJuFefp0bs0LQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head2 crispr_oligo

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimer>

=cut

__PACKAGE__->belongs_to(
  "crispr_oligo",
  "LIMS2::Model::Schema::Result::CrisprPrimer",
  { crispr_oligo_id => "crispr_oligo_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

sub as_hash {
    my $self = shift;

    return {
        species  => $self->assembly->species_id,
        assembly => $self->assembly_id,
        chr_name => $self->chr->name,
        chr_id   => $self->chr_id,
        map { $_ => $self->$_ } qw( chr_start chr_end chr_strand )
    };
}

__PACKAGE__->meta->make_immutable;
1;
