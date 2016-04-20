use utf8;
package LIMS2::Model::Schema::Result::QcAlignmentRegion;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::QcAlignmentRegion::VERSION = '0.395';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcAlignmentRegion

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

=head1 TABLE: C<qc_alignment_regions>

=cut

__PACKAGE__->table("qc_alignment_regions");

=head1 ACCESSORS

=head2 qc_alignment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 length

  data_type: 'integer'
  is_nullable: 0

=head2 match_count

  data_type: 'integer'
  is_nullable: 0

=head2 query_str

  data_type: 'text'
  is_nullable: 0

=head2 target_str

  data_type: 'text'
  is_nullable: 0

=head2 match_str

  data_type: 'text'
  is_nullable: 0

=head2 pass

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "qc_alignment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "length",
  { data_type => "integer", is_nullable => 0 },
  "match_count",
  { data_type => "integer", is_nullable => 0 },
  "query_str",
  { data_type => "text", is_nullable => 0 },
  "target_str",
  { data_type => "text", is_nullable => 0 },
  "match_str",
  { data_type => "text", is_nullable => 0 },
  "pass",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_alignment_id>

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("qc_alignment_id", "name");

=head1 RELATIONS

=head2 qc_alignment

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcAlignment>

=cut

__PACKAGE__->belongs_to(
  "qc_alignment",
  "LIMS2::Model::Schema::Result::QcAlignment",
  { id => "qc_alignment_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rlO+BrctsXIqfdSScKBKTw

use HTGT::QC::Util::Alignment;

sub format_alignment {
    my ( $self, $line_len, $header_len ) = @_;

    my $strand = $self->qc_alignment->target_strand == 1 ? '+' : '-';

    return HTGT::QC::Util::Alignment::format_alignment(
        target_id  => "Target ($strand)",
        target_str => $self->target_str,
        query_id   => 'Sequence Read',
        query_str  => $self->query_str,
        match_str  => $self->match_str,
        line_len   => $line_len,
        header_len => $header_len
    );
}
__PACKAGE__->meta->make_immutable;
1;
