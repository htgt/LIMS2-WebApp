package LIMS2::WebApp::Controller::PublicAPI;

use Moose;
use LIMS2::Report;
use Try::Tiny;
use LIMS2::Util::TraceServer;
use Bio::SCF;
use Bio::Perl qw( revcom );
use namespace::autoclean;
use LIMS2::Model::Util::MutationSignatures qw(get_mutation_signatures_barcode_data);
use LIMS2::Model::Util::CrisprESQCView qw(ep_pick_is_het crispr_damage_type_for_ep_pick);
use Data::Dumper;
use JSON;
with "MooseX::Log::Log4perl";

BEGIN {extends 'Catalyst::Controller::REST'; }

has traceserver => (
    is         => 'ro',
    isa        => 'LIMS2::Util::TraceServer',
    lazy_build => 1,
);

sub _build_traceserver {
    return LIMS2::Util::TraceServer->new;
}

sub trace_data : Path( '/public_api/trace_data' ) : Args(0) : ActionClass( 'REST' ) {
}

sub trace_data_GET{
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    $self->log->debug( "Finding trace for '" . $params->{name} . "'" );
    my $trace;
    my $traceserver_error;
    try{
        $trace = $self->traceserver->get_trace( $params->{name}, $params->{version} );
    }
    catch{
        $traceserver_error = $_;
    };

    if($traceserver_error){
        return $self->status_bad_request($c, message => $traceserver_error);
    }

    my $fh = $self->traceserver->write_temp_file( $trace );
    tie my %scf, 'Bio::SCF', $fh;

    my $seq = join "", @{ $scf{bases} };
    $params->{search_seq} = revcom( $params->{search_seq} )->seq if $params->{reverse};

    my ( $match, @rest ) = $self->_get_matches( $seq, $params->{search_seq} );

    # if we don't have a match, the reverse flag might be wrong.... try and reverse it
    if (!$match) {
        $c->log->debug('reverse flag: '.$params->{reverse});
        $c->log->debug('No match, reverse flag may be wrong');
        if ($params->{reverse}) {
            delete $params->{reverse};
        } else {
            $params->{reverse} = 1;
        }
        $params->{search_seq} = revcom( $params->{search_seq} )->seq;
    }

    ( $match, @rest ) = $self->_get_matches( $seq, $params->{search_seq} );

    return $self->status_bad_request( $c, message => "Couldn't find specified sequence in the trace" ) unless $match;
    return $self->status_bad_request( $c, message => "Found the search sequence more than once" ) if @rest;

    $c->log->debug('final reverse flag: '.$params->{reverse});
    my $context = 0;

    # Context around the search seq is only relevant if we have a search seq
    if($params->{search_seq} and $params->{context}){
        $context = $params->{context};
    }

    my $data = $self->_extract_region( \%scf, $match->{start} - $context, $match->{end} + $context, $params->{reverse} );
    return $self->status_ok( $c, entity => $data );
}

sub _get_matches {
    my ( $self, $seq, $search ) = @_;
$self->log->debug("getting matches for $search");

    my @matches;

    if($search){
        my $length = length( $search ) - 1;

        my $index = 0;
        while ( 1 ) {
            #increment
            $index = index $seq, $search, ++$index;
            last if $index == -1;

            push @matches, { start => $index, end => $index+$length };
        }
    }
    else{
        push @matches, { start => 1, end => length($seq) - 1 };
    }

    return @matches;
}

sub _extract_region {
    my ( $self, $scf, $start, $end, $reverse ) = @_;

    my $length = scalar( @{ $scf->{samples}{A} } );

    #convert the base locations to actual sample locations
    my $sample_start = $scf->{index}[$start];
    my $sample_end   = $scf->{index}[$end];

    #create a mapping to allow us to get a base for a given sample (if one exists)
    my %sample_to_base;
    for my $i ( $start .. $end ) {
        my $sample_loc = $scf->{index}[$i];
        my $nuc = $scf->{bases}[$i];
#        die "One sample has two base calls??" if exists $sample_to_base{ $sample_loc };
#        Instead of die-ing which causes a valid tracefile to not be displayed,
#        we accept that the call may be ambiguous and just take the first one as valid
#        This approach may need to be reviewed - perhaps we should put in an ambiguity code
#        once we know how often this occurs at a specific location - DP-S 28/01/2015
        if ( exists $sample_to_base{ $sample_loc } ) {
            $self->log->debug( "This sample has two base calls:");
            $self->log->debug( $sample_loc . ' => ' . $sample_to_base{ $sample_loc } . " (already in the hash)");
            $self->log->debug( $sample_loc . ' => ' . ($reverse ? revcom( $nuc )->seq : $nuc) . " (ready to place in hash)");
        }
        else {
            #we have to lie and reverse complement if we're reversing
            #$sample_to_base{ $sample_loc } = $nuc;
            $sample_to_base{ $sample_loc } = $reverse ? revcom( $nuc )->seq : $nuc;
        }
    }

    my ( @series, @labels );

    my @nucs = qw( A C G T );
    #create a map from nucleotide to series_id
    my %series_ids = map { $nucs[$_] => $_ } 0 .. ( @nucs-1 );
    $series_ids{N} = 0; #draw N on A for now

    for my $nuc ( @nucs ) {
        #x axis goes from sample_start to sample end
        my $i = $sample_start;

        my @data;

        my @samples = $sample_start .. $sample_end;
        @samples = reverse @samples if $reverse; #we want it backwards if its a rev read

        #add all the x,y data for flot,
        #and check each sample to see if it has a base call. If it does add a label
        for my $sample_loc ( @samples ) {
            my $intensity = $scf->{samples}{$nuc}[$sample_loc];
            push @data, [$i, $intensity];

            #add a label if this intensity has one
            if ( exists $sample_to_base{ $sample_loc } && $sample_to_base{ $sample_loc } eq $nuc ) {
                push @labels, { x => $i, y => $intensity, nuc => $nuc, series => $series_ids{$nuc} };
            }

            ++$i;
        }

        #add an index to every read for the js graphing library
        #this is the format desired by flot
        push @series, {
            label => $nuc,
            data => \@data,
        };
    }

    return { labels => \@labels, series => \@series, length => $length, bases => \%sample_to_base };
}

=head1 NAME

LIMS2::WebApp::Controller::PublicAPI- Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller - API for public, no login required

=cut

sub report_ready :Path( '/public_api/report_ready' ) :Args(1) :ActionClass('REST') {
}

sub report_ready_GET {
    my ( $self, $c, $report_id ) = @_;

    my $status = LIMS2::Report::get_report_status( $report_id );
    return $self->status_ok( $c, entity => { status => $status } );
}

sub experiment : Path( '/public_api/experiment' ) : Args(0) : ActionClass( 'REST' ){
}

sub experiment_GET{
    my ($self, $c) = @_;

    my $id =  $c->request->param( 'id' );
    my $project;
    try{
        $project = $c->model( 'Golgi' )->retrieve_experiment( { id => $id } );
    }
    catch{
         $c->stash->{json_data} = { error => "experiment not found: $_"};
    };

    if($project){
        $c->stash->{json_data} = $project->as_hash_with_detail;
    }

    $c->forward('View::JSON');
    return;
}

# keeping url to api and not public_api for now as I believe it is being used
# by external groups
sub well_genotyping_crispr_qc :Path('/api/fetch_genotyping_info_for_well') :Args(1) :ActionClass('REST') {
}

sub well_genotyping_crispr_qc_GET {
    my ( $self, $c, $barcode ) = @_;

    #if this is slow we should use processgraph instead of 1 million traversals
    my $well = $c->model('Golgi')->retrieve_well( { barcode => $barcode } );

    return $self->status_bad_request( $c, message => "Barcode $barcode doesn't exist" )
        unless $well;

    my ( $data, $error );
    try {
        #needs to be given a method for finding genes
        my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); };
        $data = $well->genotyping_info( $gene_finder );
        $data->{child_barcodes} = $well->distributable_child_barcodes;

    }
    catch {
        #get string representation if its a lims2::exception
        $error = ref $_ && $_->can('as_string') ? $_->as_string : $_;
    };

    return $error ? $self->status_bad_request( $c, message => $error )
                  : $self->status_ok( $c, entity => $data );
}

sub mutation_signatures_barcodes :Path( '/public_api/mutation_signatures_barcodes' ) :Args(0) :ActionClass('REST'){
}

sub mutation_signatures_barcodes_GET{
    my ($self, $c) = @_;

    try{
        my $ms_barcode_data = get_mutation_signatures_barcode_data($c->model('Golgi'));
        $c->stash->{json_data} = $ms_barcode_data;
    }
    catch{
        $c->stash->{json_data} = { error => $_ };
    };

    $c->forward('View::JSON');
    return;
}

sub mutation_signatures_info :Path('/public_api/mutation_signatures_info') :Args(1) :ActionClass('REST') {
}

sub mutation_signatures_info_GET{
    my ($self, $c, $barcode) = @_;

    my $error;

    try{
        my $well = $c->model('Golgi')->retrieve_well( { barcode => $barcode } );
        my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); };

        my @sibling_barcodes = grep { $_ }
                               map { $_->barcode }
                               $well->sibling_wells;
        my $data = {
            well_id          => $well->id,
            well_name        => $well->well_name,
            plate_name       => $well->plate_name,
            parameters       => $well->input_process_parameters_skip_versioned_plates,
            child_barcodes   => $well->distributable_child_barcodes,
            sibling_barcodes => \@sibling_barcodes,
            ms_qc_data       => ( $well->ms_qc_data($gene_finder) // [] ),
        };

        my $design = try{ $well->design };
        if($design){
            my @gene_ids = $design->gene_ids;
            my @genes = $design->gene_symbols($gene_finder);
            $data->{gene_id} = (@gene_ids == 1 ? $gene_ids[0] : [ @gene_ids ]);
            $data->{gene} = (@genes == 1 ? $genes[0] : [ @genes ]);

            # damaged required to check if clone is het. clone qc_data hash seems to be inside an array (of max size 1)?
            my $damage = $data->{ms_qc_data}->[0]->{qc_data}->{damage_type};
            my $species = $c->model('Golgi')->schema->resultset('Species')->find({ id => $well->plate_species->id});
            my $assembly_id = $species->default_assembly->assembly_id;
            my $design_oligo_locus = $design->oligos->first->search_related( 'loci', { assembly_id => $assembly_id } )->first;
            my $chromosome = $design_oligo_locus->chr->name;
            $data->{chromosome} = $chromosome;
            $data->{is_het} = ep_pick_is_het($c->model('Golgi'), $well->id, $chromosome, $damage) unless !$damage;
        }

        unless (exists $data->{is_het}){
            # PIQ QC may be missing for hets in which case we go back to the ep_pick well to get this
            my $ep_pick = try{ $well->first_ep_pick };
            if($ep_pick){
                my $damage = crispr_damage_type_for_ep_pick($c->model('Golgi'), $ep_pick->id);
                $data->{is_het} = ep_pick_is_het($c->model('Golgi'), $ep_pick->id, $data->{chromosome}, $damage);
            }
            else{
                $c->log->warn("Could not set is_het flag for barcode $barcode");
            }
        }
        $c->stash->{json_data} = $data;
    }
    catch {
        #get string representation if its a lims2::exception
        $error = ref $_ && $_->can('as_string') ? $_->as_string : $_;
        $c->stash->{json_data} = { error => $error };
    };

    $c->forward('View::JSON');
    return;
}

sub announcements :Path('/public_api/announcements') : Args(0) :ActionClass('REST') {
}

sub announcements_GET {
    my ( $self, $c ) = @_;
    my $schema = $c->model( 'Golgi' )->schema;

    my $sys = $c->request->param( 'sys' );

    my $feed = $schema->resultset('Message')->search({
        $sys => 1,
        expiry_date => { '>=', \'now()' }
    },
    {
        order_by => { -desc => 'created_date' }
    });
    my @messages;
    my @high_prior;
    while (my $status = $feed->next){
        my $message = $status->as_hash;
        if ($message->{priority} eq 'high'){
            push @high_prior, $message;
        } else {
            push @messages, $message;
        }
    }
    my %body = (
        high => \@high_prior,
        normal => \@messages,
    );
    my $json = encode_json \%body;
    return $c->response->body( $json );
}
=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
