use utf8;
package LIMS2::Model::Schema::Result::GeneDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::GeneDesign::VERSION = '0.407';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::GeneDesign

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

=head1 TABLE: C<gene_design>

=cut

__PACKAGE__->table("gene_design");

=head1 ACCESSORS

=head2 gene_id

  data_type: 'text'
  is_nullable: 0

=head2 design_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 gene_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gene_id",
  { data_type => "text", is_nullable => 0 },
  "design_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "gene_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gene_id>

=item * L</design_id>

=back

=cut

__PACKAGE__->set_primary_key("gene_id", "design_id");

=head1 RELATIONS

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

=head2 gene_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::GeneType>

=cut

__PACKAGE__->belongs_to(
  "gene_type",
  "LIMS2::Model::Schema::Result::GeneType",
  { id => "gene_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6ynGWcTWKNiqwuDRzdV4xw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub ensEMBL_gene {
    my $self = shift;

    my $species      = $self->design->species_id;
    my $gene_id      = $self->gene_id;
    my $gene_type_id = $self->gene_type->id;

    require LIMS2::Util::EnsEMBL;
    my $ensEMBL_util = LIMS2::Util::EnsEMBL->new( { 'species' => $species, } );
    my $ga = $ensEMBL_util->gene_adaptor();

    my $gene;
    if ( $gene_type_id eq 'HGNC' ) {
        if( $gene_id =~ /HGNC:(\d+)/ ) {
            $gene = _fetch_by_external_name( $ga, $1, 'HGNC' );
        }
    }
    elsif ( $gene_type_id eq 'MGI' ) {
        $gene = _fetch_by_external_name( $ga, $gene_id, 'MGI' );
    }
    elsif ( $gene_type_id eq 'marker_symbol' ) {
        $gene = _fetch_by_external_name( $ga, $gene_id );
    }

    return $gene;
}

=head2 _fetch_by_external_name

Wrapper around fetching ensembl gene given external gene name.

=cut
sub _fetch_by_external_name {
    my ( $ga, $gene_name, $type ) = @_;

    my @genes = @{ $ga->fetch_all_by_external_name($gene_name, $type) };

    #Remove stable ids that don't look like ENS... - human build has stable ids like LRG_...
    my @reduced_genes = grep {($_->stable_id =~ /ENS/) && ($_->seq_region_name !~ /PATCH/)} @genes;

    unless( @reduced_genes ) {
        LIMS2::Exception->throw("Unable to find gene $gene_name in EnsEMBL" );
    }

    if ( scalar(@reduced_genes) > 1 ) {
        my @stable_ids = map{ $_->stable_id } @reduced_genes;
        $type ||= 'marker symbol';

        LIMS2::Exception->throw( "Found multiple EnsEMBL genes with $type id $gene_name,"
                . " try using one of the following EnsEMBL gene ids: "
                . join( ', ', @stable_ids ) );
    }
    else {
        return shift @reduced_genes;
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;
