use utf8;
package LIMS2::Model::Schema::Result::DesignAppendAlias;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::DesignAppendAlias

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

=head1 TABLE: C<design_append_aliases>

=cut

__PACKAGE__->table("design_append_aliases");

=head1 ACCESSORS

=head2 design_type

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 alias

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "design_type",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "alias",
  { data_type => "text", is_nullable => 1 },
);

=head1 RELATIONS

=head2 design_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::DesignType>

=cut

__PACKAGE__->belongs_to(
  "design_type",
  "LIMS2::Model::Schema::Result::DesignType",
  { id => "design_type" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:woogtqlu5nYBgf2uRMqfhw

sub get_alias {
    my $self = shift;
    return $self->alias;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
