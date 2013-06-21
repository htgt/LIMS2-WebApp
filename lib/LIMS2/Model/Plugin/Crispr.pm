package LIMS2::Model::Plugin::Crispr;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Crispr::VERSION = '0.082';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_crispr {
    return {
        type               => { validate => 'existing_crispr_loci_type', rename => 'crispr_loci_type_id' },
        seq                => { validate =>  'dna_seq' },
        species            => { validate => 'existing_species', rename => 'species_id' },
        off_target_outlier => { validate => 'boolean', default => 0 },
        comment            => { validate => 'non_empty_string', optional => 1 },
        locus              => { validate => 'hashref' },
        off_targets        => { optional => 1 },
    };
}

=head2 create_crispr

Create a crispr record, along with its locus and off target information.
If crispr with same sequence and locus already exists then just replace
the off target information.

=cut
sub create_crispr {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr );

    my $crispr = $self->find_crispr_by_seq_and_locus(
        {
            seq     => $validated_params->{seq},
            species => $validated_params->{species_id},
            slice_def(
                $validated_params->{locus},
                qw( chr_start chr_end chr_name chr_strand assembly )
            )
        }
    );

    # If crispr with same seq and locus exists just drop off targets and create new ones
    # otherwise create brand new crispr
    if ( $crispr ) {
        $self->log->debug( 'Found identical crispr site, just replacing off targets: ' . $crispr->id );
        $crispr->off_targets->delete;
        for my $o ( @{ $validated_params->{off_targets} || [] } ) {
            $o->{crispr_id} = $crispr->id;
            $self->create_crispr_off_target( $o, $crispr );
        }
    }
    else {
        $crispr = $self->_create_crispr( $validated_params );
    }

    return $crispr;
}

=head2 _create_crispr

Actually create the crispr record here.

=cut
sub _create_crispr {
    my ( $self, $validated_params ) = @_;

    my $crispr = $self->schema->resultset('Crispr')->create(
        {   slice_def(
                $validated_params,
                qw( id species_id crispr_loci_type_id
                    seq off_target_outlier comment
                    )
            )
        }
    );
    $self->log->debug( 'Create crispr ' . $crispr->id );

    my $locus_params = $validated_params->{locus};
    $locus_params->{crispr_id} = $crispr->id;
    $self->create_crispr_locus( $locus_params, $crispr );

    for my $o ( @{ $validated_params->{off_targets} || [] } ) {
        $o->{crispr_id} = $crispr->id;
        $self->create_crispr_off_target( $o, $crispr );
    }

    return $crispr;
}

sub pspec_create_crispr_locus {
    return {
        assembly   => { validate => 'existing_assembly' },
        chr_name   => { validate => 'existing_chromosome' },
        chr_start  => { validate => 'integer' },
        chr_end    => { validate => 'integer' },
        chr_strand => { validate => 'strand' },
        crispr_id  => { validate => 'integer' },
    };
}

=head2 create_crispr_locus

Create a locus row for a given crispr.

=cut
sub create_crispr_locus {
    my ( $self, $params, $crispr ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr_locus );
    $self->trace( "Create crispr locus", $validated_params );

    $crispr ||= $self->retrieve_crispr(
        {
            id => $validated_params->{crispr_id},
        }
    );

    $crispr->species->check_assembly_belongs( $validated_params->{assembly} );

    my $crispr_locus = $crispr->create_related(
        loci => {
            assembly_id => $validated_params->{assembly},
            chr_id      => $self->_chr_id_for( @{$validated_params}{ 'assembly', 'chr_name' } ),
            chr_start   => $validated_params->{chr_start},
            chr_end     => $validated_params->{chr_end},
            chr_strand  => $validated_params->{chr_strand}
        }
    );

    return $crispr_locus;
}

sub pspec_create_crispr_off_target {
    return {
        assembly   => { validate => 'existing_assembly' },
        build      => { validate => 'integer' },
        chr_name   => { validate => 'non_empty_string' },
        chr_start  => { validate => 'integer' },
        chr_end    => { validate => 'integer' },
        chr_strand => { validate => 'strand' },
        crispr_id  => { validate => 'integer' },
        type       => { validate => 'existing_crispr_loci_type' },
    };
}

=head2 create_crispr_off_target

Create a off target hit for a given crispr.

=cut
sub create_crispr_off_target {
    my ( $self, $params, $crispr ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr_off_target );
    $self->trace( "Create crispr off target", $validated_params );

    $crispr ||= $self->retrieve_crispr(
        {
            id => $validated_params->{crispr_id},
        }
    );

    $crispr->species->check_assembly_belongs( $validated_params->{assembly} );

    my $crispr_off_target = $crispr->create_related(
        off_targets => {
            assembly_id         => $validated_params->{assembly},
            build_id            => $validated_params->{build},
            chromosome          => $validated_params->{chr_name},
            chr_start           => $validated_params->{chr_start},
            chr_end             => $validated_params->{chr_end},
            chr_strand          => $validated_params->{chr_strand},
            crispr_loci_type_id => $validated_params->{type},
        }
    );

    return $crispr_off_target;
}

sub pspec_delete_crispr {
    return {
        id => { validate => 'integer' },
    };
}

sub delete_crispr {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_delete_crispr );

    my %search = slice( $validated_params, 'id' );
    my $crispr = $self->schema->resultset( 'Crispr' )->find( \%search )
        or $self->throw(
            NotFound => {
                entity_class  => 'Crispr',
                search_params => \%search
            }
        );

    #TODO check this works sp12 Wed 22 May 2013 14:57:08 BST
    # Check that crispr is not allocated to a process and, if it is, refuse to delete
    #if ( $crispr->process_cripers_rs->count > 0 ) {
        #$self->throw( InvalidState => 'Crisper ' . $crisper->id . ' has been used in one or more processes' );
    #}

    $crispr->off_targets->delete;
    $crispr->loci->delete;
    $crispr->delete;

    return 1;
}

sub pspec_retrieve_crispr {
    return {
        id      => { validate => 'integer' },
        species => { validate => 'existing_species', rename => 'species_id', optional => 1 }
    };
}

sub retrieve_crispr {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr );

    my $crispr = $self->retrieve( Crispr => { slice_def $validated_params, qw( id species_id ) } );

    return $crispr;
}

sub pspec_find_crispr_by_seq_and_locus {
    return {
        species    => { validate => 'existing_species', rename => 'species_id' },
        assembly   => { validate => 'existing_assembly' },
        chr_name   => { validate => 'existing_chromosome' },
        chr_start  => { validate => 'integer' },
        chr_end    => { validate => 'integer' },
        chr_strand => { validate => 'strand' },
        seq        => { validate => 'dna_seq' },
    };
}

=head2 find_crispr_by_seq_and_locus

Find crispr site by sequence and locus ( on same assembly for same species )

=cut
sub find_crispr_by_seq_and_locus {
    my ( $self, $params ) = @_;
    my @identical_crisprs;

    my $validated_params = $self->check_params( $params, $self->pspec_find_crispr_by_seq_and_locus );

    my @crisprs_same_seq = $self->schema->resultset('Crispr')->search(
        {
            seq        => $validated_params->{seq},
            species_id => $validated_params->{species_id},
        }
    );

    for my $crispr ( @crisprs_same_seq ) {
        my $locus = $crispr->loci->find( { assembly_id => $validated_params->{assembly} } );
        $self->throw(
            InvalidState => "Can not find crispr locus information on assembly "
            . $validated_params->{assembly}
        ) unless $locus;

        if (
               $locus->chr->name  eq $validated_params->{chr_name}
            && $locus->chr_start  eq $validated_params->{chr_start}
            && $locus->chr_end    eq $validated_params->{chr_end}
            && $locus->chr_strand eq $validated_params->{chr_strand}
        ) {
            push @identical_crisprs, $crispr;
        }
    }

    if ( scalar( @identical_crisprs ) == 1 ) {
        return shift @identical_crisprs;
    }
    elsif ( scalar( @identical_crisprs ) > 1 ) {
        $self->throw( InvalidState => 'Found multiple crispr sites with same sequence and locus' );
    }

    return;
}

1;

__END__
