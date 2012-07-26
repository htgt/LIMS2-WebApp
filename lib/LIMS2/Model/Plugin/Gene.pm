package LIMS2::Model::Plugin::Gene;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Const::Fast;
use Data::Dump 'pp';
use namespace::autoclean;

const my $MGI_ACCESSION_ID_RX => qr/^MGI:\d+$/;
const my $ENSEMBL_GENE_ID_RX  => qr/^ENS[A-Z]*G\d+$/;

requires qw( schema check_params throw retrieve log trace );

has [ qw( _gene_cache_mouse _gene_cache_human ) ] => (
    is         => 'ro',
    isa        => 'CHI::Driver',
    lazy_build => 1
);

sub _build__gene_cache_mouse {
    return shift->_build_cache( 'gene_cache_mouse' );
}

sub _build__gene_cache_human {
    return shift->_build_cache( 'gene_cache_human' );
}

sub pspec_search_genes {
    return {
        species     => { validate => 'existing_species' },
        search_term => { validate => 'string_min_length_3' },
    };
}

sub search_genes {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_search_genes );
    $self->log->debug( "Search genes: " . pp $params );

    my $species = $validated_params->{species};

    my @genes;

    if ( $species eq 'Mouse' ) {
        @genes = map { $self->_normalize_solr_result( $_ ) }
            @{ $self->solr_query( $validated_params->{search_term} ) };
    }
    elsif ( $species eq 'Human' ) {
        @genes = ( $self->retrieve_gene( $validated_params ) || () );
    }
    else {
        LIMS2::Exception::Implementation->throw( "search_genes() for species '$species' not implemented" );
    }

    if ( @genes == 0 ) {
        $self->throw( NotFound => { entity_class => 'Gene', search_params => $validated_params } );
    }

    return \@genes;
}

sub pspec_retrieve_gene {
    return {
        species     => { validate => 'existing_species' },
        search_term => { validate => 'non_empty_string' }
    }
}

## no critic(RequireFinalReturn)
sub retrieve_gene {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_gene );

    $self->log->debug( "retrieve_gene: " . pp $validated_params );

    my $species = $validated_params->{species};

    if ( $species eq 'Mouse' ) {
        return $self->_gene_cache_mouse->compute(
            $validated_params->{search_term}, undef, sub {
                $self->_retrieve_solr_gene( $validated_params );
            }
        );
    }

    if ( $species eq 'Human' ) {
        return $self->_gene_cache_human->compute(
            $validated_params->{search_term}, undef, sub {
                $self->_retrieve_ensembl_gene( $validated_params );
            }
        );
    }

    $self->throw( Implementation => "retrieve_gene() for species $species not implemented" );
}
## use critic

sub _retrieve_solr_gene {
    my ( $self, $params ) = @_;

    my $search_term = $params->{search_term};

    my $genes;

    if ( $search_term =~ $MGI_ACCESSION_ID_RX ) {
        $genes = $self->solr_query( [ mgi_accession_id => $search_term ] );
    }
    elsif ( $search_term =~ $ENSEMBL_GENE_ID_RX ) {
        $genes = $self->solr_query( [ ensembl_gene_id => $search_term ] );
    }
    else {
        $genes = $self->solr_query( [ marker_symbol_str => $search_term ] );
    }

    if ( @{$genes} == 0 ) {
        $self->throw( NotFound => { entity_class => 'Gene', search_params => $params } );
    }

    if ( @{$genes} > 1 ) {
        $self->throw( Implementation => "Retrieval of gene Mouse/$search_term returned " . @{$genes} . " genes" );
    }

    return $self->_normalize_solr_result( shift @{$genes} );
}

sub _retrieve_ensembl_gene {
    my ( $self, $params ) = @_;

    if ( $params->{search_term} =~ $ENSEMBL_GENE_ID_RX ) {
        my $gene = $self->ensembl_gene_adaptor( $params->{species} )->fetch_by_stable_id( $params->{search_term} )
            or $self->throw( NotFound => { entity_class => 'Gene', search_params => $params } );
        return { gene_id => $gene->stable_id, gene_symbol => $gene->external_name };
    }

    my $genes = $self->ensembl_gene_adaptor( $params->{species} )->fetch_all_by_external_name( $params->{search_term} );

    if ( @{$genes} == 0 ) {
        $self->throw( NotFound => { entity_class => 'Gene', search_params => $params } );
    }

    if ( @{$genes} > 1 ) {
        $self->throw( Implementation => "Retrieval of gene $params->{species}/$params->{search_term} returned " . @{$genes} . " genes" );
    }

    return { gene_id => $genes->[0]->stable_id, gene_symbol => $genes->[0]->external_name };
}

sub _normalize_solr_result {
    my ( $self, $solr_result ) = @_;

    my %normalized = %{ $solr_result };

    $normalized{gene_id}     = delete $normalized{mgi_accession_id};
    $normalized{gene_symbol} = delete $normalized{marker_symbol};

    return \%normalized;
}

1;

__END__
