package LIMS2::Model::Util::GeneSearch;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::GeneSearch::VERSION = '0.137';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            retrieve_solr_gene
            retrieve_ensembl_gene
            normalize_solr_result
          )
    ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;
use LIMS2::Exception::NotFound;
use LIMS2::Exception::Implementation;

const my $MGI_ACCESSION_ID_RX => qr/^MGI:\d+$/;
const my $ENSEMBL_GENE_ID_RX  => qr/^ENS[A-Z]*G\d+$/;

sub retrieve_solr_gene {
    my ( $model, $params ) = @_;

    my $search_term = $params->{search_term};

    my $genes;

    if ( $search_term =~ $MGI_ACCESSION_ID_RX ) {
        $genes = $model->solr_query( [ mgi_accession_id => $search_term ] );
    }
    elsif ( $search_term =~ $ENSEMBL_GENE_ID_RX ) {
        $genes = $model->solr_query( [ ensembl_gene_id => $search_term ] );
    }
    else {
        $genes = $model->solr_query( [ marker_symbol_str => $search_term ] );
    }

    if ( @{$genes} == 0 ) {
        $genes = $model->check_for_local_symbol( $search_term );
    }

    if ( @{$genes} == 0 ) {
        LIMS2::Exception::NotFound->throw( { entity_class => 'Gene', search_params => $params } );
    }

    if ( @{$genes} > 1 ) {
        LIMS2::Exception::Implementation->throw(
            "Retrieval of gene Mouse/$search_term returned " . @{$genes} . " genes" );
    }

    return normalize_solr_result( shift @{$genes} );
}

sub retrieve_ensembl_gene {
    my ( $model, $params ) = @_;

    if ( $params->{search_term} =~ $ENSEMBL_GENE_ID_RX ) {
        my $gene = $model->ensembl_gene_adaptor( $params->{species} )
            ->fetch_by_stable_id( $params->{search_term} )
                or LIMS2::Exception::NotFound->throw( { entity_class => 'Gene', search_params => $params } );

        return { gene_id => $gene->stable_id, gene_symbol => $gene->external_name };
    }

    my $genes = $model->ensembl_gene_adaptor( $params->{species} )
        ->fetch_all_by_external_name( $params->{search_term} );

    if ( @{$genes} == 0 ) {
        LIMS2::Exception::NotFound->throw( { entity_class => 'Gene', search_params => $params } );
    }

    if ( @{$genes} > 1 ) {
        LIMS2::Exception::Implementation->throw(
            "Retrieval of gene $params->{species}/$params->{search_term} returned "
            . @{$genes} . " genes"
        );
    }

    return { gene_id => $genes->[0]->stable_id, gene_symbol => $genes->[0]->external_name };
}

sub normalize_solr_result {
    my ( $solr_result ) = @_;
    my %normalized = %{ $solr_result };

    $normalized{gene_id}     = delete $normalized{mgi_accession_id} if $normalized{mgi_accession_id};
    $normalized{gene_symbol} = delete $normalized{marker_symbol} if $normalized{marker_symbol};

    return \%normalized;
}

1;

__END__
