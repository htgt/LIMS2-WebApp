use utf8;
package LIMS2::Model::Schema::Result::CellLineExternal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CellLineExternal

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

=head1 TABLE: C<cell_line_external>

=cut

__PACKAGE__->table("cell_line_external");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_line_external_id_seq'

=head2 cell_line_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 remote_identifier

  data_type: 'text'
  is_nullable: 0

=head2 repository

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 url

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_line_external_id_seq",
  },
  "cell_line_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "remote_identifier",
  { data_type => "text", is_nullable => 0 },
  "repository",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "url",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 cell_line

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CellLine>

=cut

__PACKAGE__->belongs_to(
  "cell_line",
  "LIMS2::Model::Schema::Result::CellLine",
  { id => "cell_line_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 repository

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CellLineRepository>

=cut

__PACKAGE__->belongs_to(
  "repository",
  "LIMS2::Model::Schema::Result::CellLineRepository",
  { id => "repository" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7CVCcSlvP5nWrkvE3PWQOQ

sub as_hash {
    my $self = shift;

    my %h = (
        id          => $self->id,
        line_id     => $self->cell_line_id,
        ext_name    => $self->remote_identifier,
        repo        => $self->repository->id,
        url         => $self->url,
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
