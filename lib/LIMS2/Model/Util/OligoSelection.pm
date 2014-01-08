package LIMS2::Model::Util::OligoSelection;
use strict;
use warnings FATAL => 'all';


=head1 NAME

LIMS2::Model::Util::OligoSelection

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ qw(
        oligos_for_gibson
        oligos_for_crispr_pair
    ) ]
};

use Log::Log4perl qw( :easy );

=head2 oligos_for_gibson 

Generate genotyping primer oligos for a design. 

=cut


=head2 oligos_for_crispr_pair

Generate sequencing primer oligos for a crispr pair

=cut
