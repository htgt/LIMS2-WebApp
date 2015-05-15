package LIMS2::Model::Plugin::CrisprEsQc;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::CrisprEsQc::VERSION = '0.317';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use DDP;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_crispr_es_qc_run {
    return {
        id         => { validate => 'uuid' },
        created_by => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at => { validate => 'date_time', post_filter => 'parse_date_time', optional => 1 },
        species    => { validate => 'existing_species', rename => 'species_id' },
        sequencing_project => { validate => 'non_empty_string' },
        sub_project => { validate => 'non_empty_string' }
    };
}

=head create_crispr_es_qc

Create a new crispr_es_qc with attached wells.

=cut
sub create_crispr_es_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr_es_qc_run );

    #these will be created separately
    my $wells = delete $validated_params->{wells};

    my $qc_run = $self->schema->resultset('CrisprEsQcRuns')->create( $validated_params );

    #later this will be moved to its own method as we won't create
    #wells when we create the qc
    for my $well ( @{ $wells } ) {
        $well->{crispr_es_qc_run_id} = $qc_run->id;
        $well->{species} = $qc_run->species_id;
        $self->create_crispr_es_qc_well( $well );
    }

    return $qc_run;
}

sub pspec_update_crispr_es_qc_run {
    return {
        id         => { validate => 'uuid' },
        validated  => { validate => 'boolean_string', optional => 1 },
    };
}

=head update_crispr_es_qc

Create a new crispr_es_qc with attached wells.

=cut
sub update_crispr_es_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_crispr_es_qc_run );
    my $qc_run_id = delete $validated_params->{id};
    my $qc_run = $self->retrieve( CrisprEsQcRuns => { id => $qc_run_id } );

    $qc_run->update( $validated_params );
    $self->log->info( "Updated crispr es qc run $qc_run_id  to: " . p( $validated_params ) );

    return $qc_run;
}

sub pspec_create_crispr_es_qc_well {
    return {
        well_id             => { validate => 'integer' },
        fwd_read            => { validate => 'non_empty_string', optional => 1 },
        rev_read            => { validate => 'non_empty_string', optional => 1 },
        crispr_chr_name     => { validate => 'existing_chromosome', optional => 1 },
        crispr_start        => { validate => 'integer', optional => 1},
        crispr_end          => { validate => 'integer', optional => 1},
        analysis_data       => { validate => 'json' },
        vcf_file            => { validate => 'non_empty_string', optional => 1 },
        crispr_es_qc_run_id => { validate => 'non_empty_string' },
        species             => { validate => 'existing_species' },
        crispr_damage_type  => { validate => 'existing_crispr_damage_type', optional => 1, rename => 'crispr_damage_type_id' },
        variant_size        => { validate => 'integer', optional => 1 },
        accepted            => { validate => 'boolean', optional => 1 },
    };
}

=head2 create_crispr_es_qc_well

Given a QC run add a well with the given parameters

=cut
sub create_crispr_es_qc_well {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_crispr_es_qc_well );

    # if the qc well has been marked accepted run this logic
    if ( $validated_params->{accepted} ) {
        my $well = $self->retrieve_well( { id => $validated_params->{well_id} } );
        # only mark qc accepted if the linked well is not already accepted in another run
        if ( $well->accepted ) {
            delete $validated_params->{accepted};
        }
        # mark the linked well accepted
        else {
            $well->update( { accepted => 1 } );
        }
    }

    my $species = delete $validated_params->{species};
    if ( $validated_params->{crispr_chr_name} ) {
        my $chr_name = delete $validated_params->{crispr_chr_name};
        my $chr = $self->schema->resultset('Chromosome')->find(
            {
                name       => $chr_name,
                species_id => $species,
            }
        );
        $validated_params->{crispr_chr_id} = $chr->id;
    }

    return $self->schema->resultset('CrisprEsQcWell')->create( $validated_params );
}

sub pspec_retrieve_crispr_es_qc_well {
    return {
        id => { validate => 'integer' },
    };
}

=head2 retrieve_crispr_es_qc_well

Return a crispr_es_qc_run result for a given id

=cut
sub retrieve_crispr_es_qc_well {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr_es_qc_well );

    return $self->retrieve( CrisprEsQcWell => $validated_params );
}

sub pspec_delete_crispr_es_qc_run {
    return {
        id => { validate => 'non_empty_string' },
    };
}

=head2

Delete a run and all of its associated crispr_es_qc_wells

=cut
sub delete_crispr_es_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_delete_crispr_es_qc_run );

    my $run = $self->schema->resultset('CrisprEsQcRuns')->find( $validated_params );

    $self->throw(
        NotFound => { entity_class  => 'CrisprEsQcRuns', search_params => $validated_params }
    ) unless $run;

    #if we can later create plates off this we will have to add a check in here
    #to make sure none have been made

    $run->crispr_es_qc_wells->delete;
    $run->delete;

    return 1;
}

sub pspec_retrieve_crispr_es_qc_run {
    return {
        id => { validate => 'uuid' },
    };
}

=head2 retrieve_crispr_es_qc_run

Return a crispr_es_qc_run result for a given id

=cut
sub retrieve_crispr_es_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_crispr_es_qc_run );

    return $self->retrieve( CrisprEsQcRuns => $validated_params );
}

sub pspec_update_crispr_es_qc_well {
    return {
        id          => { validate => 'integer' },
        damage_type => {
            validate => 'existing_crispr_damage_type',
            optional => 1,
            rename   => 'crispr_damage_type_id'
            },
        variant_size => { validate => 'integer', optional => 1 },
        accepted     => { validate => 'boolean_string', optional => 1 },
        MISSING_OPTIONAL_VALID => 1,
    };
}

=head2 update_crispr_well_damage

Update the specific values of a crispr es qc well row
- damage_type
- variant_size
- accepted

=cut
sub update_crispr_es_qc_well{
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_crispr_es_qc_well );

    my $id = delete $validated_params->{id};
    my $qc_well = $self->schema->resultset('CrisprEsQcWell')->find( { id => $id } );
    unless ( $qc_well ) {
        $self->throw(
            NotFound => { entity_class => 'CrisprEsQcWell', search_params => { id => $id } } );
    }

    # if the qc well has been marked accepted run this logic
    if ( exists $validated_params->{accepted} ) {
        my $well = $qc_well->well;
        # only mark qc accepted if the linked well is not already accepted in another run
        if ( $well->accepted && $validated_params->{accepted} eq 'true' ) {
            delete $validated_params->{accepted};
            $self->throw(
                'Well already accepted in another run, not marking crispr es qc well as accepted');
        }
        # mark the linked well accepted
        else {
            $well->update( { accepted => $validated_params->{accepted} } );
            $self->log->info( "Updated $well well accepted " . $validated_params->{accepted} );
        }
    }
    # if damage type set to no-call or mosaic then the well must not be accepted
    elsif ( my $damage = $validated_params->{crispr_damage_type_id} ) {
        if ( ( $damage eq 'no-call' || $damage eq 'mosaic' ) && $qc_well->accepted ) {
            $validated_params->{accepted} = 'false';
            $qc_well->well->update( { accepted => 'false' } );
        }
    }

    $qc_well->update( $validated_params );

    $self->log->info( "Updated crispr es qc well "
            . $qc_well->id . ' to: ' . p( $validated_params ) );


    return $qc_well;
}

1;

__END__
