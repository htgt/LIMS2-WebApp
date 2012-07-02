use utf8;
package LIMS2::Model::Schema::Result::Well;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Well

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

=head1 TABLE: C<wells>

=cut

__PACKAGE__->table("wells");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'wells_id_seq'

=head2 plate_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 created_by_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 assay_pending

  data_type: 'timestamp'
  is_nullable: 1

=head2 assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 accepted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "wells_id_seq",
  },
  "plate_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "created_by_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "assay_pending",
  { data_type => "timestamp", is_nullable => 1 },
  "assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "accepted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<wells_plate_id_name_key>

=over 4

=item * L</plate_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("wells_plate_id_name_key", ["plate_id", "name"]);

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

=head2 plate

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "plate",
  "LIMS2::Model::Schema::Result::Plate",
  { id => "plate_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 process_input_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessInputWell>

=cut

__PACKAGE__->has_many(
  "process_input_wells",
  "LIMS2::Model::Schema::Result::ProcessInputWell",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 process_output_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessOutputWell>

=cut

__PACKAGE__->has_many(
  "process_output_wells",
  "LIMS2::Model::Schema::Result::ProcessOutputWell",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_accepted_override

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellAcceptedOverride>

=cut

__PACKAGE__->might_have(
  "well_accepted_override",
  "LIMS2::Model::Schema::Result::WellAcceptedOverride",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_comments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellComment>

=cut

__PACKAGE__->has_many(
  "well_comments",
  "LIMS2::Model::Schema::Result::WellComment",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_dna_quality

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellDnaQuality>

=cut

__PACKAGE__->might_have(
  "well_dna_quality",
  "LIMS2::Model::Schema::Result::WellDnaQuality",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_dna_status

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellDnaStatus>

=cut

__PACKAGE__->might_have(
  "well_dna_status",
  "LIMS2::Model::Schema::Result::WellDnaStatus",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_qc_sequencing_result

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellQcSequencingResult>

=cut

__PACKAGE__->might_have(
  "well_qc_sequencing_result",
  "LIMS2::Model::Schema::Result::WellQcSequencingResult",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_recombineering_results

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellRecombineeringResult>

=cut

__PACKAGE__->has_many(
  "well_recombineering_results",
  "LIMS2::Model::Schema::Result::WellRecombineeringResult",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 input_processes

Type: many_to_many

Composing rels: L</process_input_wells> -> process

=cut

__PACKAGE__->many_to_many("input_processes", "process_input_wells", "process");

=head2 output_processes

Type: many_to_many

Composing rels: L</process_output_wells> -> process

=cut

__PACKAGE__->many_to_many("output_processes", "process_output_wells", "process");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-06-29 14:10:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sGn4iJx9ohRNUty9LjY+Yw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use List::MoreUtils qw( any );

sub is_accepted {
    my $self = shift;

    my $override = $self->well_accepted_override;

    if ( defined $override ) {
        return $override->accepted;
    }
    else {
        return $self->accepted;
    }    
}

use overload '""' => \&as_string;

sub as_string {
    my $self = shift;

    return sprintf( '%s_%s', $self->plate->name, $self->name );    
}

sub as_hash {
    my $self = shift;

    return {
        plate_name     => $self->plate->name,
        plate_type     => $self->plate->type_id,
        well_name      => $self->name,
        created_by     => $self->created_by->name,
        created_at     => $self->created_at->iso8601,
        assay_pending  => $self->assay_pending ? $self->assay_pending->iso8601 : undef,
        assay_complete => $self->assay_complete ? $self->assay_complete->iso8601 : undef,
        accepted       => $self->is_accepted
    };
}

has ancestors => (
    is         => 'ro',
    isa        => 'LIMS2::Model::ProcessGraph',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_ancestors {
    my $self = shift;

    require LIMS2::Model::ProcessGraph;

    return LIMS2::Model::ProcessGraph->new( start_with => $self, type => 'ancestors' );    
}

has descendants => (
    is         => 'ro',
    isa        => 'LIMS2::Model::ProcessGraph',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_descendants {
    my $self = shift;

    require LIMS2::Model::ProcessGraph;

    return LIMS2::Model::ProcessGraph->new( start_with => $self, type => 'descendants' );    
}

sub is_double_targeted {
    my $self = shift;

    my $it = $self->ancestors->breadth_first_traversal( $self, 'in' );    
    while ( my $well = $it->next ) {
        if ( $well->plate->type_id eq 'SEP' ) {            
            return 1;
        }
    }

    return 0;
}

sub assert_not_double_targeted {
    my $self = shift;

    if ( $self->is_double_targeted ) {
        require LIMS2::Exception::Implementation;
        LIMS2::Exception::Implementation->throw(
            "Must specify first or second allele when querying double-targeted construct"
        );
    }

    return;    
}

sub cassette {
    my $self = shift;

    $self->assert_not_double_targeted;
    
    my $process_cassette = $self->ancestors->find_process( $self, 'process_cassette' );

    return $process_cassette ? $process_cassette->cassette : '';
}

sub backbone {
    my $self = shift;

    $self->assert_not_double_targeted;
    
    my $process_backbone = $self->ancestors->find_process( $self, 'process_backbone' );

    return $process_backbone ? $process_backbone->backbone : '';
}

sub recombinases {
    my $self = shift;

    # XXX This assumes no recombinase applied to a cell after 2nd
    # electroporation; we may have to query recombinase application
    # that happened after the 2nd electroporation, in which case we
    # must cut short the traversal at the SEP step rather than
    # throwing an assertion error
    $self->assert_not_double_targeted;

    my $it = $self->ancestors->breadth_first_traversal( $self, 'in' );

    my @recombinases;
    
    while( my $this_well = $it->next ) {
        for my $process ( $self->ancestors->input_processes( $this_well ) ) {
            my @this_recombinase = sort { $a->rank <=> $b->rank } $process->process_recombinases;
            if ( @this_recombinase > 0 ) {
                unshift @recombinases, @this_recombinase;
            }
        }
    }

    return [ map { $_->recombinase_id } @recombinases ];
}

sub design {
    my $self = shift;

    $self->assert_not_double_targeted;

    my $process_design = $self->ancestors->find_process( $self, 'process_design' );

    return $process_design ? $process_design->design : undef;
}

__PACKAGE__->meta->make_immutable;
1;
