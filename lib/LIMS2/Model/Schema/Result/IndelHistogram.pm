use utf8;
package LIMS2::Model::Schema::Result::IndelHistogram;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::IndelHistogram

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

=head1 TABLE: C<indel_histogram>

=cut

__PACKAGE__->table("indel_histogram");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'indel_histogram_id_seq'

=head2 miseq_well_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 indel_size

  data_type: 'integer'
  is_nullable: 1

=head2 frequency

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "indel_histogram_id_seq",
  },
  "miseq_well_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "indel_size",
  { data_type => "integer", is_nullable => 1 },
  "frequency",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 miseq_well_experiment

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqWellExperiment>

=cut

__PACKAGE__->belongs_to(
  "miseq_well_experiment",
  "LIMS2::Model::Schema::Result::MiseqWellExperiment",
  { id => "miseq_well_experiment_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mr7phBrs4cnytNe4JXomTQ

sub as_hash {
    my $self = shift;

    my %h = (
        id          => $self->id,
        well_exp_id => $self->miseq_well_experiment_id,
        indel_size  => $self->indel_size,
        frequency   => $self->frequency,
    );

    return \%h;
}



# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
