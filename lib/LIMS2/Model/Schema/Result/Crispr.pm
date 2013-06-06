use utf8;
package LIMS2::Model::Schema::Result::Crispr;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Crispr::VERSION = '0.077';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Crispr

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

=head1 TABLE: C<crisprs>

=cut

__PACKAGE__->table("crisprs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crisprs_id_seq'

=head2 seq

  data_type: 'text'
  is_nullable: 0

=head2 species_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 crispr_loci_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 off_target_outlier

  data_type: 'boolean'
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crisprs_id_seq",
  },
  "seq",
  { data_type => "text", is_nullable => 0 },
  "species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "crispr_loci_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "off_target_outlier",
  { data_type => "boolean", is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 crispr_loci_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprLociType>

=cut

__PACKAGE__->belongs_to(
  "crispr_loci_type",
  "LIMS2::Model::Schema::Result::CrisprLociType",
  { id => "crispr_loci_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 loci

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprLocus>

=cut

__PACKAGE__->has_many(
  "loci",
  "LIMS2::Model::Schema::Result::CrisprLocus",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 off_targets

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprOffTargets>

=cut

__PACKAGE__->has_many(
  "off_targets",
  "LIMS2::Model::Schema::Result::CrisprOffTargets",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessCrispr>

=cut

__PACKAGE__->has_many(
  "process_crisprs",
  "LIMS2::Model::Schema::Result::ProcessCrispr",
  { "foreign.crispr_id" => "self.id" },
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
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-05-28 13:08:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:faA/1QpKzSQnix5C03kX8A

sub as_hash {
    my ( $self ) = @_;

    my $locus;
    if ( my $default_assembly = $self->species->default_assembly ) {
        $locus = $self->search_related( 'loci', { assembly_id => $default_assembly->assembly_id } )->first;
    }

    my %h = (
        id                 => $self->id,
        type               => $self->crispr_loci_type_id,
        seq                => $self->seq,
        species            => $self->species_id,
        off_target_outlier => $self->off_target_outlier,
        comment            => $self->comment,
        locus              => $locus ? $locus->as_hash : undef,
    );

    $h{off_targets} = [ map { $_->as_hash } $self->off_targets ];

    return \%h;
}

sub forward_order_seq {
    my ( $self ) = @_;

    my $site = substr( $self->seq, 1, 19 );
    return  "ACCG" . $site;
}

sub reverse_order_seq {
    my ( $self ) = @_;

    require Bio::Seq;
    my $bio_seq = Bio::Seq->new( -alphabet => 'dna', -seq => substr( $self->seq, 1,19) );
    my $revcomp_seq = $bio_seq->revcom->seq;
    return "AAAC" . $revcomp_seq;
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
