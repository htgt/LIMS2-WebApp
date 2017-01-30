package LIMS2::ReportGenerator::Plate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::Plate::VERSION = '0.443';
}
## use critic


use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;
use LIMS2::Exception::Implementation;
use LIMS2::Model::Util::Crisprs qw( get_crispr_group_by_crispr_ids gene_ids_for_crispr );
use Module::Pluggable::Object;
use List::MoreUtils qw( uniq any );
use Try::Tiny;
use Log::Log4perl qw( :easy );
use namespace::autoclean;
use Time::HiRes qw(time);
use Data::Dumper;
use JSON;

extends qw( LIMS2::ReportGenerator );

BEGIN {
    #try not to override the lims2 logger
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->easy_init( { level => $DEBUG } );
    }
}

sub _report_plugins {
    return grep { $_->isa( 'LIMS2::ReportGenerator::Plate' ) }
        Module::Pluggable::Object->new( search_path => [ 'LIMS2::Report' ], require => 1 )->plugins;
}

## no critic(RequireFinalReturn)
sub report_class_for {
    my ( $class, $plate_type ) = @_;

    for my $plugin ( $class->_report_plugins ) {
        if ( $plugin->handles_plate_type( $plate_type ) && !$plugin->additional_report ) {
            return $plugin;
        }
    }

    LIMS2::Exception::Implementation->throw( "No report class implemented for plate type $plate_type" );
}
## use critic

has plate_name => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1
);

has plate_id => (
    is       => 'ro',
    isa      => 'Int'
);

has plate => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::Plate',
    lazy_build => 1,
    handles    => {
        species => 'species_id'
    }
);

has '+param_names' => (
    default => sub { [ 'plate_name' ] }
);

has time_taken => (
    is => 'rw',
    default => 0,
    isa => 'Num',
);

# HashRef linking each well on the plate to crispr wells via crispr_design
# Structure is like this:
#   crispr_wells => {
#       <well_id> => {
#          <crispr_design_id> => {
#              single => [ <array of crispr wells> ],
#              left   => [ <array of crispr wells> ],
#              right  => [ <array of crispr wells> ],
#          }
#       }
#   }
has crispr_wells => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build_crispr_wells {
    my ($self) = @_;

    my $crispr_wells = {};

    my $start = time();
    foreach my $well ($self->plate->wells){
        $crispr_wells->{ $well->id } = {};
        my $well_ref = $crispr_wells->{ $well->id };

        my $design;
        if ( $self->well_designs->{ $well->id } ) {
            $design = $self->well_designs->{ $well->id };
        }
        else {
            $design = $well->design;
        }

        if ( $design ){
            foreach my $crispr_design ($design->crispr_designs){
                $well_ref->{ $crispr_design->id } = {};
                my $crispr_design_ref = $well_ref->{ $crispr_design->id };
                if(my $crispr = $crispr_design->crispr){
                    $crispr_design_ref->{single} = [ $crispr->crispr_wells ];
                }
                elsif(my $crispr_pair = $crispr_design->crispr_pair){
                    $crispr_design_ref->{left} = [ $crispr_pair->left_crispr->crispr_wells ];
                    $crispr_design_ref->{right} = [ $crispr_pair->right_crispr->crispr_wells ];
                }
            }
        }
        else{
            LIMS2::Exception::Implementation->throw("Cannot find design for well ".$well->as_string);
        }
    }
    my $end = time();
    TRACE(sprintf "Finding crispr wells for each well took: %.2f",$end - $start);

    return $crispr_wells;
}

has crispr_well_descendants => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build_crispr_well_descendants {
    my ($self) = @_;
    my ($start, $end);

    # Find crispr wells for all designs on the plate
    # using the crispr_wells cache
    $start = time();
    my @crispr_wells;

    my @types = qw(single left right);
    foreach my $well ($self->plate->wells){
        my $crispr_designs = $self->crispr_wells->{ $well->id };
        foreach my $crispr_design_id ( keys %{ $crispr_designs || {} } ){
            foreach my $type (@types){
                push @crispr_wells, @{ $crispr_designs->{$crispr_design_id}->{$type} || [] };
            }
        }
    }

    my @ids = uniq map { $_->id } @crispr_wells;
    $end = time();
    TRACE(sprintf "Search for all crispr wells took: %.2f",$end - $start);

    # Search for descendants of all crispr wells using single recursive query
    $start = time();
    my $result = $self->model->get_descendants_for_well_id_list(\@ids);
    $end = time();
    TRACE(sprintf "All descendants query took: %.2f",$end - $start);

    # Store list of child well ids for each crispr well
    my $child_well_ids = {};
    foreach my $path (@$result){
        my ($root, @children) = @{ $path->[0]  };
        unless(exists $child_well_ids->{$root}){
            $child_well_ids->{$root} = [];
        }
        my $arrayref = $child_well_ids->{$root};
        push @$arrayref, @children;
    }

    return $child_well_ids;
}

# key = well_id, value = design_id, can only set when using PlateReport custom resultset
has well_designs => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub{ {} },
);

=head2 set_well_designs

If the PlateReport custom resultset has been used to gather data for the plate report
then we already have the design id for each well

=cut
sub set_well_designs {
    my ( $self, $wells_data ) = @_;
    my ( %well_designs, %designs );

    for my $well_data ( @{ $wells_data } ) {
        my $well_id = $well_data->{well_id};
        my $design_id = $well_data->{design_id};
        next unless $design_id; # crispr well
        unless ( exists $designs{ $design_id } ) {
            $designs{ $design_id } = $self->model->c_retrieve_design( { id => $design_id } );
        }
        $well_designs{ $well_id } = $designs{ $design_id };
    }
    $self->well_designs( \%well_designs );

    return;
}

# Needed way of having multiple plate type reports but having only one of these
# reports as the default report for that plate type.
# When adding additional reports override this sub to return 1:
# i.e.
# override additional_report => sub {
#    return 1;
# };
sub additional_report {
    return;
}

sub plate_types {
    confess( "plate_types() must be implemented by a subclass" );
}

sub handles_plate_type {
    my ( $class, $plate_type ) = @_;

    for my $handled_plate_type ( @{ $class->plate_types } ) {
        return 1 if $plate_type eq $handled_plate_type;
    }

    return;
}

sub _build_plate {
    my $self = shift;

    my %search = ( type => $self->plate_types );

    if ( $self->plate_id ) {
        $search{id} = $self->plate_id;
    }
    elsif ( $self->plate_name ) {
        $search{name} = $self->plate_name;
    }
    else {
        LIMS2::Exception::Implementation->throw( "PlateReportGenerator requires one of plate, plate_name, or plate_id be specified" );
    }

    return $self->model->retrieve_plate( \%search, { prefetch => 'wells' } );
}

sub _build_plate_name {
    my $self = shift;

    return $self->plate->name;
}

# Get ancestor trees for all plate wells with one query
# and pre-load them into well objects
sub prefetch_well_ancestors{
    my $self = shift;

    my @wells = $self->plate->wells;

    # Pre-populate ancestors for all plate wells using batch query
    my @well_ids = map { $_->id } @wells;
    my $well_ancestors = $self->model->fast_get_well_ancestors(@well_ids);
    foreach my $this_well (@wells){
        $this_well->set_ancestors( $well_ancestors->{ $this_well->id } );
    }
    return;
}

sub base_columns {
    confess "base_columns() must be implemented by a subclass";
}

sub base_data {
    confess "base_data() must be implemented by a subclass";
}

sub accepted_crispr_columns {
    return ("Accepted Crispr Single", "Accepted Crispr Pairs");
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _find_accepted_CRISPR_V_wells{
    my ($self,$crispr_wells) = @_;

    my ($start, $end);

    my @ids = map { $_->id } @{ $crispr_wells || [] };

    return () unless @ids;

    # Fetch crispr well descendant IDs from cache
    $start = time();
    my @descendant_ids = uniq map { @{ $self->crispr_well_descendants->{$_} || [] } } @ids;

    # Fetch CRISPR_V wells from db
    my @vectors = $self->model->schema->resultset('Well')->search(
        {
            'me.id' => { -in => \@descendant_ids },
            'plate.type_id' => 'CRISPR_V'
        },
        {
            prefetch => ['plate','well_accepted_override']
        }
    )->all;
    $end = time();
    TRACE(sprintf "Well search took: %.2f",$end - $start);

    # Assume we are only interested in vectors on the most recently created crispr_v plate
    my @accepted_wells;
    my $most_recent_plate;

    $start = time();
    foreach my $well (@vectors){

        next unless $well->is_accepted;

        push @accepted_wells, $well;

        my $plate = $well->plate;
        $most_recent_plate ||= $plate;
        if ($plate->created_at > $most_recent_plate->created_at){
            $most_recent_plate = $plate;
        }
    }

    my @return = grep { $_->plate_id == $most_recent_plate->id } @accepted_wells;
    $end = time();
    TRACE(sprintf "Newest accepted filter took: %.2f",$end - $start);

    return @return;
}
## use critic

## no critic (ProhibitUnusedPrivateSubroutines)
sub _find_accepted_DNA_wells {
    my ($self,$crispr_wells) = @_;

    my ($start, $end);

    my @ids = map { $_->id } @{ $crispr_wells || [] };

    return () unless @ids;

    # Fetch crispr well descendant IDs from cache
    $start = time();
    my @descendant_ids = uniq map { @{ $self->crispr_well_descendants->{$_} || [] } } @ids;

    # Fetch CRISPR_V wells from db
    my @dna_wells = $self->model->schema->resultset('Well')->search(
        {
            'me.id' => { -in => \@descendant_ids },
            'plate.type_id' => 'DNA'
        },
        {
            prefetch => ['plate','well_accepted_override']
        }
    )->all;
    $end = time();
    TRACE(sprintf "Well search took: %.2f",$end - $start);

    return grep { $_->is_accepted } @dna_wells;
}
## use critic

sub accepted_crispr_data {
    my ( $self, $well, $well_type ) = @_;

    # Find accepted CRISPR_V wells as default
    $well_type ||= 'CRISPR_V';
    my $find_method = '_find_accepted_'.$well_type.'_wells';

    my $f_start = time();
    my (@single_crisprs, @paired_crisprs);

    DEBUG("Finding accepted crispr wells for ".$well->as_string);

    # Generate a list of single crispr wells related to well
    my @single_cr_wells;

    my $crispr_designs = $self->crispr_wells->{ $well->id };
    foreach my $crispr_design_id ( keys %{ $crispr_designs || {} } ){

        my $crispr_design = $crispr_designs->{$crispr_design_id};

        # Store single crisprs for handling later
        push @single_cr_wells, @{ $crispr_design->{single} || [] };

        # Handle paired crisprs for each crispr_design because
        # left and right wells need to be reported together
        my @left_cr_wells = @{ $crispr_design->{left} || [] };
        my @right_cr_wells = @{ $crispr_design->{right} || [] };

        my @left_accepted = $self->$find_method(\@left_cr_wells);
        my @right_accepted = $self->$find_method(\@right_cr_wells);
        if (@left_accepted and @right_accepted){
            # Fetch the pair ID to display
            my $pair_id = $self->model->schema->resultset('Experiment')->find({
                id => $crispr_design_id,
            })->crispr_pair_id;

            my $left_as_string = join( q{/}, map {$_->as_string} @left_accepted);
            my $right_as_string = join( q{/}, map {$_->as_string} @right_accepted);
            my $pair_as_string = "Pair $pair_id"."[left:$left_as_string-right:$right_as_string]";
            push @paired_crisprs, $pair_as_string;
        }
    }

    # Handle the single crisprs for this well
    @single_crisprs = $self->$find_method(\@single_cr_wells);

    my $f_end = time();
    my $elapsed = $f_end - $f_start;
    TRACE(sprintf "Accepted crispr well search took: %.2f",$elapsed);
    $self->time_taken($self->time_taken + $elapsed);
    TRACE("total time taken: ".$self->time_taken);
    return (
        join( q{/}, map {$_->as_string} @single_crisprs ),
        join( q{ }, @paired_crisprs ),
    );
}

sub design_and_gene_cols {
    my ( $self, $well, $crispr ) = @_;

    # If well crispr is provided we need to get design and gene info via crispr_designs
    if($crispr){
        return $self->crispr_design_and_gene_cols($crispr);
    }

    my $design        = $well->design;
    my @gene_ids      = uniq map { $_->gene_id } $design->genes;
    my @gene_symbols;
    try {
        @gene_symbols  = uniq map {
            $self->model->retrieve_gene( { species => $self->species, search_term => $_ } )->{gene_symbol}
        } @gene_ids;
    };

    my @gene_projects = $self->model->schema->resultset('Project')->search({ gene_id => { -in => \@gene_ids }})->all;
    my @sponsors = uniq map { $_->sponsor_ids } @gene_projects;

    return ( $design->id, $design->design_type_id, join( q{/}, @gene_ids ), join( q{/}, @gene_symbols ), join( q{/}, @sponsors ) );
}

sub ancestor_cols {
    my ( $self, $well, $plate_type ) = @_;

    my $ancestors = $well->ancestors->depth_first_traversal($well, 'in');

    while ( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate_type eq $plate_type ) {
            return (
                $ancestor->as_string,
                $self->qc_result_cols( $ancestor )
            );
        }
    }

    return ('')x5;
}

=head2 ancestor_cols_quick

If we are using the PlateReport custom resultset to gather the plate report
data we can use this method to quickly grab ancestor wells.

=cut
sub ancestor_cols_quick {
    my ( $self, $result, $plate_type ) = @_;

    my $well_name = $result->{well_ancestors}{$plate_type}{well_name};
    my $well_id = $result->{well_ancestors}{$plate_type}{well_id};

    if ( $well_id ) {
        my $well = $self->model->schema->resultset('Well')->find(
            { id => $well_id },
            { prefetch => 'well_qc_sequencing_result' }
        );

        return (
            $well_name,
            $self->qc_result_cols( $well ),
        );
    }

    return ('')x5;
}

sub pick_counts {
    my ( $self, $well, $pick_type ) = @_;

    # XXX This assumes the picked wells are immediate descendants of
    # $well: we aren't doing a full traversal.
    my @picks = grep { $_->plate_type eq $pick_type }
        $well->descendants->output_wells( $well );

    my $picked   = scalar @picks;
    my $accepted = scalar grep { $_->is_accepted } @picks;

    return ( $picked, $accepted );
}

sub crispr_marker_symbols{
    my ($self, $crispr) = @_;

    my %symbols;
    foreach my $design ($crispr->related_designs){
        $self->_symbols_from_design($design, \%symbols);
    }

    return join ", ", keys %symbols;
}

sub crispr_design_and_gene_cols{
    my ($self, $crispr) = @_;

    my %designs = map{ $_->id => $_->design_type_id } $crispr->related_designs;
    my $gene_finder = sub { $self->model->find_genes( @_ ); }; #gene finder method
    my @gene_ids = uniq @{ gene_ids_for_crispr( $gene_finder, $crispr, $self->model ) };

    my @symbols;
    for my $gene_id ( @gene_ids ) {
        try {
            my $gene = $self->model->find_gene( { species => $self->species, search_term => $gene_id } );
            push @symbols, $gene->{gene_symbol};
        };
    }

    my @gene_projects = $self->model->schema->resultset('Project')->search({ gene_id => { -in => \@gene_ids }})->all;
    my @sponsors = uniq map { $_->sponsor_ids } @gene_projects;

    return (
        join( q{/}, keys %designs ),
        join( q{/}, values %designs ),
        join( q{/}, @gene_ids ),
        join( q{/}, uniq @symbols ),
        join( q{/}, @sponsors )
    );

}

=head create_button_json
Returns a custom json string ( lims2_custom ) for interpretation by the view (template toolkit).

Note that you must provide key/value pairs for:
api_url - the view will use a c.uri_for call using this as the api method used to render the view
button_label - text to be used to label the button for this cell
browser_target - an html keyword or arbitrary string to indicate whether the button will create a new tab or window, or render in the curent window

All key value pairs are passed by the uri_for call to render the action/view.

=cut

sub create_button_json {
    my $self = shift;
    my $params = shift;

    my $custom_value = {
        'lims2_custom' => {
            %{$params}
        },
    };
    my $json_text = encode_json( $custom_value );

    return $json_text;
}

# Create a JSON string which will be rendered as a combo box
# in generic_report_grid.tt and simple_table.tt
# See LIMS2::Report::AssemblyPlate for an example
sub create_combo_json {
    my $self = shift;
    my $params = shift;

    # "-" represents the unset option
    # When a user selects this option in the combobox the request is sent
    # with no "value" parameter added to the url
    my @options = (["-","-"]);

    # When an option is selected it is added to the url as value=<option>
    foreach my $item (@{ $params->{options} }){
        push @options, [$item,$item];
    }

    # api_params are key value pairs which are always added
    # in the request URL, e.g. well_id=12345&qc_type=CRISPR_LEFT_QC
    my @api_params;
    foreach my $key (keys %{ $params->{api_params} }){
        my $param_string = $key."=".$params->{api_params}->{$key};
        DEBUG("param string: $param_string");
        push @api_params, $param_string;
    }
    my $api_params_string = join "&", @api_params;

    # api_base is the path added after c.uri_for(/)
    # selected is the currently selected option from the database
    my $combo = {
        'lims2_combo' => {
            options => \@options,
            selected => $params->{selected},
            api_base => $params->{api_base},
            api_params => $api_params_string,
        },
    };
    my $json_text = encode_json( $combo );
    return $json_text;
}

sub well_primer_bands_data {
    my ( $self, $well ) = @_;

    my @primer_bands_data;
    for my $primer_band ( $well->well_primer_bands->all ) {
        push @primer_bands_data, $primer_band->primer_band_type_id . '(' . $primer_band->pass . ')';
    }

    return join( ', ', @primer_bands_data );
}

sub well_qc_sequencing_result_data {
    my ( $self, $well ) = @_;

    my @qc_data = ( '', '', '' );
    if ( my $well_qc_sequencing_result = $well->well_qc_sequencing_result ) {
        @qc_data = (
            $self->boolean_str( $well_qc_sequencing_result->pass ),
            $well_qc_sequencing_result->valid_primers,
            $well_qc_sequencing_result->test_result_url,
        );
    }

    return @qc_data;
}

=head2 get_crispr_data

Gather crispr data for all the wells on plate.
Only works for ASSEMBLY plates or its child plates.
Works out if crisprs linked to well form a group, pair or single crispr entity.

=cut
sub get_crispr_data {
    my ( $self, $wells_data ) = @_;

    my $crisprs = $self->prefetch_crisprs( $wells_data );

    my $crispr_data_method;
    # We have to assume all the assemblies on the plate are of same type
    ## no critic (ProhibitCascadingIfElse)
    if ( any { $_->{crispr_assembly_process} eq 'single_crispr_assembly' } @{ $wells_data } ) {
        $crispr_data_method = 'single_crispr_data';
    }
    elsif ( any { $_->{crispr_assembly_process} eq 'paired_crispr_assembly' } @{ $wells_data } ) {
        $crispr_data_method = 'crispr_pair_data';
    }
    # this process type does not exist yet but should in the future
    elsif ( any { $_->{crispr_assembly_process} eq 'group_crispr_assembly' } @{ $wells_data } ) {
        $crispr_data_method = 'crispr_group_data';
    }
    elsif ( any { $_->{crispr_assembly_process} eq 'oligo_assembly' } @{ $wells_data } ) {
        $crispr_data_method = 'single_crispr_data';
    }
    else {
        die( 'Can not find a crispr_assembly process, unable to work out crispr type' );
    }
    ## use critic

    my %well_crisprs;
    for my $well_data ( @{ $wells_data } ) {
        my $crispr_ids = $well_data->{crispr_ids};
        next unless $crispr_ids;

        my ( $crispr_type, $crispr_obj ) = $self->$crispr_data_method( $crispr_ids );

        my %crispr_data;
        $crispr_data{type} = $crispr_type;
        $crispr_data{obj}  = $crispr_obj;
        # use crispr ids array for well to take a hash slice of the pre_fetched crispr data
        $crispr_data{crisprs} =[ @{ $crisprs }{ @{ $crispr_ids } } ];

        $well_crisprs{ $well_data->{well_id} } = \%crispr_data;
    }

    return \%well_crisprs;
}

=head2 prefetch_crisprs

Gather all crisprs that are linked to the plate into a hash for easy lookup later

=cut
sub prefetch_crisprs {
    my ( $self, $wells_data ) = @_;
    my %crisprs;

    for my $wd ( @{ $wells_data } ) {
        next unless $wd->{crispr_wells};
        for my $cw ( @{ $wd->{crispr_wells}{crisprs} } ) {
            next if exists $crisprs{ $cw->{crispr_id} };

            my $crispr = $self->model->schema->resultset('Crispr')->find( { id => $cw->{crispr_id} } );
            $crisprs{ $cw->{crispr_id} } = {
                crispr      => $crispr,
                crispr_well => $cw->{plate_name} . '_' . $cw->{well_name},
            };
        }
    }

    return \%crisprs;
}

=head2 single_crispr_data

Retrieve single crispr

=cut
sub single_crispr_data {
    my ( $self, $crispr_ids ) = @_;

    my $crispr = $self->model->schema->resultset( 'Crispr' )->find(
        {
            id => $crispr_ids->[0],
        },
        {
            prefetch => 'crispr_primers',
        }
    );

    return ( 'crispr', $crispr );
}

=head2 crispr_pair_data

Retrieve crispr pair given 2 crispr ids

=cut
sub crispr_pair_data {
    my ( $self, $crispr_ids ) = @_;

    my $crispr_pair = $self->model->schema->resultset('CrisprPair')->search(
        {
            -or => [
                -and => [
                    left_crispr_id  => $crispr_ids->[0],
                    right_crispr_id => $crispr_ids->[1],
                ],
                -and => [
                    left_crispr_id  => $crispr_ids->[1],
                    right_crispr_id => $crispr_ids->[0],
                ],
            ]
        },
        {
            prefetch => [ 'crispr_primers' ]
        }
    )->first;

    unless ( $crispr_pair ) {
        ERROR( 'No pairs with ids: ' . join( ', ', @$crispr_ids ) );
    }

    return ( 'crispr_pair', $crispr_pair );
}

=head2 crispr_group_data

retrieve crispr group given list of crispr ids

=cut
sub crispr_group_data {
    my ( $self, $crispr_ids ) = @_;

    my $crispr_group = get_crispr_group_by_crispr_ids( $self->model->schema, { crispr_ids => $crispr_ids } );

    return ( 'crispr_group', $crispr_group );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
