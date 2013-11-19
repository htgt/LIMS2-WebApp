use utf8;
package LIMS2::Model::Schema::Result::WellPrimerBand;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::WellPrimerBand::VERSION = '0.128';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::WellPrimerBand

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

=head1 TABLE: C<well_primer_bands>

=cut

__PACKAGE__->table("well_primer_bands");

=head1 ACCESSORS

=head2 well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 primer_band_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 pass

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "primer_band_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "pass",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</well_id>

=item * L</primer_band_type_id>

=back

=cut

__PACKAGE__->set_primary_key("well_id", "primer_band_type_id");

=head1 RELATIONS

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 primer_band_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::PrimerBandType>

=cut

__PACKAGE__->belongs_to(
  "primer_band_type",
  "LIMS2::Model::Schema::Result::PrimerBandType",
  { id => "primer_band_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-07 14:44:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d04iRCugQhzAhJeRNwE0jw
sub as_hash {
    my $self = shift;

    return {
        well_id                => $self->well_id,
        primer_band_type       => $self->primer_band_type->id,
        pass                   => $self->pass,
        created_by             => $self->created_by->name,
        created_at             => $self->created_at->iso8601,
    }
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
