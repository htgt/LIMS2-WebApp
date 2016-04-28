package LIMS2::Model::Util::DrawPlateGraph;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::DrawPlateGraph::VERSION = '0.397';
}
## use critic


use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use Log::Log4perl qw( :easy );
use GraphViz2;
use List::MoreUtils qw( uniq );
use Data::Dumper;

use Sub::Exporter -setup => {
    exports => [
        qw(
            draw_plate_graph
          )
    ]
};

my %seen_edge;
my %orig_names_for;

=item draw_plate_graph(<plate_name>)

Construct a graph of plate ancestors and descendants and render it to <plate_name>.svg

=cut

sub draw_plate_graph{
    my ($plate_name, $type, $filename) = @_;

    # Use some defaults if output file and graph type not specified
    $type ||= "both";
    $filename ||= $plate_name.".svg";

    %seen_edge = ();
    %orig_names_for = ();

    my ($graph) = GraphViz2->new( global => {
	                                  directed => 1,
	                                  record_orientation => 'horizontal',
                                  },
                                  graph => {
                                      landscape => 'false',
                                      concentrate => 'true',
                                  },
	                         );

    my $model = LIMS2::Model->new( user => 'lims2' );


    my $plate = $model->retrieve_plate({ name => $plate_name });

    $graph->add_node( name => condense_seq_plate_names($plate_name), color => 'red' );

    if ($type eq "ancestors"){
        add_ancestors($graph,$plate);
    }
    elsif ($type eq "descendants"){
        add_descendants($graph, $plate);
    }
    elsif ($type eq "both"){
    	add_ancestors($graph,$plate);
    	add_descendants($graph, $plate);
    }
    else {
    	die "Unrecognized graph type $type requested";
    }

    # Add orig plate name lists to condensed nodes
    foreach my $condensed_node (keys %orig_names_for){
    	$graph->add_node(
    	                  name => $condensed_node,
    	                  label => join "\\n", uniq sort @{ $orig_names_for{$condensed_node} },
    	                 );
    }

    $graph->run(format => "svg", output_file => $filename);
    return $filename;
}

sub add_ancestors{
    my ($graph, $plate, $seen) = @_;

    $seen ||= {};

    return if $seen->{$plate->name};

    DEBUG "Adding ancestors of $plate to graph";

    $seen->{$plate->name}++;

    my $parents = $plate->parent_plates_by_process_type;

    foreach my $type (keys %{ $parents || {} }){
    	foreach my $parent_plate_name (keys %{ $parents->{$type}  }){

    		# ARGS: graph, input, output, process type
    		add_edge($graph, $parent_plate_name, $plate->name, $type);

    		add_ancestors($graph, $parents->{$type}->{$parent_plate_name}, $seen);
    	}
    }
    return;
}

sub add_descendants{
    my ($graph, $plate, $seen) = @_;

    $seen ||= {};

    return if $seen->{$plate->name};

    DEBUG "Adding descendants of $plate to graph";

    $seen->{$plate->name}++;

    my $children = $plate->child_plates_by_process_type;

    foreach my $type (keys %{ $children || {} }){
    	foreach my $child_plate_name (keys %{ $children->{$type}  }){

    		# ARGS: graph, input, output, process type
    		add_edge($graph, $plate->name, $child_plate_name, $type);

    		add_descendants($graph, $children->{$type}->{$child_plate_name}, $seen);
    	}
    }
    return;
}

sub condense_seq_plate_names{
	my ($name) = @_;

	my $orig_name = $name;

	# e.g. MOHSA60001_A_1 -> MOHSA6001_A_x
	# to reduce number of nodes created for sequencing plates
	my $changed = ($name =~ s/^([A-Z0-9]+_[A-Z])_[0-9]$/$1_x/g);

    if ($changed){
     	$orig_names_for{$name} ||= [];
     	push @{ $orig_names_for{$name} }, $orig_name;
    }

	return $name;
}

sub add_edge{
	my ($graph, $input_name, $output_name, $type) = @_;

    my $input = condense_seq_plate_names($input_name);
    my $output = condense_seq_plate_names($output_name);
    my $edge_name = $input.$type.$output;
    return if $seen_edge{$edge_name};
    $seen_edge{$edge_name}++;

    DEBUG "Process type: $type";
    $graph->add_edge(
    	from => $input,
    	to => $output,
    	label => $type,
    );

    return;
}

1;
