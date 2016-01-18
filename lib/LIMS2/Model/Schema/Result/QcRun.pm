use utf8;
package LIMS2::Model::Schema::Result::QcRun;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::QcRun::VERSION = '0.363';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcRun

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

=head1 TABLE: C<qc_runs>

=cut

__PACKAGE__->table("qc_runs");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 36

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 profile

  data_type: 'text'
  is_nullable: 0

=head2 qc_template_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 software_version

  data_type: 'text'
  is_nullable: 0

=head2 upload_complete

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 36 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "profile",
  { data_type => "text", is_nullable => 0 },
  "qc_template_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "software_version",
  { data_type => "text", is_nullable => 0 },
  "upload_complete",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_alignments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcAlignment>

=cut

__PACKAGE__->has_many(
  "qc_alignments",
  "LIMS2::Model::Schema::Result::QcAlignment",
  { "foreign.qc_run_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_run_seq_projects

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcRunSeqProject>

=cut

__PACKAGE__->has_many(
  "qc_run_seq_projects",
  "LIMS2::Model::Schema::Result::QcRunSeqProject",
  { "foreign.qc_run_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_run_seq_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcRunSeqWell>

=cut

__PACKAGE__->has_many(
  "qc_run_seq_wells",
  "LIMS2::Model::Schema::Result::QcRunSeqWell",
  { "foreign.qc_run_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcTemplate>

=cut

__PACKAGE__->belongs_to(
  "qc_template",
  "LIMS2::Model::Schema::Result::QcTemplate",
  { id => "qc_template_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 qc_template_well_crispr_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellCrisprPrimer>

=cut

__PACKAGE__->has_many(
  "qc_template_well_crispr_primers",
  "LIMS2::Model::Schema::Result::QcTemplateWellCrisprPrimer",
  { "foreign.qc_run_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_well_genotyping_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellGenotypingPrimer>

=cut

__PACKAGE__->has_many(
  "qc_template_well_genotyping_primers",
  "LIMS2::Model::Schema::Result::QcTemplateWellGenotypingPrimer",
  { "foreign.qc_run_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_test_results

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTestResult>

=cut

__PACKAGE__->has_many(
  "qc_test_results",
  "LIMS2::Model::Schema::Result::QcTestResult",
  { "foreign.qc_run_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_seq_projects

Type: many_to_many

Composing rels: L</qc_run_seq_projects> -> qc_seq_project

=cut

__PACKAGE__->many_to_many("qc_seq_projects", "qc_run_seq_projects", "qc_seq_project");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-01-05 12:52:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8sx3uKbG4mH0cl+ftVPF+Q

use List::MoreUtils qw( uniq );

sub as_hash {
    my $self = shift;

    return {
        id               => $self->id,
        created_at       => $self->created_at->iso8601,
        created_by       => $self->created_by->name,
        profile          => $self->profile,
        software_version => $self->software_version,
        qc_template      => $self->qc_template->name,
        sequencing_projects => [ map{ $_->id } $self->qc_seq_projects ],
    };
}

sub count_designs {
    my $self = shift;

    my $qc_template_wells = $self->qc_template->qc_template_wells;
    return 0 unless $qc_template_wells->count;

    my @design_ids;
    foreach my $well ( $qc_template_wells->all ) {
        my $design_id = $well->as_hash->{eng_seq_params}{design_id};
        push @design_ids, $design_id if $design_id;
    }

    return scalar( uniq @design_ids );
}

sub count_observed_designs {
    my $self = shift;

    return $self->_uniq_design_ids_from_test_results(
        $self->search_related_rs(
            qc_test_results => {},
            { prefetch => 'qc_eng_seq', }
        )
    );
}

sub count_valid_designs {
    my $self = shift;

    return $self->_uniq_design_ids_from_test_results(
        $self->search_related_rs(
            qc_test_results => {
                'me.pass' => 1
            },
            {
                prefetch => 'qc_eng_seq',
            }
        )
    );
}

sub _uniq_design_ids_from_test_results {
    my ( $self, $test_results ) = @_;

    return 0 unless $test_results->count;

    my @design_ids;
    foreach my $test_result ( $test_results->all ) {
        my $eng_seq_params = $test_result->qc_eng_seq->as_hash;
        my $design_id = $eng_seq_params->{eng_seq_params}{design_id};
        push @design_ids, $design_id if $design_id;
    }

    return scalar( uniq @design_ids );
}

sub primers {
    my $self = shift;

    my @primers;
    for my $seq_well ( $self->qc_run_seq_wells ) {
        for my $seq_read ( $seq_well->qc_seq_reads ) {
            push @primers, map{ $_->primer_name  } $seq_read->qc_alignments;
        }
    }

    return [ uniq @primers ];
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
