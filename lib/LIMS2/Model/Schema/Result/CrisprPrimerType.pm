use utf8;
package LIMS2::Model::Schema::Result::CrisprPrimerType;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprPrimerType::VERSION = '0.524';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprPrimerType

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

=head1 TABLE: C<crispr_primer_types>

=cut

__PACKAGE__->table("crispr_primer_types");

=head1 ACCESSORS

=head2 primer_name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns("primer_name", { data_type => "text", is_nullable => 0 });

=head1 PRIMARY KEY

=over 4

=item * L</primer_name>

=back

=cut

__PACKAGE__->set_primary_key("primer_name");

=head1 RELATIONS

=head2 crispr_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimer>

=cut

__PACKAGE__->has_many(
  "crispr_primers",
  "LIMS2::Model::Schema::Result::CrisprPrimer",
  { "foreign.primer_name" => "self.primer_name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-10-07 10:47:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CXr98aUWuTb1xOFIQFTf8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
