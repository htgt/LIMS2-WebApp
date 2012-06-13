package LIMS2::Model::ProcessGraph;

use Moose;
use Const::Fast;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

const my $PROCESS_GRAPH_QUERY => <<'EOT';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id) AS (
    SELECT pr.id, pr_in.well_id, pr_out.well_id
    FROM processes pr
    JOIN processes_output_wells pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN processes_input_wells pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id = ?
    UNION ALL
    SELECT pr.id, pr_in.well_id, pr_out.well_id
    FROM processes pr
    JOIN processes_output_wells pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN processes_input_wells pr_in ON pr_in.process_id = pr.id
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
        $graph->add_node( name => $well->full_name );
    }

    for my $edge ( @{ $self->edges } ) {
        my ( $process_id, $input_well_id, $output_well_id ) = @{ $edge };
        $self->log->debug( "Adding edge $process_id to GraphVis" );
        $graph->add_edge(
            from  => defined $input_well_id ? $self->well( $input_well_id )->full_name : 'ROOT',
            to    => $self->well( $output_well_id )->full_name,
            label => $self->process( $process_id )->type
        );
    }

    $graph->run( %opts );

    return $opts{output_file} ? () : $graph->dot_output;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
