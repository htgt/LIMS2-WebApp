use utf8;
package LIMS2::Model::Schema::Result::QcSeqRead;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::QcSeqRead::VERSION = '0.432';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcSeqRead

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

=head1 TABLE: C<qc_seq_reads>

=cut

__PACKAGE__->table("qc_seq_reads");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 primer_name

  data_type: 'text'
  is_nullable: 0

=head2 seq

  data_type: 'text'
  is_nullable: 0

=head2 length

  data_type: 'integer'
  is_nullable: 0

=head2 qc_seq_project_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "primer_name",
  { data_type => "text", is_nullable => 0 },
  "seq",
  { data_type => "text", is_nullable => 0 },
  "length",
  { data_type => "integer", is_nullable => 0 },
  "qc_seq_project_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 qc_alignments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcAlignment>

=cut

__PACKAGE__->has_many(
  "qc_alignments",
  "LIMS2::Model::Schema::Result::QcAlignment",
  { "foreign.qc_seq_read_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_run_seq_well_qc_seqs_read

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcRunSeqWellQcSeqRead>

=cut

__PACKAGE__->has_many(
  "qc_run_seq_well_qc_seqs_read",
  "LIMS2::Model::Schema::Result::QcRunSeqWellQcSeqRead",
  { "foreign.qc_seq_read_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_seq_project

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcSeqProject>

=cut

__PACKAGE__->belongs_to(
  "qc_seq_project",
  "LIMS2::Model::Schema::Result::QcSeqProject",
  { id => "qc_seq_project_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qH8WK+10S98cpFCQ+8w5/w

__PACKAGE__->many_to_many("qc_seq_wells", "qc_run_seq_well_qc_seqs_read", "qc_run_seq_well");

sub as_hash {
    my $self = shift;

    return { map { $_ => $self->$_ } __PACKAGE__->columns };
}

use Bio::Seq;
sub bio_seq {
    my $self = shift;

    return Bio::Seq->new(
        -display_id => $self->id,
        -desc       => $self->description,
        -alphabet   => 'dna',
        -seq        => $self->seq
    );
}

#qc_alignments can return duplicates, but if we have a qc_run_id we will only return
#the ones attached to that run (because a seq read can belong to multiple runs)
sub alignments_for_run {
  my ( $self, $qc_run_id ) = @_;

  my @all_qc_alignments = $self->qc_alignments;

  my @run_alignments = grep { defined $_->qc_run_id && $_->qc_run_id eq $qc_run_id }
                          @all_qc_alignments;

  #if we didn't get any alignments for this specific run just return everything.
  return ( @run_alignments ) ? @run_alignments : @all_qc_alignments;
};

__PACKAGE__->meta->make_immutable;
1;
