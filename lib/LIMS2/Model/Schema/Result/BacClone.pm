use utf8;
package LIMS2::Model::Schema::Result::BacClone;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::BacClone::VERSION = '0.472';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::BacClone

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

=head1 TABLE: C<bac_clones>

=cut

__PACKAGE__->table("bac_clones");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'bac_clones_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 bac_library_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "bac_clones_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "bac_library_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<bac_clones_name_bac_library_id_key>

=over 4

=item * L</name>

=item * L</bac_library_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "bac_clones_name_bac_library_id_key",
  ["name", "bac_library_id"],
);

=head1 RELATIONS

=head2 bac_library

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::BacLibrary>

=cut

__PACKAGE__->belongs_to(
  "bac_library",
  "LIMS2::Model::Schema::Result::BacLibrary",
  { id => "bac_library_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 loci

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BacCloneLocus>

=cut

__PACKAGE__->has_many(
  "loci",
  "LIMS2::Model::Schema::Result::BacCloneLocus",
  { "foreign.bac_clone_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_bacs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessBac>

=cut

__PACKAGE__->has_many(
  "process_bacs",
  "LIMS2::Model::Schema::Result::ProcessBac",
  { "foreign.bac_clone_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lI+AOQpDqVzJ6C0XYy3R0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_hash {
    my $self = shift;

    my %h = (
        id          => $self->id,
        bac_name    => $self->name,
        bac_library => $self->bac_library_id,
    );

    if ( my @loci = $self->loci ) {
        $h{loci} = [ map { $_->as_hash } @loci ]
    }

    return \%h;
}

__PACKAGE__->meta->make_immutable;
1;
