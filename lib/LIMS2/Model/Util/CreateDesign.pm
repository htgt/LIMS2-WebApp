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

=head2 exons_for_gene


=cut
sub exons_for_gene {
    my ( $model, $gene_name, $species, $build ) = @_;

    my $gene = get_ensembl_gene( $model, $gene_name, $species );

    # add lots of additional data
    my $canonical_transcript = $gene->canonical_transcript;
    my $exons = $canonical_transcript->get_all_Exons;

    return $exons;
}

=head2 get_ensembl_gene


=cut
## no critic(BuiltinFunctions::ProhibitComplexMappings)
sub get_ensembl_gene {
    my ( $model, $gene_name, $species ) = @_;

    my $ga = $model->ensembl_util->gene_adaptor( $species );

    my $gene;
    if ( $gene_name =~ /HGNC:\d+/ ) {
        my @genes = @{ $ensembl_util->gene_adaptor->fetch_all_by_external_name($hgnc_name, 'HGNC') };
        unless( @genes ) {
            WARN( "Unable to find gene $gene_name in EnsEMBL" );
            return;
        }
        if ( scalar(@genes) > 1 ) {
            #TODO throw error, use ensembl if instead sp12 Wed 27 Nov 2013 14:58:41 GMT
            DEBUG("Found multiple EnsEMBL genes for $gene_name");
        else {
            $gene = shift @genes;
        }
    }
    elsif ( $gene_name =~ /MGI:\d+/  ) {
        my @genes = @{ $ensembl_util->gene_adaptor->fetch_all_by_external_name($hgnc_name, 'MGI') };
        unless( @genes ) {
            WARN( "Unable to find gene $gene_name in EnsEMBL" );
            return;
        }
        if ( scalar(@genes) > 1 ) {
            #TODO throw error, use ensembl if instead sp12 Wed 27 Nov 2013 14:58:41 GMT
            DEBUG("Found multiple EnsEMBL genes for $gene_name");
        else {
            $gene = shift @genes;
        }

    }
    elsif ( $gene_name =~ /ENS(MUS)?G\d+/ ) {
        $gene = $ga->fetch_by_stable_id( $gene_name );
    }
    else {
        #assume its a marker symbol
        my @genes = @{ $ga->fetach_all_by_external_name( $gene_name, 'type' ) };
        unless( @genes ) {
            WARN( "Unable to find gene $gene_name in EnsEMBL" );
            return;
        }
        if ( scalar(@genes) > 1 ) {
            #TODO throw error, use ensembl if instead sp12 Wed 27 Nov 2013 14:58:41 GMT
            DEBUG("Found multiple EnsEMBL genes for $gene_name");
        else {
            $gene = shift @genes;
        }
    }

    return $gene;
}
## use critic

1;

__END__
