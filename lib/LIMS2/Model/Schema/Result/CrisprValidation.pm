use utf8;
package LIMS2::Model::Schema::Result::CrisprValidation;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprValidation::VERSION = '0.390';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprValidation

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

=head1 TABLE: C<crispr_validation>

=cut

__PACKAGE__->table("crispr_validation");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispr_validation_id_seq'

=head2 crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 crispr_es_qc_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 validated

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crispr_validation_id_seq",
  },
  "crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "crispr_es_qc_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "validated",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<crispr_es_qc_well_crispr_key>

=over 4

=item * L</crispr_id>

=item * L</crispr_es_qc_well_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "crispr_es_qc_well_crispr_key",
  ["crispr_id", "crispr_es_qc_well_id"],
);

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

=head2 crispr_es_qc_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprEsQcWell>

=cut

__PACKAGE__->belongs_to(
  "crispr_es_qc_well",
  "LIMS2::Model::Schema::Result::CrisprEsQcWell",
  { id => "crispr_es_qc_well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-05-22 08:27:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EAR81deOJV1B8vtGG2YAFw

sub as_hash {
    my $self = shift;

    return { map { $_ => $self->$_ } $self->columns };
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
