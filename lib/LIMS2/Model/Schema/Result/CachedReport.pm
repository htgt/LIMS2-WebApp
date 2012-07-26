use utf8;
package LIMS2::Model::Schema::Result::CachedReport;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CachedReport

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

=head1 TABLE: C<cached_reports>

=cut

__PACKAGE__->table("cached_reports");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 36

=head2 report_class

  data_type: 'text'
  is_nullable: 0

=head2 params

  data_type: 'text'
  is_nullable: 0

=head2 expires

  data_type: 'timestamp'
  default_value: (now() + '08:00:00'::interval)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 36 },
  "report_class",
  { data_type => "text", is_nullable => 0 },
  "params",
  { data_type => "text", is_nullable => 0 },
  "expires",
  {
    data_type     => "timestamp",
    default_value => \"(now() + '08:00:00'::interval)",
    is_nullable   => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cached_reports_report_class_params_key>

=over 4

=item * L</report_class>

=item * L</params>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "cached_reports_report_class_params_key",
  ["report_class", "params"],
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-07-26 18:16:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L/KCszm7wcxQEDmoFTrhjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
