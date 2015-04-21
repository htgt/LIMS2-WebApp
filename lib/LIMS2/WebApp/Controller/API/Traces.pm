package LIMS2::WebApp::Controller::API::Traces;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Traces::VERSION = '0.307';
}
## use critic


use Moose;
use namespace::autoclean;

use LIMS2::Util::TraceServer;
use Bio::SCF;
use Bio::Perl qw( revcom );

with "MooseX::Log::Log4perl";

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

has traceserver => (
    is => 'ro',
    isa => 'LIMS2::Util::TraceServer',
    lazy_build => 1,
);

sub _build_traceserver {
    return LIMS2::Util::TraceServer->new;
}

sub trace_data : Path( '/api/trace_data' ) : Args(0) : ActionClass( 'REST' ) {
}

sub trace_data_GET{
    my ( $self, $c ) = @_;

    # $c->assert_user_roles('read');

    my $params = $c->request->params;

    $self->log->debug( "Finding trace for '" . $params->{name} . "'" );
    my $trace = $self->traceserver->get_trace( $params->{name} );

    my $fh = $self->traceserver->write_temp_file( $trace );
    tie my %scf, 'Bio::SCF', $fh;

    my $seq = join "", @{ $scf{bases} };
    $params->{search_seq} = revcom( $params->{search_seq} )->seq if $params->{reverse};

    my ( $match, @rest ) = $self->_get_matches( $seq, $params->{search_seq} );

    # if we don't have a match, the reverse flag might be wrong.... try and reverse it
    if (!$match) {
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

    #$self->log->debug( $seq );
    #$self->log->debug( "Start: " . $match->{start} . " End: " . $match->{end} );
    #$self->log->debug( "Start: " . $scf{bases}[$match->{start}] . " End: " . $scf{bases}[$match->{end}] );

    my $data = $self->_extract_region( \%scf, $match->{start}, $match->{end}, $params->{reverse} );

    return $self->status_ok( $c, entity => $data );
}

sub _get_matches {
    my ( $self, $seq, $search ) = @_;

    my $length = length( $search ) - 1;

    my @matches;
    my $index = 0;
    while ( 1 ) {
        #increment
        $index = index $seq, $search, ++$index;
        last if $index == -1;

        push @matches, { start => $index, end => $index+$length };
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

    return { labels => \@labels, series => \@series, length => $length };
}

1;
