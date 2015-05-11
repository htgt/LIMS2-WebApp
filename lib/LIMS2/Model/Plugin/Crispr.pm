package LIMS2::Model::Plugin::Crispr;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Crispr::VERSION = '0.314';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use Data::Dump 'pp';
use TryCatch;
use LIMS2::Exception;
use LIMS2::Util::WGE;
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
        wge_crispr_id        => { validate => 'integer', optional => 1 },
        nonsense_crispr_original_crispr_id => { validate => 'integer', optional => 1 },
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
        #also update the wge_crispr_id if its set
        if ( $params->{wge_crispr_id} ) {
            if ( (! $crispr->{wge_crispr_id}) || $crispr->{wge_crispr_id} ne $params->{wge_crispr_id} ) {
                $crispr->update( { wge_crispr_id => $params->{wge_crispr_id} } );
            }
        }

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
                    seq comment pam_right wge_crispr_id
                    nonsense_crispr_original_crispr_id
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

    # If we have existing off target data for this algorithm throw error
    if ( $crispr->off_targets->count ) {
        $self->throw(
            InvalidState => 'Crispr ' . $crispr->id . ' has off targets stored in database, can not update' );
    }

    my $existing_off_targets = $crispr->off_target_summaries->find(
        {
            algorithm => $validated_params->{off_target_algorithm}
        }
    );

    # if we just have off target summary data replace it
    if ( $existing_off_targets ) {
        $existing_off_targets->delete;
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

sub pspec_retrieve_crispr_off_target {
    return {
        crispr_id            => { validate => 'integer', optional => 1 },
        off_target_crispr_id => { validate => 'integer', optional => 1 },
        id                   => { validate => 'integer', optional => 1 },
        REQUIRE_SOME         => { id_or_crispr_id => [ 1, qw( id crispr_id ) ] },
        DEPENDENCY_GROUPS    => { crispr_ids => [ qw( crispr_id off_target_crispr_id ) ] },
    };
}

=head2 retrieve_crispr_off_target

Create a off target hit for a given crispr.

=cut
sub retrieve_crispr_off_target {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr_off_target );
    $self->log->debug( 'Retrieve crispr off target: ' . pp $validated_params );

    my $crispr_off_target = $self->retrieve(
        CrisprOffTargets => { slice_def $validated_params, qw( id crispr_id off_target_crispr_id ) } );

    return $crispr_off_target;
}

sub pspec_create_crispr_off_target {
    return {
        crispr_id        => { validate => 'integer' },
        ot_crispr_id     => { validate => 'integer', optional => 1 },
        mismatches       => { validate => 'integer' },
    };
}

=head2 create_crispr_off_target

Create a off target hit for a given crispr.

=cut
sub create_crispr_off_target {
    my ( $self, $params, $crispr ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr_off_target );
    $self->log->debug( 'Create crispr off target: ' . pp $validated_params );

    if ( $validated_params->{crispr_id} == $validated_params->{ot_crispr_id} ) {
        $self->throw(
            InvalidState => 'Crispr can not be its own off target');
    }

    $crispr ||= $self->retrieve_crispr(
        {
            id => $validated_params->{crispr_id},
        }
    );

    if ( $crispr->off_targets->find( { off_target_crispr_id => $validated_params->{ot_crispr_id} } )
        )
    {
        $self->throw(
            Validation => 'Crispr already has off target: ' . $validated_params->{ot_crispr_id} );
    }


    my $ot_crispr = $self->retrieve_crispr( { id => $validated_params->{ot_crispr_id} } );

    my $crispr_off_target = $crispr->create_related(
        off_targets => {
            off_target_crispr_id => $ot_crispr->id,
            mismatches           => $validated_params->{mismatches},
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
        id      => { validate => 'integer', optional => 1},
        wge_crispr_id  => { validate => 'integer', optional => 1 },
        REQUIRE_SOME => { id_or_wge_crispr_id => [ 1, qw( id wge_crispr_id ) ] },
        species => { validate => 'existing_species', rename => 'species_id', optional => 1 },
    };
}

sub retrieve_crispr {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr );

    my $crispr = $self->retrieve( Crispr => { slice_def $validated_params, qw( id wge_crispr_id species_id ) } );

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

sub pspec_retrieve_crispr_pair {
    return {
        id => { validate => 'integer' },
    };
}

sub retrieve_crispr_pair {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr_pair );

    my $crispr_pair = $self->retrieve(
        CrisprPair => {  'me.id' => $validated_params->{id} },
        { prefetch => [ 'left_crispr', 'right_crispr' ] }
    );

    return $crispr_pair;
}

sub pspec_update_crispr_off_target_summary{
    return {
         id                 => { validate => 'integer' },
         algorithm          => { validate => 'non_empty_string' },
         off_target_summary => { validate => 'non_empty_string' },
    };
}

sub update_crispr_off_target_summary {
    my ( $self, $params ) = @_;

    my $validated_params  =$self->check_params( $params, $self->pspec_update_crispr_off_target_summary );

    my $crispr = $self->retrieve_crispr({ id => $validated_params->{id} });

    $self->log->debug("Updating crsipr " . $crispr->id . " with "
                        . $validated_params->{off_target_summary} . "\n");

    my $summary = $crispr->off_target_summaries->find( { algorithm => $validated_params->{algorithm} } );

    $summary->update( { summary => $validated_params->{off_target_summary} } );

    return $summary;
}

sub pspec_update_crispr_pair_off_target_summary{
    return {
         l_id               => { validate => 'integer' },
         r_id               => { validate => 'integer' },
         off_target_summary => { validate => 'non_empty_string' },
    };
}

sub update_crispr_pair_off_target_summary{
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_crispr_pair_off_target_summary);

    my $pair =  $self->schema->resultset("CrisprPair")->find(
                                {
                                    left_crispr_id => $validated_params->{l_id},
                                    right_crispr_id => $validated_params->{r_id},
                                }
                            );

    $pair->update( { off_target_summary => $validated_params->{off_target_summary} } );
    return $pair;
}

sub pspec_update_or_create_crispr_pair{
    # FIXME: spacer should be signed int - need to add this to form validator
    return {
        l_id               => { validate => 'integer' },
        r_id               => { validate => 'integer' },
        spacer             => { validate => 'non_empty_string' },
        off_target_summary => { validate => 'non_empty_string', optional => 1 },
    };
}

sub update_or_create_crispr_pair{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_or_create_crispr_pair );

    my $pair = $self->schema->resultset("CrisprPair")->update_or_create(
                {
                    left_crispr_id     => $validated_params->{l_id},
                    right_crispr_id    => $validated_params->{r_id},
                    spacer             => $validated_params->{spacer},
                    off_target_summary => $validated_params->{off_target_summary},
                },
                { key => "unique_pair" }
            );

    return $pair;
}

sub import_wge_crisprs {
    my ( $self, $ids, $species, $assembly, $wge ) = @_;

    $wge ||= LIMS2::Util::WGE->new;

    my @output;
    for my $crispr_id ( @{ $ids } ) {
        next unless $crispr_id; #skip blank lines

        try {
            my $crispr_data = $wge->get_crispr( $crispr_id, $assembly, $species );
            my $crispr = $self->create_crispr( $crispr_data );
            push @output, { wge_id => $crispr_id, lims2_id => $crispr->id, db_crispr => $crispr };
        }
        catch ($err) {
            LIMS2::Exception->throw( "Error importing WGE crispr with id $crispr_id\n$err" );
        }
    }

    return @output;
}

sub import_wge_pairs {
    my ( $self, $pair_ids, $species, $assembly ) = @_;

    my $wge = LIMS2::Util::WGE->new;

    my @output;
    for my $pair_id ( @{ $pair_ids } ) {
        next unless $pair_id;

        my @ids = $pair_id =~ /^(\d+)_(\d+)$/;

        unless ( @ids == 2 ) {
            LIMS2::Exception->throw( "Invalid WGE crispr pair id: $pair_id" );
        }

        try {
            my $crispr_pair_data = $wge->get_crispr_pair( @ids, $species, $assembly );
            if ( $species ne $crispr_pair_data->{species} ) {
                LIMS2::Exception->throw(
                    "LIMS2 is set to '$species' and pair is '" . $crispr_pair_data->{species} . "'\n"
                  . "Please switch to the correct species"
                );
            }

            #this creates the two crisprs in lims2
            my @crisprs = $self->import_wge_crisprs( \@ids, $species, $assembly );

            #pull out the dbix rows so its clear what we're actually doing
            my $lims2_left_crispr  = $crisprs[0]->{db_crispr};
            my $lims2_right_crispr = $crisprs[1]->{db_crispr};

            #now create the lims2 crispr pair
            my $lims2_crispr_pair = $self->update_or_create_crispr_pair( {
                l_id   => $lims2_left_crispr->id,
                r_id   => $lims2_right_crispr->id,
                spacer => $crispr_pair_data->{spacer},
            } );

            push @output, {
                wge_id      => $pair_id,
                lims2_id    => $lims2_crispr_pair->id,
                left_id     => $lims2_left_crispr->id,
                right_id    => $lims2_right_crispr->id,
                spacer      => $crispr_pair_data->{spacer},
            };
        }
        catch ( $err ) {
            LIMS2::Exception->throw( "Error importing WGE pair with id $pair_id\n$err" );
        }
    }

    return @output;
}

sub pspec_retrieve_crispr_group {
    return {
        id => { validate => 'integer' },
    };
}

sub retrieve_crispr_group {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr_group );

    my $crispr_group = $self->retrieve(
        CrisprGroup => {  'me.id' => $validated_params->{id} },
    );

    return $crispr_group;
}

sub pspec_create_crispr_group {
    return {
        crisprs      => { validate => 'hashref' },
        gene_id      => { validate => 'non_empty_string' },
        gene_type_id => { validate => 'non_empty_string' },
    };
}

# needs as params the gene_id and gene_type_id, and an array of hashes containing the crispr_id and the left_of_target boolean
sub create_crispr_group {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr_group );

    my $crispr_group;
    $self->schema->txn_do( sub {
        try {
            # create the group for the given gene
            $crispr_group = $self->schema->resultset('CrisprGroup')->create({
                gene_id      => $validated_params->{'gene_id'},
                gene_type_id => $validated_params->{'gene_type_id'},
            });
            $self->log->debug( 'Create crispr group ' . $crispr_group->id );

            # add the given crisprs to that group
            foreach my $crispr ( @{ $validated_params->{'crisprs'} } ) {
                $crispr_group->crispr_group_crisprs->create( {
                    crispr_id  => $crispr->{'crispr_id'},
                    left_of_target => $crispr->{'left_of_target'},
                } );
            }

        }
        catch ($err) {
            $self->schema->txn_rollback;
            LIMS2::Exception->throw( "Error creating crispr group: $err" );
        }

    });

    return $crispr_group;
}

sub pspec_retrieve_crispr_collection{
    return{
        crispr_id       => { validate => 'integer', optional => 1, rename => 'id' },
        crispr_pair_id  => { validate => 'integer', optional => 1, rename => 'id' },
        crispr_group_id => { validate => 'integer', optional => 1, rename => 'id' },
        REQUIRE_SOME    => { crispr_pair_or_group_id => [ 1, qw( crispr_id crispr_pair_id crispr_group_id ) ] }
    };
}

# Retrieves a crispr, crispr_pair or crispr_group depending on params it is given
sub retrieve_crispr_collection{
    my ($self, $params) = @_;

    my $method_for_type = {
        crispr_id       => 'retrieve_crispr',
        crispr_pair_id  => 'retrieve_crispr_pair',
        crispr_group_id => 'retrieve_crispr_group',
    };

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr_collection );
    my ($id_type) = keys %$params;
    my $method_name = $method_for_type->{$id_type} or die "No method to retrieve $id_type";

    return $self->$method_name($validated_params);
}

1;

__END__
