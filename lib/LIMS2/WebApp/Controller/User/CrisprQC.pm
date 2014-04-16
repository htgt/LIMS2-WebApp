package LIMS2::WebApp::Controller::User::CrisprQC;

use Moose;
use namespace::autoclean;
use Path::Class;
use JSON;
use List::Util qw ( min max );
use List::MoreUtils qw( uniq );

BEGIN { extends 'Catalyst::Controller' };

with qw(
    MooseX::Log::Log4perl
    WebAppCommon::Crispr::SubmitInterface
);

sub crispr_es_qc_run :Path( '/user/crisprqc/es_qc_run' ) :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my $params = $c->request->params;

    #default is to truncate
    my $truncate_seqs = defined $params->{truncate} ? $params->{"truncate"} : 1;

    #should prefetch wells too
    my $run = $c->model('Golgi')->schema->resultset('CrisprEsQcRuns')->find(
        { id => $qc_run_id },
        { prefetch => {'crispr_es_qc_wells' => 'well'} } 
    );

    unless ( $run ) {
        $c->stash( error_msg => "Run id $qc_run_id not found" );
        return;
    }

    my @qc_wells;
    for my $qc_well ( $run->crispr_es_qc_wells ) {
        my $json = decode_json( $qc_well->analysis_data );

        my $pair = $c->model('Golgi')->schema->resultset('CrisprPair')->find(
            { id => $json->{crispr_id} },
            { prefetch => [ 'left_crispr', 'right_crispr' ] }
        );

        #get HGNC/MGI ids
        my @gene_ids = uniq map { $_->gene_id }
                                map { $_->genes } 
                                    $pair->left_crispr->related_designs;

        #get gene symbol from the solr
        my @genes = map { $_->{gene_symbol} } 
                    values %{ $c->model('Golgi')->find_genes( $run->species_id, \@gene_ids ) };

        #format no alignment properly
        for my $direction ( qw( forward reverse ) ) {
            if ( exists $json->{$direction}{no_alignment} ) {
                $json->{$direction} = { full_match_string => '', query_align_str => 'No alignment' };
            }
        }

        #get start, end and size data relative to our seq strings
        my $str_start = $pair->start - $json->{target_sequence_start};
        my $str_end = $json->{target_sequence_end} - $pair->end;
        my $crispr_size = ($pair->end - $pair->start) + 1;

        #swap start and end of crispr if its -ve strand
        my ( $target_start, $target_end );
        if ( exists $json->{target_region_strand} && $json->{target_region_strand} eq "-1" ) {
            ( $str_start, $str_end ) = ( $str_end, $str_start );
        }

        #extract read sequence and its match string
        my %alignment_data = (
            a_match   => $json->{forward}{full_match_string},
            a_seq     => $json->{forward}{query_align_str},
            b_seq     => $json->{reverse}{query_align_str},
            b_match   => $json->{reverse}{full_match_string},
        );

        #forward and reverse will have the same target_align_str
        my $seq = $json->{forward}{target_align_str} || "";

        #truncate sequences if necessary,
        #and split the target align seq into three parts: before, crispr, after
        my $padding;
        if ( $truncate_seqs ) {
            $padding = defined $params->{padding} ? $params->{padding} : 25;
            my $padded_start = max(0, ($str_start-$padding));

            #truncate all the seqs
            for my $s ( values %alignment_data ) {
                next if $s eq "" or $s eq "No alignment";
                #make sure we don't exceed the length of the string
                #my $len = min( length($s)-$padded_start, ($padding*2)+$crispr_size );
                #$s = substr($s, $padded_start, $len);

                #use split sequence to get crispr and surrounding region then merge back
                $s = join "", split_sequence( $s, $str_start, $crispr_size, $padding );
            }
        }

        #split ref sequence into crispr and its surrounding sequence
        @alignment_data{qw(ref_start crispr_seq ref_end)}
            = split_sequence( $seq, $str_start, $crispr_size, $padding );

        #match strings aren't padded with X to the right, ideally they would all be the same length

        push @qc_wells, {
            es_qc_well_id => $qc_well->id,
            well_name     => $qc_well->well->name, #fetch the well and get name
            crispr_id     => $json->{crispr_id},
            gene          => join( ",", @genes ),
            alignment     => \%alignment_data,
            longest_indel => "",
            accepted      => $qc_well->well->accepted
        };
    }

    #add comment field

    $c->stash(
        qc_run_id   => $run->id,
        seq_project => $run->sequencing_project,
        species     => $run->species_id,
        wells       => [ sort { $a->{well_name} cmp $b->{well_name} } @qc_wells ],
    );

    return;
}

#split a string containing a crispr into 3 parts
sub split_sequence {
    my ( $seq, $crispr_start, $crispr_size, $padding ) = @_;

    return ( "" ) x 3 unless $seq;

    #print "$seq\n";

    my $crispr_end = $crispr_start + $crispr_size;

    my $ref_end = "";
    my $start = 0; #default is beginning of string
    if ( $padding ) {
        $start = max(0, $crispr_start-$padding);
        #make sure we don't go over the end of the sequence
        #$last_size = min($padding, $last_size);

        #if the string is too short, add Xs to the right hand side to fill the space
        #this should really be done in the qc
        if ( length($seq) < $crispr_end+$padding ) {
            $seq .= "X" x (($crispr_end+$padding) - length($seq));
        }

        $ref_end = substr( $seq, $crispr_end, $padding );

        unless ( $ref_end ) {
            print $seq . "\n";
            print join ", ", $crispr_start, $crispr_end, $padding, "\n";
        }
    }
    else {
        #we want to the end of the string with no padding
        $ref_end = substr( $seq, $crispr_end );
    }

    #start can be 0 to do untruncated
    my $ref_start  = substr( $seq, $start, $crispr_start-$start );
    #the actual crispr seq
    my $crispr_seq = substr( $seq, $crispr_start, $crispr_size );

    return $ref_start, $crispr_seq, $ref_end;
}

sub crispr_es_qc_runs :Path( '/user/crisprqc/es_qc_runs' ) :Args(0) {
    my ( $self, $c ) = @_;

    my @runs = $c->model('Golgi')->schema->resultset('CrisprEsQcRuns')->search(
        { species_id => $c->session->{selected_species} },
        {
            prefetch => 'created_by', 
            rows     => 20, 
            order_by => { -desc => "created_at" } 
        }
    );

    $c->stash(
        runs => [ map { $_->as_hash } @runs ],
    );

}