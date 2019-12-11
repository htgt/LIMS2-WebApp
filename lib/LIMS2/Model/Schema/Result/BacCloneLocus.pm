use utf8;
package LIMS2::Model::Schema::Result::BacCloneLocus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::BacCloneLocus

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

=head1 TABLE: C<bac_clone_loci>

=cut

__PACKAGE__->table("bac_clone_loci");

=head1 ACCESSORS

=head2 bac_clone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 assembly_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 chr_start

  data_type: 'integer'
  is_nullable: 0

=head2 chr_end

  data_type: 'integer'
  is_nullable: 0

=head2 chr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "bac_clone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "assembly_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "chr_start",
  { data_type => "integer", is_nullable => 0 },
  "chr_end",
  { data_type => "integer", is_nullable => 0 },
  "chr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</bac_clone_id>

=item * L</assembly_id>

=back

=cut

__PACKAGE__->set_primary_key("bac_clone_id", "assembly_id");

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

=head2 bac_clone

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::BacClone>

=cut

__PACKAGE__->belongs_to(
  "bac_clone",
  "LIMS2::Model::Schema::Result::BacClone",
  { id => "bac_clone_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Osf6TIR8l26oNoNrcz47PA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_hash {
    my $self = shift;

    return {
        assembly  => $self->assembly_id,
        chr_name  => $self->chr->name,
        chr_start => $self->chr_start,
        chr_end   => $self->chr_end
    };
}

__PACKAGE__->meta->make_immutable;
1;
