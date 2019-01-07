use utf8;
package LIMS2::Model::Schema::Result::Trivial;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Trivial::VERSION = '0.518';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Trivial

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

=head1 TABLE: C<trivial>

=cut

__PACKAGE__->table("trivial");

=head1 ACCESSORS

=head2 species_id

  data_type: 'text'
  is_nullable: 1

=head2 experiment_id

  data_type: 'integer'
  is_nullable: 1

=head2 gene_id

  data_type: 'text'
  is_nullable: 1

=head2 crispr

  data_type: 'integer'
  is_nullable: 1

=head2 trivial_crispr

  data_type: 'bigint'
  is_nullable: 1

=head2 design_id

  data_type: 'integer'
  is_nullable: 1

=head2 trivial_design

  data_type: 'bigint'
  is_nullable: 1

=head2 trivial_experiment

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "species_id",
  { data_type => "text", is_nullable => 1 },
  "experiment_id",
  { data_type => "integer", is_nullable => 1 },
  "gene_id",
  { data_type => "text", is_nullable => 1 },
  "crispr",
  { data_type => "integer", is_nullable => 1 },
  "trivial_crispr",
  { data_type => "bigint", is_nullable => 1 },
  "design_id",
  { data_type => "integer", is_nullable => 1 },
  "trivial_design",
  { data_type => "bigint", is_nullable => 1 },
  "trivial_experiment",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2018-03-14 12:12:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lX7HFOFIKY9kT9t4Iy2iPA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
