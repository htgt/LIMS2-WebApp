package LIMS2::Model::Schema::ResultSet::PlateReport;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::ResultSet::PlateReport::VERSION = '0.398';
}
## use critic


=head1 NAME

LIMS2::Model::Schema::ResultSet::PlateReport

=head1 DESCRIPTION

Custom resultset methods for PlateReport resultset, used to speed up plate report pages.
See LIMS2::Model::Schema::Result::PlateReport for description of the data that is gathered.

Main method is consolidate, which takes the output from the resultset and parses it into
a array of hashrefs, each of which represents data for a well on the plate.

IMPORTANT: This can only be used for single targeted reports.

=cut

use strict;
use warnings;

use List::MoreUtils qw( uniq none );
use List::Util qw( first );
use Try::Tiny;
use WebAppCommon::Util::FindGene qw( c_find_gene );

use base 'DBIx::Class::ResultSet';

=head2 consolidate

The main resultset method that parses the data into the wells array.
A lot of prefetching of data is done upfront to cut down on database queries.

=cut
sub consolidate {
    my ( $self, $plate_id, $prefetch_well_data ) = @_;

    die( 'Must specify plate_id' ) unless $plate_id;

    # prefetch plate / wells and select well data
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
    # prefetch gene sponsor data
    $self->_setup_gene_sponsors( \%data );

    my $plate_user = $plate->created_by;
    my @wells_data;
    # loop through each wells data rows and gather report data
    for my $well_id ( keys %data ) {
        push @wells_data, $self->_consolidate_well_data( $data{ $well_id }, $wells{ $well_id }, $plate_user );
    }

    return \@wells_data;
}

{
    my %projects_by_gene_id;

=head2 _setup_gene_sponsors

Gather list of all gene id's linked to the designs on plate.
Prefetch all projects linked to gene id's and store sponsor information
in hash keyed on the gene id's.

=cut
    sub _setup_gene_sponsors {
        my ( $self, $data ) = @_;
        my @gene_ids = uniq map { $_->gene_id } grep{ $_->gene_id } map{ @{ $_ } } values %{ $data };
        my $schema = $self->result_source->schema;
        my @gene_projects = $schema->resultset('Project')->search( { gene_id => { -in => \@gene_ids } } )->all;
        for my $gp ( @gene_projects ) {
            push @{ $projects_by_gene_id{ $gp->gene_id } }, $gp->sponsor_ids;
        }

        return;
    }

=head2 _get_gene_sponsors

Return sponsors for gene id

=cut
    sub _get_gene_sponsors {
        my ( $gene_id ) = @_;
        return exists $projects_by_gene_id{ $gene_id } ? @{ $projects_by_gene_id{ $gene_id } } : ();
    }
}

=head2 _consolidate_well_data

Process and merge all the rows relating to one root well returned from the PlateReport query.
The root wells are the wells on the plate being reported on.

=cut
sub _consolidate_well_data {
    my ( $self, $data, $well, $plate_user ) = @_;

    my $created_by_name
        = $plate_user->id == $well->created_by_id ? $plate_user->name : $well->created_by->name;
    # create well data hash with basic data we can get from well object
    my %well_data = (
        well           => $well,
        well_name      => $well->name,
        well_id        => $well->id,
        accepted       => $well->is_accepted,
        created_by     => $created_by_name,
        created_at     => $well->created_at->ymd,
        assay_pending  => $well->assay_pending ? $well->assay_pending->ymd : '',
        assay_complete => $well->assay_complete ? $well->assay_complete->ymd : '',
        to_report      => $well->to_report,
    );

    # call as_hash method on row objects to grab data
    my @rows = map{ $_->as_hash } @{ $data };

    # set design and gene data
    $self->_design_gene_data( \%well_data, \@rows );
    # If we have a short arm design id then use this as a the design ( gene info is the same )
    if ( my $short_arm_design_id = _get_first_process_data( \@rows, 'short_arm_design_id' ) ) {
        $well_data{design_id} = $short_arm_design_id;
    }

    # Deal with crispr data if we have any
    $well_data{crispr_ids} = _get_all_process_data( \@rows, 'crispr_id' );
    if ( $well_data{crispr_ids} ) {
        $well_data{crispr_wells} = _crispr_wells_data( \@rows );
        my $assembly_process;
        if ( $assembly_process = first{ $_->{process_type} =~ /crispr_assembly$/  } @rows ) {
            $well_data{crispr_assembly_process} = $assembly_process->{process_type};
        }
        elsif ( $assembly_process = first{ $_->{process_type} =~ /oligo_assembly$/  } @rows ) {
            $well_data{crispr_assembly_process} = $assembly_process->{process_type};
            $well_data{crispr_tracker_rna} = _get_first_process_data(\@rows, 'crispr_tracker_rna');
        }
    }

    # if we have both a crispr and design we want the backbone from the design
    # not the crispr vector, we can do this by ignoring the crispr_vector process
    if ( $well_data{crispr_ids} && $well_data{design_id} ) {
        $well_data{backbone} = _get_first_process_data( \@rows, 'backbone', [ 'crispr_vector' ] );
    }
    # otherwise the first backbone process we hit it the current backbone
    else {
        $well_data{backbone} = _get_first_process_data( \@rows, 'backbone' );
    }

    $well_data{cassette} = _get_first_process_data( \@rows, 'cassette' );
    $well_data{cassette_resistance} = _get_first_process_data( \@rows, 'cassette_resistance' );
    my $cassette_promoter = _get_first_process_data( \@rows, 'cassette_promoter' );
    $well_data{cassette_promoter}
        = $cassette_promoter ? 'promoter' : defined $cassette_promoter ? 'promoterless' : '';
    $well_data{cell_line} = _get_first_process_data( \@rows, 'cell_line' );
    $well_data{nuclease} = _get_first_process_data( \@rows, 'nuclease' );

    # we want to store all recombinase data, as the effect is cumulative
    my $recombinases = _get_all_process_data( \@rows, 'recombinase' );
    $well_data{recombinases} = join( ', ', @{ $recombinases } ) if $recombinases;

    # store array of parent wells, these are all wells which are direct ancestors ( depth 1 )
    my @parent_rows = grep { $_->{depth} == 1 } @rows;
    $well_data{parent_wells}
        = [ map { { plate_name => $_->{output_plate_name}, well_name => $_->{output_well_name} } }
            @parent_rows ];

    $well_data{well_ancestors} = _well_ancestors_by_plate_type( \@rows );
    return \%well_data;
}

=head2 _well_ancestors_by_plate_type

Store a hash of ancestor wells, keyed on plate type.
We store the first well of each plate type we find.

=cut
sub _well_ancestors_by_plate_type {
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

=head2 _get_first_process_data

Loop through the rows of process data for a well and return the first
value we get for the specified data type ( e.g design_id or cassette ).
The rows are ordered by depth from the root well, we want the get the first
value we hit because this is the current value for the well.

Can optionally ignore data from specific process types.

=cut
sub _get_first_process_data {
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

=head2 _get_all_process_data

Return a array of all the process data we find for specified type.
Can optionally ignore data from specific process types.

=cut
sub _get_all_process_data {
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

=head2 _design_gene_data

Grab design, gene and sponsor data for well.

=cut
sub _design_gene_data {
    my ( $self, $well_data, $rows ) = @_;

    # the create_di process row contains the data we need
    my $create_di_process_row = first { $_->{process_type} eq 'create_di' } @{ $rows };
    return unless $create_di_process_row; # crispr well

    $well_data->{design_id} = $create_di_process_row->{design_id};
    $well_data->{design_type} = $create_di_process_row->{design_type};
    my $gene_id = $create_di_process_row->{gene_id};
    my $gene_symbol = $create_di_process_row->{gene_symbol};

    my @gene_ids;
    if ( $gene_id && $gene_symbol ) {
        $well_data->{gene_ids} = $gene_id;
        $well_data->{gene_symbols} = $gene_symbol;
        my @sponsors = uniq _get_gene_sponsors( $gene_id );
        $well_data->{sponsors} = join( '/', @sponsors );
    }
    # no gene_id for gene_symbols stored in well data, need to to work it out ourselves
    # this data may be missing because the designs are not in the summaries table yet
    else {
        my $schema = $self->result_source->schema;
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
        $well_data->{gene_symbols} = $gene ? $gene->{gene_symbol} : 'unknown';

        my @gene_projects = $schema->resultset('Project')->search( { gene_id => { -in => \@gene_ids } } )->all;
        my @sponsors = uniq map { $_->sponsor_ids } @gene_projects;
        $well_data->{sponsors} = join( '/', @sponsors );
    }

    return;
}

=head2 _crispr_wells_data

Grab crispr ids and crispr wells.

=cut
sub _crispr_wells_data {
    my ( $rows ) = @_;

    my %crispr_wells;
    my @create_crispr_rows = grep { $_->{process_type} eq 'create_crispr' } @{ $rows };

    for my $row ( @create_crispr_rows ) {
        push @{ $crispr_wells{crisprs} }, {
            plate_name => $row->{output_plate_name},
            well_name  => $row->{output_well_name},
            crispr_id  => $row->{crispr_id},
        }
    }

    my @crispr_vector_rows = grep { $_->{process_type} eq 'crispr_vector' } @{ $rows };
    for my $row ( @crispr_vector_rows ) {
        push @{ $crispr_wells{crispr_vectors} }, {
            plate_name => $row->{output_plate_name},
            well_name  => $row->{output_well_name},
        }
    }

    return \%crispr_wells;
}

1;
