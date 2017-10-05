use utf8;
package LIMS2::Model::Schema::Result::MiseqExperiment;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::MiseqExperiment::VERSION = '0.474';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqExperiment

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

=head1 TABLE: C<miseq_experiment>

=cut

__PACKAGE__->table("miseq_experiment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'miseq_experiment_id_seq'

=head2 miseq_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 gene

  data_type: 'text'
  is_nullable: 1

=head2 mutation_reads

  data_type: 'integer'
  is_nullable: 1

=head2 total_reads

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "miseq_experiment_id_seq",
  },
  "miseq_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "gene",
  { data_type => "text", is_nullable => 1 },
  "mutation_reads",
  { data_type => "integer", is_nullable => 1 },
  "total_reads",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 miseq

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqProject>

=cut

__PACKAGE__->belongs_to(
  "miseq",
  "LIMS2::Model::Schema::Result::MiseqProject",
  { id => "miseq_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 miseq_project_well_exps

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::MiseqProjectWellExp>

=cut

__PACKAGE__->has_many(
  "miseq_project_well_exps",
  "LIMS2::Model::Schema::Result::MiseqProjectWellExp",
  { "foreign.miseq_exp_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2017-03-03 16:19:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Og/3VrSe4J9056eBBHUqFA

sub as_hash {
    my $self = shift;

    my %h = (
        id          => $self->id,
        miseq_id    => $self->miseq_id,
        name        => $self->name,
        gene        => $self->gene,
        nhej_count  => $self->mutation_reads,
        read_count  => $self->total_reads,
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
