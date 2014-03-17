use utf8;
package LIMS2::Model::Schema::Result::Design;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Design::VERSION = '0.171';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Design

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

=head1 TABLE: C<designs>

=cut

__PACKAGE__->table("designs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'designs_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 created_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 design_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 phase

  data_type: 'integer'
  is_nullable: 1

=head2 validated_by_annotation

  data_type: 'text'
  is_nullable: 0

=head2 target_transcript

  data_type: 'text'
  is_nullable: 1

=head2 species_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 design_parameters

  data_type: 'text'
  is_nullable: 1

=head2 cassette_first

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
    sequence          => "designs_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "created_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "design_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "phase",
  { data_type => "integer", is_nullable => 1 },
  "validated_by_annotation",
  { data_type => "text", is_nullable => 0 },
  "target_transcript",
  { data_type => "text", is_nullable => 1 },
  "species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "design_parameters",
  { data_type => "text", is_nullable => 1 },
  "cassette_first",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 comments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::DesignComment>

=cut

__PACKAGE__->has_many(
  "comments",
  "LIMS2::Model::Schema::Result::DesignComment",
  { "foreign.design_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 crispr_designs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprDesign>

=cut

__PACKAGE__->has_many(
  "crispr_designs",
  "LIMS2::Model::Schema::Result::CrisprDesign",
  { "foreign.design_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::GeneDesign>

=cut

__PACKAGE__->has_many(
  "genes",
  "LIMS2::Model::Schema::Result::GeneDesign",
  { "foreign.design_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genotyping_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::GenotypingPrimer>

=cut

__PACKAGE__->has_many(
  "genotyping_primers",
  "LIMS2::Model::Schema::Result::GenotypingPrimer",
  { "foreign.design_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 oligos

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::DesignOligo>

=cut

__PACKAGE__->has_many(
  "oligos",
  "LIMS2::Model::Schema::Result::DesignOligo",
  { "foreign.design_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_designs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessDesign>

=cut

__PACKAGE__->has_many(
  "process_designs",
  "LIMS2::Model::Schema::Result::ProcessDesign",
  { "foreign.design_id" => "self.id" },
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

=head2 type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::DesignType>

=cut

__PACKAGE__->belongs_to(
  "type",
  "LIMS2::Model::Schema::Result::DesignType",
  { id => "design_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SMeFB4r9ZhVln+z3REjP/A


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->might_have(
    "default_locus",
    "LIMS2::Model::Schema::Result::DefaultDesignOligoLocus",
    { "foreign.design_id" => "self.id" }
);

__PACKAGE__->many_to_many(
    "processes",
    "process_designs",
    "process"
);

has 'info' => (
    is      => 'ro',
    isa     => 'LIMS2::Model::Util::DesignInfo',
    lazy    => 1,
    builder => '_build_design_info',
    handles => {
        chr_name            => 'chr_name',
        chr_strand          => 'chr_strand',
        target_region_start => 'target_region_start',
        target_region_end   => 'target_region_end',
    }
);

sub _build_design_info {
    my $self = shift;

    require LIMS2::Model::Util::DesignInfo;
    return LIMS2::Model::Util::DesignInfo->new( { design => $self } );
}

sub as_hash {
    my ( $self, $suppress_relations ) = @_;

    # updates design object with latest information from database
    # if not done then the created_at value which can default to the current
    # timestamp does not seem to be set and a error is thrown
    $self->discard_changes;

    my %h = (
        id                      => $self->id,
        name                    => $self->name,
        type                    => $self->design_type_id,
        created_at              => $self->created_at->iso8601,
        created_by              => $self->created_by->name,
        phase                   => $self->phase,
        validated_by_annotation => $self->validated_by_annotation,
        target_transcript       => $self->target_transcript,
        species                 => $self->species_id,
        assigned_genes          => [ map { $_->gene_id } $self->genes ],
        cassette_first          => $self->cassette_first,
    );

    if ( ! $suppress_relations ) {
        my $oligos = $self->_sort_oligos;
        $h{comments}           = [ map { $_->as_hash } $self->comments ];
        $h{oligos}             = $oligos;
        $h{oligos_fasta}       = $self->_oligos_fasta( $oligos );
        $h{genotyping_primers} = [ sort { $a->{type} cmp $b->{type} } map { $_->as_hash } $self->genotyping_primers ];
    }

    return \%h;
}

use overload '""' => \&as_string;

sub as_string {
    return shift->id;
}

sub _sort_oligos {
    my $self = shift;

    my @oligos = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
            map { [ $_, $_->{locus} ? $_->{locus}{chr_start} : -1 ] }
                map { $_->as_hash } $self->oligos;

    return \@oligos;
}

sub _oligos_fasta {
    my ( $self, $oligos ) = @_;

    return unless @{$oligos};

    my $strand = $oligos->[0]{locus}{chr_strand};
    return unless $strand;

    require Bio::Seq;
    require Bio::SeqIO;
    require IO::String;

    my $fasta;
    my $seq_io = Bio::SeqIO->new( -format => 'fasta', -fh => IO::String->new( $fasta ) );

    my $seq = Bio::Seq->new( -display_id => 'design_' . $self->id,
                             -alphabet   => 'dna',
                             -seq        => join '', map { $_->{seq} } @{ $oligos } );

    $seq_io->write_seq( $strand == 1 ? $seq : $seq->revcom );

    return $fasta;
}

sub oligo_order_seqs {
    my $self = shift;
    my %oligo_order_seqs;

    my @oligos = $self->oligos;
    for my $oligo ( @oligos ) {
        my $type = $oligo->design_oligo_type_id;
        $oligo_order_seqs{ $type } = $oligo->oligo_order_seq( $self->chr_strand, $self->design_type_id );
    }

    return \%oligo_order_seqs;
}

sub design_parameters_hash {
    my $self = shift;

    require JSON;
    use Try::Tiny;

    if ( my $design_param_string = $self->design_parameters ) {
        return try{ JSON->new->utf8->decode( $design_param_string ); };
    }

    return;
}

=head2 fetch_canonical_transcript_id

Fetch the gene for the design, then retrieve and return the canonical transcript if one exists

=cut
sub fetch_canonical_transcript_id {
    my $self = shift;

    # fetch array of gene designs
    my @gene_designs = $self->genes;

    if( scalar @gene_designs > 1 ) {
      # expecting only one gene, error
      return 0;
    }

    foreach my $gene_design ( @gene_designs ) {
      my $ensEMBL_gene = $gene_design->ensEMBL_gene;
      unless ( $ensEMBL_gene ) { next; };
      my $canonical_transcript = $ensEMBL_gene->canonical_transcript;
      unless ( $canonical_transcript ) { next; };
      return $canonical_transcript->stable_id;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;
