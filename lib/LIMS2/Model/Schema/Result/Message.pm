use utf8;
package LIMS2::Model::Schema::Result::Message;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Message::VERSION = '0.419';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Message

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

=head1 TABLE: C<messages>

=cut

__PACKAGE__->table("messages");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'messages_id_seq'

=head2 message

  data_type: 'text'
  is_nullable: 1

=head2 created_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 expiry_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 priority

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 wge

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 lims

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 htgt

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "messages_id_seq",
  },
  "message",
  { data_type => "text", is_nullable => 1 },
  "created_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "expiry_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "priority",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "wge",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "lims",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "htgt",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 priority

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Priority>

=cut

__PACKAGE__->belongs_to(
  "priority",
  "LIMS2::Model::Schema::Result::Priority",
  { id => "priority" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-04-20 15:17:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:48GHmHI2baow5zMxya+/ew


sub as_hash {
    my $self = shift;

    my %h = (
        id          => $self->id,
        created     => $self->created_date->dmy('/'),
        message     => $self->message,
        expiry      => $self->expiry_date->dmy('/'),
        priority    => $self->priority->id,
        wge         => $self->wge,
        lims        => $self->lims,
        htgt        => $self->htgt,
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
