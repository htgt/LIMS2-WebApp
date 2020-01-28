use utf8;
package LIMS2::Model::Schema::Result::ProcessRecombinase;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::ProcessRecombinase

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

=head1 TABLE: C<process_recombinase>

=cut

__PACKAGE__->table("process_recombinase");

=head1 ACCESSORS

=head2 process_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recombinase_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 rank

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "process_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recombinase_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "rank",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</process_id>

=item * L</rank>

=back

=cut

__PACKAGE__->set_primary_key("process_id", "rank");

=head1 UNIQUE CONSTRAINTS

=head2 C<process_recombinase_process_id_recombinase_id_key>

=over 4

=item * L</process_id>

=item * L</recombinase_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "process_recombinase_process_id_recombinase_id_key",
  ["process_id", "recombinase_id"],
);

=head1 RELATIONS

=head2 process

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Process>

=cut

__PACKAGE__->belongs_to(
  "process",
  "LIMS2::Model::Schema::Result::Process",
  { id => "process_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 recombinase

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Recombinase>

=cut

__PACKAGE__->belongs_to(
  "recombinase",
  "LIMS2::Model::Schema::Result::Recombinase",
  { id => "recombinase_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OM61BgLvvINqwX8rcLzmkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
