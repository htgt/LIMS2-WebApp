package LIMS2::Model::Plugin::BAC;

use strict;
use warnings FATAL => 'all';

use Moose::Role;

requires qw( schema check_params throw retrieve );

sub list_bac_libraries {
    my ( $self ) = @_;

    return [ map { $_->id } $self->schema->resultset( 'BacLibrary' )->all ];
}

sub pspec_create_bac_clone {
    return {
        bac_library => { validate => 'existing_bac_library', rename => 'bac_library_id' },
        bac_name    => { validate => 'bac_name', rename => 'name' },
        loci        => { optional => 1 }
    };
}

sub pspec_create_bac_clone_locus {
    return {
        assembly  => { validate => 'existing_assembly', rename => 'assembly_id' },
        chr_name  => { validate => 'existing_chromosome', rename => 'chr_id' },
        chr_start => { validate => 'integer' },
        chr_end   => { validate => 'integer' }
    };
}

sub create_bac_clone {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_bac_clone );

    my $loci = delete $validated_params->{loci} || [];

    my $bac_clone = $self->schema->resultset( 'BacClone' )->create( $validated_params );

    for my $locus ( @{$loci} ) {
        my $validated_locus = $self->check_params( $locus, $self->pspec_create_bac_clone_locus );
        $bac_clone->create_related( loci => $validated_locus );
    }

    return $bac_clone;
}

sub pspec_delete_bac_clone {
    return {
        bac_library => { validate => 'existing_bac_library', rename => 'bac_library_id' },
        bac_name    => { validate => 'bac_name', rename => 'name' }
    };
}

sub delete_bac_clone {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_delete_bac_clone );

    my $bac_clone = $self->schema->resultset( 'BacClone' )->find( $validated_params )
        or $self->throw(
            NotFound => {
                entity_class  => 'BacClone',
                search_params => $validated_params
            }
        );

    for my $locus ( $bac_clone->loci ) {
        $locus->delete;
    }

    $bac_clone->delete;

    return 1;
}

1;

__END__
