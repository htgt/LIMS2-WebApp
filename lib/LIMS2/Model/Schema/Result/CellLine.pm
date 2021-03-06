use utf8;
package LIMS2::Model::Schema::Result::CellLine;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CellLine

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

=head1 TABLE: C<cell_lines>

=cut

__PACKAGE__->table("cell_lines");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_lines_id_seq'

=head2 name

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 species_id

  data_type: 'text'
  default_value: 'Human'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_lines_id_seq",
  },
  "name",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "species_id",
  {
    data_type      => "text",
    default_value  => "Human",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 cell_line_externals

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CellLineExternal>

=cut

__PACKAGE__->has_many(
  "cell_line_externals",
  "LIMS2::Model::Schema::Result::CellLineExternal",
  { "foreign.cell_line_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_internal

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::CellLineInternal>

=cut

__PACKAGE__->might_have(
  "cell_line_internal",
  "LIMS2::Model::Schema::Result::CellLineInternal",
  { "foreign.cell_line_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_cell_lines

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessCellLine>

=cut

__PACKAGE__->has_many(
  "process_cell_lines",
  "LIMS2::Model::Schema::Result::ProcessCellLine",
  { "foreign.cell_line_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projects

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Project>

=cut

__PACKAGE__->has_many(
  "projects",
  "LIMS2::Model::Schema::Result::Project",
  { "foreign.cell_line_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-12-09 15:32:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lTL2kjvEfHJp0SELL7Tn8w
use Try::Tiny;

sub tracking {
    my $self = shift;

    my $tracking_details = $self->as_hash;

    try {
        $tracking_details->{internal} = $self->cell_line_internal->as_hash;
    };

    try {
        my $external_tracking = $self->cell_line_externals;
        while (my $ext = $external_tracking->next) {
            push (@{ $tracking_details->{external} }, $ext->as_hash);
        }
    };

    return $tracking_details;
}

sub as_hash {
    my $self = shift;

    my %h = (
        id          => $self->id,
        name        => $self->name,
        description => $self->description,
        species     => $self->species->id,
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
