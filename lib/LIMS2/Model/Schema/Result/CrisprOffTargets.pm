use utf8;
package LIMS2::Model::Schema::Result::CrisprOffTargets;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprOffTargets::VERSION = '0.414';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprOffTargets

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

=head1 TABLE: C<crispr_off_targets>

=cut

__PACKAGE__->table("crispr_off_targets");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispr_off_targets_id_seq'

=head2 crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 off_target_crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 mismatches

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crispr_off_targets_id_seq",
  },
  "crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "off_target_crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "mismatches",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<unique_crispr_off_target>

=over 4

=item * L</crispr_id>

=item * L</off_target_crispr_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "unique_crispr_off_target",
  ["crispr_id", "off_target_crispr_id"],
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

=head2 off_target_crispr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Crispr>

=cut

__PACKAGE__->belongs_to(
  "off_target_crispr",
  "LIMS2::Model::Schema::Result::Crispr",
  { id => "off_target_crispr_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-05-07 08:15:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zjMoP44vGOWErbXK6M8EOg

sub as_hash {
    my $self = shift;

    return {
        id                   => $self->id,
        crispr_id            => $self->crispr_id,
        off_target_crispr_id => $self->off_target_crispr_id,
        ot_crispr            => $self->off_target_crispr->as_hash( { no_off_targets => 1 } ),
        mismatches           => $self->mismatches,
    };
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
