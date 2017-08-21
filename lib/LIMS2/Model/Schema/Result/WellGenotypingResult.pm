use utf8;
package LIMS2::Model::Schema::Result::WellGenotypingResult;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::WellGenotypingResult::VERSION = '0.468';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::WellGenotypingResult

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

=head1 TABLE: C<well_genotyping_results>

=cut

__PACKAGE__->table("well_genotyping_results");

=head1 ACCESSORS

=head2 well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genotyping_result_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 call

  data_type: 'text'
  is_nullable: 0

=head2 copy_number

  data_type: 'double precision'
  is_nullable: 1

=head2 copy_number_range

  data_type: 'double precision'
  is_nullable: 1

=head2 confidence

  data_type: 'text'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 vic

  data_type: 'double precision'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genotyping_result_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "call",
  { data_type => "text", is_nullable => 0 },
  "copy_number",
  { data_type => "double precision", is_nullable => 1 },
  "copy_number_range",
  { data_type => "double precision", is_nullable => 1 },
  "confidence",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "vic",
  { data_type => "double precision", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</well_id>

=item * L</genotyping_result_type_id>

=back

=cut

__PACKAGE__->set_primary_key("well_id", "genotyping_result_type_id");

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

=head2 genotyping_result_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::GenotypingResultType>

=cut

__PACKAGE__->belongs_to(
  "genotyping_result_type",
  "LIMS2::Model::Schema::Result::GenotypingResultType",
  { id => "genotyping_result_type_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-15 16:48:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sX8+0b+ZHr0Q8sVljZJaiw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
