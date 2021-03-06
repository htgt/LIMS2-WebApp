use utf8;
package LIMS2::Model::Schema::Result::DnaTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::DnaTemplate

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

=head1 TABLE: C<dna_templates>

=cut

__PACKAGE__->table("dna_templates");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns("id", { data_type => "text", is_nullable => 0 });

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 processes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Process>

=cut

__PACKAGE__->has_many(
  "processes",
  "LIMS2::Model::Schema::Result::Process",
  { "foreign.dna_template" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 summaries

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Summary>

=cut

__PACKAGE__->has_many(
  "summaries",
  "LIMS2::Model::Schema::Result::Summary",
  { "foreign.dna_template" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-02-03 15:36:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Dw5sSeQGPQHC3iohHNlwsA

sub as_string {
    my $self = shift;
    return $self->id;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
