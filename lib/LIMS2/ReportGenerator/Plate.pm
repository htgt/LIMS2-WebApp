package LIMS2::ReportGenerator::Plate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::Plate::VERSION = '0.195';
}
## use critic


use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;
use LIMS2::Exception::Implementation;
use Module::Pluggable::Object;
use List::MoreUtils qw( uniq );
use Try::Tiny;
use Log::Log4perl qw( :easy );
use namespace::autoclean;
use Time::HiRes qw(time);
use Data::Dumper;

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
        if (my $design = $well->design){
            foreach my $crispr_design ($design->crispr_designs){
                $well_ref->{ $crispr_design->id } = {};
                my $crispr_design_ref = $well_ref->{ $crispr_design->id };
                if(my $crispr = $crispr_design->crispr){
                    $crispr_design_ref->{sinlge} = [ $crispr->crispr_wells ];
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

sub base_columns {
    confess "base_columns() must be implemented by a subclass";
}

sub base_data {
    confess "base_data() must be implemented by a subclass";
}

sub accepted_crispr_columns {
    return ("Accepted Crispr Single", "Accepted Crispr Pairs");
}

sub _find_accepted_vector_wells{
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

sub accepted_crispr_data {
    my ( $self, $well ) = @_;

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

        my @left_accepted = $self->_find_accepted_vector_wells(\@left_cr_wells);
        my @right_accepted = $self->_find_accepted_vector_wells(\@right_cr_wells);
        if (@left_accepted and @right_accepted){
            my $left_as_string = join( q{/}, map {$_->as_string} @left_accepted);
            my $right_as_string = join( q{/}, map {$_->as_string} @right_accepted);
            my $pair_as_string = "[left:$left_as_string-right:$right_as_string]";
            push @paired_crisprs, $pair_as_string;
        }
    }

    # Handle the single crisprs for this well
    @single_crisprs = $self->_find_accepted_vector_wells(\@single_cr_wells);

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
    my @sponsors = uniq map { $_->sponsor_id } @gene_projects;

    return ( $design->id, join( q{/}, @gene_ids ), join( q{/}, @gene_symbols ), join( q{/}, @sponsors ) );
}

sub qc_result_cols {
    my ( $self, $well ) = @_;

    my $result = $well->well_qc_sequencing_result;

    if ( $result ) {
        return (
            $result->test_result_url,
            $result->valid_primers,
            $self->boolean_str( $result->mixed_reads ),
            $self->boolean_str( $result->pass )
        );
    }

    return ('')x4;
}

sub ancestor_cols {
    my ( $self, $well, $plate_type ) = @_;

    my $ancestors = $well->ancestors->depth_first_traversal($well, 'in');

    while ( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate->type_id eq $plate_type ) {
            return (
                $ancestor->as_string,
                $self->qc_result_cols( $ancestor )
            );
        }
    }

    return ('')x5;
}

sub pick_counts {
    my ( $self, $well, $pick_type ) = @_;

    # XXX This assumes the picked wells are immediate descendants of
    # $well: we aren't doing a full traversal.
    my @picks = grep { $_->plate->type_id eq $pick_type }
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

    my %symbols;
    my (@design_ids, @gene_ids);

    foreach my $design ($crispr->related_designs){
        $self->_symbols_from_design($design, \%symbols);
        push @design_ids, $design->id;
        push @gene_ids,  map { $_->gene_id } $design->genes;
    }

    my @gene_projects = $self->model->schema->resultset('Project')->search({ gene_id => { -in => \@gene_ids }})->all;
    my @sponsors = uniq map { $_->sponsor_id } @gene_projects;

    return (
        join( q{/}, uniq @design_ids ),
        join( q{/}, uniq @gene_ids ),
        join( q{/}, keys %symbols ),
        join( q{/}, @sponsors )
    );
}

sub _symbols_from_design{
    my ($self, $design, $symbols) = @_;

    my @gene_ids      = uniq map { $_->gene_id } $design->genes;
    my @gene_symbols;
    try {
        @gene_symbols  = uniq map {
            $self->model->retrieve_gene( { species => $self->species, search_term => $_ } )->{gene_symbol}
        } @gene_ids;
    };

    # Add any symbols we found to the hash
    foreach my $symbol (@gene_symbols){
        $symbols->{$symbol} = 1;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
