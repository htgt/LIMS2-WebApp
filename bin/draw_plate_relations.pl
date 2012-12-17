#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use Log::Log4perl qw( :easy );
use GraphViz2;

Log::Log4perl->easy_init($DEBUG);

my $plate_name = $ARGV[0];

my ($graph) = GraphViz2->new( global => {
	                              directed => 1, 
	                              record_orientation => 'horizontal',
                              },
                              graph => {
                                  landscape => 'false', 	  
                              }
	                         );

my $model = LIMS2::Model->new( user => 'tasks' );

my $plate = $model->retrieve_plate({ name => $plate_name });

$graph->add_node( name => $plate_name, color => 'red' );

add_ancestors($graph,$plate);
add_descendants($graph, $plate);

$graph->run(format => "svg", output_file => $plate_name.".svg");

sub add_ancestors{
    my ($graph, $plate, $seen) = @_;
    
    $seen ||= {};
    
    return if $seen->{$plate->name};
    
    DEBUG "Adding ancestors of $plate to graph";
    
    $seen->{$plate->name}++;
    
    my $parents = $plate->parent_plates_by_process_type;
    
    foreach my $type (keys %{ $parents || {} }){
    	foreach my $parent_plate_name (keys %{ $parents->{$type}  }){
    		DEBUG "Process type: $type";
    		$graph->add_edge( 
    		    from => $parent_plate_name, 
    		    to => $plate->name, 
    		    label => $type, 
    		);
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
    		DEBUG "Process type: $type";
    		$graph->add_edge( 
    		    from => $plate->name, 
    		    to => $child_plate_name, 
    		    label => $type, 
    		);
    		add_descendants($graph, $children->{$type}->{$child_plate_name}, $seen);
    	}
    }
    return;	
}


