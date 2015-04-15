use utf8;
package LIMS2::Model::Schema::Result::Experiment;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Experiment::VERSION = '0.303';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Experiment

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

=head1 TABLE: C<experiments>

=cut

__PACKAGE__->table("experiments");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'experiments_id_seq'

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 design_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 crispr_pair_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 crispr_group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "experiments_id_seq",
  },
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "design_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr_pair_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<experiment_components_key>

=over 4

=item * L</project_id>

=item * L</design_id>

=item * L</crispr_id>

=item * L</crispr_pair_id>

=item * L</crispr_group_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "experiment_components_key",
  [
    "project_id",
    "design_id",
    "crispr_id",
    "crispr_pair_id",
    "crispr_group_id",
  ],
);

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

=head2 design

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "LIMS2::Model::Schema::Result::Design",
  { id => "design_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 project

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "LIMS2::Model::Schema::Result::Project",
  { id => "project_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-03-30 14:31:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jY+6DMtaTv42ooTBAbaZkw

sub as_hash{
    my $self = shift;

    return {
        id              => $self->id,
        project_id      => $self->project_id,
        design_id       => $self->design_id,
        crispr_id       => $self->crispr_id,
        crispr_pair_id  => $self->crispr_pair_id,
        crispr_group_id => $self->crispr_group_id,
    };
}

sub as_hash_with_detail{
    my $self = shift;

    my $info = $self->as_hash;

    $info->{gene_id} = $self->project->gene_id;

    if(my $design = $self->design){
        my @design_primers = map { $_->as_hash } $design->genotyping_primers;
        $info->{design_genotyping_primers} = \@design_primers;
    }

    my @crisprs;
    my @crispr_entities;
    if(my $crispr = $self->crispr){
        push @crisprs, $crispr;
        push @crispr_entities, $crispr;
    }
    if(my $pair = $self->crispr_pair){
        push @crisprs, $pair->left_crispr, $pair->right_crispr;
        push @crispr_entities, $pair;
    }
    if(my $group = $self->crispr_group){
        push @crisprs, $group->crisprs;
        push @crispr_entities, $group;
    }

    if(@crisprs){
        my @crispr_info;
        foreach my $crispr (@crisprs){
            push @crispr_info, {
                id  => $crispr->id,
                seq => $crispr->seq,
            };
        }
        $info->{crisprs} = \@crispr_info;
    }

    if(@crispr_entities){
        my @primers;
        foreach my $entity (@crispr_entities){
            foreach my $primer ($entity->crispr_primers){
                push @primers, $primer->as_hash;
            }
        }
        $info->{crispr_primers} = \@primers;
    }
    return $info;
}

sub crispr_description{
    my $self = shift;

    my $description = "";
    if(my $crispr = $self->crispr){
        my $location = $self->_chr_location($crispr);
        $description.= "Single crispr ".$crispr->id." ($location)\n";
    }

    if(my $pair = $self->crispr_pair){
        my $location = $self->_chr_location($pair);
        $description.= "Crispr pair ".$pair->id." ($location)\n";
    }

    if(my $group = $self->crispr_group){
        my $location = $self->_chr_location($group);
        my $count = scalar $group->crisprs;
        $description.="Crispr group ".$group->id
        ." ($location, $count crisprs)";
    }

    return $description;
}

sub _chr_location{
    my ($self, $entity) = @_;
    my $location = "chr".$entity->chr_name.":".$entity->start."-".$entity->end;
    return $location;
}
# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
