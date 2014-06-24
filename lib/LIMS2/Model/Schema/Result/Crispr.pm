use utf8;
package LIMS2::Model::Schema::Result::Crispr;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Crispr::VERSION = '0.210';
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

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 pam_right

  data_type: 'boolean'
  is_nullable: 1

=head2 wge_crispr_id

  data_type: 'integer'
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
  "comment",
  { data_type => "text", is_nullable => 1 },
  "pam_right",
  { data_type => "boolean", is_nullable => 1 },
  "wge_crispr_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<crisprs_wge_crispr_id_key>

=over 4

=item * L</wge_crispr_id>

=back

=cut

__PACKAGE__->add_unique_constraint("crisprs_wge_crispr_id_key", ["wge_crispr_id"]);

=head1 RELATIONS

=head2 crispr_designs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprDesign>

=cut

__PACKAGE__->has_many(
  "crispr_designs",
  "LIMS2::Model::Schema::Result::CrisprDesign",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 crispr_pairs_left_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPair>

=cut

__PACKAGE__->has_many(
  "crispr_pairs_left_crisprs",
  "LIMS2::Model::Schema::Result::CrisprPair",
  { "foreign.left_crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_pairs_right_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPair>

=cut

__PACKAGE__->has_many(
  "crispr_pairs_right_crisprs",
  "LIMS2::Model::Schema::Result::CrisprPair",
  { "foreign.right_crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimer>

=cut

__PACKAGE__->has_many(
  "crispr_primers",
  "LIMS2::Model::Schema::Result::CrisprPrimer",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 off_target_summaries

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprOffTargetSummary>

=cut

__PACKAGE__->has_many(
  "off_target_summaries",
  "LIMS2::Model::Schema::Result::CrisprOffTargetSummary",
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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-05-07 11:32:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iCBcK0B07XGoh/EQgHXNfA

use Bio::Perl qw( revcom );

use overload '""' => \&as_string;

sub as_string {
    return shift->id;
}

sub as_hash {
    my ( $self ) = @_;

    my $locus;
    if ( my $default_assembly = $self->species->default_assembly ) {
        $locus = $self->search_related( 'loci', { assembly_id => $default_assembly->assembly_id } )->first;
    }

    my %h = (
        id        => $self->id,
        type      => $self->crispr_loci_type_id,
        seq       => $self->seq,
        species   => $self->species_id,
        comment   => $self->comment,
        locus     => $locus ? $locus->as_hash : undef,
        pam_right => !defined $self->pam_right ? '' : $self->pam_right == 1 ? 'true' : 'false',
    );

    $h{off_targets} = [ map { $_->as_hash } $self->off_targets ];
    $h{off_target_summaries} = [ map { $_->as_hash } $self->off_target_summaries ];

    return \%h;
}

sub current_locus {
    my $self = shift;

    my $loci = $self->result_source->schema->resultset('CrisprLocus')->find(
        {
            'me.crispr_id'                          => $self->id,
            'species_default_assemblies.species_id' => $self->species_id
        },
        {
            join => {
                assembly => 'species_default_assemblies'
            }
        }
    );

    return $loci;
}

sub start {
    return shift->current_locus->chr_start;
}

sub end {
    return shift->current_locus->chr_end;
}

sub chr_id {
    return shift->current_locus->chr_id;
}

sub chr_name {
    return shift->current_locus->chr->name;
}

sub target_slice {
    my ( $self, $ensembl_util ) = @_;

    unless ( $ensembl_util ) {
        require WebAppCommon::Util::EnsEMBL;
        $ensembl_util = WebAppCommon::Util::EnsEMBL->new( species => $self->species_id );
    }

    my $slice = $ensembl_util->slice_adaptor->fetch_by_region(
        'chromosome',
        $self->chr_name,
        $self->start,
        $self->end
    );

    return $slice;
}

sub guide_rna {
    my ( $self ) = @_;

    if ( ! defined $self->pam_right ) {
        return substr( $self->seq, 1, 19 );
    }
    elsif ( $self->pam_right == 1 ) {
        return substr( $self->seq, 1, 19 );
    }
    elsif ( $self->pam_right == 0 ) {
        #its pam left, so strip first three characters and the very last one,
        #we revcom so that the grna is always relative to the NGG sequence
        return revcom( substr( $self->seq, 3, 19 ) )->seq;
    }
    else {
        die "Unexpected value in pam_right: " . $self->pam_right;
    }

}

sub forward_order_seq {
    my ( $self ) = @_;

    return  "ACCG" . $self->guide_rna;
}

sub reverse_order_seq {
    my ( $self ) = @_;

    #require Bio::Seq;
    #my $bio_seq = Bio::Seq->new( -alphabet => 'dna', -seq => $self->guide_rna );
    #my $revcomp_seq = $bio_seq->revcom->seq;
    return "AAAC" . revcom( $self->guide_rna )->seq;
}

#we need to add the G here so its the full forward grna
sub vector_seq {
    my ( $self ) = @_;

    return  "G" . $self->guide_rna;
}

sub pairs {
  my $self = shift;

  return ($self->pam_right) ? $self->crispr_pairs_right_crisprs : $self->crispr_pairs_left_crisprs;
}

# Designs may be linked to single crispr directly or to crispr pair
sub related_designs {
  my $self = shift;

  my @designs;
      foreach my $crispr_design ($self->crispr_designs->all){
        my $design = $crispr_design->design;
        push @designs, $design;
    }

    foreach my $pair ($self->crispr_pairs_left_crisprs->all, $self->crispr_pairs_right_crisprs->all){
        foreach my $pair_crispr_design ($pair->crispr_designs->all){
            my $pair_design = $pair_crispr_design->design;
            push @designs, $pair_design;
        }
    }

    return @designs;
}

sub crispr_wells{
    my $self = shift;

    return map { $_->process->output_wells } $self->process_crisprs;
}

sub vector_wells{
    my $self = shift;

    my @wells = $self->crispr_wells;

    return map { $_->descendant_crispr_vectors } @wells;
}

sub accepted_vector_wells{
    my $self = shift;

    # Assume we are only interested in vectors on the most recently created crispr_v plate
    my @accepted_wells;
    my $most_recent_plate;
    foreach my $well ($self->vector_wells){

        next unless $well->is_accepted;

        push @accepted_wells, $well;

        my $plate = $well->plate;
        $most_recent_plate ||= $plate;
        if ($plate->created_at > $most_recent_plate->created_at){
            $most_recent_plate = $plate;
        }
    }

    return grep { $_->plate_id == $most_recent_plate->id } @accepted_wells;
}

sub is_pair { return; }

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
