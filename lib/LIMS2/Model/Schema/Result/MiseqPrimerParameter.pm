use utf8;
package LIMS2::Model::Schema::Result::MiseqPrimerParameter;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::MiseqPrimerParameter::VERSION = '0.511';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqPrimerParameter

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

=head1 TABLE: C<miseq_primer_parameters>

=cut

__PACKAGE__->table("miseq_primer_parameters");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'miseq_primer_parameters_id_seq'

=head2 internal

  data_type: 'boolean'
  is_nullable: 0

=head2 min_length

  data_type: 'integer'
  is_nullable: 1

=head2 max_length

  data_type: 'integer'
  is_nullable: 1

=head2 opt_length

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "miseq_primer_parameters_id_seq",
  },
  "internal",
  { data_type => "boolean", is_nullable => 0 },
  "min_length",
  { data_type => "integer", is_nullable => 1 },
  "max_length",
  { data_type => "integer", is_nullable => 1 },
  "opt_length",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2018-02-21 13:01:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kCGhasY6LcIuPo9ocRco5w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
