use utf8;
package LIMS2::Model::Schema::Result::Experiment;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Experiment::VERSION = '0.412';
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

=head2 gene_id

  data_type: 'text'
  is_nullable: 1

=head2 plated

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 deleted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "experiments_id_seq",
  },
  "design_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr_pair_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "gene_id",
  { data_type => "text", is_nullable => 1 },
  "plated",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-02-22 12:24:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r1V5OvWyV0Ze3tthsOkhBg

sub as_hash{
    my $self = shift;

    return {
        id              => $self->id,
        gene_id         => $self->gene_id,
        design_id       => $self->design_id,
        crispr_id       => $self->crispr_id,
        crispr_pair_id  => $self->crispr_pair_id,
        crispr_group_id => $self->crispr_group_id,
        deleted         => $self->deleted,
    };
}

sub as_hash_with_detail{
    my $self = shift;

    my $info = $self->as_hash;

    $info->{gene_id} = $self->gene_id;

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
            my $crispr_detail =  {
                id        => $crispr->id,
                seq       => $crispr->seq,
                pam_right => !defined $crispr->pam_right ? '' : $crispr->pam_right == 1 ? 'true' : 'false',
            };

            if(my $locus = $crispr->current_locus){
                $crispr_detail->{chr_name}  = $locus->chr->name;
                $crispr_detail->{chr_start} = $locus->chr_start;
                $crispr_detail->{chr_end}   = $locus->chr_end;
                $crispr_detail->{assembly}  = $locus->assembly_id;
            }
            push @crispr_info, $crispr_detail;
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

# Grab the first design or crispr entity we find so we can get chromosome info etc from it
sub _related_entity{
    my $self = shift;
    my ($related_entity) = grep { $_ } ( $self->crispr, $self->crispr_pair, $self->crispr_group, $self->design );
    return $related_entity;
}

sub species_id{
    my $self = shift;
    return $self->_related_entity->species_id;
}

sub chr_name{
    my $self = shift;
    return $self->_related_entity->chr_name;
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

sub crisprs{
    my $self = shift;
    my @crisprs;
    if($self->crispr){
        push @crisprs, $self->crispr;
    }

    if($self->crispr_pair){
        push @crisprs, ($self->crispr_pair->left_crispr, $self->crispr_pair->right_crispr);
    }

    if($self->crispr_group){
        push @crisprs, $self->crispr_group->crisprs;
    }
    return @crisprs;
}

# In practice experiments seem to have only 1 of crispr, pair or group
# but this is an assumption and is not restricted by the schema
sub crispr_entity{
    my $self = shift;
    if($self->crispr){
        return $self->crispr;
    }

    if($self->crispr_pair){
        return $self->crispr_pair;
    }

    if($self->crispr_group){
        return $self->crispr_group;
    }
    return;
}
sub _chr_location{
    my ($self, $entity) = @_;
    my $location = "chr".$entity->chr_name.":".$entity->start."-".$entity->end;
    return $location;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
