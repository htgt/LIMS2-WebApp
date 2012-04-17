use utf8;
package LIMS2::Model::Schema::Result::QcTestResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcTestResult

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

=head1 TABLE: C<qc_test_results>

=cut

__PACKAGE__->table("qc_test_results");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'qc_test_results_id_seq'

=head2 qc_run_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 36

=head2 well_name

  data_type: 'text'
  is_nullable: 0

=head2 score

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 pass

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 plate_name

  data_type: 'text'
  is_nullable: 0

=head2 qc_eng_seq_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "qc_test_results_id_seq",
  },
  "qc_run_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 36 },
  "well_name",
  { data_type => "text", is_nullable => 0 },
  "score",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "pass",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "plate_name",
  { data_type => "text", is_nullable => 0 },
  "qc_eng_seq_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 qc_eng_seq

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcEngSeq>

=cut

__PACKAGE__->belongs_to(
  "qc_eng_seq",
  "LIMS2::Model::Schema::Result::QcEngSeq",
  { id => "qc_eng_seq_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_run

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcRuns>

=cut

__PACKAGE__->belongs_to(
  "qc_run",
  "LIMS2::Model::Schema::Result::QcRuns",
  { id => "qc_run_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_test_result_alignment_maps

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTestResultAlignmentMap>

=cut

__PACKAGE__->has_many(
  "qc_test_result_alignment_maps",
  "LIMS2::Model::Schema::Result::QcTestResultAlignmentMap",
  { "foreign.qc_test_result_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2012-04-13 11:34:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cB+EtEsbSB5Cy5Zrd/2BCA

sub as_hash {
    my $self = shift;

    return {
        id         => $self->id,
        qc_run_id  => $self->qc_run_id,
        well_name  => $self->well_name,
        plate_name => $self->plate_name,
        score      => $self->score,
        pass       => $self->pass,
    };
}

__PACKAGE__->meta->make_immutable;
1;
