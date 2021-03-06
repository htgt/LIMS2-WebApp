use utf8;
package LIMS2::Model::Schema::Result::CrisprEsQcRuns;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprEsQcRuns

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

=head1 TABLE: C<crispr_es_qc_runs>

=cut

__PACKAGE__->table("crispr_es_qc_runs");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 36

=head2 sequencing_project

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 species_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 sub_project

  data_type: 'text'
  is_nullable: 1

=head2 validated

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 sequencing_data_version

  data_type: 'text'
  is_nullable: 1

=head2 allele_number

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 36 },
  "sequencing_project",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "sub_project",
  { data_type => "text", is_nullable => 1 },
  "validated",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "sequencing_data_version",
  { data_type => "text", is_nullable => 1 },
  "allele_number",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 crispr_es_qc_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprEsQcWell>

=cut

__PACKAGE__->has_many(
  "crispr_es_qc_wells",
  "LIMS2::Model::Schema::Result::CrisprEsQcWell",
  { "foreign.crispr_es_qc_run_id" => "self.id" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sXVN4E07sAHwRf0HJGnk2A

sub as_hash {
  my ( $self, $options ) = @_;

  my $data = {
    created_by => $self->created_by->name,
    map { $_ => $self->$_ } $self->columns
  };
  $data->{created_at} = $self->created_at->iso8601;

  #if you enable this you should do a prefetch with:
  #{'crispr_es_qc_wells' => { well => 'plate' }
  if ( exists $options->{include_plate_name} ) {
    $data->{plate_name} = $self->plate_name;
  }

  $data->{gene_number} = $self->allele_number;

  return $data;
}

sub plate_name{
    my $self = shift;
    #wells might not exist yet, so for now just show a -
    #TODO: make this work even without a well
    my $qc_well = $self->crispr_es_qc_wells->first;
    return $qc_well ? $qc_well->well->plate_name : "-";
}

# Mouse double targeted cells refer to first and second targeted alleles
# Human crispr double targeted cells refer to first and second targeted genes
# In the code they are interchangable, so this method is provided just to make
# code easier to understand (I hope!) in the double targeted gene case
sub gene_number{
    return shift->allele_number;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
