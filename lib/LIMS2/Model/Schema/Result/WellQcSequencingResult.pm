use utf8;
package LIMS2::Model::Schema::Result::WellQcSequencingResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::WellQcSequencingResult

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

=head1 TABLE: C<well_qc_sequencing_result>

=cut

__PACKAGE__->table("well_qc_sequencing_result");

=head1 ACCESSORS

=head2 well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 valid_primers

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 mixed_reads

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 pass

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 test_result_url

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "valid_primers",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "mixed_reads",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "pass",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "test_result_url",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</well_id>

=back

=cut

__PACKAGE__->set_primary_key("well_id");

=head1 RELATIONS

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "well_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lJ3fdzHF5cdkA2k+zIFrcQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_hash {
    my $self = shift;

    return {
        well_id         => $self->well_id,
        valid_primers   => $self->valid_primers,
        mixed_reads     => $self->mixed_reads,
        pass            => $self->pass,
        test_result_url => $self->test_result_url,
        created_by      => $self->created_by->name,
        created_at      => $self->created_at->iso8601,
    }
}

__PACKAGE__->meta->make_immutable;
1;
