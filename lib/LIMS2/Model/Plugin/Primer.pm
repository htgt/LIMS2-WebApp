package LIMS2::Model::Plugin::Primer;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Primer::VERSION = '0.286';
}
## use critic


use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use TryCatch;
use LIMS2::Exception;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub pspec_retrieve_crispr_primer {
    return {
        crispr_id       => { validate => 'integer', optional => 1 },
        crispr_pair_id  => { validate => 'integer', optional => 1 },
        crispr_group_id => { validate => 'integer', optional => 1 },
        primer_name     => { validate => 'alphanumeric_string' },
        REQUIRE_SOME => { single_pair_or_group_crispr_id =>
                [ 1, qw( crispr_id crispr_pair_id crispr_group_id ) ] },
    };
}

sub retrieve_crispr_primer {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr_primer );

    my $crispr_primer = $self->retrieve(
        CrisprPrimer => {
            slice_def $validated_params,
            qw( crispr_id crispr_pair_id crispr_group_id primer_name )
        }
    );

    return $crispr_primer;
}

sub pspec_create_crispr_primer {
    return {
        crispr_id       => { validate => 'integer', optional => 1 },
        crispr_pair_id  => { validate => 'integer', optional => 1 },
        crispr_group_id => { validate => 'integer', optional => 1 },
        primer_name     => { validate => 'existing_crispr_primer_type' },
        primer_seq      => { validate => 'dna_seq' },
        tm              => { validate => 'numeric', optional => 1 },
        gc_content      => { validate => 'numeric', optional => 1 },
        locus           => { validate => 'hashref' },
        REQUIRE_SOME    => { single_pair_or_group_crispr_id =>
                [ 1, qw( crispr_id crispr_pair_id crispr_group_id ) ] },
    };
}

=head2 create_crispr_primer

Create a crispr primer record, along with its locus.
First check to see crispr does not already have primer of same type.

=cut
sub create_crispr_primer {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr_primer );

    my $crispr_primer = $self->schema->resultset('CrisprPrimer')->create(
        {   slice_def(
                $validated_params,
                qw( crispr_id crispr_pair_id crispr_group_id
                    primer_seq primer_name tm gc_content
                    )
            )
        }
    );
    $self->log->debug( 'Create crispr primer ' . $crispr_primer->id );

    my $locus_params = $validated_params->{locus};
    $locus_params->{crispr_oligo_id} = $crispr_primer->id;
    $self->create_crispr_primer_locus( $locus_params, $crispr_primer );

    return;
}

sub pspec_create_crispr_primer_locus {
    return {
        assembly        => { validate => 'existing_assembly' },
        chr_name        => { validate => 'existing_chromosome' },
        chr_start       => { validate => 'integer' },
        chr_end         => { validate => 'integer' },
        chr_strand      => { validate => 'strand' },
        crispr_oligo_id => { validate => 'integer' },
    };
}

=head2 create_crispr_primer_locus

Create locus record for a crisper primer, for a given assembly

=cut
sub create_crispr_primer_locus {
    my ( $self, $params, $crispr_primer ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr_primer_locus );
    $self->trace( "Create crispr primer locus", $validated_params );

    $crispr_primer ||= $self->schema->resultset( 'CrisprPrimer' )->find(
        {
            id => $validated_params->{crispr_oligo_id},
        }
    );

    my $crispr_primer_locus = $crispr_primer->create_related(
        crispr_primer_loci => {
            assembly_id => $validated_params->{assembly},
            chr_id      => $self->_chr_id_for( @{$validated_params}{ 'assembly', 'chr_name' } ),
            chr_start   => $validated_params->{chr_start},
            chr_end     => $validated_params->{chr_end},
            chr_strand  => $validated_params->{chr_strand}
        }
    );

    return $crispr_primer_locus;
}

1;

__END__
