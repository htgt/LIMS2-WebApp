use utf8;
package LIMS2::Model::Schema::Result::DesignOligoAppend;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::DesignOligoAppend::VERSION = '0.435';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::DesignOligoAppend

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

=head1 TABLE: C<design_oligo_appends>

=cut

__PACKAGE__->table("design_oligo_appends");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 design_oligo_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 seq

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "design_oligo_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "seq",
  { data_type => "text", is_nullable => 0 },
);

=head1 RELATIONS

=head2 design_oligo_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::DesignOligoType>

=cut

__PACKAGE__->belongs_to(
  "design_oligo_type",
  "LIMS2::Model::Schema::Result::DesignOligoType",
  { id => "design_oligo_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-01-05 14:00:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+y8pKKQ+Sl/Czz63sA+8Hw

sub as_hash {
    my $self = shift;

    my %h = (
        id      => $self->id,
        oligo   => $self->design_oligo_type_id,
        seq     => $self->seq,
    );

    return \%h;
}

sub get_seq {
    my $self = shift;
    return $self->seq;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
