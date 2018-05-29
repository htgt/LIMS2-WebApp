use utf8;
package LIMS2::Model::Schema::Result::DesignHdrTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::DesignHdrTemplate

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

=head1 TABLE: C<design_hdr_templates>

=cut

__PACKAGE__->table("design_hdr_templates");

=head1 ACCESSORS

=head2 design_id

  data_type: 'integer'
  is_nullable: 0

=head2 template

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "design_id",
  { data_type => "integer", is_nullable => 0 },
  "template",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_id>

=back

=cut

__PACKAGE__->set_primary_key("design_id");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2018-05-29 10:33:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/ZKbHScaKniqzpUKh8weNA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
