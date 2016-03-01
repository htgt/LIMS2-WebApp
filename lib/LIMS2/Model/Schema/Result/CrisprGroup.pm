use utf8;
package LIMS2::Model::Schema::Result::CrisprGroup;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprGroup::VERSION = '0.379';
}
## use critic


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

=head2 experiments_including_deleted

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Experiment>

=cut

__PACKAGE__->has_many(
  "experiments_including_deleted",
  "LIMS2::Model::Schema::Result::Experiment",
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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-02-22 11:13:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:k1J27j84/wlQQfgZqNcH4w
#
=head2 crisprs

Type: many_to_many

Composing rels: L</crispr_group_crisprs> -> crispr

=cut

__PACKAGE__->many_to_many("crisprs", "crispr_group_crisprs", "crispr");

__PACKAGE__->has_many(
  "experiments",
  "LIMS2::Model::Schema::Result::Experiment",
  { "foreign.crispr_group_id" => "self.id" },
  { where => { "deleted" => 0 } },
);

# crispr_designs table merged into experiments table
sub crispr_designs{
    return shift->experiments;
}

has ranked_crisprs => (
    is         => 'ro',
    isa        => 'ArrayRef[LIMS2::Model::Schema::Result::Crispr]',
    lazy_build => 1,
);

sub _build_ranked_crisprs {
    my $self = shift;
    return [ sort { $a->current_locus->chr_start <=> $b->current_locus->chr_start } $self->crisprs ];
}

has left_ranked_crisprs => (
    is         => 'ro',
    isa        => 'ArrayRef[LIMS2::Model::Schema::Result::Crispr]',
    lazy_build => 1,
);

sub _build_left_ranked_crisprs {
    my $self = shift;
    return [
        sort { $a->current_locus->chr_start <=> $b->current_locus->chr_start } map { $_->crispr }
        grep { $_->left_of_target } $self->crispr_group_crisprs
    ];
}

has right_ranked_crisprs => (
    is         => 'ro',
    isa        => 'ArrayRef[LIMS2::Model::Schema::Result::Crispr]',
    lazy_build => 1,
);

sub _build_right_ranked_crisprs {
    my $self = shift;
    return [
        sort { $a->current_locus->chr_start <=> $b->current_locus->chr_start } map { $_->crispr }
        grep { !$_->left_of_target } $self->crispr_group_crisprs
    ];
}

has left_most_crispr  => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::Crispr',
    lazy_build => 1,
);

sub _build_left_most_crispr {
    return shift->ranked_crisprs->[0];
}

has right_most_crispr  => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::Crispr',
    lazy_build => 1,
);

sub _build_right_most_crispr {
    return shift->ranked_crisprs->[-1];
}

sub as_hash {
    my ( $self ) = @_;

    my %h = (
        id             => $self->id,
        gene_id        => $self->gene_id,
        gene_type_id   => $self->gene_type_id,
        crispr_ids     => [ map{ $_->id } $self->crisprs ],
        left_crisprs   => [ map { $_->id } @{ $self->left_ranked_crisprs } ],
        right_crisprs  => [ map { $_->id } @{ $self->right_ranked_crisprs } ],
        group_crisprs  => [ map{ $_->as_hash } $self->crisprs ],
        crispr_primers => [ map { $_->as_hash } $self->crispr_primers ],
    );

    return \%h;
}

use overload '""' => \&as_string;

sub as_string {
    my $self = shift;

    return $self->id . '(' . join( '-', map { $_->id } $self->crisprs ) . ')';
}

sub start {
    return shift->left_most_crispr->current_locus->chr_start;
}

sub end {
    return shift->right_most_crispr->current_locus->chr_end;
}

sub chr_id {
    return shift->right_most_crispr->current_locus->chr_id;
}

sub chr_name {
    return shift->right_most_crispr->current_locus->chr->name;
}

sub species {
    return shift->right_most_crispr->species_id;
}

# Added species_id method to CrisprPair and CrisprGroup to fetch
# the species_id (name string) so it is equivalent to Crispr->species_id
# (Crispr->species returns the Species object)
sub species_id {
    return shift->right_most_crispr->species_id;
}

sub default_assembly{
    return shift->right_most_crispr->default_assembly;
}

# The name of the foreign key column to use when
# linking e.g. a crispr_primer to a crispr_group
sub id_column_name{
    return 'crispr_group_id';
}

sub target_slice {
    my ( $self, $ensembl_util ) = @_;

    unless ( $ensembl_util ) {
        require WebAppCommon::Util::EnsEMBL;
        $ensembl_util = WebAppCommon::Util::EnsEMBL->new( species => $self->right_most_crispr->species_id );
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

sub current_primer{
    my ( $self, $primer_type ) = @_;

    unless($primer_type){
        require LIMS2::Exception::Implementation;
        LIMS2::Exception::Implementation->throw( "You must provide a primer_type to the current_primer method" );
    }

    my @primers = $self->search_related('crispr_primers', { primer_name => $primer_type });

    # FIXME: what if more than 1?
    my ($current_primer) = grep { ! $_->is_rejected } @primers;
    return $current_primer;
}

__PACKAGE__->meta->make_immutable;

1;
