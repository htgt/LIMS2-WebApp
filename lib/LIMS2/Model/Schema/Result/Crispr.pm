use utf8;
package LIMS2::Model::Schema::Result::Crispr;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Crispr::VERSION = '0.452';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Crispr

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

=head1 TABLE: C<crisprs>

=cut

__PACKAGE__->table("crisprs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crisprs_id_seq'

=head2 seq

  data_type: 'text'
  is_nullable: 0

=head2 species_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 crispr_loci_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 pam_right

  data_type: 'boolean'
  is_nullable: 1

=head2 wge_crispr_id

  data_type: 'integer'
  is_nullable: 1

=head2 nonsense_crispr_original_crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crisprs_id_seq",
  },
  "seq",
  { data_type => "text", is_nullable => 0 },
  "species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "crispr_loci_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "pam_right",
  { data_type => "boolean", is_nullable => 1 },
  "wge_crispr_id",
  { data_type => "integer", is_nullable => 1 },
  "nonsense_crispr_original_crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<crisprs_wge_crispr_id_key>

=over 4

=item * L</wge_crispr_id>

=back

=cut

__PACKAGE__->add_unique_constraint("crisprs_wge_crispr_id_key", ["wge_crispr_id"]);

=head1 RELATIONS

=head2 crispr_group_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprGroupCrispr>

=cut

__PACKAGE__->has_many(
  "crispr_group_crisprs",
  "LIMS2::Model::Schema::Result::CrisprGroupCrispr",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_loci_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprLociType>

=cut

__PACKAGE__->belongs_to(
  "crispr_loci_type",
  "LIMS2::Model::Schema::Result::CrisprLociType",
  { id => "crispr_loci_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 crispr_pairs_left_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPair>

=cut

__PACKAGE__->has_many(
  "crispr_pairs_left_crisprs",
  "LIMS2::Model::Schema::Result::CrisprPair",
  { "foreign.left_crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_pairs_right_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPair>

=cut

__PACKAGE__->has_many(
  "crispr_pairs_right_crisprs",
  "LIMS2::Model::Schema::Result::CrisprPair",
  { "foreign.right_crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_primers

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimer>

=cut

__PACKAGE__->has_many(
  "crispr_primers",
  "LIMS2::Model::Schema::Result::CrisprPrimer",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_validations

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprValidation>

=cut

__PACKAGE__->has_many(
  "crispr_validations",
  "LIMS2::Model::Schema::Result::CrisprValidation",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 experiments_including_deleted

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Experiment>

=cut

__PACKAGE__->has_many(
  "experiments_including_deleted",
  "LIMS2::Model::Schema::Result::Experiment",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 loci

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprLocus>

=cut

__PACKAGE__->has_many(
  "loci",
  "LIMS2::Model::Schema::Result::CrisprLocus",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nonsense_crispr_original_crispr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Crispr>

=cut

__PACKAGE__->belongs_to(
  "nonsense_crispr_original_crispr",
  "LIMS2::Model::Schema::Result::Crispr",
  { id => "nonsense_crispr_original_crispr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 nonsense_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Crispr>

=cut

__PACKAGE__->has_many(
  "nonsense_crisprs",
  "LIMS2::Model::Schema::Result::Crispr",
  { "foreign.nonsense_crispr_original_crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nonsense_designs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Design>

=cut

__PACKAGE__->has_many(
  "nonsense_designs",
  "LIMS2::Model::Schema::Result::Design",
  { "foreign.nonsense_design_crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 off_target_crispr_for

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprOffTargets>

=cut

__PACKAGE__->has_many(
  "off_target_crispr_for",
  "LIMS2::Model::Schema::Result::CrisprOffTargets",
  { "foreign.off_target_crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 off_target_summaries

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprOffTargetSummary>

=cut

__PACKAGE__->has_many(
  "off_target_summaries",
  "LIMS2::Model::Schema::Result::CrisprOffTargetSummary",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 off_targets

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprOffTargets>

=cut

__PACKAGE__->has_many(
  "off_targets",
  "LIMS2::Model::Schema::Result::CrisprOffTargets",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessCrispr>

=cut

__PACKAGE__->has_many(
  "process_crisprs",
  "LIMS2::Model::Schema::Result::ProcessCrispr",
  { "foreign.crispr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 species

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "species",
  "LIMS2::Model::Schema::Result::Species",
  { id => "species_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-02-22 11:13:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uJN4fU8zwjPTSPud+ljxDg

__PACKAGE__->many_to_many("crispr_groups" => "crispr_group_crisprs", "crispr_group");

__PACKAGE__->has_many(
  "experiments",
  "LIMS2::Model::Schema::Result::Experiment",
  { "foreign.crispr_id" => "self.id" },
  { where => { "deleted" => 0 } },
);

# crispr_designs table merged into experiments table
sub crispr_designs{
    return shift->experiments;
}

use Bio::Perl qw( revcom );

use overload '""' => \&as_string;

sub as_string {
    return shift->id;
}

sub as_hash {
    my ( $self, $options ) = @_;

    my $locus;
    if ( my $default_assembly = $self->species->default_assembly ) {
        $locus = $self->search_related( 'loci', { assembly_id => $default_assembly->assembly_id } )->first;
    }

    my %h = (
        id             => $self->id,
        type           => $self->crispr_loci_type_id,
        seq            => $self->seq,
        fwd_seq        => $self->fwd_seq,
        species        => $self->species_id,
        comment        => $self->comment,
        locus          => $locus ? $locus->as_hash : undef,
        pam_right      => !defined $self->pam_right ? '' : $self->pam_right == 1 ? 'true' : 'false',
        wge_crispr_id  => $self->wge_crispr_id,
        crispr_primers => [ map { $_->as_hash } $self->crispr_primers ],
        nonsense_crispr_original_crispr_id => $self->nonsense_crispr_original_crispr_id,
        # pairs          => $self->pair_ids,
        # groups         => $self->group_ids,
        experiments    => $self->experiment_ids,
    );

    if ( !$options->{no_off_targets} ) {
        $h{off_targets} = [ sort { $a->{mismatches} <=> $b->{mismatches} } map { $_->as_hash } $self->off_targets ];
    }
    $h{off_target_summaries} = [ map { $_->as_hash } $self->off_target_summaries ];

    return \%h;
}

sub fwd_seq {
    my $self = shift;
    my $fwd_seq = !$self->pam_right ? revcom( $self->seq )->seq : $self->seq;
    return $fwd_seq;
}

sub current_locus {
    my $self = shift;

    my $loci = $self->result_source->schema->resultset('CrisprLocus')->find(
        {
            'me.crispr_id'                          => $self->id,
            'species_default_assemblies.species_id' => $self->species_id
        },
        {
            join => {
                assembly => 'species_default_assemblies'
            }
        }
    );

    return $loci;
}

sub start {
    return shift->current_locus->chr_start;
}

sub end {
    return shift->current_locus->chr_end;
}

sub chr_id {
    return shift->current_locus->chr_id;
}

sub chr_name {
    return shift->current_locus->chr->name;
}

sub default_assembly{
    return shift->species->default_assembly;
}

# The name of the foreign key column to use when
# linking e.g. a crispr_primer to a crispr
sub id_column_name{
    return 'crispr_id';
}

sub target_slice {
    my ( $self, $ensembl_util ) = @_;

    unless ( $ensembl_util ) {
        require WebAppCommon::Util::EnsEMBL;
        $ensembl_util = WebAppCommon::Util::EnsEMBL->new( species => $self->species_id );
    }

    my $slice = $ensembl_util->slice_adaptor->fetch_by_region(
        'chromosome',
        $self->chr_name,
        $self->start,
        $self->end
    );

    return $slice;
}

#
# Methods for U6 specific order sequences
#
sub guide_rna {
    my ( $self, $appends ) = @_;

    WARN ( "No appends type provided for guide_rna, defaulting to u6" ) unless $appends;

    if ($appends eq 't7-barry') {

        if ( ! defined $self->pam_right ) {
            return substr( $self->seq, 0, 20 );
        }
        elsif ( $self->pam_right == 1 ) {
            return substr( $self->seq, 0, 20 );
        }
        elsif ( $self->pam_right == 0 ) {
            #its pam left, so strip first three characters
            #we revcom so that the grna is always relative to the NGG sequence
            return revcom( substr( $self->seq, 3, 20 ) )->seq;
        }
        else {
            die "Unexpected value in pam_right: " . $self->pam_right;
        }

    } else {

        if ( ! defined $self->pam_right ) {
            return substr( $self->seq, 1, 19 );
        }
        elsif ( $self->pam_right == 1 ) {
            return substr( $self->seq, 1, 19 );
        }
        elsif ( $self->pam_right == 0 ) {
            #its pam left, so strip first three characters and the very last one,
            #we revcom so that the grna is always relative to the NGG sequence
            return revcom( substr( $self->seq, 3, 19 ) )->seq;
        }
        else {
            die "Unexpected value in pam_right: " . $self->pam_right;
        }

    }

}

sub forward_order_seq {
    my ( $self, $appends ) = @_;

    WARN ( "No appends type provided for forward_order_seq, defaulting to u6" ) unless $appends;

    if ($appends eq 't7-barry' || $appends eq 't7-wendy' ) {

        return "ATAGG" . $self->guide_rna($appends);

    } else {

        return  "ACCG" . $self->guide_rna($appends);
    }

}

sub reverse_order_seq {
    my ( $self, $appends ) = @_;

    WARN ( "No appends type provided for reverse_order_seq, defaulting to u6" ) unless $appends;

    if ($appends eq 't7-barry' || $appends eq 't7-wendy' ) {

        return "AAAC" . revcom( $self->guide_rna($appends) )->seq . "C";

    } else {

        return "AAAC" . revcom( $self->guide_rna($appends) )->seq;
    }

}

#we need to add the G here so its the full forward grna
sub vector_seq {
    my ( $self, $appends ) = @_;

    WARN ( "No appends type provided for vector_seq, defaulting to u6" ) unless $appends;

    return  "G" . $self->guide_rna($appends);
}


sub pairs {
  my $self = shift;

  return ($self->pam_right) ? $self->crispr_pairs_right_crisprs : $self->crispr_pairs_left_crisprs;
}


sub pair_ids {
    my $self = shift;

    my $schema = $self->result_source->schema;
    my @crispr_pairs = $schema->resultset('CrisprPair')->search(
        {
            -or => [
                'left_crispr_id'  => $self->id,
                'right_crispr_id' => $self->id,
            ]
        },
        {
            distinct => 1,
        }
    );

    my @pair_ids;
    foreach my $pair ( @crispr_pairs ) {
        push @pair_ids, $pair->id;
    }

    return \@pair_ids;
}

sub group_ids {
    my $self = shift;

    my @group_ids;
    foreach my $group ( $self->crispr_groups->all ) {
        push @group_ids, $group->id;
    }

    return \@group_ids;
}

sub experiment_ids {
    my $self = shift;

    my $schema = $self->result_source->schema;

    my $pair_ids = $self->pair_ids;

    my $group_ids = $self->group_ids;

    my @experiments = $schema->resultset('Experiment')->search(
        {
            -or => [
                'crispr_id'       => $self->id,
                'crispr_pair_id'  => { '-in' => $pair_ids },
                'crispr_group_id' => { '-in' => $group_ids },
            ]
        },
        {
            distinct => 1,
        }
    );

    my @experiment_ids;
    foreach my $experiment ( @experiments ) {
        push @experiment_ids, $experiment->id;
    }

    return \@experiment_ids;
}



# Designs may be linked to single crispr directly or to crispr pair
sub related_designs {
    my $self = shift;

    my @designs;
    foreach my $crispr_design ( $self->crispr_designs->all ) {
        my $design = $crispr_design->design;
        push @designs, $design;
    }

    foreach my $nonsense_design ( $self->nonsense_designs->all ) {
        push @designs, $nonsense_design;
    }

    foreach my $pair ( $self->crispr_pairs_left_crisprs->all, $self->crispr_pairs_right_crisprs->all ) {
        foreach my $pair_crispr_design ( $pair->crispr_designs->all ) {
            my $pair_design = $pair_crispr_design->design;
            push @designs, $pair_design;
        }
    }

    foreach my $group ( $self->crispr_groups->all ) {
        foreach my $group_design ( $group->crispr_designs ) {
            my $crispr_group_design = $group_design->design;
            push @designs, $crispr_group_design unless !defined($crispr_group_design);
        }
    }

    return @designs;
}

sub crispr_wells{
    my $self = shift;

    return map { $_->process->output_wells } $self->process_crisprs;
}

sub vector_wells{
    my $self = shift;

    my @wells = $self->crispr_wells;

    return map { $_->descendant_crispr_vectors } @wells;
}

sub accepted_vector_wells{
    my $self = shift;

    # Assume we are only interested in vectors on the most recently created crispr_v plate
    my @accepted_wells;
    my $most_recent_plate;
    foreach my $well ($self->vector_wells){

        next unless $well->is_accepted;

        push @accepted_wells, $well;

        my $plate = $well->plate;
        $most_recent_plate ||= $plate;
        if ($plate->created_at > $most_recent_plate->created_at){
            $most_recent_plate = $plate;
        }
    }

    return grep { $_->plate_id == $most_recent_plate->id } @accepted_wells;
}

sub is_pair { return; }

sub is_group { return; }

sub is_nonsense_crispr {
    my $self = shift;
    return $self->nonsense_crispr_original_crispr_id ? 1 : 0;
}

sub linked_nonsense_crisprs {
    my $self = shift;
    my $schema = $self->result_source->schema;

    my @nonsense_crisprs = $schema->resultset('Crispr')->search(
        {
            nonsense_crispr_original_crispr_id => $self->id,
        }
    );

    return \@nonsense_crisprs;
}

sub current_primer{
    my ( $self, $primer_type ) = @_;

    unless($primer_type){
        require LIMS2::Exception::Implementation;
        LIMS2::Exception::Implementation->throw( "You must provide a primer_type to the current_primer method" );
    }

    my @primers = $self->search_related('crispr_primers', { primer_name => $primer_type });

    # FIXME: what if more than 1?
    my ($current_primer) = grep { ! $_->is_rejected } @primers;
    return $current_primer;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
