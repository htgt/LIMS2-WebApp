package LIMS2::Model::Util::OligoSelection;
use strict;
use warnings FATAL => 'all';


=head1 NAME

LIMS2::Model::Util::GenomeBrowser

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ qw(
        crisprs_for_region
        crisprs_to_gff
        crispr_pairs_for_region
        crispr_pairs_to_gff 
        gibson_designs_for_region
        design_oligos_to_gff
    ) ]
};

use Log::Log4perl qw( :easy );

=head2 crisprs_for_region 

Find crisprs for a specific chromosome region. The search is not design
related. The method accepts species, chromosome id, start and end coordinates.

This method is used by the browser REST api to server data for the genome browser.

dp10
=cut

