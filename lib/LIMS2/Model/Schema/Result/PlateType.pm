use utf8;
package LIMS2::Model::Schema::Result::PlateType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::PlateType

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

=head1 TABLE: C<plate_types>

=cut

__PACKAGE__->table("plate_types");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 eng_seq_stage

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "eng_seq_stage",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 plates

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Plate>

=cut

__PACKAGE__->has_many(
  "plates",
  "LIMS2::Model::Schema::Result::Plate",
  { "foreign.type_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-09-23 14:38:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zwnx7xYhaSDyHRRlKrKNTA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_hash {
    my $self = shift;
    return {
        id          => $self->id,
        description => $self->description
    }
}

use overload '""' => \&as_string;

sub as_string {
    return shift->id;
}

__PACKAGE__->meta->make_immutable;
1;
