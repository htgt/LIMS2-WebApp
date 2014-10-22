package LIMS2::Model::Schema::ResultSet::PlateReport;
use strict;
use warnings;

use List::MoreUtils qw( uniq none );
use List::Util qw( first );
use Try::Tiny;
use WebAppCommon::Util::FindGene qw( c_find_gene );

use base 'DBIx::Class::ResultSet';

# NOTE - does not work for double targeted plates / well

# TODO tidy this up
sub consolidate {
    my ( $self, $plate_id, $prefetch_well_data ) = @_;

    unless ( $plate_id ) {
        die( 'Must specify plate_id' );
    }

    my @prefetch = ( 'well_accepted_override' );
    if ( $prefetch_well_data ) {
        push @prefetch, @{ $prefetch_well_data };
    }
    my $plate = $self->result_source->schema->resultset( 'Plate' )->find(
        {
            id => $plate_id,
        },
        {
            prefetch => { wells => \@prefetch },
        }
    );
    my %wells = map{ $_->id => $_ } $plate->wells->all;

    my %data;
    while ( my $r = $self->next ) {
        push @{ $data{ $r->root_well_id } }, $r;
    }

    my $plate_user = $plate->created_by;
    my @wells_data;
    for my $well_id ( keys %data ) {
        push @wells_data, $self->consolidate_well_data( $data{ $well_id }, $wells{ $well_id }, $plate_user );
    }

    return \@wells_data;
}

sub consolidate_well_data {
    my ( $self, $data, $well, $plate_user ) = @_;

    my $created_by_name
        = $plate_user->id == $well->created_by_id ? $plate_user->name : $well->created_by->name;
    my %well_data = (
        well           => $well,
        well_name      => $well->name,
        well_id        => $well->id,
        accepted       => $well->is_accepted,
        created_by     => $created_by_name,
        created_at     => $well->created_at->ymd,
        assay_pending  => $well->assay_pending ? $well->assay_pending->ymd : '',
        assay_complete => $well->assay_complete ? $well->assay_complete->ymd : '',
    );

    # TODO make sure its sorted by depth?
    my @rows = map{ $_->as_hash } @{ $data };

    $self->design_gene_data( \%well_data, \@rows );

    # If we have a short arm design id then use this as a the design ( gene info is the same )
    if ( my $short_arm_design_id = get_data( \@rows, 'short_arm_design_id' ) ) {
        $well_data{design_id} = $short_arm_design_id;
    }

    $well_data{crispr_ids} = get_multiple_data( \@rows, 'crispr_id' );
    $well_data{crispr_wells} = crispr_wells_data( \@rows ) if $well_data{crispr_ids};

    # if we have both a crispr and design we want the backbone from the design
    if ( $well_data{crispr_ids} && $well_data{design_id} ) {
        $well_data{backbone} = get_data( \@rows, 'backbone', [ 'crispr_vector' ] );
    }
    else {
        $well_data{backbone} = get_data( \@rows, 'backbone' );
    }

    $well_data{cassette} = get_data( \@rows, 'cassette' );
    $well_data{cassette_resistance} = get_data( \@rows, 'cassette_resistance' );
    my $cassette_promoter = get_data( \@rows, 'cassette_promoter' );
    $well_data{cassette_promoter} = $cassette_promoter ? 'promoter' : 'promoterless';

    $well_data{cell_line} = get_data( \@rows, 'cell_line' );
    $well_data{nuclease} = get_data( \@rows, 'nuclease' );
    my $recombinases = get_multiple_data( \@rows, 'recombinase' );
    $well_data{recombinases} = join( ', ', @{ $recombinases } ) if $recombinases;

    my @parent_rows = grep { $_->{depth} == 1 } @rows;
    $well_data{parent_wells}
        = [ map { { plate_name => $_->{output_plate_name}, well_name => $_->{output_well_name} } }
            @parent_rows ];

    $well_data{well_ancestors} = well_ancestors_by_plate_type( \@rows );
    return \%well_data;
}

sub well_ancestors_by_plate_type {
    my ( $rows ) = @_;
    my %ancestors;

    for my $row ( @{ $rows } ) {
        next if exists $ancestors{ $row->{output_plate_type} };

        $ancestors{ $row->{output_plate_type} } = {
            well_id    => $row->{output_well_id},
            well_name  => $row->{output_plate_name} . '_' . $row->{output_well_name},
        };
    }

    return \%ancestors;
}

sub get_data {
    my ( $rows, $data_type, $ignore_process_types ) = @_;

    my $row;
    if ( $ignore_process_types ) {
        my @filtered_rows;
        for my $row ( @{ $rows } ) {
            push @filtered_rows, $row if none { $_ eq $row->{process_type} } @{ $ignore_process_types };
        }
        $row = first{ $_->{$data_type} } @filtered_rows;
    }
    else {
        $row = first{ $_->{$data_type} } @{ $rows };
    }

    return $row ? $row->{$data_type} : undef;
}

sub get_multiple_data {
    my ( $rows, $data_type, $ignore_process_types ) = @_;

    my @matched_rows;
    if ( $ignore_process_types ) {
        my @filtered_rows;
        for my $row ( @{ $rows } ) {
            push @filtered_rows, $row if none { $_ eq $row->{process_type} } @{ $ignore_process_types };
        }
        @matched_rows = grep { $_->{$data_type} } @filtered_rows;
    }
    else {
        @matched_rows = grep { $_->{$data_type} } @{ $rows };
    }

    return @matched_rows ? [ map{ $_->{$data_type} } @matched_rows ] : undef;
}

sub design_gene_data {
    my ( $self, $well_data, $rows ) = @_;
    my $schema = $self->result_source->schema;

    # the create_di process row contains the data we need
    my $create_di_process_row = first { $_->{process_type} eq 'create_di' } @{ $rows };
    return unless $create_di_process_row; # crispr well

    $well_data->{design_id} = $create_di_process_row->{design_id};
    my $gene_id = $create_di_process_row->{gene_id};
    my $gene_symbol = $create_di_process_row->{gene_symbol};

    my @gene_ids;
    if ( $gene_id && $gene_symbol ) {
        $well_data->{gene_ids} = $gene_id;
        $well_data->{gene_symbols} = $gene_symbol;
        push @gene_ids, $gene_id;
    }
    else {

        my $design = $schema->resultset('Design')->find( { id => $well_data->{design_id} } );
        @gene_ids = uniq map { $_->gene_id } $design->genes;

        my $gene;
        try {
            $gene = c_find_gene(
                {   species     => $design->species_id,
                    search_term => $gene_ids[0],
                }
            );
        };
        $well_data->{gene_ids} = join( '/', @gene_ids );
        $well_data->{gene_symbol} = $gene ? $gene->{gene_symbol} : 'unknown';
    }

    my @gene_projects = $schema->resultset('Project')->search( { gene_id => { -in => \@gene_ids } } )->all;
    my @sponsors = uniq map { $_->sponsor_id } @gene_projects;

    $well_data->{sponsors} = join( '/', @sponsors );

    return;
}

sub crispr_wells_data {
    my ( $rows ) = @_;

    my @crispr_wells;
    my @create_crispr_rows = grep { $_->{process_type} eq 'create_crispr' } @{ $rows };

    for my $row ( @create_crispr_rows ) {
        push @crispr_wells, {
            plate_name => $row->{output_plate_name},
            well_name  => $row->{output_well_name},
            crispr_id  => $row->{crispr_id},
        }
    }

    return \@crispr_wells;
}

1;
