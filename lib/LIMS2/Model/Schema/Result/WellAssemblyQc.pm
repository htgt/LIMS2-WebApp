use utf8;
package LIMS2::Model::Schema::Result::WellAssemblyQc;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::WellAssemblyQc::VERSION = '0.522';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::WellAssemblyQc

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

=head1 TABLE: C<well_assembly_qc>

=cut

__PACKAGE__->table("well_assembly_qc");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'well_assembly_qc_id_seq'

=head2 assembly_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 qc_type

  data_type: 'enum'
  extra: {custom_type_name => "assembly_well_qc_type",list => ["CRISPR_LEFT_QC","CRISPR_RIGHT_QC","VECTOR_QC"]}
  is_nullable: 0

=head2 value

  data_type: 'enum'
  extra: {custom_type_name => "qc_element_type",list => ["Good","Bad","Wrong"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "well_assembly_qc_id_seq",
  },
  "assembly_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "qc_type",
  {
    data_type => "enum",
    extra => {
      custom_type_name => "assembly_well_qc_type",
      list => ["CRISPR_LEFT_QC", "CRISPR_RIGHT_QC", "VECTOR_QC"],
    },
    is_nullable => 0,
  },
  "value",
  {
    data_type => "enum",
    extra => {
      custom_type_name => "qc_element_type",
      list => ["Good", "Bad", "Wrong"],
    },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<well_assembly_qc_assembly_well_id_qc_type_key>

=over 4

=item * L</assembly_well_id>

=item * L</qc_type>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "well_assembly_qc_assembly_well_id_qc_type_key",
  ["assembly_well_id", "qc_type"],
);

=head1 RELATIONS

=head2 assembly_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "assembly_well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "assembly_well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-09-16 16:54:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5WPJF2f+P3EcIRUM6S/U0A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
