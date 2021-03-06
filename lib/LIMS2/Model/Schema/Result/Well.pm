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
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

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

=head2 accepted_rules_version

  data_type: 'text'
  is_nullable: 1

=head2 to_report

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 barcode

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 barcode_state

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

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
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
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
  "accepted_rules_version",
  { data_type => "text", is_nullable => 1 },
  "to_report",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "barcode",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "barcode_state",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<wells_barcode_key>

=over 4

=item * L</barcode>

=back

=cut

__PACKAGE__->add_unique_constraint("wells_barcode_key", ["barcode"]);

=head2 C<wells_plate_id_name_key>

=over 4

=item * L</plate_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("wells_plate_id_name_key", ["plate_id", "name"]);

=head1 RELATIONS

=head2 barcode_events

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BarcodeEvent>

=cut

__PACKAGE__->has_many(
  "barcode_events",
  "LIMS2::Model::Schema::Result::BarcodeEvent",
  { "foreign.barcode" => "self.barcode" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 barcode_state

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::BarcodeState>

=cut

__PACKAGE__->belongs_to(
  "barcode_state",
  "LIMS2::Model::Schema::Result::BarcodeState",
  { id => "barcode_state" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 cell_line_internals

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CellLineInternal>

=cut

__PACKAGE__->has_many(
  "cell_line_internals",
  "LIMS2::Model::Schema::Result::CellLineInternal",
  { "foreign.origin_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 crispr_es_qc_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprEsQcWell>

=cut

__PACKAGE__->has_many(
  "crispr_es_qc_wells",
  "LIMS2::Model::Schema::Result::CrisprEsQcWell",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fp_picking_list_well_barcodes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::FpPickingListWellBarcode>

=cut

__PACKAGE__->has_many(
  "fp_picking_list_well_barcodes",
  "LIMS2::Model::Schema::Result::FpPickingListWellBarcode",
  { "foreign.well_barcode" => "self.barcode" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 miseq_well_experiments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::MiseqWellExperiment>

=cut

__PACKAGE__->has_many(
  "miseq_well_experiments",
  "LIMS2::Model::Schema::Result::MiseqWellExperiment",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plate

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "plate",
  "LIMS2::Model::Schema::Result::Plate",
  { id => "plate_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
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

=head2 qc_template_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWell>

=cut

__PACKAGE__->has_many(
  "qc_template_wells",
  "LIMS2::Model::Schema::Result::QcTemplateWell",
  { "foreign.source_well_id" => "self.id" },
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

=head2 well_assembly_qcs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellAssemblyQc>

=cut

__PACKAGE__->has_many(
  "well_assembly_qcs",
  "LIMS2::Model::Schema::Result::WellAssemblyQc",
  { "foreign.assembly_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_chromosome_fail

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellChromosomeFail>

=cut

__PACKAGE__->might_have(
  "well_chromosome_fail",
  "LIMS2::Model::Schema::Result::WellChromosomeFail",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_colony_counts

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellColonyCount>

=cut

__PACKAGE__->has_many(
  "well_colony_counts",
  "LIMS2::Model::Schema::Result::WellColonyCount",
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

=head2 well_genotyping_results

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellGenotypingResult>

=cut

__PACKAGE__->has_many(
  "well_genotyping_results",
  "LIMS2::Model::Schema::Result::WellGenotypingResult",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_het_status

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellHetStatus>

=cut

__PACKAGE__->might_have(
  "well_het_status",
  "LIMS2::Model::Schema::Result::WellHetStatus",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_lab_number

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellLabNumber>

=cut

__PACKAGE__->might_have(
  "well_lab_number",
  "LIMS2::Model::Schema::Result::WellLabNumber",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_primer_bands

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellPrimerBand>

=cut

__PACKAGE__->has_many(
  "well_primer_bands",
  "LIMS2::Model::Schema::Result::WellPrimerBand",
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

=head2 well_t7

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellT7>

=cut

__PACKAGE__->might_have(
  "well_t7",
  "LIMS2::Model::Schema::Result::WellT7",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_targeting_neo_pass

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellTargetingNeoPass>

=cut

__PACKAGE__->might_have(
  "well_targeting_neo_pass",
  "LIMS2::Model::Schema::Result::WellTargetingNeoPass",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_targeting_pass

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellTargetingPass>

=cut

__PACKAGE__->might_have(
  "well_targeting_pass",
  "LIMS2::Model::Schema::Result::WellTargetingPass",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_targeting_puro_pass

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellTargetingPuroPass>

=cut

__PACKAGE__->might_have(
  "well_targeting_puro_pass",
  "LIMS2::Model::Schema::Result::WellTargetingPuroPass",
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OSwhIiXVAMlK7KZZJ54EMA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use List::MoreUtils qw( any uniq );

use Try::Tiny;

use Log::Log4perl qw(:easy);
BEGIN {
    #try not to override the lims2 logger
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->easy_init( { level => $DEBUG } );
    }
}

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

    my $name;
    if($self->plate){
        $name = sprintf( '%s_%s', $self->plate->name, $self->well_name );

        if($self->plate->version){
            $name = sprintf( '%s(v%s)_%s', $self->plate->name, $self->plate->version, $self->name);
        }
    }
    else{
        $name = 'Barcode:'.$self->barcode.'('.$self->barcode_state->id.')';
    }
    return $name;
}

sub as_hash {
    my $self = shift;

    return {
        id             => $self->id,
        plate_name     => $self->plate_name,
        plate_type     => $self->plate_type,
        well_name      => $self->well_name,
        created_by     => $self->created_by->name,
        created_at     => $self->created_at->iso8601,
        assay_pending  => $self->assay_pending ? $self->assay_pending->iso8601 : undef,
        assay_complete => $self->assay_complete ? $self->assay_complete->iso8601 : undef,
        accepted       => $self->is_accepted,
        barcode        => $self->barcode,
        barcode_state  => ( $self->barcode_state ? $self->barcode_state->id : undef ),
        last_known_location => $self->last_known_location_str,
    };
}

sub plate_id {
    my $self = shift;
    return $self->plate ? $self->plate->id : undef;
}

sub plate_name {
    my $self = shift;
    return $self->plate ? $self->plate->name : '';
}

sub well_name {
    my $self = shift;
    return $self->name // '';
}

sub well_id {
    my $self = shift;
    return $self->id // '';
}

sub plate_type{
    my $self = shift;
    return $self->last_known_plate->type_id;
}

sub plate_species{
    my $self = shift;
    return $self->last_known_plate->species;
}

sub plate_sponsor{
    my $self = shift;
    return $self->last_known_plate->sponsor_id;
}

has ancestors => (
    is         => 'rw',
    isa        => 'LIMS2::Model::ProcessGraph',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_ancestors {
    my $self = shift;
    DEBUG "Building ancestors for well $self";
    require LIMS2::Model::ProcessGraph;

    return LIMS2::Model::ProcessGraph->new( start_with => $self, type => 'ancestors' );
}

# Use this to set the well's ancestors using results of a batch ancestor query
sub set_ancestors{
    my ($self, $edges) = @_;

    my $graph = LIMS2::Model::ProcessGraph->new(
      start_with => $self,
      type => 'ancestors',
      edges => $edges
    );

    $self->ancestors($graph);
    return;
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

has is_double_targeted => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1
);

sub _build_is_double_targeted {
    my $self = shift;

    my $it = $self->ancestors->breadth_first_traversal( $self, 'in' );
    while ( my $well = $it->next ) {
        if ( $well->plate_type eq 'SEP' ) {
            return 1;
        }
        if( $well->plate_type eq 'CRISPR_SEP'){
            return 1;
        }
    }

    return 0;
}

has first_allele => (
    is => 'ro',
    isa => 'LIMS2::Model::Schema::Result::Well',
    lazy_build => 1,
);

## no critic(RequireFinalReturn)
sub _build_first_allele {
    my $self = shift;

    for my $input ( $self->second_electroporation_process->input_wells ) {
        if ( $input->plate_type eq 'XEP' ) {
            return $input;
        }
        if ( $input->plate_type eq 'PIQ' ){
            return $input;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw(
        "Failed to determine first allele for $self"
    );
}
## use critic

has second_allele => (
    is => 'ro',
    isa => 'LIMS2::Model::Schema::Result::Well',
    lazy_build => 1,
);

## no critic(RequireFinalReturn)
sub _build_second_allele {
    my $self = shift;

    for my $input ( $self->second_electroporation_process->input_wells ) {
        if ( $input->plate_type eq 'DNA' ) {
            return $input;
        }
        if( $input->plate_type eq 'ASSEMBLY'){
            return $input;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw(
        "Failed to determine second allele for $self"
    );
}
## use critic

sub last_known_plate{
    my $self = shift;

    my $plate = $self->plate;
    unless($plate){
        # Well no longer on a plate so fetch last related
        # plate from the barcode_events table
        $plate = $self->last_known_location_event->old_plate;
    }
    return $plate;
}

sub last_known_well_name{
    my $self = shift;

    my $well_name = $self->name;
    unless($well_name){
        # Well no longer on a plate so fetch last related
        # plate from the barcode_events table
        $well_name = $self->last_known_location_event->old_well_name;
    }
    return $well_name;
}

sub last_known_location_str{
    my $self = shift;

    if(my $event = $self->last_known_location_event){
        return sprintf( '%s_%s', $event->old_plate->name, $event->old_well_name );
    }
    return '';
}

sub last_known_location_event{
    my $self = shift;
    my $event;
    if($self->barcode){
        ($event) = $self->search_related('barcode_events',
            {
                old_plate_id => { '!=' => undef },
                new_plate_id => undef,
            },
            {
                order_by => { -desc => [qw/created_at id/] }
            }
        );
    }
    return $event;
}

# if this well has a global arm shortened design then
# populate this attribute, otherwise it is undef
has global_arm_shortened_design => (
    is         => 'ro',
    isa        => 'Maybe[LIMS2::Model::Schema::Result::Design]',
    lazy_build => 1
);

sub _build_global_arm_shortened_design {
    my $self = shift;

    my $process_arm_shortening = $self->ancestors->find_process( $self, 'process_global_arm_shortening_design' );
    if ( $process_arm_shortening ) {
        return $process_arm_shortening->design;
    }

    return;
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

sub recombineering_result {
    my ( $self, $result_type ) = @_;

    my $rec_result = $self->well_recombineering_results_rs->find( { result_type_id => $result_type } )
        or return;

    return $rec_result;
}

sub recombineering_results_string{
    my ( $self ) = @_;

    my @results = $self->well_recombineering_results_rs->search(
        undef,
        { order_by => { '-asc', 'result_type_id '} }
    )->all;

    my @strings = map { $_->result_type_id.":".$_->result } @results;
    my $string = join ", ",@strings;
    DEBUG("recombineering results string: $string");
    return $string;
}

sub cassette {
    my $self = shift;

    $self->assert_not_double_targeted;

    my $process_cassette = $self->ancestors->find_process( $self, 'process_cassette' );

    return $process_cassette ? $process_cassette->cassette : undef;
}

sub backbone {
    my ( $self, $args ) = @_;

    $self->assert_not_double_targeted;

    my $process_backbone = $self->ancestors->find_process( $self, 'process_backbone', $args );

    return $process_backbone ? $process_backbone->backbone : undef;
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

# fetches any recombinases at vector levels
sub vector_recombinases {
    my $self = shift;

    my $it = $self->ancestors->breadth_first_traversal( $self, 'in' );

    my @list_of_plate_types = ( "DESIGN", "INT", "POSTINT", "FINAL", "FINAL_PICK", "CREBAC", "DNA" );

    my @vector_recombinases;

    while( my $this_well = $it->next ) {
        # check plate type
        my $this_well_plate_type = $this_well->plate_type;
        #my $match_found = any { $this_well_plate_type } @list_of_plate_types;
        if ( grep {$_ eq $this_well_plate_type} @list_of_plate_types ) {
            for my $process ( $self->ancestors->input_processes( $this_well ) ) {
                my @this_well_recombinases = sort { $a->rank <=> $b->rank } $process->process_recombinases;
                if ( @this_well_recombinases > 0 ) {
                    unshift @vector_recombinases, @this_well_recombinases;
                }
            }
        }
    }

    return [ map { $_->recombinase_id } @vector_recombinases ];
}

# fetches any recombinases at cell levels
sub cell_recombinases {
    my $self = shift;

    my $it = $self->ancestors->breadth_first_traversal( $self, 'in' );

    my @list_of_plate_types = ( "EP", "EP_PICK", "XEP", "XEP_PICK", "XEP_POOL", "SEP", "SEP_PICK", "SEP_POOL", "FP", "SFP", "PIQ");

    my @cell_recombinases;

    while( my $this_well = $it->next ) {
        # check plate type
        my $this_well_plate_type = $this_well->plate_type;
        #my $match_found = any { $this_well_plate_type } @list_of_plate_types;
        if ( grep {$_ eq $this_well_plate_type} @list_of_plate_types ) {
            for my $process ( $self->ancestors->input_processes( $this_well ) ) {
                my @this_well_recombinases = sort { $a->rank <=> $b->rank } $process->process_recombinases;
                if ( @this_well_recombinases > 0 ) {
                    unshift @cell_recombinases, @this_well_recombinases;
                }
            }
        }
    }

    return [ map { $_->recombinase_id } @cell_recombinases ];
}

# fetches first cell line
sub first_cell_line {
    my $self = shift;

    my $electroporation = $self->ancestors->find_process( $self, 'process_cell_line' );

    return $electroporation ? $electroporation->cell_line : undef;
}

# fetches second cell line
sub second_cell_line {
    my $self = shift;

    my $electroporation = $self->second_electroporation_process;

    return $electroporation ? $electroporation->process_cell_line : undef;
}

sub design {
    my $self = shift;

    $self->assert_not_double_targeted;

    # If the well has a global_arm_shortening_design process then its real
    # design is linked to this process, it is not the root design well
    if ( $self->global_arm_shortened_design ) {
        return $self->global_arm_shortened_design;
    }

    my $process_design = $self->ancestors->find_process( $self, 'process_design' );

    return $process_design ? $process_design->design : undef;
}

sub nuclease {
    my $self = shift;

    my $process_nuclease = $self->ancestors->find_process( $self, 'process_nuclease');

    return $process_nuclease ? $process_nuclease->nuclease : undef;
}

sub designs {
	my $self = shift;

    # if its not double targeted then there is only one design
    if ( !$self->is_double_targeted ) {
        return ( $self->design );
    }

    # ok its double targeted, grab design from the first and second allele wells
	  my @designs;
    push @designs, $self->first_allele->design;
    push @designs, $self->second_allele->design;

    return @designs;
}

sub parent_processes{
	my $self = shift;
	# Fetch processes of which this well is an output
	my @parent_processes = map { $_->process } $self->process_output_wells->all;

	return @parent_processes;
}

sub parent_wells {
    my $self = shift;

    my @parent_processes = $self->parent_processes;

    return map{ $_->input_wells } @parent_processes;
}

sub child_processes{
    my $self = shift;

	# Fetch processes of which this well is an input
	my @child_processes = map { $_->process } $self->process_input_wells->all;

	return @child_processes;
}


sub child_wells {
    my $self = shift;

    my @child_processes = $self->child_processes;

    return map{ $_->output_wells } @child_processes;
}

sub child_wells_skip_versioned_plates{
    my $self = shift;

    DEBUG "Finding real child wells of $self";

    my @real_child_wells;

    my @child_wells = $self->child_wells;
    foreach my $well (@child_wells){
        if($well->plate and $well->plate->version){
            push @real_child_wells, $well->child_wells_skip_versioned_plates;
        }
        else{
            push @real_child_wells, $well;
        }
    }
    return @real_child_wells;
}

sub sibling_wells{
    my ($self) = @_;

    # Includes "half-siblings", i.e. those that share any parent
    # with the parents of the current well
    my @parent_wells = $self->parent_wells;
    my @siblings = map { $_->child_wells } @parent_wells;

    my @siblings_not_self = grep { $_->id != $self->id } @siblings;
    return @siblings_not_self;
}

has second_electroporation_process => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::Process',
    lazy_build => 1
);

## no critic(RequireFinalReturn)
sub _build_second_electroporation_process {
    my $self = shift;

    my $it = $self->ancestors->breadth_first_traversal( $self, 'in' );
    while ( my $well = $it->next ) {
        for my $process ( $self->ancestors->input_processes( $well ) ) {
            if ( $process->type_id eq 'second_electroporation' ) {
                return $process;
            }
            if( $process->type_id eq 'crispr_sep' ){
                return $process;
            }
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw(
        "Cannot request second_electroporation_process for single-targeted construct"
    );
}
## use critic

## no critic(RequireFinalReturn)
sub final_vector {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if (  $ancestor->plate_type eq 'FINAL' || $ancestor->plate_type eq 'FINAL_PICK' ) {
            return $ancestor;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine final vector for $self" );
}
## use critic

## no critic(RequireFinalReturn)
sub first_dna {
    my $self = shift;

    if ( $self->is_double_targeted ) {
        my $first_ep = $self->first_ep;
        return $first_ep->first_dna;
    }
    else {
        my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
        while( my $ancestor = $ancestors->next ) {
            if ( $ancestor->plate_type eq 'DNA' ) {
                return $ancestor;
            }
        }
    }


    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine first dna for $self" );
}
## use critic

## no critic(RequireFinalReturn)
sub second_dna {
    my $self = shift;

    for my $input ( $self->second_electroporation_process->input_wells ) {
        if ( $input->plate_type eq 'DNA' ) {
            return $input;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw(
        "Failed to determine second allele for $self"
    );

}
## use critic

## no critic(RequireFinalReturn)
sub first_ep {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate_type eq 'EP' ) {
            return $ancestor;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine first electroporation plate/well for $self" );
}
## use critic

## no critic(RequireFinalReturn)
sub first_ep_pick {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate_type eq 'EP_PICK' ) {
            return $ancestor;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine first electroporation pick plate/well for $self" );
}
## use critic

#Check if well is currently of type X, if not - ascend
sub is_plate_type_or_later {
    my ($self, $plate_type) = @_;

    return $self if $self->plate_type eq $plate_type;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while ( my $ancestor = $ancestors->next ) {
        return $ancestor if $ancestor->plate_type eq $plate_type;
    }

    return;
}

# return the first parent well that has crispr es QC linked to it
sub first_parent_with_crispr_qc{
    my $self = shift;

    return $self if $self->crispr_es_qc_wells->count;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while ( my $ancestor = $ancestors->next ) {
        return $ancestor if $ancestor->crispr_es_qc_wells->count;
    }
    return;
}

## no critic(RequireFinalReturn)
sub second_ep {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate_type eq 'SEP' ) {
            return $ancestor;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine second electroporation plate/well for $self" );
}
## use critic

sub get_input_wells_as_string {
    my $well = shift;

	my $parents;

    foreach my $process ($well->parent_processes){
        foreach my $input ($process->input_wells){
	    		my $plate_name = $input->plate_name;
                my $well_name = $input->name;
                my $specification = $plate_name . '[' . $well_name . ']';
                $parents = !$parents ? $specification : join q{ }, ( $parents, $specification );
        }
    }
    return ( $parents );
}

sub get_output_wells_as_string {
    my $well = shift;

    my $children;

    foreach my $process ($well->child_processes){
        foreach my $output ($process->output_wells){
          my $plate_name = $output->plate_name;
                my $well_name = $output->name;
                my $specification = $plate_name . '[' . $well_name . ']';
                $children = !$children ? $specification : join q{ }, ( $children, $specification );
        }
    }
    return ( $children );
}

## no critic(RequireFinalReturn)
sub second_ep_pick {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate_type eq 'SEP_PICK' ) {
            return $ancestor;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine second electroporation pick plate/well for $self" );
}
## use critic

## no critic(RequireFinalReturn)
sub freezer_instance {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate_type eq 'SFP' ||  $ancestor->plate_type eq 'FP' ) {
            return $ancestor;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine freezer plate/well for $self" );
}
## use critic

## no critic(RequireFinalReturn)
sub descendant_piq {
    my $self = shift;

    my $descendants = $self->descendants->depth_first_traversal( $self, 'out' );
    if ( defined $descendants ) {
  		while( my $descendant = $descendants->next ) {
  			if ( $descendant->plate_type eq 'PIQ' ) {
  				return $descendant;
  			}
  		}
    }
    return;
}
## use critic

## no critic(RequireFinalReturn)
sub ancestor_piq {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    if ( defined $ancestors ) {
      $ancestors->next;
      while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate_type eq 'PIQ' ) {
          return $ancestor;
        }
      }
    }
    return;
}
## use critic

sub barcoded_descendant_of_type{
    my ($self, $type) = @_;

    my $descendants = $self->descendants->depth_first_traversal( $self, 'out' );
    if ( defined $descendants ){
      while( my $descendant = $descendants->next ){
        if( ($descendant->plate_type eq $type) and $descendant->barcode ){
          return $descendant;
        }
      }
    }
    return;
}

sub barcoded_descendants{
    my ($self) = @_;
    my @barcoded_descendants;
    my $descendants = $self->descendants->depth_first_traversal( $self, 'out' );
    if ( defined $descendants ){
      while( my $descendant = $descendants->next ){
        if( $descendant->barcode ){
          push @barcoded_descendants, $descendant;
        }
      }
    }
    return @barcoded_descendants;
}
sub descendant_crispr_vectors {
    my $self = shift;

    return $self->descendants_of_type('CRISPR_V');
}

# Returns array of all descendant wells of the requested type
sub descendants_of_type{
    my ($self, $type) = @_;

    die "No type specified" unless $type;

    my @results;
    my $descendants = $self->descendants->depth_first_traversal( $self, 'out' );
    if ( defined $descendants ) {
      while( my $descendant = $descendants->next ) {
        if ( $descendant->plate_type eq $type ) {
          push @results, $descendant;
        }
      }
    }
    return @results;
}

=head2 parent_crispr_wells

Return array of all the parent CRISPR wells.

=cut
sub parent_crispr_wells {
    my $self = shift;

    my @crisprs;
    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    if ( defined $ancestors ) {
      while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate_type eq 'CRISPR' ) {
          push @crisprs, $ancestor;
        }
      }
    }
    return @crisprs;
}

=head2 parent_crispr_vectors

This returns the final set of CRISPR_V parent wells
It will stop traversing if it hits a CRISPR_V grandparent,
i.e. if CRISPR_V plates have been rearrayed

=cut
## no critic(RequireFinalReturn)
sub parent_crispr_vectors {
    my $self = shift;

    my @parents;
    my $ancestors = $self->ancestors->breadth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate_type eq 'CRISPR_V' ) {

            # Ignore CRISPR_V well if it does not have any DNA child wells..
            if ( grep { $_->plate_type eq 'DNA' } $self->ancestors->output_wells($ancestor) ) {
                push ( @parents, $ancestor );
            }
        }
    }

    if (scalar @parents) {
      return @parents;
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine crispr vector plate/well for $self" );
}
## use critic

sub parent_assembly_well{
    my $self = shift;
    if ( $self->plate_type eq 'ASSEMBLY' || $self->plate_type eq 'OLIGO_ASSEMBLY' ) {
        return $self;
    }
    else{
        my $ancestors = $self->ancestors->breadth_first_traversal( $self, 'in' );
        while( my $ancestor = $ancestors->next ) {
            if (   $ancestor->plate_type eq 'ASSEMBLY'
                || $ancestor->plate_type eq 'OLIGO_ASSEMBLY' )
            {
                return $ancestor;
            }
        }
    }
    return;
}

sub parent_assembly_process_type{
    my $self = shift;

    if (my $assembly_well = $self->parent_assembly_well){
        my ($process) = $assembly_well->parent_processes;
        return $process->type_id;
    }
    return;
}

=head2 crispr_entity

Return any crispr entity ( crispr, crispr pair or crispr group ) linked to the well.
Method takes a list of crisprs linked to the well and trys to work out what type of
crispr entity we have.

NOTE: There is a small chance we can have a crispr group and crispr pair that are identical,
in these cases the crispr pair will be returned.

=cut
sub crispr_entity {
    my ( $self ) = @_;
    use LIMS2::Model::Util::Crisprs qw( get_crispr_group_by_crispr_ids );
    use Try::Tiny;

    my @crisprs = $self->crisprs;
    my $num_crisprs = scalar( @crisprs );

    my $crispr_entity;
    if ( $num_crisprs == 1 ) {
        $crispr_entity = $crisprs[0];
    }
    elsif ( $num_crisprs > 2 ) {
        try{
            $crispr_entity = get_crispr_group_by_crispr_ids(
                $self->result_source->schema,
                { crispr_ids => [ map{ $_->id } @crisprs ] },
            );
        }
        catch{
            ERROR( "Unable to find crispr group: $_" );
        };
    }
    elsif ( $num_crisprs == 2 ) {
        # if one crispr left and the other right then search for crispr pair
        my ( $right_crispr ) = grep { $_->pam_right } @crisprs;
        my ( $left_crispr ) = grep { !$_->pam_right } @crisprs;
        if ( $left_crispr && $right_crispr ) {
            $crispr_entity = $self->result_source->schema->resultset('CrisprPair')->find(
                {   left_crispr_id  => $left_crispr->id,
                    right_crispr_id => $right_crispr->id,
                }
            );
        }

        # its not a pair, maybe its a group
        unless ( $crispr_entity ) {
            try{
                $crispr_entity = get_crispr_group_by_crispr_ids(
                    $self->result_source->schema,
                    { crispr_ids => [ map{ $_->id } @crisprs ] },
                );
            }
            catch{
                ERROR( "Unable to find crispr group: $_" );
            };
        }
    }
    else {
        ERROR( "No crisprs linked to well $self" );
    }

   return $crispr_entity;
}

=head experiments

Returns all experiment specifications matching this well

Note: only works for assembly well or later at the moment

=cut
use Time::HiRes qw(gettimeofday tv_interval);
sub experiments {
    my $self = shift;
    my $assembly = $self->parent_assembly_well;
    unless($assembly){
        die "No assembly well parent found for $self. Cannot identify related experiments";
    }

    my $t0 = [gettimeofday];
    my $crispr_entity = $self->crispr_entity;
    DEBUG "Time taken to get crispr_entity: ".tv_interval($t0);
    my $design = $self->design;

    unless($crispr_entity or $design){
        # This should never happen but just in case
        die "No crispr entity or design found for $self. Cannot identify related experiments";
    }

    my $search = { deleted => 0};
    if($crispr_entity){
        $search->{ $crispr_entity->id_column_name } = $crispr_entity->id;
    }
    if($design){
        $search->{design_id} = $design->id;
    }

    return $self->result_source->schema->resultset('Experiment')->search($search)->all;
}

sub experiments_pipelineII {
    my $self = shift;

    my $design = $self->design;

    my $search = { deleted => 0};

    if ($design) {
        $search->{design_id} = $design->id;
    }

    return $self->result_source->schema->resultset('Experiment')->search($search)->all;
}

=head2 crisprs

Return array of all crispr(s) linked to this well.

=cut
sub crisprs {
    my $self = shift;
    return map { $_->process_output_wells->first->process->process_crispr->crispr } $self->parent_crispr_wells;
}

=head2 crispr_pair

Legacy method, returns a crispr pair object if the well is linked to one

=cut
sub crispr_pair {
    my $self = shift;

    my $crispr_entity = $self->crispr_entity;
    if ( $crispr_entity->is_pair ) {
        return $crispr_entity;
    }
    ERROR( "Well is not linked to a crispr pair" );
    return;
}

=head2 crispr

Legacy method, returns a crispr object if the well is linked to one.

=cut
sub crispr {
    my $self = shift;

    my $crispr_entity = $self->crispr_entity;
    if ( !$crispr_entity->is_pair && !$crispr_entity->is_group ) {
        return $crispr_entity;
    }
    ERROR( "Well is not linked to a single crispr" );
    return;
}

=head2 crispr_group

Returns a crispr_group object if the well is linked to one.
Added because we have a crispr and crispr_pair method.

=cut
sub crispr_group {
    my $self = shift;

    my $crispr_entity = $self->crispr_entity;
    if ( $crispr_entity->is_group ) {
        return $crispr_entity;
    }
    ERROR( "Well is not linked to a crispr group" );
    return;
}

sub crispr_primer_for{
    my $self = shift;
    my $params = shift;
    #does params need validation?
    my $crispr_primer_seq = '-'; # default sequence is hyphen - no sequence available
    return $crispr_primer_seq if $params->{'crispr_pair_id'} eq 'Invalid';

    my $primer_type = $params->{'primer_label'} =~ m/\A [SP] /xms ? 'crispr_primer' : 'genotyping_primer';
    my $crispr_entity = $self->crispr_entity;

    if ( $primer_type eq 'crispr_primer' ){
        my $result = $crispr_entity->crispr_primers->find(
            {
                'primer_name' => $params->{'primer_label'},
                is_rejected => [0, undef],
            }
        );
        if ($result) {
            $crispr_primer_seq = $result->primer_seq;
        }
    }
    else {
        # it's a genotyping primer
        my $genotyping_primer_rs = $self->result_source->schema->resultset('GenotypingPrimer')->search({
                'design_id' => $self->design->id,
                'genotyping_primer_type_id' => $params->{'primer_label'},
            },
            {
                'columns' => [ qw/design_id genotyping_primer_type_id seq/ ],
                'distinct' => 1,
            }
        );
        if ($genotyping_primer_rs){
            if ($genotyping_primer_rs->count == 1) {
                $crispr_primer_seq = $genotyping_primer_rs->first->seq;
            }
            elsif ( $genotyping_primer_rs->count > 1) {
                $crispr_primer_seq = 'multiple results!';
            }
        }
    }

    return $crispr_primer_seq;
}

sub distributable_child_barcodes{
    my ( $self ) = @_;

    my @barcodes;

    # Find all child wells which have a barcode and are distributable (accepted)
    foreach my $well ( $self->child_wells_skip_versioned_plates ){
        next unless $well->barcode;
        next unless $well->is_accepted;
        push @barcodes, $well->barcode;
    }
    return \@barcodes;
}

sub input_process_parameters{
    my ( $self, $parameters ) = @_;
    $parameters ||= {};
    foreach my $process ($self->parent_processes){
        foreach my $param ($process->process_parameters){
            # FIXME: will overwrite if we have multiple input protocols with
            # same parameter names
            $parameters->{ $param->parameter_name } = $param->parameter_value;
        }
    }
    return $parameters;
}

sub input_process_parameters_skip_versioned_plates{
    my ( $self, $parameters ) = @_;
    $parameters ||= {};
    foreach my $process ($self->parent_processes){
        my ($input_well) = $process->input_wells;
        if($input_well->last_known_plate->version and $process->type_id eq 'rearray'){
            DEBUG ("process input well $input_well is versioned."
                    ."skipping this process in search for process parameters");
            $input_well->input_process_parameters_skip_versioned_plates($parameters);
        }
        else{
            foreach my $param ($process->process_parameters){
                # FIXME: will overwrite if we have multiple input protocols with
                # same parameter names
                $parameters->{ $param->parameter_name } = $param->parameter_value;
            }
        }
    }
    return $parameters;
}

#gene finder should be a method that accepts a species id and some gene ids,
#returning a hashref
#see code in WellData for an example
# NOTE this will return the QC data for the first parent well with crispr QC attached
sub genotyping_info {
    my ( $self, $gene_finder, $only_qc_data ) = @_;

    require LIMS2::Exception;

    #get the epd well if one exists (could be ourself)
    my $epd = is_plate_type_or_later($self, 'EP_PICK');


    LIMS2::Exception->throw( "Provided well must be an epd well or later" )
        unless $epd;

    LIMS2::Exception->throw( "EPD well is not accepted" )
        unless $epd->accepted;

    my $parent_qc_well = $self->first_parent_with_crispr_qc;

    DEBUG "First parent with crispr QC is $parent_qc_well";

    my $accepted_qc_well = $parent_qc_well->accepted_crispr_es_qc_well;
    LIMS2::Exception->throw( "No accepted Crispr ES QC wells found" )
        unless $accepted_qc_well;

    if ( $only_qc_data ) {
        DEBUG "Formatting QC data";
        my $data = $accepted_qc_well->format_well_data( $gene_finder, { truncate => 1 } );
        DEBUG "Formatting QC data DONE";
        return $data;
    }
    my $qc_info = _qc_info($accepted_qc_well,$gene_finder);

    # Add some extra info about which well the reported QC comes from
    $qc_info->{qc_plate_name} = $parent_qc_well->last_known_plate->name;
    $qc_info->{qc_well_name} = $parent_qc_well->name;
    $qc_info->{qc_plate_type} = $parent_qc_well->plate_type;
    if($qc_info->{qc_plate_type} eq 'EP_PICK'){
        $qc_info->{qc_type} = 'Primary QC';
    }
    elsif($qc_info->{qc_plate_type} eq 'PIQ'){
        $qc_info->{qc_type} = 'Secondary QC';
    }

    # store primers in a hash of primer name -> seq
    my %primers;
    for my $primer ( $accepted_qc_well->get_crispr_primers ) {
        #val is hash with name + seq
        my ( $key, $val ) = _group_primers( $primer->primer_name->primer_name, $primer->primer_seq );

        push @{ $primers{crispr_primers}{$key} }, $val;
    }

    my $vector_well = $self->final_vector;
    my $design = $vector_well->design;

    #find primers related to the design
    my @design_primers = $self->result_source->schema->resultset('GenotypingPrimer')->search(
        { design_id => $design->id },
        { order_by => { -asc => 'me.id'} }
    );

    for my $primer ( @design_primers ) {
        my ( $key, $val ) = _group_primers( $primer->genotyping_primer_type_id, $primer->seq );

        push @{ $primers{design_primers}{$key} }, $val;
    }

    my @gene_ids = $design->gene_ids;

    #get gene symbol from the solr
    my @genes = $design->gene_symbols($gene_finder);

    return {
        %$qc_info,
        gene             => @genes == 1 ? $genes[0] : [ @genes ],
        gene_id          => @gene_ids == 1 ? $gene_ids[0] : [ @gene_ids ],
        design_id        => $design->id,
        well_id          => $self->id,
        barcode          => $self->barcode,
        well_name        => $self->name,
        plate_name       => $self->plate_name,
        epd_plate_name   => $epd->plate_name,
        accepted         => $epd->accepted,
        targeting_vector => $vector_well->plate_name,
        vector_cassette  => $vector_well->cassette->name,
        primers          => \%primers,
        species          => $design->species_id,
        cell_line        => $self->first_cell_line->name,
    };
}

# Get QC results for related MS_QC plates (mutation signatures workflow)
sub ms_qc_data{
    my ($self, $gene_finder) = @_;

    my @mutation_signatures_qc;

    # Find parent doubling process/well
    my $doubling = $self->ancestors->find_process_of_type($self,'doubling');
    return unless $doubling;
    my ($ms_parent) = $doubling->input_wells;

    DEBUG "Looking for MS_QC wells with parent $ms_parent";

    my @ms_parent_child_wells = $ms_parent->child_wells_skip_versioned_plates;
    # Get QC results for MS_QC plates produced from the parent well
    my @ms_qc_wells = grep { $_->plate_type eq 'MS_QC' } @ms_parent_child_wells;
    foreach my $qc_well (@ms_qc_wells){
        DEBUG "Looking for accepted_crispr_es_qc_well for $qc_well";
        my $crispr_qc_well = $qc_well->accepted_crispr_es_qc_well;
        next unless $crispr_qc_well;
        DEBUG "Storing MS_QC info for $qc_well";
        my $qc_info = _qc_info($crispr_qc_well,$gene_finder);
        $qc_info->{parameters} = $qc_well->input_process_parameters_skip_versioned_plates;
        push @mutation_signatures_qc, $qc_info;
    }

    # Add any QC info linked to the PIQ QC well produced by the doubling process
    # To find the correct well to use look for an ancestor of the current well
    # which is in the list of real (not versioned) child wells of the doubling input
    # well.
    my $final_qc_well;
    my $ancestors = $self->ancestors->depth_first_traversal($self,'in');
    while (my $ancestor = $ancestors->next){
        if (grep { $_->id eq $ancestor->id } @ms_parent_child_wells){
            $final_qc_well = $ancestor;
            last;
        }
    }

    DEBUG "Final QC well for MS QC: $final_qc_well";

    my $crispr_qc_well = $final_qc_well->accepted_crispr_es_qc_well;
    if($crispr_qc_well){
        my $final_qc_info = _qc_info($crispr_qc_well, $gene_finder);
        $final_qc_info->{parameters} = $final_qc_well->input_process_parameters_skip_versioned_plates;
        $final_qc_info->{final_ms_qc_result} = 1;
        push @mutation_signatures_qc, $final_qc_info;
    }

    return \@mutation_signatures_qc;
}

sub accepted_crispr_es_qc_well{
    my ($self, $allele_number) = @_;
    my @qc_wells = $self->crispr_es_qc_wells;

    my $accepted_qc_well;
    for my $qc_well ( @qc_wells ) {
        if ( $qc_well->accepted ) {
            if ($allele_number){
                # optional check of QC run allele number for use with double targeted wells
                my $well_allele_number = ( $qc_well->crispr_es_qc_run->allele_number || 0 );
                if($allele_number == $well_allele_number){
                    $accepted_qc_well = $qc_well;
                }
            }
            else{
                $accepted_qc_well = $qc_well;
                last;
            }
        }
    }

    return $accepted_qc_well;
}

sub _qc_info{
    my ($accepted_qc_well, $gene_finder) = @_;
    my $qc_info = {
        fwd_read  => $accepted_qc_well->fwd_read,
        rev_read  => $accepted_qc_well->rev_read,
        qc_run_id => $accepted_qc_well->crispr_es_qc_run_id,
        vcf_file  => $accepted_qc_well->vcf_file,
        qc_data   => $accepted_qc_well->format_well_data( $gene_finder, { truncate => 1 } ),
    };
    return $qc_info;
}

sub _group_primers {
    my ( $name, $seq ) = @_;

    #split SF1 into qw(S F 1) so we can group properly
    my @fields = split //, $name;

    my $key = $fields[0] . $fields[-1];

    return $key, { name => $name, seq => $seq };
}

sub egel_pass_string {
    my ($self) = @_;

    my $string = "-";

    if(my $quality = $self->well_dna_quality){
        $string = $quality->egel_pass ? "pass" : "fail";
    }
    return $string;
}
# Compute accepted flag for DNA created from FINAL_PICK
# accepted = true if:
# FINAL_PICK qc_sequencing_result pass == true AND
# DNA well_dna_status pass == true AND
# DNA well_dna_quality egel_pass == true
sub compute_final_pick_dna_well_accepted {
    my ( $self ) = @_;

    return unless $self->plate_type eq 'DNA';

    my $ancestors = $self->ancestors->depth_first_traversal($self, 'in');

    my $final_pick_parent;
    while ( my $ancestor = $ancestors->next ) {

        # Allow for rearraying of DNA plates
        next if $ancestor->plate_type eq 'DNA';

        # Check plate type of parent well
        if ( $ancestor->plate_type eq 'FINAL_PICK' ) {
            $final_pick_parent = $ancestor;
            DEBUG("Found final pick parent ".$ancestor->as_string);
            last;
        }
        else{
            # Parent is not a FINAL_PICK so skip accepted flag computation
            DEBUG("Parent is not FINAL_PICK");
            return;
        }
    }

    if ($final_pick_parent){
        my $final_pick_qc_seq = $final_pick_parent->well_qc_sequencing_result;
        my $dna_status = $self->well_dna_status;
        my $dna_quality = $self->well_dna_quality;
        if ($final_pick_qc_seq and $dna_status and $dna_quality){
            DEBUG("Computing final pick DNA accepted status");
            DEBUG("Final pick QC status: ".$final_pick_qc_seq->pass);
            DEBUG("DNA status: ".$dna_status->pass);
            DEBUG("DNA egel pass: ".$dna_quality->egel_pass);
            if ( $final_pick_qc_seq->pass and $dna_status->pass and $dna_quality->egel_pass){
                DEBUG("Setting accepted to true");
                $self->update({ accepted => 1 });
            }
            else{
                DEBUG("Setting accepted to false");
                $self->update({ accepted => 0 });
            }
        }
        else{
            # We do not have enough data to compute the accepted flag
            # unset accepted flag which may have been set elsewhere
            $self->update({accepted => 0 });
            DEBUG("Not enough info to set accepted flag");
            return;
        }
    }

    return;
}

sub assembly_qc_value{
    my ($self, $qc_type) = @_;

    die "No assembly QC type specified" unless $qc_type;

    my $qc = $self->search_related('well_assembly_qcs',{
        qc_type => $qc_type,
    })->first;

    if ($qc){
        return $qc->value;
    }

    return;
}

sub assembly_well_qc_verified{
    my ($self) = @_;

    # Must have all 3 qc results set to make this call
    unless($self->well_assembly_qcs->all == 3){
        return;
    }

    my @good = map { $_->qc_type }
               $self->search_related('well_assembly_qcs',{
                  value => 'Good',
               });

    # True if vector is good and at least one crispr good
    my $vector_good = grep { $_ eq 'VECTOR_QC' } @good;
    my $crispr_good = grep { $_ =~ /CRISPR/ } @good;

    my $is_good = $vector_good && $crispr_good ? 1 : 0;

    return $is_good;
}

# Find most recent event for the barcode.
# If state is provided find the most recent event which *changed* the state to the one specified
sub most_recent_barcode_event{
    my ($self, $state) = @_;

    my $search_criteria = {};

    if($state){
        $search_criteria = {
            new_state => $state,
            old_state => {'!=' => $state }
        };
    }

    my $event = $self->search_related('barcode_events',
        $search_criteria,
        {
            order_by => { -desc => [qw/created_at/] }
        }
    )->first;

    return $event;
}

sub parent_plates {
    my ( $self ) = @_;

    my @parent_wells = $self->parent_wells;

    my @plate_wells = map { { plate => $_->plate, well => $_ } } @parent_wells;

    return @plate_wells;
}

__PACKAGE__->meta->make_immutable;
1;
