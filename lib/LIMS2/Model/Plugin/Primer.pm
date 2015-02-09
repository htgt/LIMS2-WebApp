package LIMS2::Model::Plugin::Primer;

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

# Retrieve only the crispr primer where the is_rejected flag is not set to true
# There should be only one of these but this is constrained in the model
# rather than the database so it may not always be the case
sub retrieve_current_crispr_primer{
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr_primer );

    my %params = slice_def $validated_params,
            qw( crispr_id crispr_pair_id crispr_group_id primer_name );

    $params{is_rejected} = [0, undef];

    my $crispr_primer = $self->retrieve(
        CrisprPrimer => \%params,
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
        overwrite       => { validate => 'boolean', optional => 1, default => 0 },
        check_for_rejection => { validate => 'boolean', optional => 1, default => 0 },
        REQUIRE_SOME    => { single_pair_or_group_crispr_id =>
                [ 1, qw( crispr_id crispr_pair_id crispr_group_id ) ] },
    };
}

=head2 create_genotyping_primer

Like create_crispr_primer.. but for genotyping primers which are linked to a design

=cut
sub create_genotyping_primer{
    my ($self) = @_;

    die "Not yet implemented";

    return;
}

=head2 create_crispr_primer

Create a crispr primer record, along with its locus.
First check to see crispr does not already have primer of same type.

To overwrite the existing primer use overwrite = 1
To check if this primer seq has previously been rejected before creating it
use check_for_rejection = 1

You should run this in a txn_do

=cut
sub create_crispr_primer {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr_primer );

    my %search_params = slice_def( $validated_params,
        qw( crispr_id crispr_pair_id crispr_group_id primer_name )
    );
    my @existing_primers = $self->schema->resultset('CrisprPrimer')->search(\%search_params)->all;
    my %rejected_seqs;
    my @current_primers;
    foreach my $existing (@existing_primers){
        if($existing->is_rejected){
            my $seq = uc($existing->primer_seq);
            $rejected_seqs{$seq} = 1;
        }
        else{
            push @current_primers, $existing;
        }
    }

    my $ready_to_create = 0;
    if(@current_primers){
        $self->log->debug('Existing crispr primers found');
        unless($validated_params->{overwrite}){
            $self->throw( Validation => 'Primer '.$validated_params->{primer_name}.' already exists' );
        }

        if($validated_params->{check_for_rejection}){
            $self->_check_for_rejection($validated_params->{primer_seq}, \%rejected_seqs);
        }

        # If method has not died yet it is time to remove existing and create new primer
        foreach my $existing (@current_primers){
            $self->log->debug('Deleting existing primer '.$existing->id);
            $existing->delete;
        }
        $ready_to_create = 1;
    }
    else{
        if($validated_params->{check_for_rejection}){
            $self->_check_for_rejection($validated_params->{primer_seq}, \%rejected_seqs);
        }

        # If method has not died we can go ahead and create the primer
        $ready_to_create = 1;
    }

    my $crispr_primer;
    if($ready_to_create){
        $crispr_primer = $self->schema->resultset('CrisprPrimer')->create({
            slice_def(
                $validated_params,
                qw( crispr_id crispr_pair_id crispr_group_id
                    primer_seq primer_name tm gc_content
                    )
            )
        });

        $self->log->debug( 'Create crispr primer ' . $crispr_primer->id );

        my $locus_params = $validated_params->{locus};
        $locus_params->{crispr_oligo_id} = $crispr_primer->id;
        $self->create_crispr_primer_locus( $locus_params, $crispr_primer );
    }

    return $crispr_primer;
}

sub _check_for_rejection{
    my ($self, $seq, $rejected_seqs) = @_;
    $seq = uc($seq);
    $self->log->debug('Checking if new primer seq has previously been rejected');
    if($rejected_seqs->{$seq}){
        $self->throw( Validation => "Primer with sequence $seq has previously been rejected" );
    }
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
