use utf8;
package LIMS2::Model::Schema::Result::ProcessBac;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::ProcessBac::VERSION = '0.204';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::ProcessBac

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

=head1 TABLE: C<process_bac>

=cut

__PACKAGE__->table("process_bac");

=head1 ACCESSORS

=head2 process_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 bac_plate

  data_type: 'text'
  is_nullable: 0

=head2 bac_clone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "process_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "bac_plate",
  { data_type => "text", is_nullable => 0 },
  "bac_clone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</process_id>

=item * L</bac_plate>

=back

=cut

__PACKAGE__->set_primary_key("process_id", "bac_plate");

=head1 RELATIONS

=head2 bac_clone

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::BacClone>

=cut

__PACKAGE__->belongs_to(
  "bac_clone",
  "LIMS2::Model::Schema::Result::BacClone",
  { id => "bac_clone_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 process

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Process>

=cut

__PACKAGE__->belongs_to(
  "process",
  "LIMS2::Model::Schema::Result::Process",
  { id => "process_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YlsiNRVA4G9OtUHWfjxMmA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
