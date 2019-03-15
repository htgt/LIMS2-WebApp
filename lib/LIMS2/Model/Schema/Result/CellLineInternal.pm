use utf8;
package LIMS2::Model::Schema::Result::CellLineInternal;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CellLineInternal::VERSION = '0.531';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CellLineInternal

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

=head1 TABLE: C<cell_line_internal>

=cut

__PACKAGE__->table("cell_line_internal");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_line_internal_id_seq'

=head2 cell_line_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 origin_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 unique_identifier

  data_type: 'varchar'
  is_nullable: 1
  size: 4

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_line_internal_id_seq",
  },
  "cell_line_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "origin_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "unique_identifier",
  { data_type => "varchar", is_nullable => 1, size => 4 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cell_line_internal_cell_line_id_key>

=over 4

=item * L</cell_line_id>

=back

=cut

__PACKAGE__->add_unique_constraint("cell_line_internal_cell_line_id_key", ["cell_line_id"]);

=head2 C<cell_line_internal_unique_identifier_key>

=over 4

=item * L</unique_identifier>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "cell_line_internal_unique_identifier_key",
  ["unique_identifier"],
);

=head1 RELATIONS

=head2 cell_line

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CellLine>

=cut

__PACKAGE__->belongs_to(
  "cell_line",
  "LIMS2::Model::Schema::Result::CellLine",
  { id => "cell_line_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 origin_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "origin_well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "origin_well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2019-01-29 15:56:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3Dc8+CRQf/J91uV4s2HbWg

sub as_hash {
    my $self = shift;

    my %h = (
        id          => $self->id,
        line_id     => $self->cell_line_id,
        origin_well => $self->origin_well->as_hash,
        uniq_tag    => $self->unique_identifier,
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
