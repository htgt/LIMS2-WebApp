use utf8;
package LIMS2::Model::Schema::Result::QcTemplateWell;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::QcTemplateWell::VERSION = '0.459';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcTemplateWell

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

=head1 TABLE: C<qc_template_wells>

=cut

__PACKAGE__->table("qc_template_wells");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'qc_template_wells_id_seq'

=head2 qc_template_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 qc_eng_seq_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 source_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "qc_template_wells_id_seq",
  },
  "qc_template_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "qc_eng_seq_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "source_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<qc_template_wells_qc_template_id_name_key>

=over 4

=item * L</qc_template_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "qc_template_wells_qc_template_id_name_key",
  ["qc_template_id", "name"],
);

=head1 RELATIONS

=head2 qc_eng_seq

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcEngSeq>

=cut

__PACKAGE__->belongs_to(
  "qc_eng_seq",
  "LIMS2::Model::Schema::Result::QcEngSeq",
  { id => "qc_eng_seq_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_template

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcTemplate>

=cut

__PACKAGE__->belongs_to(
  "qc_template",
  "LIMS2::Model::Schema::Result::QcTemplate",
  { id => "qc_template_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_template_well_backbone

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellBackbone>

=cut

__PACKAGE__->might_have(
  "qc_template_well_backbone",
  "LIMS2::Model::Schema::Result::QcTemplateWellBackbone",
  { "foreign.qc_template_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_well_cassette

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellCassette>

=cut

__PACKAGE__->might_have(
  "qc_template_well_cassette",
  "LIMS2::Model::Schema::Result::QcTemplateWellCassette",
  { "foreign.qc_template_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_well_crispr_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellCrisprPrimer>

=cut

__PACKAGE__->has_many(
  "qc_template_well_crispr_primers",
  "LIMS2::Model::Schema::Result::QcTemplateWellCrisprPrimer",
  { "foreign.qc_template_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_well_genotyping_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellGenotypingPrimer>

=cut

__PACKAGE__->has_many(
  "qc_template_well_genotyping_primers",
  "LIMS2::Model::Schema::Result::QcTemplateWellGenotypingPrimer",
  { "foreign.qc_template_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_well_recombinases

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellRecombinase>

=cut

__PACKAGE__->has_many(
  "qc_template_well_recombinases",
  "LIMS2::Model::Schema::Result::QcTemplateWellRecombinase",
  { "foreign.qc_template_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 source_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "source_well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "source_well_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 recombinases

Type: many_to_many

Composing rels: L</qc_template_well_recombinases> -> recombinase

=cut

__PACKAGE__->many_to_many("recombinases", "qc_template_well_recombinases", "recombinase");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-01-05 12:52:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SitxEnCSkBRIPvUvseN23g

use JSON qw( decode_json );

sub as_hash {
    my $self = shift;

    return {
        name           => $self->name,
        eng_seq_id     => $self->qc_eng_seq->id,
        eng_seq_method => $self->qc_eng_seq->method,
        eng_seq_params => decode_json( $self->qc_eng_seq->params ),
        source_well    => $self->source_well ? $self->source_well->as_hash : undef,
    };
}

sub design_id {
    my $self = shift;

    return $self->qc_eng_seq->design_id;
}

sub crispr_id {
    my $self = shift;

    return $self->qc_eng_seq->crispr_id;
}

__PACKAGE__->meta->make_immutable;
1;
