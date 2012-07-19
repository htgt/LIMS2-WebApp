package LIMS2::Model::Plugin::Gene;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

has [ qw( _cache_marker_symbol _cache_mgi_accession_id _cache_ensembl_gene_id ) ] => (
    is         => 'ro',
    isa        => 'CHI::Driver',
    lazy_build => 1
);

sub list_species {
    my $self = shift;

    my @species = map { $_->id }
        $self->schema->resultset('Species')->search( {}, { order_by => { -asc => 'id' } } );

    return \@species;
}

sub _build__cache_marker_symbol {
    return shift->_build_cache( 'marker_symbol' );
}

sub _build__cache_mgi_accession_id {
    return shift->_build_cache( 'mgi_accession_id' );
}

sub _build__cache_ensembl_gene_id {
    return shift->_build_cache( 'ensembl_gene_id' );
}

sub pspec_search_genes {
    return {
        gene             => { validate => 'string_min_length_3', optional => 1 },
        mgi_accession_id => { validate => 'mgi_accession_id', optional => 1 },
        marker_symbol    => { validate => 'non_empty_string', optional => 1 },
        ensembl_gene_id  => { validate => 'ensembl_gene_id', optional => 1 },
        REQUIRE_SOME     => { gene_identifier => [ 1, qw( gene mgi_accession_id marker_symbol ensembl_gene_id ) ] }
    };
}

sub search_genes {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_search_genes );

    if ( $validated_params->{gene} ) {
        return $self->_search_genes( $validated_params );
    }
    else {
        return $self->_search_cached_genes( $validated_params );
    }
}

sub _search_genes {
    my ( $self, $params ) = @_;

    my $genes = $self->solr_query( $params->{gene} );
    $self->throw( NotFound => { entity_class => 'Gene', search_params => $params } )
        unless @{$genes} > 0;

    return $genes;
}

sub _search_cached_genes {
    my ( $self, $params ) = @_;

    my $search_key = ( keys %{$params} )[0];

    my $cache = '_cache_' . $search_key;

    my $search_str = $params->{$search_key};

    return $self->$cache->compute(
        $search_str,
        undef,
        sub {
            my $genes = $self->solr_query( [ $search_key => $search_str ] );
            $self->throw( NotFound => { entity_class => 'Gene', search_params => $params } )
                unless @{$genes} > 0;
            return $genes;
        }
    );
}

sub pspec_retrieve_gene {
    return {
        gene => { validate => 'non_empty_string' }
    }
}

sub retrieve_gene {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_gene );
    my $search_term = $validated_params->{gene};

    my $genes;

    if ( $search_term =~ m/^MGI:\d+$/ ) {
        $genes = $self->_search_cached_genes( { mgi_accession_id => $search_term } );
    }
    elsif ( $search_term =~ m/^ENS[A-Z]*G\d+$/ ) {
        $genes = $self->_search_cached_genes( { ensembl_gene_id => $search_term } );
    }
    else {
        $genes = $self->_search_cached_genes( { marker_symbol => $search_term } );
    }

    if ( @{$genes} > 1 ) {
        $self->throw( Implementation => "Retrieval of gene '$search_term' returned " . @{$genes} . " genes" );
    }

    return shift @{$genes};
}

1;

__END__
