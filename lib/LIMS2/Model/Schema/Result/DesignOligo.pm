use utf8;
package LIMS2::Model::Schema::Result::DesignOligo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::DesignOligo

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

=head1 TABLE: C<design_oligos>

=cut

__PACKAGE__->table("design_oligos");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'design_oligos_id_seq'

=head2 design_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 design_oligo_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 seq

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "design_oligos_id_seq",
  },
  "design_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "design_oligo_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "seq",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<design_oligos_design_id_design_oligo_type_id_key>

=over 4

=item * L</design_id>

=item * L</design_oligo_type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "design_oligos_design_id_design_oligo_type_id_key",
  ["design_id", "design_oligo_type_id"],
);

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

=head2 design_oligo_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::DesignOligoType>

=cut

__PACKAGE__->belongs_to(
  "design_oligo_type",
  "LIMS2::Model::Schema::Result::DesignOligoType",
  { id => "design_oligo_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 loci

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::DesignOligoLocus>

=cut

__PACKAGE__->has_many(
  "loci",
  "LIMS2::Model::Schema::Result::DesignOligoLocus",
  { "foreign.design_oligo_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-05-30 12:46:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yQ588C3CzDsvMAkIKT+NKg


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_hash {
    my $self = shift;

    my $locus;
    if ( my $default_assembly = $self->design->species->default_assembly ) {
        $locus = $self->search_related( 'loci', { assembly_id => $default_assembly->assembly_id } )->first;
    }

    return {
        id    => $self->id,
        type  => $self->design_oligo_type_id,
        seq   => $self->seq,
        locus => $locus ? $locus->as_hash : undef
    };
}

#
# TODO move to constants?
#
my %ARTIFICIAL_INTRON_OLIGO_APPENDS = (
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "D3" => "TGAACTGATGGCGAGCTCAGACC",
    "D5" => "GAGATGGCGCAACGCAATTAATG",
    "U3" => "CTGAAGGAAATTAGATGTAAGGAGC",
    "U5" => "GTGAGTGTGCTAGAGGGGGTG",
);

my %STANDARD_KO_OLIGO_APPENDS = (
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "U5" => "AAGGCGCATAACGATACCAC",
    "U3" => "CCGCCTACTGCGACTATAGA",
    "D5" => "GAGATGGCGCAACGCAATTAATG",
    "D3" => "TGAACTGATGGCGAGCTCAGACC",
);

my %STANDARD_INS_DEL_OLIGO_APPENDS = (
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "U5" => "AAGGCGCATAACGATACCAC",
    "D3" => "CCGCCTACTGCGACTATAGA",
);
my %OLIGO_STRAND_VS_DESIGN_STRAND = (
    "G5" => -1,
    "U5" => 1,
    "U3" => -1,
    "D5" => 1,
    "D3" => -1,
    "G3" => 1,
);

=head2 oligo_order_seq

Sequence used when ordering the oligo.
Need to add the correct append sequence and revcomp if needed.

=cut
sub oligo_order_seq {
    my $self = shift;

    my $revcomp;
    #
    my $oligo_type = $self->design_oligo_type_id;
    my $design_strand = $self->design->chr_strand;
    my $oligo_strand = $OLIGO_STRAND_VS_DESIGN_STRAND{ $oligo_type };

    if ( $design_strand == $oligo_strand ) {
        $revcomp = 'no';
    }
    # design_strand not equal to oligo_strand
    else {
        $revcomp = 'yes';
    }
}

=head2 oligo_strand_vs_design_strand

What is the orientation of the oligo in relation to strand the design is targeted against.
Remember, all oligo sequence is stored on the +ve strand, no matter the design strand.

For example, the U5 oligo is on the same strand as the design ( 1 )
So a U5 oligo for a +ve stranded design is on the +ve strand ( i.e do not revcomp )
Conversly, a U5 oligo for a -ve stranded design is on the -ve strand ( i.e we must revcomp it )

=cut


__PACKAGE__->meta->make_immutable;
1;
