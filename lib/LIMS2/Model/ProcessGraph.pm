package LIMS2::Model::ProcessGraph;

use Moose;
use Const::Fast;
use List::MoreUtils qw( uniq );
use LIMS2::Exception::Implementation;
use Iterator::Simple qw( iter );
use namespace::autoclean;

const my $PROCESS_GRAPH_QUERY => <<'EOT';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id) AS (
    SELECT pr.id, pr_in.well_id, pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id = ?
    UNION ALL
    SELECT pr.id, pr_in.well_id, pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT process_id, input_well_id, output_well_id
FROM well_hierarchy
EOT

with 'MooseX::Log::Log4perl';

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    if ( @_ == 1 and ref $_[0] ne 'HASH' ) {
        unshift @_, 'start_with';
    }

    return $self->$orig( @_ );
};

has start_with => (
    is       => 'ro',
    isa      => 'LIMS2::Model::Schema::Result::Well',
    required => 1
);

has prefetch_process_data => (
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub {
        [ qw( process_design process_cassette process_backbone process_recombinases ) ]
    }
);

sub schema {
    shift->start_with->result_source->schema;
}

has edges => (
    is         => 'ro',
    isa        => 'ArrayRef',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_edges {
    my $self = shift;

    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare_cached( $PROCESS_GRAPH_QUERY );
            $sth->execute( $self->start_with->id );
            $sth->fetchall_arrayref;
        }
    );    
}

has _processes => (
    isa        => 'HashRef',
    init_arg   => undef,
    traits     => [ 'Hash' ],
    handles    => {
        process => 'get'
    },
    lazy_build => 1,
);

sub _build__processes {
    my $self = shift;

    my @process_ids = map { $_->[0] } @{ $self->edges };

    my $rs = $self->schema->resultset( 'Process' )->search(
        {
            'me.id' => { '-in' => \@process_ids }
        },
        {
            prefetch => $self->prefetch_process_data
        }
    );

    $self->_cache_by_id( $rs );
}

has _wells => (
    isa      => 'HashRef',
    init_arg => undef,
    traits   => [ 'Hash' ],
    handles => {
        well  => 'get',
        wells => 'values'
    },
    lazy_build => 1
);

sub _build__wells {
    my $self = shift;

    my @well_ids = uniq grep {defined} map { @{$_}[1,2] } @{ $self->edges };

    my $rs = $self->schema->resultset( 'Well' )->search(
        {
            'me.id' => { '-in' => \@well_ids }
        },
        {
            prefetch => [ 'plate' ]
        }
    );

    $self->_cache_by_id( $rs );
}

sub _cache_by_id {
    my ( $self, $rs ) = @_;
    
    my %cache;

    while ( my $r = $rs->next ) {
        $cache{ $r->id } = $r;
    }

    return \%cache;
}

sub edges_in {
    my ( $self, $node ) = @_;

    my $node_id = $node->id;
    
    grep { defined $_->[2] and $_->[2] == $node_id } @{ $self->edges };
}

sub edges_out {
    my ( $self, $node ) = @_;

    my $node_id = $node->id;

    grep { defined $_->[1] and $_->[1] == $node_id } @{ $self->edges };
}

sub input_processes {
    my ( $self, $node ) = @_;

    map { $self->process( $_->[0] ) } $self->edges_in( $node );
}

sub output_processes {
    my ( $self, $node ) = @_;

    map { $self->process( $_->[0] ) } $self->edges_out( $node );
}

sub input_wells {
    my ( $self, $node ) = @_;

    map {
        defined $_->[1] ? $self->well( $_->[1] ) : ()
    } $self->edges_in( $node );
}

sub output_wells {
    my ( $self, $node ) = @_;

    map {
        defined $_->[2] ? $self->well( $_->[2] ) : ()
    } $self->edges_out( $node );
}

sub breadth_first_traversal {
    my ( $self, $node, $direction ) = @_;

    my $neighbours;
    if ( $direction eq 'in' ) {
        $neighbours = 'input_wells';
    }
    elsif ( $direction eq 'out' ) {
        $neighbours = 'output_wells';
    }
    else {    
        LIMS2::Exception::Implementation->throw( "direction must be 'in' or 'out'" );
    }    
    
    my ( %seen, @queue );

    push @queue, $node;

    return iter sub {
        my $this_node = shift @queue;
        while ( $this_node and $seen{$this_node->as_string}++ ) {
            $this_node = shift @queue;
        }
        return unless $this_node;
        push @queue, $self->$neighbours( $this_node );
        return $this_node;
    }    
}

sub process_data_for {
    my ( $self, $well ) = @_;

    # XXX This will return the WRONG DATA for double-targeted cells.
    # We need to know whether we are retrieving data for the first
    # allele or the second allele.
    
    return map { $self->$_($well) } qw( design_id_for cassette_for backbone_for recombinases_for ); 
}

# Breadth-first search for a process with a value in the related table
# $relation.  Returns the related record. $relation should be
# something like 'process_design', 'process_cassette', etc.
sub find_process {
    my ( $self, $start_well, $relation ) = @_;

    my $it = $self->breadth_first_traversal( $start_well, 'in' );

    while( my $well = $it->next ) {
        for my $process ( $self->input_processes( $well ) ) {
            if ( my $related = $process->$relation() ) {
                return $related;
            }
        }
    }

    return;
}

sub design_id_for {
    my ( $self, $well ) = @_;

    my $process_design = $self->find_process( $well, 'process_design' );
    
    return $process_design ? $process_design->design_id : '';
}

sub cassette_for {
    my ( $self, $well ) = @_;

    my $process_cassette = $self->find_process( $well, 'process_cassette' );

    return $process_cassette ? $process_cassette->cassette : '';    
}

sub backbone_for {
    my ( $self, $well ) = @_;

    my $process_backbone = $self->find_process( $well, 'process_backbone' );

    return $process_backbone ? $process_backbone->backbone : '';
}

sub recombinases_for {
    my ( $self, $well ) = @_;

    # XXX This has a similar problem to process_data_for re. data for
    # first vs second allele. There could also be a problem with data
    # brought in from HTGT where apply_cre has been stamped at more
    # than one point in the hierarchy, even though Cre was only
    # applied once.

    my $it = $self->breadth_first_traversal( $well, 'in' );

    my @recombinases;
    
    while( my $this_well = $it->next ) {
        for my $process ( $self->input_processes( $this_well ) ) {
            my @this_recombinase = sort { $a->rank <=> $b->rank } $process->process_recombinases;
            if ( @this_recombinase > 0 ) {
                unshift @recombinases, @this_recombinase;
            }
        }
    }

    return join q{, }, map { $_->recombinase->id } @recombinases;
}

sub render {
    my ( $self, %opts ) = @_;

    require GraphViz2;
    
    my $graph = GraphViz2->new(
        edge    => { color => 'grey' },
        global  => { directed => 1   },
        node    => { shape => 'oval' },
        verbose => 0,
    );

    for my $well ( $self->wells ) {
        $self->log->debug( "Adding $well to GraphViz" );
        $graph->add_node( name => $well->as_string, label => [ $well->as_string, $self->process_data_for( $well ) ] );
    }

    for my $edge ( @{ $self->edges } ) {
        my ( $process_id, $input_well_id, $output_well_id ) = @{ $edge };
        $self->log->debug( "Adding edge $process_id to GraphVis" );
        $graph->add_edge(
            from  => defined $input_well_id ? $self->well( $input_well_id )->as_string : 'ROOT',
            to    => $self->well( $output_well_id )->as_string,
            label => $self->process( $process_id )->as_string
        );
    }

    $graph->run( %opts );

    return $opts{output_file} ? () : $graph->dot_output;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
