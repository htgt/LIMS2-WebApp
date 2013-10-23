package LIMS2::Model::Plugin::Crispr;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Crispr::VERSION = '0.115';
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
        type                 => { validate => 'existing_crispr_loci_type', rename => 'crispr_loci_type_id' },
        seq                  => { validate =>  'dna_seq' },
        species              => { validate => 'existing_species', rename => 'species_id' },
        comment              => { validate => 'non_empty_string', optional => 1 },
        off_target_summary   => { validate => 'non_empty_string', optional => 1 },
        off_target_algorithm => { validate => 'non_empty_string' },
        off_target_outlier   => { validate => 'boolean', default => 0 },
        locus                => { validate => 'hashref' },
        pam_right            => { validate => 'boolean' },
        off_targets          => { optional => 1 },
    };
}

=head2 create_crispr

Create a crispr record, along with its locus and off target information.
If crispr with same sequence and locus already exists then add or replace
the off target information.

=cut
sub create_crispr {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr );

    my $crispr = $self->find_crispr_by_seq_and_locus(
        {
            seq       => $validated_params->{seq},
            species   => $validated_params->{species_id},
            pam_right => $validated_params->{pam_right},
            slice_def(
                $validated_params->{locus},
                qw( chr_start chr_end chr_name chr_strand assembly )
            )
        }
    );

    # If crispr with same seq and locus exists we need to just deal with the crispr off target data
    if ( $crispr ) {
        $self->log->debug( 'Found identical crispr site, just updating off target data: ' . $crispr->id );
        return $self->update_or_create_crispr_off_targets( $crispr, $validated_params );
    }

    return $self->_create_crispr( $validated_params );
}

=head2 _create_crispr

Actually create the brand new crispr record here.

=cut
sub _create_crispr {
    my ( $self, $validated_params ) = @_;

    my $crispr = $self->schema->resultset('Crispr')->create(
        {   slice_def(
                $validated_params,
                qw( id species_id crispr_loci_type_id
                    seq comment pam_right
                    )
            )
        }
    );
    $self->log->debug( 'Create crispr ' . $crispr->id );

    my $locus_params = $validated_params->{locus};
    $locus_params->{crispr_id} = $crispr->id;
    $self->create_crispr_locus( $locus_params, $crispr );

    $self->add_crispr_off_target_data( $crispr, $validated_params );

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

=head2 update_or_create_crispr_off_targets

If we already have off target data for crispr using same algorithm replace the data.
If no off target data exists for the algorithm then insert data.

=cut
sub update_or_create_crispr_off_targets {
    my ( $self, $crispr, $validated_params ) = @_;

    my $existing_off_targets = $crispr->off_target_summaries->find(
        {
            algorithm => $validated_params->{off_target_algorithm}
        }
    );

    # If we have existing off target data for this algorithm delete current data
    if ( $existing_off_targets ) {
        $existing_off_targets->delete;
        $crispr->off_targets->search_rs(
            { algorithm => $validated_params->{off_target_algorithm} } )->delete;
    }

    $self->add_crispr_off_target_data( $crispr, $validated_params );

    return $crispr;

}

=head2 add_crispr_off_target_data

Add data about off target hits for a crispr

=cut
sub add_crispr_off_target_data {
    my ( $self, $crispr, $validated_params ) = @_;

    for my $o ( @{ $validated_params->{off_targets} || [] } ) {
        $o->{crispr_id} = $crispr->id;
        $o->{algorithm} = $validated_params->{off_target_algorithm};
        $self->create_crispr_off_target( $o, $crispr );
    }

    $crispr->create_related(
        off_target_summaries => {
            outlier    => $validated_params->{off_target_outlier},
            algorithm  => $validated_params->{off_target_algorithm},
            summary    => $validated_params->{off_target_summary},
        }
    );

    return;
}

=head2 create_crispr_locus

Create locus record for a crisper, for a given assembly

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
        algorithm  => { validate => 'non_empty_string' },
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
            algorithm           => $validated_params->{algorithm},
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

    # Check that crispr is not allocated to a process and, if it is, refuse to delete
    if ( $crispr->process_crisprs->count > 0 ) {
        $self->throw(
            InvalidState => 'Crispr ' . $crispr->id . ' has been used in one or more processes' );
    }

    $crispr->off_targets->delete;
    $crispr->off_target_summaries->delete;
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
        pam_right  => { validate => 'boolean' },
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
            pam_right  => $validated_params->{pam_right},
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
