use utf8;
package LIMS2::Model::Schema::Result::CrisprGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprGroup

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

=head1 TABLE: C<crispr_groups>

=cut

__PACKAGE__->table("crispr_groups");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispr_groups_id_seq'

=head2 gene_id

  data_type: 'text'
  is_nullable: 0

=head2 gene_type_id

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
    sequence          => "crispr_groups_id_seq",
  },
  "gene_id",
  { data_type => "text", is_nullable => 0 },
  "gene_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 crispr_group_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprGroupCrispr>

=cut

__PACKAGE__->has_many(
  "crispr_group_crisprs",
  "LIMS2::Model::Schema::Result::CrisprGroupCrispr",
  { "foreign.crispr_group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimer>

=cut

__PACKAGE__->has_many(
  "crispr_primers",
  "LIMS2::Model::Schema::Result::CrisprPrimer",
  { "foreign.crispr_group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::GeneType>

=cut

__PACKAGE__->belongs_to(
  "gene_type",
  "LIMS2::Model::Schema::Result::GeneType",
  { id => "gene_type_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-08-12 11:27:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L64+4SL07Gv0mJ+k8wxPWg

has ranked_crisprs => (
    is         => 'ro',
    isa        => 'ArrayRef[LIMS2::Model::Schema::Result::Crispr]',
    lazy_build => 1,
);

sub _build_ranked_crisprs {
    my $self = shift;
    return [ sort { $a->current_locus->chr_start <=> $b->current_locus->chr_start } $self->crisprs ];
}

has left_crispr  => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::Crispr',
    lazy_build => 1,
);

sub _build_left_crispr {
    return shift->ranked_crisprs->[0];
}

has right_crispr  => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::Crispr',
    lazy_build => 1,
);

sub _build_right_crispr {
    return shift->ranked_crisprs->[-1];
}

sub as_hash {
    my ( $self ) = @_;

    my %h = (
        id           => $self->id,
        gene_id      => $self->gene_id,
        gene_type_id => $self->gene_type_id,
        crispr_ids   => [ map{ $_->id  } $self->crisprs ],
    );

    return \%h;
}

use overload '""' => \&as_string;

sub as_string {
    my $self = shift;

    return $self->id . '(' . join( '-', map { $_->id } $self->crisprs ) . ')';
}

sub start {
    return shift->left_crispr->current_locus->chr_start;
}

sub end {
    return shift->right_crispr->current_locus->chr_end;
}

sub chr_id {
    return shift->right_crispr->current_locus->chr_id;
}

sub chr_name {
    return shift->right_crispr->current_locus->chr->name;
}

sub species {
    return shift->right_crispr->species_id;
}

sub target_slice {
    my ( $self, $ensembl_util ) = @_;

    unless ( $ensembl_util ) {
        require WebAppCommon::Util::EnsEMBL;
        $ensembl_util = WebAppCommon::Util::EnsEMBL->new( species => $self->right_crispr->species_id );
    }

    my $slice = $ensembl_util->slice_adaptor->fetch_by_region(
        'chromosome',
        $self->chr_name,
        $self->start,
        $self->end
    );

    return $slice;
}

sub is_pair { return; }

sub is_group { return 1; }

__PACKAGE__->meta->make_immutable;

1;