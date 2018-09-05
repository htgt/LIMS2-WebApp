use utf8;
package LIMS2::Model::Schema::Result::MiseqDesignPreset;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::MiseqDesignPreset::VERSION = '0.512';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqDesignPreset

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

=head1 TABLE: C<miseq_design_presets>

=cut

__PACKAGE__->table("miseq_design_presets");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'miseq_design_presets_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 created_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genomic_threshold

  data_type: 'integer'
  is_nullable: 0

=head2 min_gc

  data_type: 'integer'
  is_nullable: 0

=head2 max_gc

  data_type: 'integer'
  is_nullable: 0

=head2 opt_gc

  data_type: 'integer'
  is_nullable: 0

=head2 min_mt

  data_type: 'integer'
  is_nullable: 0

=head2 max_mt

  data_type: 'integer'
  is_nullable: 0

=head2 opt_mt

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "miseq_design_presets_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "created_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genomic_threshold",
  { data_type => "integer", is_nullable => 0 },
  "min_gc",
  { data_type => "integer", is_nullable => 0 },
  "max_gc",
  { data_type => "integer", is_nullable => 0 },
  "opt_gc",
  { data_type => "integer", is_nullable => 0 },
  "min_mt",
  { data_type => "integer", is_nullable => 0 },
  "max_mt",
  { data_type => "integer", is_nullable => 0 },
  "opt_mt",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<miseq_design_presets_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("miseq_design_presets_name_key", ["name"]);

=head1 RELATIONS

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 miseq_primer_presets

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::MiseqPrimerPreset>

=cut

__PACKAGE__->has_many(
  "miseq_primer_presets",
  "LIMS2::Model::Schema::Result::MiseqPrimerPreset",
  { "foreign.preset_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2018-06-13 17:03:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RwM9N+S66LX3fITl2u4idg

sub as_hash {
    my $self = shift;

    my %h = (
        id => $self->id,
        name => $self->name,
        user => $self->created_by->name,
        genomic_threshold => $self->genomic_threshold,
        gc => {
            min => $self->min_gc,
            opt => $self->opt_gc,
            max => $self->max_gc,
        },
        mt => {
            min => $self->min_mt,
            opt => $self->opt_mt,
            max => $self->max_mt,
        },
    );

    my $intext_to_name = {
        1   => 'miseq',
        0   => 'pcr',
    };

    my @primers = $self->miseq_primer_presets;
    foreach my $primer (@primers) {
        $h{'primers'}{$intext_to_name->{$primer->internal}} = $primer->as_hash;
    }

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
