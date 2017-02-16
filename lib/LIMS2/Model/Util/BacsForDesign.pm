package LIMS2::Model::Util::BacsForDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::BacsForDesign::VERSION = '0.446';
}
## use critic

use strict;
use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::BacsForDesign

=head1 DESCRIPTION

Exported one method, bacs_for_design.
This method takes a design object and returns a ordered list of bac clone names for that design.
List of ordered by:
- RP24 clones over RP23 clones
- The closer the bac clone length is to the prefered bac clone size ( currently 200,000 )

The list will consist of 4 bac clone names if available.
If none are found error is throw.


=cut

use Sub::Exporter -setup => {
    exports => [ qw( bacs_for_design ) ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Exception;
use Const::Fast;

const my $TARGET_REGION_BUFFER_LENGTH => 6000;
const my $DEFAULT_BAC_LIBRARY         => 'black6';
const my $PREFERRED_BAC_CLONE_SIZE    => 200000;

=head2 bacs_for_design

Input: model, design object, and optional bac library id ( defaults to black6 )
Output: array ref of up to 4 bac clone names.

=cut
sub bacs_for_design {
    my ( $model, $design, $bac_library ) = @_;
    INFO( 'Find bac clones for design: ' . $design->id );
    my $assembly_id = $design->species->default_assembly->assembly_id;
    $bac_library ||= $DEFAULT_BAC_LIBRARY;

    my $bacs = get_bac_clones( $model, $design, $assembly_id, $bac_library );

    return order_bacs( $bacs, $assembly_id, $design->id );
}

=head2 get_bac_clones

Grabs all the bac clones that could be used for this design, filtering done on:
- bac library ( default black6 )
- current default assembly
- bac clone encloses designs target start and target end values

=cut
sub get_bac_clones {
    my ( $model, $design, $assembly_id, $bac_library ) = @_;
    DEBUG( "Assembly: $assembly_id, bac library: $bac_library" );

    my $target_start = target_start( $design );
    my $target_end   = target_end( $design );
    my $chr_id       = $model->_chr_id_for( $assembly_id, $design->chr_name );
    DEBUG( "Target start: $target_start, target end: $target_end, chromosome: " . $design->chr_name );

    my @bacs = $model->schema->resultset( 'BacClone' )->search(
        {
           bac_library_id     => $bac_library,
           'loci.chr_id'      => $chr_id,
           'loci.chr_start'   => { '<=' => $target_start },
           'loci.chr_end'     => { '>=' => $target_end },
           'loci.assembly_id' => $assembly_id,
        },
        {
            join => 'loci',
        }
    );

    LIMS2::Exception->throw( 'No bacs found for design ' . $design->id )
        unless @bacs;

    return \@bacs;
}

=head2 target_start

Calculates target start value for design, which is the designs target region start value
minus buffer length, currently defaults to 6000 bases.

=cut
sub target_start {
    my $design = shift;

    my $start = $design->target_region_start;
    LIMS2::Exception->throw( 'Can not find design target region start' )
        unless $start;

    return $start - $TARGET_REGION_BUFFER_LENGTH;
}

=head2 target_end

Calculates target end value for design, which is the designs target region end value
minus buffer length, currently defaults to 6000 bases.

=cut
sub target_end {
    my $design = shift;

    my $end = $design->target_region_end;
    LIMS2::Exception->throw( 'Can not find design target region end' )
        unless $end;

    return $end + $TARGET_REGION_BUFFER_LENGTH;
}

=head2 order_bacs

Orders list of bac clones:
- prefer RP24 over RP23 bacs
- then orders on closeness to preferred bac size ( 200,000 )

Returns array ref of bac clone names.

=cut
sub order_bacs {
    my ( $bacs, $assembly_id, $design_id ) = @_;
    my @rp24_bacs = grep{ $_->name =~ /^RP24/ } @{ $bacs };
    my @rp23_bacs = grep{ $_->name =~ /^RP23/ } @{ $bacs };
    my $sorted_rp24_bacs = sort_bacs_by_size( \@rp24_bacs, $assembly_id );
    my $sorted_rp23_bacs = sort_bacs_by_size( \@rp23_bacs, $assembly_id );

    my @ordered_bac_ids;
    push @ordered_bac_ids, @{ $sorted_rp24_bacs } if $sorted_rp24_bacs;
    push @ordered_bac_ids, @{ $sorted_rp23_bacs } if $sorted_rp23_bacs;

    my $num_clones = scalar( @ordered_bac_ids );
    LIMS2::Exception->throw( "No valid bacs (RP24 or RP23) found for design $design_id" )
        if $num_clones == 0;
    INFO( "Found bac clones: $num_clones" );

    if ( $num_clones > 4 ) {
        splice( @ordered_bac_ids, 4 );
    }

    return \@ordered_bac_ids;
}

=head2 sort_bacs_by_size

Orders bacs on closeness to preferred bac size ( 200,000 ).
Returns array ref of bac clone names.

=cut
sub sort_bacs_by_size {
    my ( $bacs, $assembly_id ) = @_;
    return unless @{ $bacs };
    my %bac_pref_size_diff;

    for my $bac ( @{ $bacs } ) {
        my $loci = $bac->loci->search_rs( { assembly_id => $assembly_id } )->first;
        my $bac_size = ( $loci->chr_end - $loci->chr_start ) + 1;
        my $preferred_length_diff = abs( $PREFERRED_BAC_CLONE_SIZE - $bac_size );

        $bac_pref_size_diff{ $bac->name } = $preferred_length_diff;
    }

    return [ sort { $bac_pref_size_diff{$a} <=> $bac_pref_size_diff{$b} }
            keys %bac_pref_size_diff ];
}

1;
