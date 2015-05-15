package LIMS2::Model::Util::GenoverseSupport;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::GenoverseSupport::VERSION = '0.317';
}
## use critic


use strict;
use warnings;

=head1 NAME

LIMS2::Model::Util::GenoverseSupport

=head1 DESCRIPTION
Methods used by Genoverse to implement a variety of tracks


=cut

use LIMS2::Model::Util::OligoSelection;

use Sub::Exporter -setup => {
    exports => [ qw(
        get_genotyping_primer_extent
        get_design_extent
        get_gene_extent
    ) ]
};

use LIMS2::Exception;

use Log::Log4perl qw(:easy);

=head get_genotyping_extent

Given

Returns
hashref:
    start_coord
    end_coord
    chr_name
    assembly
=cut

sub get_genotyping_primer_extent {
    my $model = shift;
    my $params = shift;
    my $species = shift;

    my $g_primer_hash = get_db_genotyping_primers_as_hash($model->schema, $params );

    if ( ! %{$g_primer_hash} ) {
        LIMS2::Exception->throw( 'No data returned for design primers' );
    }

    my %extent_hash;

    # Simply compare all the start and end positions (chr_start, chr_end) and take the min of chr_start and the max of chr_end

    $extent_hash{'chr_start'} = $g_primer_hash->{'GF1'}->{'chr_start'};
    $extent_hash{'chr_end'} = $g_primer_hash->{'GF1'}->{'chr_end'};
    while ( my ($primer, $vals) = each %$g_primer_hash ) {
        $extent_hash{'chr_start'} = $vals->{'chr_start'} if $extent_hash{'chr_start'} > $vals->{'chr_start'};
        $extent_hash{'chr_end'} = $vals->{'chr_end'} if $extent_hash{'chr_end'} < $vals->{'chr_start'};
    }
    $extent_hash{'chr_name'} = $g_primer_hash->{'GF1'}->{'chr_name'};
    $extent_hash{'assembly'} = $model->get_species_default_assembly( $species );

    return \%extent_hash;
}

sub get_gene_extent {
    my $model = shift;
    my $params = shift;
    my $species = shift;

    my $ensembl_stable_id;

    $ensembl_stable_id = $model->find_gene({
            species => $species,
            search_term => $params->{'gene_id'}
        })->{'ensembl_id'};

    DEBUG ( $params->{'gene_id'} . ' = ' . $ensembl_stable_id );

    my %extent_hash;

    my $slice_adaptor = $model->ensembl_slice_adaptor($species);
    my $slice = $slice_adaptor->fetch_by_gene_stable_id( $ensembl_stable_id, 5e3 );

    my $coord_sys  = $slice->coord_system()->name();
    my $seq_region = $slice->seq_region_name();
    my $start      = $slice->start();
    my $end        = $slice->end();
    my $strand     = $slice->strand();

    DEBUG ("Slice: $coord_sys $seq_region $start-$end ($strand)");

    if ( $start <= $end ){
        $extent_hash{'chr_start'} = $start;
        $extent_hash{'chr_end'} = $end;
    }
    else {
        $extent_hash{'chr_start'} = $end;
        $extent_hash{'chr_end'} = $start;
    }
    $extent_hash{'chr_name'} = $seq_region;
    $extent_hash{'assembly'} = $model->get_species_default_assembly( $species );

    return \%extent_hash;
}

sub get_design_extent {
    my $model = shift;
    my $params = shift;
    my $species = shift;

    my $design_r = $model->schema->resultset('Design')->find($params->{'design_id'});

    my $design_info = LIMS2::Model::Util::DesignInfo->new( design => $design_r );
    my $design_oligos = $design_info->oligos;

    my %extent_hash;

    # Simply compare all the start and end positions (chr_start, chr_end) and take the min of chr_start and the max of chr_end
    my @label_keys = keys %$design_oligos;
    my $arbitrary_key = $label_keys[0];

    $extent_hash{'chr_start'} = $design_oligos->{$arbitrary_key}->{'start'};
    $extent_hash{'chr_end'} = $design_oligos->{$arbitrary_key}->{'end'};
    while ( my ($primer, $vals) = each %$design_oligos ) {
        $extent_hash{'chr_start'} = $vals->{'start'} if $extent_hash{'chr_start'} > $vals->{'start'};
        $extent_hash{'chr_end'} = $vals->{'end'} if $extent_hash{'chr_end'} < $vals->{'start'};
    }
    $extent_hash{'chr_name'} = $design_oligos->{$arbitrary_key}->{'chromosome'};
    $extent_hash{'assembly'} = $model->get_species_default_assembly( $species );

    return \%extent_hash;
}

1;
