package LIMS2::Model::Util::CreateDesign;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
              exons_for_gene
          )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( uniq );
use LIMS2::Util::EnsEMBL;
use LIMS2::Exception;

sub exons_for_gene {
    my ( $model, $gene_name, $species, $build ) = @_;

    my $gene = get_ensembl_gene( $gene_name, $species );
}

=head2 _sort_gene_id

Sort the input from the gene search box into gene id types

=cut
## no critic(BuiltinFunctions::ProhibitComplexMappings)
sub get_ensembl_gene {
    my ( $gene_name, $species ) = @_;

    my $ensembl_util = LIMS2::Util::EnsEMBL->new( species => $species );
    if ( $gene_name =~ /HGNC:\d+/ || $gene_name =~ /MGI:\d+/  ) {
    }
    elsif ( $gene_name =~ /ENS(MUS)?G\d+/ ) {
    }
    else {
        #assume its a marker symbol
    }


    return $gene;
}
## use critic

1;

__END__
