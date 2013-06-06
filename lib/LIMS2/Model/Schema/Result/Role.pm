use utf8;
package LIMS2::Model::Schema::Result::Role;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Role::VERSION = '0.077';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Role

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

=head1 TABLE: C<roles>

=cut

__PACKAGE__->table("roles");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'roles_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "roles_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<roles_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("roles_name_key", ["name"]);

=head1 RELATIONS

=head2 user_roles

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "LIMS2::Model::Schema::Result::UserRole",
  { "foreign.role_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: many_to_many

Composing rels: L</user_roles> -> user

=cut

__PACKAGE__->many_to_many("users", "user_roles", "user");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-05-10 09:34:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uumBlrhfH+BMqB+tge67iw

sub as_hash {
    my $self = shift;

    return { map { $_ => $self->$_ } $self->columns };
}

__PACKAGE__->meta->make_immutable;
1;
