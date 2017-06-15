use utf8;
package LIMS2::Model::Schema::Result::QcEngSeq;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::QcEngSeq::VERSION = '0.460';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcEngSeq

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

=head1 TABLE: C<qc_eng_seqs>

=cut

__PACKAGE__->table("qc_eng_seqs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'qc_eng_seqs_id_seq'

=head2 method

  data_type: 'text'
  is_nullable: 0

=head2 params

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "qc_eng_seqs_id_seq",
  },
  "method",
  { data_type => "text", is_nullable => 0 },
  "params",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<qc_eng_seqs_method_params_key>

=over 4

=item * L</method>

=item * L</params>

=back

=cut

__PACKAGE__->add_unique_constraint("qc_eng_seqs_method_params_key", ["method", "params"]);

=head1 RELATIONS

=head2 qc_alignments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcAlignment>

=cut

__PACKAGE__->has_many(
  "qc_alignments",
  "LIMS2::Model::Schema::Result::QcAlignment",
  { "foreign.qc_eng_seq_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWell>

=cut

__PACKAGE__->has_many(
  "qc_template_wells",
  "LIMS2::Model::Schema::Result::QcTemplateWell",
  { "foreign.qc_eng_seq_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_test_results

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTestResult>

=cut

__PACKAGE__->has_many(
  "qc_test_results",
  "LIMS2::Model::Schema::Result::QcTestResult",
  { "foreign.qc_eng_seq_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:spzc0EL87hhmz1CLei+9YQ

use JSON qw( decode_json );

sub as_hash {
    my $self = shift;

    return {
        eng_seq_id     => $self->id,
        eng_seq_method => $self->method,
        eng_seq_params => decode_json( $self->params )
    };
}

sub design_id {
    my $self = shift;

    my $eng_seq_params = decode_json( $self->params );

    return $eng_seq_params->{design_id};
}

sub crispr_id {
    my $self = shift;

    my $eng_seq_params = decode_json( $self->params );

    return $eng_seq_params->{crispr_id};
}

__PACKAGE__->meta->make_immutable;
1;
