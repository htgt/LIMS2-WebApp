use utf8;
package LIMS2::Model::Schema::Result::DesignOligoLocus;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::DesignOligoLocus::VERSION = '0.481';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::DesignOligoLocus

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

=head1 TABLE: C<design_oligo_loci>

=cut

__PACKAGE__->table("design_oligo_loci");

=head1 ACCESSORS

=head2 design_oligo_id

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

=head2 chr_strand

  data_type: 'integer'
  is_nullable: 0

=head2 chr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "design_oligo_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "assembly_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "chr_start",
  { data_type => "integer", is_nullable => 0 },
  "chr_end",
  { data_type => "integer", is_nullable => 0 },
  "chr_strand",
  { data_type => "integer", is_nullable => 0 },
  "chr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_oligo_id>

=item * L</assembly_id>

=back

=cut

__PACKAGE__->set_primary_key("design_oligo_id", "assembly_id");

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

=head2 design_oligo

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::DesignOligo>

=cut

__PACKAGE__->belongs_to(
  "design_oligo",
  "LIMS2::Model::Schema::Result::DesignOligo",
  { id => "design_oligo_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d3Svyes0fxaXZJCWRv0N7Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_hash {
    my $self = shift;
    return {
        species  => $self->assembly->species_id,
        assembly => $self->assembly_id,
        chr_name  => $self->chr->name,
        map { $_ => $self->$_ } qw( chr_start chr_end chr_strand )
    };
}

__PACKAGE__->meta->make_immutable;
1;
