package LIMS2::Model::Plugin::Gene;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Gene::VERSION = '0.048';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Data::Dump 'pp';
use namespace::autoclean;
use LIMS2::Model::Util::GeneSearch qw( retrieve_solr_gene retrieve_ensembl_gene normalize_solr_result );

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
        @genes = map { normalize_solr_result( $_ ) }
            @{ $self->solr_query( $validated_params->{search_term} ) };
    }
    elsif ( $species eq 'Human' ) {
        my $genes = $self->retrieve_gene( $validated_params ) || [];
        @genes = @{ $genes };
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
                retrieve_solr_gene( $self, $validated_params );
            }
        );
    }

    if ( $species eq 'Human' ) {
        return $self->_gene_cache_human->compute(
            $validated_params->{search_term}, undef, sub {
                retrieve_ensembl_gene( $self, $validated_params );
            }
        );
    }

    $self->throw( Implementation => "retrieve_gene() for species '$species' not implemented" );
}
## use critic


1;

__END__
