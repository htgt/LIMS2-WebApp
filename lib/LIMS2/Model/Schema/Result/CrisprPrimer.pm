use utf8;
package LIMS2::Model::Schema::Result::CrisprPrimer;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprPrimer::VERSION = '0.329';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprPrimer

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

=head1 TABLE: C<crispr_primers>

=cut

__PACKAGE__->table("crispr_primers");

=head1 ACCESSORS

=head2 crispr_oligo_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispr_primers_crispr_oligo_id_seq'

=head2 crispr_pair_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 primer_name

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 primer_seq

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

=head2 crispr_group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 is_validated

  data_type: 'boolean'
  is_nullable: 1

=head2 is_rejected

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "crispr_oligo_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crispr_primers_crispr_oligo_id_seq",
  },
  "crispr_pair_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "primer_name",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "primer_seq",
  { data_type => "text", is_nullable => 0 },
  "tm",
  { data_type => "numeric", is_nullable => 1, size => [5, 3] },
  "gc_content",
  { data_type => "numeric", is_nullable => 1, size => [5, 3] },
  "crispr_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "is_validated",
  { data_type => "boolean", is_nullable => 1 },
  "is_rejected",
  { data_type => "boolean", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</crispr_oligo_id>

=back

=cut

__PACKAGE__->set_primary_key("crispr_oligo_id");

=head1 RELATIONS

=head2 crispr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Crispr>

=cut

__PACKAGE__->belongs_to(
  "crispr",
  "LIMS2::Model::Schema::Result::Crispr",
  { id => "crispr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 crispr_group

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprGroup>

=cut

__PACKAGE__->belongs_to(
  "crispr_group",
  "LIMS2::Model::Schema::Result::CrisprGroup",
  { id => "crispr_group_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 crispr_pair

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprPair>

=cut

__PACKAGE__->belongs_to(
  "crispr_pair",
  "LIMS2::Model::Schema::Result::CrisprPair",
  { id => "crispr_pair_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 primer_name

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimerType>

=cut

__PACKAGE__->belongs_to(
  "primer_name",
  "LIMS2::Model::Schema::Result::CrisprPrimerType",
  { primer_name => "primer_name" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_template_well_crispr_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellCrisprPrimer>

=cut

__PACKAGE__->has_many(
  "qc_template_well_crispr_primers",
  "LIMS2::Model::Schema::Result::QcTemplateWellCrisprPrimer",
  { "foreign.crispr_primer_id" => "self.crispr_oligo_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-02-05 12:08:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G+Y4JJM59Dy+9mc1CNIDoA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head2 crispr_primer_loci

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimersLoci>

=cut

__PACKAGE__->has_many(
  "crispr_primer_loci",
  "LIMS2::Model::Schema::Result::CrisprPrimersLoci",
  { "foreign.crispr_oligo_id" => "self.crispr_oligo_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub id {
  return shift->crispr_oligo_id;
}

sub as_hash {
    my $self = shift;

    my $species;
    if ( $self->crispr_id ) {
        $species = $self->crispr->species;
    }
    elsif ( $self->crispr_pair_id ) {
        $species = $self->crispr_pair->left_crispr->species;
    }
    elsif ( $self->crispr_group_id ) {
        $species = $self->crispr_group->left_most_crispr->species;
    }
    else {
        die ( 'Crispr primer not linked to crispr, crispr pair or crispr group' );
    }

    my $locus;
    if ( my $default_assembly = $species->default_assembly ) {
        $locus = $self->search_related( 'crispr_primer_loci',
            { assembly_id => $default_assembly->assembly_id } )->first;
    }

    return {
        crispr_oligo_id => $self->crispr_oligo_id,
        primer_seq      => $self->primer_seq,
        primer_name     => $self->primer_name->primer_name,
        tm              => $self->tm,
        gc_content      => $self->gc_content,
        locus           => $locus ? $locus->as_hash : undef,
        crispr_pair_id  => $self->crispr_pair_id,
        crispr_id       => $self->crispr_id,
        crispr_group_id => $self->crispr_group_id,
        is_validated    => $self->is_validated,
        is_rejected     => $self->is_rejected,
    };
}

__PACKAGE__->meta->make_immutable;
1;
