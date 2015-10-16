package LIMS2::WebApp::Controller::User::Graph;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Graph::VERSION = '0.345';
}
## use critic

use Moose;
use MooseX::Types::Path::Class;
use Data::UUID;
use LIMS2::Model::Util::DrawPlateGraph qw(draw_plate_graph);
use Try::Tiny;
use namespace::autoclean;
use LIMS2::Model;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::Graph - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

has graph_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    default  => sub { Path::Class::dir( '/tmp' ) }
);

has graph_format => (
    is      => 'ro',
    isa     => 'Str',
    default => 'svg'
);

has graph_content_type => (
    is      => 'ro',
    isa     => 'Str',
    default =>  'image/svg+xml'
);

has graph_filename => (
    is      => 'ro',
    isa     => 'Str',
    default => 'graph.svg'
);

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $plate_name  = $c->req->param('plate_name');
    my $well_name   = $c->req->param('well_name');
    my $graph_type  = $c->req->param('graph_type') || 'descendants';
    my $crisprs     = $c->req->param('crisprs');

    my $pr_plate_name = $c->req->param('pr_plate_name');
    my $pr_graph_type = $c->req->param('pr_graph_type') || 'both';

    $c->stash(
        plate_name  => $plate_name,
        well_name   => $well_name,
        graph_type  => $graph_type,
        pr_plate_name => $pr_plate_name,
        pr_graph_type => $pr_graph_type,
        crisprs     => $crisprs,
    );

    return unless $c->req->param('go');

    # Handle request for plate relation graph
    if ($c->req->param('go') eq 'go_plate'){
    	if ( ! $pr_plate_name ){
    		$c->stash( error_msg => 'Please enter a plate name');
    		return;
    	}

    	if ( ! $pr_graph_type ){
    		$c->stash( error_msg => "Please select 'ancestors', 'descendants' or 'both'");
    		return;
    	}

        my $plate;
        try{
            $plate = $c->model('Golgi')->retrieve_plate({ name => $pr_plate_name });
        };

        unless($plate){
            $c->stash( error_msg => "Plate $pr_plate_name not found" );
            return;
        }

    	try{
    	    my $uuid = $self->_write_plate_graph($pr_plate_name, $pr_graph_type);
    	    $c->stash( graph_uri => $c->uri_for( "/user/graph/render/$uuid" ) );
    	}
    	catch{
    		$c->stash( error_msg => 'Error generating plate relation graph for plate: ' . $_);
    	};

    	return;
    }

    # Or generate a well relation graph
    if ( ! $plate_name || ! $well_name ) {
        $c->stash( error_msg => 'Please enter a plate name and well name' );
        return;
    }

    if ( $graph_type ne 'ancestors' && $graph_type ne 'descendants' ) {
        $c->stash( error_msg => "Please select 'ancestors' or 'descendants'" );
        return;
    }

    my $plate;
    try{
        $plate = $c->model('Golgi')->retrieve_plate({ name => $plate_name });
    };

    unless($plate){
        $c->stash( error_msg => "Plate $plate_name not found" );
        return;
    }

    my $well;
    try{
        $well = $c->model('Golgi')->retrieve_well( { plate_name => $plate_name, well_name => $well_name } );
    };

    unless($well){
        $c->stash( error_msg => "Well $well_name not found on plate $plate_name");
        return;
    }

    # If the well has no design, it means its a crispr already, so no need to include crisprs
    my $has_design;
    try{
        $well->design->id;
        $has_design = 1;
    }
    catch{
        $has_design = 0;
    };

    my $uuid;

    # include crispr plates?
    if ( $crisprs && $has_design) {
        $uuid = $self->_write_crispr_graph( $c, $well, $graph_type );
    } else {
        $uuid = $self->_write_graph( $c, $well, $graph_type );
    }

    $c->stash( graph_uri => $c->uri_for( "/user/graph/render/$uuid" ) );

    return;
}

sub _write_graph {
    my ( $self, $c, $well, $graph_type ) = @_;

    my $uuid = Data::UUID->new->create_str;

    my $output_dir = $self->graph_dir->subdir( $uuid );
    $output_dir->mkpath;

    my $graph = $well->$graph_type();

    $graph->render( output_file => $output_dir->file( $self->graph_filename )->stringify, format => $self->graph_format );

    return $uuid;
}

sub render :Path( '/user/graph/render' )  :Args(1) {
    my ( $self, $c, $uuid ) = @_;

    my $file = $self->graph_dir->subdir( $uuid )->file( $self->graph_filename );

    my $sb = $file->stat;
    my $fh = $file->openr;

    $c->response->content_type( $self->graph_content_type );
    $c->response->content_length( $sb->size );
    $c->response->body( $fh );

    return;
}

sub _write_plate_graph{
	my ($self, $plate_name, $type)  = @_;

    my $uuid = Data::UUID->new->create_str;
    my $output_dir = $self->graph_dir->subdir( $uuid );
    $output_dir->mkpath;
    my $output_file = $output_dir->file( $self->graph_filename )->stringify;
    draw_plate_graph($plate_name, $type, $output_file );

    return $uuid;
}

sub _write_crispr_graph {
    my ( $self, $c, $original_well, $graph_type ) = @_;

    my $design_id = $original_well->design->id;

    my @wells = $c->model('Golgi')->get_crispr_wells_for_design( $design_id );
    unshift @wells, $original_well;

    my $uuid = Data::UUID->new->create_str;

    my $output_dir = $self->graph_dir->subdir( $uuid );
    $output_dir->mkpath;

    my @pgraphs;
    foreach my $well (@wells) {
        push @pgraphs, $well->$graph_type();
    }

    render_crispr( { output_file => $output_dir->file( $self->graph_filename )->stringify, format => $self->graph_format} , \@pgraphs);

    return $uuid;
}

sub render_crispr {
    my ( $opts, $pgraphs_ref ) = @_;

    require GraphViz2;

    my %opts = %{$opts};
    my @pgraphs = @{$pgraphs_ref};

    my $graph = GraphViz2->new(
        edge    => { color => 'grey' },
        global  => { directed => 1   },
        node    => { shape => 'oval' },
        verbose => 0,
    );

    my %seen_process;

    # URL attribute is not working properly because the basapath on the webapp is sanger.ac.uk/htgt/lims2 ... temporary fix
    foreach my $pgraph (@pgraphs) {
        for my $well ( $pgraph->wells ) {
            $pgraph->log->debug( "Adding $well to GraphViz" );
            $graph->add_node(
                name   => $well->as_string,
                label  => [ $well->as_string, 'Plate Type: ' . $well->plate->type_id, LIMS2::Model::ProcessGraph::process_data_for($well) ],
                URL    => "/htgt/lims2/user/view_plate?id=" . $well->plate->id,
                target => '_blank',
            );
        }

        for my $edge ( @{ $pgraph->edges } ) {
            my ( $process_id, $input_well_id, $output_well_id ) = @{ $edge };
            next if $seen_process{$process_id}{$input_well_id}{$output_well_id}++;
            $pgraph->log->debug( "Adding edge $process_id to GraphViz" );
            $graph->add_edge(
                from  => defined $input_well_id ? $pgraph->well( $input_well_id )->as_string : 'ROOT',
                to    => $pgraph->well( $output_well_id )->as_string,
                label => $pgraph->process( $process_id )->as_string
            );
        }
    }

    $graph->run( %opts );

    return $opts{output_file} ? () : $graph->dot_output;

}


=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
