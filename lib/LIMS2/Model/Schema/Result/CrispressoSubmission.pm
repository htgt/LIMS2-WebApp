use utf8;
package LIMS2::Model::Schema::Result::CrispressoSubmission;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrispressoSubmission

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

=head1 TABLE: C<crispresso_submissions>

=cut

__PACKAGE__->table("crispresso_submissions");

=head1 ACCESSORS

=head2 miseq_well_exp_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 crispr

  data_type: 'text'
  is_nullable: 1

=head2 date_stamp

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "miseq_well_exp_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "crispr",
  { data_type => "text", is_nullable => 1 },
  "date_stamp",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</miseq_well_exp_id>

=back

=cut

__PACKAGE__->set_primary_key("miseq_well_exp_id");

=head1 RELATIONS

=head2 miseq_well_exp

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqWellExperiment>

=cut

__PACKAGE__->belongs_to(
  "miseq_well_exp",
  "LIMS2::Model::Schema::Result::MiseqWellExperiment",
  { id => "miseq_well_exp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2019-04-30 10:16:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gzmDvAuMHoAztad8pUCC2w

sub as_hash {
    my $self = shift;

    my %h = (
        miseq_well_exp_id   => $self->miseq_well_exp_id,
        crispr              => $self->crispr,
        date_stamp          => $self->date_stamp->iso8601,
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
