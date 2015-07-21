use utf8;
package LIMS2::Model::Schema::Result::Process;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Process::VERSION = '0.328';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Process

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

=head1 TABLE: C<processes>

=cut

__PACKAGE__->table("processes");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'processes_id_seq'

=head2 type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "processes_id_seq",
  },
  "type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 process_backbone

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::ProcessBackbone>

=cut

__PACKAGE__->might_have(
  "process_backbone",
  "LIMS2::Model::Schema::Result::ProcessBackbone",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_bacs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessBac>

=cut

__PACKAGE__->has_many(
  "process_bacs",
  "LIMS2::Model::Schema::Result::ProcessBac",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_cassette

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::ProcessCassette>

=cut

__PACKAGE__->might_have(
  "process_cassette",
  "LIMS2::Model::Schema::Result::ProcessCassette",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_cell_line

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::ProcessCellLine>

=cut

__PACKAGE__->might_have(
  "process_cell_line",
  "LIMS2::Model::Schema::Result::ProcessCellLine",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_crispr

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::ProcessCrispr>

=cut

__PACKAGE__->might_have(
  "process_crispr",
  "LIMS2::Model::Schema::Result::ProcessCrispr",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_crispr_tracker_rna

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::ProcessCrisprTrackerRna>

=cut

__PACKAGE__->might_have(
  "process_crispr_tracker_rna",
  "LIMS2::Model::Schema::Result::ProcessCrisprTrackerRna",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_design

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::ProcessDesign>

=cut

__PACKAGE__->might_have(
  "process_design",
  "LIMS2::Model::Schema::Result::ProcessDesign",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_global_arm_shortening_design

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::ProcessGlobalArmShorteningDesign>

=cut

__PACKAGE__->might_have(
  "process_global_arm_shortening_design",
  "LIMS2::Model::Schema::Result::ProcessGlobalArmShorteningDesign",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_input_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessInputWell>

=cut

__PACKAGE__->has_many(
  "process_input_wells",
  "LIMS2::Model::Schema::Result::ProcessInputWell",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_nuclease

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::ProcessNuclease>

=cut

__PACKAGE__->might_have(
  "process_nuclease",
  "LIMS2::Model::Schema::Result::ProcessNuclease",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_output_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessOutputWell>

=cut

__PACKAGE__->has_many(
  "process_output_wells",
  "LIMS2::Model::Schema::Result::ProcessOutputWell",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_parameters

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessParameter>

=cut

__PACKAGE__->has_many(
  "process_parameters",
  "LIMS2::Model::Schema::Result::ProcessParameter",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_recombinases

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessRecombinase>

=cut

__PACKAGE__->has_many(
  "process_recombinases",
  "LIMS2::Model::Schema::Result::ProcessRecombinase",
  { "foreign.process_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::ProcessType>

=cut

__PACKAGE__->belongs_to(
  "type",
  "LIMS2::Model::Schema::Result::ProcessType",
  { id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 input_wells

Type: many_to_many

Composing rels: L</process_input_wells> -> well

=cut

__PACKAGE__->many_to_many("input_wells", "process_input_wells", "well");

=head2 output_wells

Type: many_to_many

Composing rels: L</process_output_wells> -> well

=cut

__PACKAGE__->many_to_many("output_wells", "process_output_wells", "well");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-04-27 13:02:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1zcz5+TATfgl/qXftTzhbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_string {
    my $self = shift;

    return $self->type->description || $self->type_id;
}

sub get_parameter_value{
    my ($self,$name) = @_;
    my $parameter = $self->process_parameters->find({ parameter_name => $name });

    my $value = $parameter ? $parameter->parameter_value : undef;
    return $value;
}

__PACKAGE__->meta->make_immutable;
1;
