use utf8;
package LIMS2::Model::Schema::Result::SequencingProjectBackup;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::SequencingProjectBackup::VERSION = '0.474';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::SequencingProjectBackup

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

=head1 TABLE: C<sequencing_project_backups>

=cut

__PACKAGE__->table("sequencing_project_backups");

=head1 ACCESSORS

=head2 seq_project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 directory

  data_type: 'text'
  is_nullable: 0

=head2 creation_date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "seq_project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "directory",
  { data_type => "text", is_nullable => 0 },
  "creation_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</seq_project_id>

=item * L</directory>

=back

=cut

__PACKAGE__->set_primary_key("seq_project_id", "directory");

=head1 RELATIONS

=head2 seq_project

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::SequencingProject>

=cut

__PACKAGE__->belongs_to(
  "seq_project",
  "LIMS2::Model::Schema::Result::SequencingProject",
  { id => "seq_project_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-06-27 14:15:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yvr5h08lAr539rKXSa0V7w

sub as_hash {
    my ( $self, $options ) = @_;
    my $dt = $self->result_source->schema->storage->datetime_parser;
    my %h = (
        seq_id  => $self->seq_project_id,
        dir     => $self->directory,
        date    => $dt->format_datetime($self->creation_date),
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
