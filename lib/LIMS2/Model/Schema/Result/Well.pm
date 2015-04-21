use utf8;
package LIMS2::Model::Schema::Result::Well;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Well::VERSION = '0.307';
}
## use critic


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

=head2 accepted_rules_version

  data_type: 'text'
  is_nullable: 1

=head2 to_report

  data_type: 'boolean'
  default_value: true
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
  "accepted_rules_version",
  { data_type => "text", is_nullable => 1 },
  "to_report",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
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

=head2 barcode_events_new_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BarcodeEvent>

=cut

__PACKAGE__->has_many(
  "barcode_events_new_wells",
  "LIMS2::Model::Schema::Result::BarcodeEvent",
  { "foreign.new_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 barcode_events_old_wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BarcodeEvent>

=cut

__PACKAGE__->has_many(
  "barcode_events_old_wells",
  "LIMS2::Model::Schema::Result::BarcodeEvent",
  { "foreign.old_well_id" => "self.id" },
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
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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

=head2 well_barcode

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::WellBarcode>

=cut

__PACKAGE__->might_have(
  "well_barcode",
  "LIMS2::Model::Schema::Result::WellBarcode",
  { "foreign.well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_barcodes_root_piqs_well

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::WellBarcode>

=cut

__PACKAGE__->has_many(
  "well_barcodes_root_piqs_well",
  "LIMS2::Model::Schema::Result::WellBarcode",
  { "foreign.root_piq_well_id" => "self.id" },
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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-02-05 16:41:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YiWRvSPiOvAhXla608AoMw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use List::MoreUtils qw( any );

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
use List::MoreUtils qw( uniq );

sub as_string {
    my $self = shift;

    my $name = sprintf( '%s_%s', $self->plate->name, $self->name );

    if($self->plate->version){
        $name = sprintf( '%s(v%s)_%s', $self->plate->name, $self->plate->version, $self->name);
    }
    return $name;
}

sub as_hash {
    my $self = shift;

    return {
        id             => $self->id,
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

sub plate_name {
    my $self = shift;
    return $self->plate->name;
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

has is_double_targeted => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1
);

sub _build_is_double_targeted {
    my $self = shift;

    my $it = $self->ancestors->breadth_first_traversal( $self, 'in' );
    while ( my $well = $it->next ) {
        if ( $well->plate->type_id eq 'SEP' ) {
            return 1;
        }
    }

    return 0;
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
        my $this_well_plate_type = $this_well->plate->type_id;
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
        my $this_well_plate_type = $this_well->plate->type_id;
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
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw(
        "Cannot request second_electroporation_process for single-targeted construct"
    );
}
## use critic

## no critic(RequireFinalReturn)
sub first_allele {
    my $self = shift;

    for my $input ( $self->second_electroporation_process->input_wells ) {
        if ( $input->plate->type_id eq 'XEP' ) {
            return $input;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw(
        "Failed to determine first allele for $self"
    );
}
## use critic

## no critic(RequireFinalReturn)
sub second_allele {
    my $self = shift;

    for my $input ( $self->second_electroporation_process->input_wells ) {
        if ( $input->plate->type_id ne 'XEP' ) {
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
sub final_vector {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if (  $ancestor->plate->type_id eq 'FINAL' || $ancestor->plate->type_id eq 'FINAL_PICK' ) {
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
            if ( $ancestor->plate->type_id eq 'DNA' ) {
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
        if ( $input->plate->type_id eq 'DNA' ) {
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
        if ( $ancestor->plate->type_id eq 'EP' ) {
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
        if ( $ancestor->plate->type_id eq 'EP_PICK' ) {
            return $ancestor;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine first electroporation pick plate/well for $self" );
}
## use critic

#maybe think of a better name for this
#it just means it must be ep_pick or later
sub is_epd_or_later {
  my $self = shift;

  #epd is ok with us
  return $self if $self->plate->type_id eq 'EP_PICK';

  my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
  while ( my $ancestor = $ancestors->next ) {
    return $ancestor if $ancestor->plate->type_id eq 'EP_PICK';
  }

  #we didn't find any ep picks further up so its not
  return;
}

## no critic(RequireFinalReturn)
sub second_ep {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate->type_id eq 'SEP' ) {
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
	    		my $plate_name = $input->plate->name;
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
          my $plate_name = $output->plate->name;
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
        if ( $ancestor->plate->type_id eq 'SEP_PICK' ) {
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
        if ( $ancestor->plate->type_id eq 'SFP' ||  $ancestor->plate->type_id eq 'FP' ) {
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
  			if ( $descendant->plate->type_id eq 'PIQ' ) {
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
        if ( $ancestor->plate->type_id eq 'PIQ' ) {
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
        if( ($descendant->plate->type_id eq $type) and $descendant->well_barcode ){
          return $descendant;
        }
      }
    }
    return;
}

sub descendant_crispr_vectors {
    my $self = shift;

    my @crispr_vectors;
    my $descendants = $self->descendants->depth_first_traversal( $self, 'out' );
    if ( defined $descendants ) {
      while( my $descendant = $descendants->next ) {
        if ( $descendant->plate->type_id eq 'CRISPR_V' ) {
          push @crispr_vectors, $descendant;
        }
      }
    }
    return @crispr_vectors;
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
        if ( $ancestor->plate->type_id eq 'CRISPR' ) {
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
        if ( $ancestor->plate->type_id eq 'CRISPR_V' ) {

            # Ignore CRISPR_V well if it does not have any DNA child wells..
            if ( grep { $_->plate->type_id eq 'DNA' } $self->ancestors->output_wells($ancestor) ) {
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
    if ( $self->plate->type_id eq 'ASSEMBLY' || $self->plate->type_id eq 'OLIGO_ASSEMBLY' ) {
        return $self;
    }
    else{
        my $ancestors = $self->ancestors->breadth_first_traversal( $self, 'in' );
        while( my $ancestor = $ancestors->next ) {
            if (   $ancestor->plate->type_id eq 'ASSEMBLY'
                || $ancestor->plate->type_id eq 'OLIGO_ASSEMBLY' )
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

#gene finder should be a method that accepts a species id and some gene ids,
#returning a hashref
#see code in WellData for an example
# NOTE this will always return the epd wells qc data, even if there is qc
#      data on the current well ( e.g. with a PIQ well )
sub genotyping_info {
  my ( $self, $gene_finder, $only_qc_data ) = @_;

  require LIMS2::Exception;

  #get the epd well if one exists (could be ourself)
  my $epd = $self->is_epd_or_later;

  LIMS2::Exception->throw( "Provided well must be an epd well or later" )
      unless $epd;

  LIMS2::Exception->throw( "EPD well is not accepted" )
     unless $epd->accepted;

  my @qc_wells = $self->result_source->schema->resultset('CrisprEsQcWell')->search(
    { well_id => $epd->id }
  );

  LIMS2::Exception->throw( "No QC Wells found" )
    unless @qc_wells;

  my $accepted_qc_well;
  for my $qc_well ( @qc_wells ) {
    if ( $qc_well->accepted ) {
      $accepted_qc_well = $qc_well;
      last;
    }
  }

  LIMS2::Exception->throw( "No QC wells are accepted" )
     unless $accepted_qc_well;

  if ( $only_qc_data ) {
    return $accepted_qc_well->format_well_data( $gene_finder, { truncate => 1 } );
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

  my @gene_ids = uniq map { $_->gene_id } $design->genes;

  #get gene symbol from the solr
  my @genes = map { $_->{gene_symbol} }
                  values %{ $gene_finder->( $self->plate->species_id, \@gene_ids ) };

  return {
      gene             => @genes == 1 ? $genes[0] : [ @genes ],
      gene_id          => @gene_ids == 1 ? $gene_ids[0] : [ @gene_ids ],
      design_id        => $design->id,
      well_id          => $self->id,
      well_name        => $self->name,
      plate_name       => $self->plate->name,
      fwd_read         => $accepted_qc_well->fwd_read,
      rev_read         => $accepted_qc_well->rev_read,
      epd_plate_name   => $epd->plate->name,
      accepted         => $epd->accepted,
      targeting_vector => $vector_well->plate->name,
      vector_cassette  => $vector_well->cassette->name,
      qc_run_id        => $accepted_qc_well->crispr_es_qc_run_id,
      primers          => \%primers,
      vcf_file         => $accepted_qc_well->vcf_file,
      qc_data          => $accepted_qc_well->format_well_data( $gene_finder, { truncate => 1 } ),
      species          => $design->species_id,
      cell_line        => $self->first_cell_line->name,
  };
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

    return unless $self->plate->type_id eq 'DNA';

    my $ancestors = $self->ancestors->depth_first_traversal($self, 'in');

    my $final_pick_parent;
    while ( my $ancestor = $ancestors->next ) {

        # Allow for rearraying of DNA plates
        next if $ancestor->plate->type_id eq 'DNA';

        # Check plate type of parent well
        if ( $ancestor->plate->type_id eq 'FINAL_PICK' ) {
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
__PACKAGE__->meta->make_immutable;
1;
