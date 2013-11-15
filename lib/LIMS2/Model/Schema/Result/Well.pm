use utf8;
package LIMS2::Model::Schema::Result::Well;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Well::VERSION = '0.126';
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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QbXZA5S0PCM6d9pr1/qC5A


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

sub cassette {
    my $self = shift;

    $self->assert_not_double_targeted;

    my $process_cassette = $self->ancestors->find_process( $self, 'process_cassette' );

    return $process_cassette ? $process_cassette->cassette : undef;
}

sub backbone {
    my $self = shift;

    $self->assert_not_double_targeted;

    my $process_backbone = $self->ancestors->find_process( $self, 'process_backbone' );

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

    my $process_design = $self->ancestors->find_process( $self, 'process_design' );

    return $process_design ? $process_design->design : undef;
}

sub crispr {
    my $self = shift;

    #TODO what if we have 2 crisprs applied? sp12 Tue 01 Oct 2013 09:26:47 BST

    my $process_crispr = $self->ancestors->find_process( $self, 'process_crispr' );

    return $process_crispr ? $process_crispr->crispr : undef;
}

sub designs{
	my $self = shift;

	my $edges = $self->ancestors->edges;

	my @designs;

	foreach my $edge (@$edges){
		my ($process, $input, $output) = @$edge;
		# Edges with no input node are (probably!) design processes
		if(not defined $input){
			my $process_design = $self->result_source->schema->resultset('ProcessDesign')->find({ process_id => $process });
			if ($process_design){
			    push @designs, $process_design->design;
			}
		}
	}
    return @designs;
}

sub parent_processes{
	my $self = shift;

	# Fetch processes of which this well is an output
	my @parent_processes = map { $_->process } $self->process_output_wells->all;

	return @parent_processes;
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
sub parent_crispr {
    my $self = shift;

    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate->type_id eq 'CRISPR' ) {
            return $ancestor;
        }
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine crispr plate/well for $self" );
}
## use critic

## no critic(RequireFinalReturn)
sub parent_crispr_v {
    my $self = shift;

    my @parents;
    my $ancestors = $self->ancestors->depth_first_traversal( $self, 'in' );
    while( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate->type_id eq 'CRISPR_V' ) {
            push ( @parents, $ancestor );
            # return $ancestor;
        }
    }

    if (scalar @parents) {
      return @parents;
    }

    require LIMS2::Exception::Implementation;
    LIMS2::Exception::Implementation->throw( "Failed to determine crispr vector plate/well for $self" );
}
## use critic

__PACKAGE__->meta->make_immutable;
1;
