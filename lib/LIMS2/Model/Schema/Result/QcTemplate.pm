use utf8;
package LIMS2::Model::Schema::Result::QcTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcTemplate

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

=head1 TABLE: C<qc_templates>

=cut

__PACKAGE__->table("qc_templates");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'qc_templates_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 species_id

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
    sequence          => "qc_templates_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<qc_templates_name_created_at_key>

=over 4

=item * L</name>

=item * L</created_at>

=back

=cut

__PACKAGE__->add_unique_constraint("qc_templates_name_created_at_key", ["name", "created_at"]);

=head1 RELATIONS

=head2 qc_runs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcRun>

=cut

__PACKAGE__->has_many(
  "qc_runs",
  "LIMS2::Model::Schema::Result::QcRun",
  { "foreign.qc_template_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWell>

=cut

__PACKAGE__->has_many(
  "qc_template_wells",
  "LIMS2::Model::Schema::Result::QcTemplateWell",
  { "foreign.qc_template_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sequencing_project_templates

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::SequencingProjectTemplate>

=cut

__PACKAGE__->has_many(
  "sequencing_project_templates",
  "LIMS2::Model::Schema::Result::SequencingProjectTemplate",
  { "foreign.qc_template_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 species

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "species",
  "LIMS2::Model::Schema::Result::Species",
  { id => "species_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dhVwj6T09KhYdw99pss4qw

sub as_hash {
    my $self = shift;

    return {
        name       => $self->name,
        created_at => $self->created_at ? $self->created_at->iso8601 : '-',
        id         => $self->id,
        wells      => { map { $_->name => $_->as_hash } $self->qc_template_wells->all }
    };
}

=head2 parent_plate_type

Work out plate type of parent plate(s) for template wells.
Its a educated guess, just checks one well and assumes the rest
should be the same, which they probably are.

=cut
sub parent_plate_type {
    my ( $self ) = @_;

    my $first_well = $self->qc_template_wells->first;

    if ( my $source_well = $first_well->source_well ) {
        return $source_well->plate_type;
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;
