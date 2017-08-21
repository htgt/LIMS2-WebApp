use utf8;
package LIMS2::Model::Schema::Result::GenotypingPrimer;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::GenotypingPrimer::VERSION = '0.468';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::GenotypingPrimer

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

=head1 TABLE: C<genotyping_primers>

=cut

__PACKAGE__->table("genotyping_primers");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'genotyping_primers_id_seq'

=head2 genotyping_primer_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 design_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 seq

  data_type: 'text'
  is_nullable: 0

=head2 tm

  data_type: 'numeric'
  is_nullable: 1
  size: [5,3]

=head2 gc_content

  data_type: 'numeric'
  is_nullable: 1
  size: [5,3]

=head2 is_validated

  data_type: 'boolean'
  is_nullable: 1

=head2 is_rejected

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "genotyping_primers_id_seq",
  },
  "genotyping_primer_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "design_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "seq",
  { data_type => "text", is_nullable => 0 },
  "tm",
  { data_type => "numeric", is_nullable => 1, size => [5, 3] },
  "gc_content",
  { data_type => "numeric", is_nullable => 1, size => [5, 3] },
  "is_validated",
  { data_type => "boolean", is_nullable => 1 },
  "is_rejected",
  { data_type => "boolean", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 design

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "LIMS2::Model::Schema::Result::Design",
  { id => "design_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 genotyping_primer_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::GenotypingPrimerType>

=cut

__PACKAGE__->belongs_to(
  "genotyping_primer_type",
  "LIMS2::Model::Schema::Result::GenotypingPrimerType",
  { id => "genotyping_primer_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_template_well_genotyping_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellGenotypingPrimer>

=cut

__PACKAGE__->has_many(
  "qc_template_well_genotyping_primers",
  "LIMS2::Model::Schema::Result::QcTemplateWellGenotypingPrimer",
  { "foreign.genotyping_primer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-01-05 12:52:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:naTLhG8UVk0Sv59M9O8dVg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
=head2 genotyping_primer_loci

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::GenotypingPrimersLoci>

=cut

__PACKAGE__->has_many(
  "genotyping_primer_loci",
  "LIMS2::Model::Schema::Result::GenotypingPrimersLoci",
  { "foreign.genotyping_primer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


sub as_hash {
    my $self = shift;

    my $locus = $self->current_locus;

    return {
        id      => $self->id,
        type    => $self->genotyping_primer_type_id,
        seq     => $self->seq,
        primer_seq => $self->seq,
        primer_name => $self->genotyping_primer_type_id,
        species => $self->design->species_id,
        locus   => $locus ? $locus->as_hash : undef,
        is_validated => $self->is_validated,
        is_rejected => $self->is_rejected,
    };
}

# Method aliases so we can use it like a CrisprPrimer
sub primer_name{
    return shift->genotyping_primer_type_id;
}

sub primer_seq{
    return shift->seq;
}

sub current_locus{
    my $self = shift;
    my $locus;
    if ( my $default_assembly = $self->design->species->default_assembly ) {
        $locus = $self->search_related( 'genotyping_primer_loci',
            { assembly_id => $default_assembly->assembly_id } )->first;
    }
    return $locus;
}
__PACKAGE__->meta->make_immutable;
1;
