package LIMS2::Model::Plugin::CrisprEsQc;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_crispr_es_qc {
    return {
        id         => { validate => 'uuid' },
        created_by => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at => { validate => 'date_time', post_filter => 'parse_date_time', optional => 1 },
        species    => { validate => 'existing_species', rename => 'species_id' },
        wells      => { validate => 'arrayref' },
        sequencing_project => { validate => 'non_empty_string' },
    };
}

=head create_crispr_es_qc

Create a new crispr_es_qc with attached wells.

=cut
sub create_crispr_es_qc_run {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_crispr_es_qc );

    #these will be created separately
    my $wells = delete $validated_params->{wells};

    my $qc_run = $self->schema->resultset('CrisprEsQcRuns')->create( $params );

    #later this will be moved to its own method as we won't create
    #wells when we create the qc
    for my $well ( @{ $wells } ) {
        $self->create_crispr_es_qc_well( $qc_run, $well );
    }

    return 1;
}

sub pspec_create_crispr_es_qc_well {
    return {
        well_id       => { validate => 'existing_well_id' },
        fwd_read      => { validate => 'non_empty_string' },
        rev_read      => { validate => 'non_empty_string' },
        crispr_chr_id => { validate => 'existing_chromosome' },
        crispr_start  => { validate => 'integer' },
        crispr_end    => { validate => 'integer' },
        analysis_data => { validate => 'non_empty_string' },
    };
}

=head2 create_crispr_es_qc_well

Given a QC run add a well with the given parameters

=cut
sub create_crispr_es_qc_well {
    my ( $self, $qc_run, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_crispr_es_qc );

    return $qc_run->create_related(
        crispr_es_qc_wells => $validated_params
    );
}

sub pspec_delete_crispr_es_qc_run {
    return {
        id => { validate => 'integer' },
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
        id => { validate => 'integer' },
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


1;

__END__
