use utf8;
package LIMS2::Model::Schema::Result::Amplicon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Amplicon

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

=head1 TABLE: C<amplicons>

=cut

__PACKAGE__->table("amplicons");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'amplicons_id_seq'

=head2 amplicon_type

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 seq

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "amplicons_id_seq",
  },
  "amplicon_type",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "seq",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 amplicon_loci

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::AmpliconLoci>

=cut

__PACKAGE__->might_have(
  "amplicon_loci",
  "LIMS2::Model::Schema::Result::AmpliconLoci",
  { "foreign.amplicon_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 amplicon_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::AmpliconType>

=cut

__PACKAGE__->belongs_to(
  "amplicon_type",
  "LIMS2::Model::Schema::Result::AmpliconType",
  { id => "amplicon_type" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design_amplicon

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::DesignAmplicon>

=cut

__PACKAGE__->might_have(
  "design_amplicon",
  "LIMS2::Model::Schema::Result::DesignAmplicon",
  { "foreign.amplicon_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-28 08:29:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zQ9ZO8h2bXXKldHS/+eOng

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
