use utf8;
package LIMS2::Model::Schema::Result::QcSeqRead;

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

=head2 seq

  data_type: 'text'
  is_nullable: 0

=head2 length

  data_type: 'integer'
  is_nullable: 0

=head2 qc_sequencing_project

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "seq",
  { data_type => "text", is_nullable => 0 },
  "length",
  { data_type => "integer", is_nullable => 0 },
  "qc_sequencing_project",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 qc_sequencing_project_rel

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcSequencingProject>

=cut

__PACKAGE__->belongs_to(
  "qc_sequencing_project_rel",
  "LIMS2::Model::Schema::Result::QcSequencingProject",
  { name => "qc_sequencing_project" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_test_result_alignments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTestResultAlignment>

=cut

__PACKAGE__->has_many(
  "qc_test_result_alignments",
  "LIMS2::Model::Schema::Result::QcTestResultAlignment",
  { "foreign.qc_seq_read_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2012-04-13 11:34:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/q2pVbuJVtw27YT0a4rqIA

sub as_hash {
    my $self = shift;

    return {
        id                    => $self->id,
        seq                   => $self->seq,
        length                => $self->length,
        description           => $self->description,
        qc_sequencing_project => $self->qc_sequencing_project,
    };
}

__PACKAGE__->meta->make_immutable;
1;
