package LIMS2::Model::Plugin::Gene;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Gene::VERSION = '0.395';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Data::Dump 'pp';
use namespace::autoclean;
use Log::Log4perl qw( :easy );
use LIMS2::Model::Util::GeneSearch qw( retrieve_solr_gene retrieve_ensembl_gene normalize_solr_result );
use WebAppCommon::Util::FindGene qw( c_find_gene c_autocomplete_gene);
use TryCatch;
use List::MoreUtils qw (uniq);

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

# DEPRECATED. use find_gene / find_genes instead
sub search_genes {
    my ( $self, $params ) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_search_genes );
    TRACE "Search genes: " . pp $params;

    my $species = $validated_params->{species};

    my @genes;

    if ( $species eq 'Mouse' ) {
        @genes = map { normalize_solr_result( $_ ) }
            @{ $self->solr_query( $validated_params->{search_term} ) };
    }
    elsif ( $species eq 'Human' ) {
     # Massive fudge to make this work while search_genes rewrite is in progress
     try{
        my $genes = $self->retrieve_gene( $validated_params ) || [];
        $self->log->trace( "Genes retrieved: ". pp $genes );
        if (ref($genes) eq "ARRAY"){
            @genes = @{ $genes };
        }
        elsif(ref($genes) eq "HASH"){
            push @genes, $genes;
        }
        else{
            die "Don't know what to do with return value from retrieve_gene: $genes";
        }
      }
      catch($err){
        $self->log->debug( "retrieve_gene failed: $err" );
        return \@genes;
      }
    }
    else {
        LIMS2::Exception::Implementation->throw( "search_genes() for species '$species' not implemented" );
    }

    if ( @genes == 0 ) {
        my $not_genes = $self->check_for_local_symbol( $validated_params->{'search_term'} );
        @genes = @{ $not_genes };
    }

    if ( @genes == 0 ) {
        $self->throw( NotFound => { entity_class => 'Gene', search_params => $validated_params } );
    }

    return \@genes;
}

=head
check_for_local_symbol

With some designs, the id that they are rooted to is not a gene_id that can be translated
using the indices. So we have an alternative strategy for finding something appropriate to
put in the gene symbol field.

A better solution would be to have an extra attribute on the upload to accommodate this...

=cut

sub check_for_local_symbol {
    my $self = shift;
    my $local_id = shift;

    my @not_genes;

    # TODO look up the symbols in the database and read the symbolic data from there.
    # This requires the data to be in a database table...
    if ( $local_id =~ m/\A CGI /xgms ) {
        push @not_genes, {
            'gene_id' => $local_id,
            'gene_symbol' => 'CPG_island',
            'ensembl_id' => '' };
    }
    elsif ( $local_id =~ m/\A LBL /xgms ) {
        push @not_genes, {
            'gene_id' => $local_id,
            'gene_symbol' => 'enhancer',
            'ensembl_id' => '' };
    }

    return \@not_genes;
}

## no critic(RequireFinalReturn)
sub retrieve_gene {

    # Keep retrieve gene for compatibility but call the new solr find_gene method
    my $ret_val =find_gene( @_ );
    # Delete the ensembl_id and chromosome key/value pair because retrieve gene is not expected to include that
    if ( defined $ret_val->{'ensembl_id'} ) {
        delete $ret_val->{'ensembl_id'};
    }
    if ( defined $ret_val->{'chromosome'} ) {
        delete $ret_val->{'chromosome'};
    }
    return $ret_val;
}
## use critic

sub pspec_find_gene {
    return {
        species     => { validate => 'existing_species' },
        search_term => { validate => 'non_empty_string' },
    }
}

## no critic(RequireFinalReturn)
# argument is an hash with species and search term
# returns an hashref with gene_id, gene_symbol and ensembl_id
# if gene not found, the gene_id returned is the search_term and the gene_symbol is 'unknown'
# ensembl_id might be an empty string
sub find_gene {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_find_gene );

    $self->log->trace( "retrieve_gene: " . pp $validated_params );

    # check species, if not mouse or human, die
    my $species = $validated_params->{species};
    LIMS2::Exception::Implementation->throw( "find_gene() for species '$species' not implemented" )
    unless ($species eq 'Mouse' || $species eq 'Human');

    # search for a gene in the solr index
    my $gene;
    try { $gene = c_find_gene( $validated_params ) };

    $self->throw( Implementation => "find_gene() failed to reach solr" )
    unless defined($gene);

    # if solr did not find a gene, search for local symbol
    my $not_gene;
    if ($gene->{gene_symbol} eq 'unknown') {
        $not_gene = $self->check_for_local_symbol( $validated_params->{search_term} );
        $not_gene = $not_gene->[0];
    }

    # return local symbol if exists, else return solr gene result
    $not_gene ? return $not_gene : return $gene;

}
## use critic

# wrapper around find_gene to find arrays of genes at a time.
# argument is a species and an arrayref of search terms.
# returns an hashref, where the keys are the search_terms and the
# values are hashrefs containing the gene_id, gene_symbol and ensembl_id
sub find_genes {
    my ( $self, $species, $serch_terms ) = @_;

    my %result;

    foreach my $search_term ( @{$serch_terms} ) {

        $result{$search_term} = $self->find_gene({
                        species => $species,
                        search_term => $search_term
                    });
    }

    return \%result;

}

# Need as input an hash with species and search_term.
# As output gives back an array of hashes (with gene_id, gene_symbol and ensembl_id)
# for the genes that contain the search_term.
sub autocomplete_gene {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_find_gene );

    $self->log->trace( "retrieve_gene: " . pp $validated_params );

    # check species, if not mouse or human, die
    my $species = $validated_params->{species};
    LIMS2::Exception::Implementation->throw( "find_gene() for species '$species' not implemented" )
    unless ($species eq 'Mouse' || $species eq 'Human');

    # search for a gene in the solr index
    my @genes = c_autocomplete_gene( $validated_params );

    return @genes;

}

sub pspec_design_genes {
    return {
        design_id   => { validate => 'integer'},
    };
}

sub design_gene_ids_and_symbols {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_design_genes );

    my $design = $self->c_retrieve_design({ id => $validated_params->{design_id} });

    my @gene_ids      = uniq map { $_->gene_id } $design->genes;

    my @gene_symbols;
    try{
        @gene_symbols  = uniq map {
            $self->retrieve_gene( { species => $design->species_id, search_term => $_ } )->{gene_symbol}
        } @gene_ids;
    };

    DEBUG("Gene symbols: ".join ",",@gene_symbols);
    return (\@gene_ids, \@gene_symbols);
}

1;

__END__
