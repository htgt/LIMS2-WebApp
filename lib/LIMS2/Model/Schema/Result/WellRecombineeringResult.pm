use utf8;
package LIMS2::Model::Schema::Result::WellRecombineeringResult;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::WellRecombineeringResult::VERSION = '0.205';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::WellRecombineeringResult

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

=head1 TABLE: C<well_recombineering_results>

=cut

__PACKAGE__->table("well_recombineering_results");

=head1 ACCESSORS

=head2 well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 result_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 result

  data_type: 'text'
  is_nullable: 0

=head2 comment_text

  data_type: 'text'
  default_value: (empty string)
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
  "result_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "result",
  { data_type => "text", is_nullable => 0 },
  "comment_text",
  { data_type => "text", default_value => "", is_nullable => 0 },
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

=item * L</result_type_id>

=back

=cut

__PACKAGE__->set_primary_key("well_id", "result_type_id");

=head1 RELATIONS

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 result_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::RecombineeringResultType>

=cut

__PACKAGE__->belongs_to(
  "result_type",
  "LIMS2::Model::Schema::Result::RecombineeringResultType",
  { id => "result_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rO8WdyRj3A74jLNdzC0cmw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_hash {
    my $self = shift;

    return {
        well_id     => $self->well_id,
        result_type => $self->result_type_id,
        result      => $self->result,
        comment     => $self->comment_text,
        created_by  => $self->created_by->name,
        created_at  => $self->created_at->iso8601
    }
}

__PACKAGE__->meta->make_immutable;
1;
