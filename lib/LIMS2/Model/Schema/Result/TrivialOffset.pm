use utf8;
package LIMS2::Model::Schema::Result::TrivialOffset;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::TrivialOffset::VERSION = '0.509';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::TrivialOffset

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

=head1 TABLE: C<trivial_offset>

=cut

__PACKAGE__->table("trivial_offset");

=head1 ACCESSORS

=head2 gene_id

  data_type: 'text'
  is_nullable: 0

=head2 crispr_offset

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gene_id",
  { data_type => "text", is_nullable => 0 },
  "crispr_offset",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gene_id>

=back

=cut

__PACKAGE__->set_primary_key("gene_id");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2018-04-17 15:25:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OeBv1O77Pb/+hOWH0QYINQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
