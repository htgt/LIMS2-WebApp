package LIMS2::ReportGenerator::Plate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::Plate::VERSION = '0.173';
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

extends qw( LIMS2::ReportGenerator );

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

sub accepted_crispr_data {
    my ( $self, $well ) = @_;

    my (@single_crisprs, @paired_crisprs);

    if (my $design = $well->design){
        foreach my $crispr_design ($design->crispr_designs){
            if(my $crispr = $crispr_design->crispr){
                push @single_crisprs, $crispr->accepted_vector_wells;
            }
            elsif(my $crispr_pair = $crispr_design->crispr_pair){
                my @left_crisprs = $crispr_pair->left_crispr->accepted_vector_wells;
                my @right_crisprs = $crispr_pair->right_crispr->accepted_vector_wells;
                if (@left_crisprs and @right_crisprs){
                    my $left_as_string = join( q{/}, map {$_->as_string} @left_crisprs);
                    my $right_as_string = join( q{/}, map {$_->as_string} @right_crisprs);
                    my $pair_as_string = "[left:$left_as_string-right:$right_as_string]";
                    push @paired_crisprs, $pair_as_string;
                }
            }
        }
    }
    else{
        LIMS2::Exception::Implementation->throw("Cannot find design for well ".$well->as_string);
    }
    return (
        join( q{/}, map {$_->as_string} @single_crisprs ),
        join( q{ }, @paired_crisprs ),
    );
}

sub design_and_gene_cols {
    my ( $self, $well ) = @_;

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
