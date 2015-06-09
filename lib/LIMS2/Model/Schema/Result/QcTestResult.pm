use utf8;
package LIMS2::Model::Schema::Result::QcTestResult;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::QcTestResult::VERSION = '0.322';
}
## use critic


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

=head2 qc_eng_seq_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 score

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 pass

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 qc_run_seq_well_id

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
  "qc_eng_seq_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "score",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "pass",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "qc_run_seq_well_id",
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

Related object: L<LIMS2::Model::Schema::Result::QcRun>

=cut

__PACKAGE__->belongs_to(
  "qc_run",
  "LIMS2::Model::Schema::Result::QcRun",
  { id => "qc_run_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_run_seq_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcRunSeqWell>

=cut

__PACKAGE__->belongs_to(
  "qc_run_seq_well",
  "LIMS2::Model::Schema::Result::QcRunSeqWell",
  { id => "qc_run_seq_well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YP8MdZ7cZLVKxjfuqnDYpQ

sub as_hash {
    my $self = shift;

    return { map { $_ => $self->$_ } $self->columns };
}

__PACKAGE__->meta->make_immutable;
1;
