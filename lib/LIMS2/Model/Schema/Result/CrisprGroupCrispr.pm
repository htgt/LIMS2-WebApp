use utf8;
package LIMS2::Model::Schema::Result::CrisprGroupCrispr;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprGroupCrispr::VERSION = '0.485';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprGroupCrispr

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

=head1 TABLE: C<crispr_group_crisprs>

=cut

__PACKAGE__->table("crispr_group_crisprs");

=head1 ACCESSORS

=head2 crispr_group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 left_of_target

  data_type: 'boolean'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "crispr_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "left_of_target",
  { data_type => "boolean", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</crispr_group_id>

=item * L</crispr_id>

=back

=cut

__PACKAGE__->set_primary_key("crispr_group_id", "crispr_id");

=head1 RELATIONS

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

=head2 crispr_group

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprGroup>

=cut

__PACKAGE__->belongs_to(
  "crispr_group",
  "LIMS2::Model::Schema::Result::CrisprGroup",
  { id => "crispr_group_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-08-13 10:59:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jYbbFSlBsaH2FCvzeFoflw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
sub as_hash {
    my ( $self ) = @_;

    my %h = (
        crispr_group_id => $self->crispr_group_id,
        crispr_id       => $self->crispr_id,
        left_of_target  => $self->left_of_target,
        crispr          => $self->crispr->as_hash,
    );

    return \%h;
}

__PACKAGE__->meta->make_immutable;
1;
