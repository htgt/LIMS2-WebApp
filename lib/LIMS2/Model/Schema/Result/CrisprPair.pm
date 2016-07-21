use utf8;
package LIMS2::Model::Schema::Result::CrisprPair;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprPair::VERSION = '0.413';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprPair

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

=head1 TABLE: C<crispr_pairs>

=cut

__PACKAGE__->table("crispr_pairs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispr_pairs_id_seq'

=head2 left_crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 right_crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 spacer

  data_type: 'integer'
  is_nullable: 0

=head2 off_target_summary

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crispr_pairs_id_seq",
  },
  "left_crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "right_crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "spacer",
  { data_type => "integer", is_nullable => 0 },
  "off_target_summary",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<unique_pair>

=over 4

=item * L</left_crispr_id>

=item * L</right_crispr_id>

=back

=cut

__PACKAGE__->add_unique_constraint("unique_pair", ["left_crispr_id", "right_crispr_id"]);

=head1 RELATIONS

=head2 crispr_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimer>

=cut

__PACKAGE__->has_many(
  "crispr_primers",
  "LIMS2::Model::Schema::Result::CrisprPrimer",
  { "foreign.crispr_pair_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 experiments_including_deleted

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Experiment>

=cut

__PACKAGE__->has_many(
  "experiments_including_deleted",
  "LIMS2::Model::Schema::Result::Experiment",
  { "foreign.crispr_pair_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 left_crispr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Crispr>

=cut

__PACKAGE__->belongs_to(
  "left_crispr",
  "LIMS2::Model::Schema::Result::Crispr",
  { id => "left_crispr_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 right_crispr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Crispr>

=cut

__PACKAGE__->belongs_to(
  "right_crispr",
  "LIMS2::Model::Schema::Result::Crispr",
  { id => "right_crispr_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-02-22 11:13:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LhiddgZPOuluhszoE32LqQ

__PACKAGE__->has_many(
  "experiments",
  "LIMS2::Model::Schema::Result::Experiment",
  { "foreign.crispr_pair_id" => "self.id" },
  { where => { "deleted" => 0 } },
);

# crispr_designs table merged into experiments table
sub crispr_designs{
    return shift->experiments;
}

sub as_hash {
    my ( $self ) = @_;

    my %h = (
        id                 => $self->id,
        left_crispr_id     => $self->left_crispr_id,
        right_crispr_id    => $self->right_crispr_id,
        spacer             => $self->spacer,
        off_target_summary => $self->off_target_summary,
        crispr_primers     => [ map { $_->as_hash } $self->crispr_primers ],
    );

    return \%h;
}

use overload '""' => \&as_string;

sub as_string {
    my $self = shift;

    return $self->id . '(' . $self->left_crispr_id . '-' . $self->right_crispr_id . ')';
}

sub right_crispr_locus {
    return shift->right_crispr->current_locus;
}

sub left_crispr_locus {
    return shift->left_crispr->current_locus;
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

sub species_id {
    return shift->right_crispr->species_id;
}

sub start {
    return shift->left_crispr_locus->chr_start;
}

sub end {
    return shift->right_crispr_locus->chr_end;
}

sub chr_id {
    return shift->right_crispr_locus->chr_id;
}

sub chr_name {
    return shift->right_crispr_locus->chr->name;
}

sub default_assembly {
    return shift->left_crispr->default_assembly;
}

# The name of the foreign key column to use when
# linking e.g. a crispr_primer to a crispr_pair
sub id_column_name{
    return 'crispr_pair_id';
}

sub is_pair { return 1; }

sub is_group { return; }

sub related_designs {
  my $self = shift;

  my @crispr_designs = (
    $self->crispr_designs,
    $self->left_crispr->crispr_designs,
    $self->right_crispr->crispr_designs,
  );

  return map { $_->design } @crispr_designs;
}

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
