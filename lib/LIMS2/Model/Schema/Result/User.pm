use utf8;
package LIMS2::Model::Schema::Result::User;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::User::VERSION = '0.386';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::User

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

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'users_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 password

  data_type: 'text'
  is_nullable: 1

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "users_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "password",
  { data_type => "text", is_nullable => 1 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<users_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("users_name_key", ["name"]);

=head1 RELATIONS

=head2 barcode_events

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BarcodeEvent>

=cut

__PACKAGE__->has_many(
  "barcode_events",
  "LIMS2::Model::Schema::Result::BarcodeEvent",
  { "foreign.created_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_es_qcs_runs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprEsQcRuns>

=cut

__PACKAGE__->has_many(
  "crispr_es_qcs_runs",
  "LIMS2::Model::Schema::Result::CrisprEsQcRuns",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_attempts

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::DesignAttempt>

=cut

__PACKAGE__->has_many(
  "design_attempts",
  "LIMS2::Model::Schema::Result::DesignAttempt",
  { "foreign.created_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_comments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::DesignComment>

=cut

__PACKAGE__->has_many(
  "design_comments",
  "LIMS2::Model::Schema::Result::DesignComment",
  { "foreign.created_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 designs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Design>

=cut

__PACKAGE__->has_many(
  "designs",
  "LIMS2::Model::Schema::Result::Design",
  { "foreign.created_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fp_picking_lists

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::FpPickingList>

=cut

__PACKAGE__->has_many(
  "fp_picking_lists",
  "LIMS2::Model::Schema::Result::FpPickingList",
  { "foreign.created_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene_designs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::GeneDesign>

=cut

__PACKAGE__->has_many(
  "gene_designs",
  "LIMS2::Model::Schema::Result::GeneDesign",
  { "foreign.created_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plate_comments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::PlateComment>

=cut

__PACKAGE__->has_many(
  "plate_comments",
  "LIMS2::Model::Schema::Result::PlateComment",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plates

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Plate>

=cut

__PACKAGE__->has_many(
  "plates",
  "LIMS2::Model::Schema::Result::Plate",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_runs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcRun>

=cut

__PACKAGE__->has_many(
  "qc_runs",
  "LIMS2::Model::Schema::Result::QcRun",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sequencing_projects

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::SequencingProject>

=cut

__PACKAGE__->has_many(
  "sequencing_projects",
  "LIMS2::Model::Schema::Result::SequencingProject",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_preference

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::UserPreference>

=cut

__PACKAGE__->might_have(
  "user_preference",
  "LIMS2::Model::Schema::Result::UserPreference",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_roles

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "LIMS2::Model::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_accepted_overrides

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellAcceptedOverride>

=cut

__PACKAGE__->has_many(
  "well_accepted_overrides",
  "LIMS2::Model::Schema::Result::WellAcceptedOverride",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_chromosomes_fail

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellChromosomeFail>

=cut

__PACKAGE__->has_many(
  "well_chromosomes_fail",
  "LIMS2::Model::Schema::Result::WellChromosomeFail",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_colony_counts

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellColonyCount>

=cut

__PACKAGE__->has_many(
  "well_colony_counts",
  "LIMS2::Model::Schema::Result::WellColonyCount",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_comments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellComment>

=cut

__PACKAGE__->has_many(
  "well_comments",
  "LIMS2::Model::Schema::Result::WellComment",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_dna_qualities

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellDnaQuality>

=cut

__PACKAGE__->has_many(
  "well_dna_qualities",
  "LIMS2::Model::Schema::Result::WellDnaQuality",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_dna_statuses

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellDnaStatus>

=cut

__PACKAGE__->has_many(
  "well_dna_statuses",
  "LIMS2::Model::Schema::Result::WellDnaStatus",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_genotyping_results

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellGenotypingResult>

=cut

__PACKAGE__->has_many(
  "well_genotyping_results",
  "LIMS2::Model::Schema::Result::WellGenotypingResult",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_primer_bands

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellPrimerBand>

=cut

__PACKAGE__->has_many(
  "well_primer_bands",
  "LIMS2::Model::Schema::Result::WellPrimerBand",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_qc_sequencing_results

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellQcSequencingResult>

=cut

__PACKAGE__->has_many(
  "well_qc_sequencing_results",
  "LIMS2::Model::Schema::Result::WellQcSequencingResult",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_recombineering_results

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellRecombineeringResult>

=cut

__PACKAGE__->has_many(
  "well_recombineering_results",
  "LIMS2::Model::Schema::Result::WellRecombineeringResult",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_targeting_neo_passes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellTargetingNeoPass>

=cut

__PACKAGE__->has_many(
  "well_targeting_neo_passes",
  "LIMS2::Model::Schema::Result::WellTargetingNeoPass",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_targeting_passes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellTargetingPass>

=cut

__PACKAGE__->has_many(
  "well_targeting_passes",
  "LIMS2::Model::Schema::Result::WellTargetingPass",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_targeting_puro_passes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellTargetingPuroPass>

=cut

__PACKAGE__->has_many(
  "well_targeting_puro_passes",
  "LIMS2::Model::Schema::Result::WellTargetingPuroPass",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->has_many(
  "wells",
  "LIMS2::Model::Schema::Result::Well",
  { "foreign.created_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 roles

Type: many_to_many

Composing rels: L</user_roles> -> role

=cut

__PACKAGE__->many_to_many("roles", "user_roles", "role");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-11-30 10:23:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Tz8L7rtR2we19EctCc9o5Q

# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_hash {
    my $self = shift;

    return {
        id     => $self->id,
        name   => $self->name,
        active => $self->active,
        roles  => [ sort map { $_->name } $self->roles ]
    };
}

sub is_sanger{
    my $self = shift;

    if($self->name =~ /.*\@sanger\.ac\.uk/){
        return 1;
    }
    return 0;
}

__PACKAGE__->meta->make_immutable;
1;
