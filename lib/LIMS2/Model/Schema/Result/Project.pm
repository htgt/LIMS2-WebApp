use utf8;
package LIMS2::Model::Schema::Result::Project;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Project::VERSION = '0.326';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Project

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

=head1 TABLE: C<projects>

=cut

__PACKAGE__->table("projects");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'projects_id_seq'

=head2 gene_id

  data_type: 'text'
  is_nullable: 1

=head2 targeting_type

  data_type: 'text'
  default_value: 'unknown'
  is_nullable: 0

=head2 species_id

  data_type: 'text'
  is_nullable: 1

=head2 htgt_project_id

  data_type: 'integer'
  is_nullable: 1

=head2 effort_concluded

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 recovery_comment

  data_type: 'text'
  is_nullable: 1

=head2 priority

  data_type: 'text'
  is_nullable: 1

=head2 recovery_class_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 targeting_profile_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "projects_id_seq",
  },
  "gene_id",
  { data_type => "text", is_nullable => 1 },
  "targeting_type",
  { data_type => "text", default_value => "unknown", is_nullable => 0 },
  "species_id",
  { data_type => "text", is_nullable => 1 },
  "htgt_project_id",
  { data_type => "integer", is_nullable => 1 },
  "effort_concluded",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "recovery_comment",
  { data_type => "text", is_nullable => 1 },
  "priority",
  { data_type => "text", is_nullable => 1 },
  "recovery_class_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "targeting_profile_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<gene_type_species_profile_key>

=over 4

=item * L</gene_id>

=item * L</targeting_type>

=item * L</species_id>

=item * L</targeting_profile_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "gene_type_species_profile_key",
  [
    "gene_id",
    "targeting_type",
    "species_id",
    "targeting_profile_id",
  ],
);

=head1 RELATIONS

=head2 experiments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Experiment>

=cut

__PACKAGE__->has_many(
  "experiments",
  "LIMS2::Model::Schema::Result::Experiment",
  { "foreign.project_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_sponsors

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProjectSponsor>

=cut

__PACKAGE__->has_many(
  "project_sponsors",
  "LIMS2::Model::Schema::Result::ProjectSponsor",
  { "foreign.project_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 recovery_class

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::ProjectRecoveryClass>

=cut

__PACKAGE__->belongs_to(
  "recovery_class",
  "LIMS2::Model::Schema::Result::ProjectRecoveryClass",
  { id => "recovery_class_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 targeting_profile

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::TargetingProfile>

=cut

__PACKAGE__->belongs_to(
  "targeting_profile",
  "LIMS2::Model::Schema::Result::TargetingProfile",
  { id => "targeting_profile_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-04-08 13:21:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MW9rEeT4zSlkVgyiiibv2w

__PACKAGE__->many_to_many(
    sponsors => 'project_sponsors',
    'sponsor',
);

sub as_hash {
    my $self = shift;

    my @sponsors = $self->sponsor_ids;

    return {
          "id"                => $self->id,
          "gene_id"           => $self->gene_id,
          "targeting_type"    => $self->targeting_type,
          "targeting_profile_id" => $self->targeting_profile_id,
          "species_id"        => $self->species_id,
          "htgt_project_id"   => $self->htgt_project_id,
          "effort_concluded"  => $self->effort_concluded,
          "recovery_class"    => $self->recovery_class_name,
          "recovery_comment"  => $self->recovery_comment,
          "priority"          => $self->priority,
          "sponsors"          => join "/", @sponsors,
    }
}

sub recovery_class_name {
    my $self = shift;

    return $self->recovery_class ? $self->recovery_class->name : undef;
}

sub sponsor_ids{
    my $self = shift;

    my @sponsors = map { $_->sponsor_id } $self->project_sponsors;
    my @sorted = sort @sponsors;
    return @sorted;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
