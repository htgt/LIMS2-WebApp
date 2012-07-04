package LIMS2::Model::Plugin::Gene;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

has _genes_cache => (
    is         => 'ro',
    isa        => 'CHI::Driver',
    lazy_build => 1
);

sub _build__genes_cache {
    my $self = shift;
    return $self->_build_cache( 'genes' );
}

sub pspec_search_genes {
    return {
        gene => { validate => 'string_min_length_3' }
    };
}

sub search_genes {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_search_genes );

    my $gene = $validated_params->{gene};

    return $self->_genes_cache->compute(
        $gene,
        undef,
        sub {
            my $genes = $self->solr_query( $gene );
            $self->throw( NotFound => { entity_class => 'Gene', search_params => $validated_params } )
                unless @{$genes} > 0;
            return $genes;
        }
    );
}

1;

__END__
