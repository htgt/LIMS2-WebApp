package LIMS2::Model::ProcessGraph;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::ProcessGraph::VERSION = '0.388';
}
## use critic


use Moose;
use Const::Fast;
use List::MoreUtils qw( uniq any );
use LIMS2::Exception::Implementation;
use LIMS2::Model::Types qw( ProcessGraphType );
use Log::Log4perl qw( :easy );
use Iterator::Simple qw( iter );
use namespace::autoclean;
use Data::Dumper;

const my $QUERY_DESCENDANTS => <<'EOT';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id) AS (
    SELECT pr.id, pr_in.well_id, pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id = ?
    UNION
    SELECT pr.id, pr_in.well_id, pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT process_id, input_well_id, output_well_id
FROM well_hierarchy
EOT

const my $QUERY_ANCESTORS => <<'EOT';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id) AS (
     SELECT pr.id, pr_in.well_id, pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     WHERE pr_out.well_id = ?
     UNION
     SELECT pr.id, pr_in.well_id, pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
)
SELECT process_id, input_well_id, output_well_id
FROM well_hierarchy;
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
    required => 1,
    weak_ref => 1,
);

has type => (
    is      => 'ro',
    isa     => ProcessGraphType,
    default => 'descendants'
);

has prefetch_process_data => (
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub {
        [ 'process_design',
          { 'process_cassette' => 'cassette' },
          { 'process_backbone' => 'backbone' },
          'process_recombinases',
          'process_global_arm_shortening_design',
      ]
    }
);

has prefetch_well_data => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [
            { 'plate' => 'type' }
        ]
    }
);

sub schema {
    return shift->start_with->result_source->schema;
}

has edges => (
    is         => 'ro',
    isa        => 'ArrayRef',
    init_arg   => 'edges',
    lazy_build => 1
);

sub _build_edges {
    my $self = shift;

    my $query;

    if ( $self->type eq 'descendants' ) {
        $query = $QUERY_DESCENDANTS;
    }
    elsif ( $self->type eq 'ancestors' ) {
        $query = $QUERY_ANCESTORS;
    }
    else {
        LIMS2::Exception::Implementation->throw( "Invalid graph type '" . $self->type . "'" );
    }

    return $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare_cached( $query );
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

    return $self->_cache_by_id( $rs );
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

    return $self->_cache_by_id( $rs );
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

    return unless $node;

    my $node_id = $node->id;

    return grep { defined $_->[2] and $_->[2] == $node_id } @{ $self->edges };
}

sub edges_out {
    my ( $self, $node ) = @_;

    return unless $node;

    my $node_id = $node->id;

    return grep { defined $_->[1] and $_->[1] == $node_id } @{ $self->edges };
}

sub input_processes {
    my ( $self, $node ) = @_;

    return map { $self->process( $_->[0] ) } $self->edges_in( $node );
}

sub output_processes {
    my ( $self, $node ) = @_;

    return map { $self->process( $_->[0] ) } $self->edges_out( $node );
}

sub input_wells {
    my ( $self, $node ) = @_;

    return map {
        defined $_->[1] ? $self->well( $_->[1] ) : ()
    } $self->edges_in( $node );
}

sub output_wells {
    my ( $self, $node ) = @_;

    return map {
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

sub depth_first_traversal {
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
        my $this_node = pop @queue;
        while ( $this_node and $seen{$this_node->as_string}++ ) {
            $this_node = pop @queue;
        }
        push @queue, $self->$neighbours( $this_node );
        return $this_node;
    }
}

# Breadth-first search for a process with a value in the related table
# $relation.  Returns the related record. $relation should be
# something like 'process_design', 'process_cassette', etc.
sub find_process {
    my ( $self, $start_well, $relation, $args ) = @_;

    TRACE( "find_process searching for relation $relation" );

    # setup processes to ignore if any
    my @ignore_processes;
    if ( $args && exists $args->{ignore_processes} ) {
        @ignore_processes = @{ $args->{ignore_processes} };
    }

    my $it = $self->breadth_first_traversal( $start_well, 'in' );

    while( my $well = $it->next ) {
        TRACE( "find_process examining $well" );
        for my $process ( $self->input_processes( $well ) ) {
            if ( my $related = $process->$relation() ) {
                next if @ignore_processes && any { $_ eq $process->type_id } @ignore_processes;

            	# Don't return $related if it is an empty resultset
            	next if ($related->isa("DBIx::Class::ResultSet") and $related->count == 0 );

                TRACE( "Found $relation at $well (process ".$process->id.")" );
                return $related;
            }
        }
    }

    return;
}

# Similar to find_process but looks for process type instead of process relation
sub find_process_of_type{
    my ($self, $start_well, $type ) = @_;

    TRACE( "find_process_of_type searching for type $type" );

    my $it = $self->breadth_first_traversal( $start_well, 'in' );

    while( my $well = $it->next ) {
        TRACE( "find_process_of_type examining $well" );
        for my $process ( $self->input_processes( $well ) ) {
            if ( $process->type_id eq $type ) {
                TRACE( "Found $type at $well (process ".$process->id.")" );
                return $process;
            }
        }
    }
    return;
}

sub process_data_for {
    my ( $well ) = shift;

    my @processes = $well->output_processes;

    my @data;
    for my $p ( @processes ) {
        # Ignoring process_bacs
        if ( $p->process_backbone ) {
            push @data, 'Backbone: ' . $p->process_backbone->backbone->name;
        }
        if ( $p->process_cassette ) {
            push @data, 'Cassette: ' . $p->process_cassette->cassette->name;
        }
        if ( $p->process_cell_line ) {
            push @data, 'Cell line: ' . $p->process_cell_line->cell_line->name;
        }
        if ( $p->process_nuclease ) {
            push @data, 'Nuclease: ' . $p->process_nuclease->nuclease->name;
        }
        if ( $p->process_design ) {
            my $design = $p->process_design->design;
            push @data, 'Design: ' . $design->id;
            my @genes = $design->genes;
            if ( @genes ) {
                push @data, 'Genes: ' . join( q{, }, map { $_->gene_id } @genes );
            }
        }
        if ( $p->process_crispr ) {
            my $crispr = $p->process_crispr->crispr;
            push @data, 'Crispr: ' . $crispr->id;
        }
        if ( my @recombinases = $p->process_recombinases ) {
            push @data, 'Recombinases: ' . join( q{, }, map { $_->recombinase_id } @recombinases );
        }
        if ( $p->process_global_arm_shortening_design ) {
            push @data, 'Global Arm Shorten Design: ' . $p->process_global_arm_shortening_design->design_id;
        }
        foreach my $param ($p->process_parameters){
            push @data, $param->parameter_name.': '.$param->parameter_value;
        }
    }

    return @data;
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

    # URL attribute is not working properly because the basapath on the webapp is sanger.ac.uk/htgt/lims2 ... temporary fix
    for my $well ( $self->wells ) {
        $self->log->debug( "Adding $well to GraphViz" );
        my @labels = ( $well->as_string, 'Plate Type: ' . $well->last_known_plate->type_id );
        if($well->barcode){
            push @labels, 'Barcode: '.$well->barcode;
            push @labels, 'State: '.$well->barcode_state->id;
            push @labels, 'Old Location: '.$well->last_known_location_str;
        }
        push @labels, process_data_for($well);
        my $url = ( $well->plate ? "/htgt/lims2/user/view_plate?id=" . $well->plate->id
                                 : "/htgt/lims2/user/scan_barcode?barcode=". $well->barcode );
        $graph->add_node(
            name   => $well->as_string,
            label  => \@labels,
            URL    => $url,
            target => '_blank',
        );
    }

    my %seen_process;
    for my $edge ( @{ $self->edges } ) {
        my ( $process_id, $input_well_id, $output_well_id ) = @{ $edge };
        next if $seen_process{$process_id}{$input_well_id}{$output_well_id}++;
        $self->log->debug( "Adding edge $process_id to GraphViz" );
        $graph->add_edge(
            from  => defined $input_well_id ? $self->well( $input_well_id )->as_string : 'ROOT',
            to    => $self->well( $output_well_id )->as_string,
            label => $self->process( $process_id )->as_string
        );
    }

    $graph->run( %opts );

    return $opts{output_file} ? () : $graph->dot_output;
}

# version of depth_first_traversal that returns distinct trails to each leaf node
sub depth_first_traversal_with_trails {
    my ($self, $node, $well_list, $current_trail, $all_trails, $depth) = @_;

    $depth++;

    $well_list = [] unless $well_list;

    # add the current node onto the well list and current trail
    push( @{$well_list}, $node);
    push @{$current_trail}, $node;

    my @outputs = $self->output_wells($node);

    if(scalar(@outputs) == 0){
        #  add the current trail (now 'complete') onto the list of all complete trails
        push @{$all_trails}, $current_trail;
    }else{
        # send a copy of the current trail array to each child
        foreach my $output_well (@outputs){
            my @current_trail_copy = @{$current_trail};
             $self->depth_first_traversal_with_trails ($output_well, $well_list, \@current_trail_copy, $all_trails, $depth);
        }
    }
    return ($well_list, $all_trails);
}

__PACKAGE__->meta->make_immutable;

1;

__END__
