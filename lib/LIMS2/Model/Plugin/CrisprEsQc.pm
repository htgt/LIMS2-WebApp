package LIMS2::Model::Plugin::CrisprEsQc;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::CrisprEsQc::VERSION = '0.451';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use DDP;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;
use Try::Tiny;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_crispr_es_qc_run {
    return {
        id         => { validate => 'uuid' },
        created_by => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at => { validate => 'date_time', post_filter => 'parse_date_time', optional => 1 },
        species    => { validate => 'existing_species', rename => 'species_id' },
        sequencing_project => { validate => 'non_empty_string' },
        sub_project => { validate => 'non_empty_string' },
        allele_number => { validate => 'integer', optional => 1},
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

    my $qc_id_check = $self->schema->resultset('CrisprEsQcRuns')->find( { id => $validated_params->{id} } );
    my $qc_run;
    $qc_run = $self->schema->resultset('CrisprEsQcRuns')->create( $validated_params ) unless $qc_id_check;

    #later this will be moved to its own method as we won't create
    #wells when we create the qc
    for my $well ( @{ $wells } ) {
        $well->{crispr_es_qc_run_id} = $qc_run->id;
        $well->{species} = $qc_run->species_id;
        $self->create_crispr_es_qc_well( $well );
    }
    unless ($qc_id_check) {
        return $qc_run;
    }
    else {
        return $qc_id_check;
    }
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
        crisprs_to_validate => { validate => 'integer', optional => 1 },
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

    my @crisprs_to_validate;
    if ( $validated_params->{crisprs_to_validate} ) {
        @crisprs_to_validate = @{ delete $validated_params->{crisprs_to_validate} };
    }

    my $crispr_es_qc_well = $self->schema->resultset('CrisprEsQcWell')->create( $validated_params );

    for my $crispr_id ( @crisprs_to_validate ) {
        $self->schema->resultset( 'CrisprValidation' )->create(
            {
                crispr_es_qc_well_id => $crispr_es_qc_well->id,
                crispr_id => $crispr_id,
                validated => 0, # default to false, in future we may try to automatically set this value
            }
        );
    }

    return $crispr_es_qc_well;
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

    foreach my $qc_well ($run->crispr_es_qc_wells) {
        # for each qc well we are about to delete
        # update validation to false
        $qc_well->update( { accepted => 0 } );

        # if well is not accepted elsewhere, unaccept well
        if (! $qc_well->well_accepted_any_run) {
            $self->schema->resultset('Well')->find( { id => $qc_well->well->id } )->update( { accepted => 0 } );
        }
    }

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
        if($qc_well->well->plate_type eq 'S_PIQ'){
            # Double targeted!
            # only mark the linked well accepted if we have accepted QC well for the other allele too
            my $this_allele_number = $qc_well->crispr_es_qc_run->allele_number;
            my $other_allele_number;
            if($this_allele_number == 1){
                $other_allele_number = 2;
            }
            elsif($this_allele_number == 2){
                $other_allele_number = 1;
            }
            else{
                die "Sorry, allele number $this_allele_number not supported yet";
            }

            my $other_accepted_qc = $qc_well->well->accepted_crispr_es_qc_well($other_allele_number);
            if($other_accepted_qc){
                $well->update( { accepted => $validated_params->{accepted} } );
                $self->log->info( "Updated $well well accepted to ".$validated_params->{accepted}
                                  ."Accepted crispr QC was found for allele $other_allele_number" );
            }
        }
        else{
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

sub pspec_update_crispr_validation_status {
    return {
        crispr_es_qc_well_id => { validate => 'integer' },
        crispr_id            => { validate => 'integer' },
        validated            => { validate => 'boolean_string' },
    };
}

=head2 update_crispr_validation_status

Update the validated status of a crispr linked to crispr es qc well record.

=cut
sub update_crispr_validation_status {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_crispr_validation_status );

    my $crispr_validation = $self->schema->resultset( 'CrisprValidation' )->find_or_create(
         { slice_def $validated_params, qw( crispr_es_qc_well_id crispr_id ) }
    );

    $crispr_validation->update(
        {
            validated => $validated_params->{validated},
        }
    );
    $self->log->info( "Updated validated crispr: " . p( $validated_params ) );

    return $crispr_validation;
}


sub pspec_set_unset_het_validation {
    return {
        well_id => { validate => 'integer' },
        set => {validate => 'non_empty_string', optional => 1 },
        user => { validate => 'existing_user' },
    };
}

=head2 set_unset_het_validation

Either removes existing Het validation data on a well, or creates blank one.

=cut
sub set_unset_het_validation {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_set_unset_het_validation );
    my $het;

    my $user = $validated_params->{'user'};
    delete $validated_params->{'user'};

    if ( $validated_params->{'set'} eq 'false' ) {
        $het = $self->schema->resultset('WellHetStatus')->find( { well_id => $validated_params->{'well_id'} } )->delete;
        try {
            my $override = $self->delete_well_accepted_override({
                created_by  => $user,
                well_id     => $validated_params->{'well_id'},
            });
        };
    } elsif ($validated_params->{'set'} eq 'true') {
        $het = $self->schema->resultset('WellHetStatus')->create( { well_id => $validated_params->{'well_id'} } );
    }

    return $het;
}


sub pspec_set_het_status {
    return {
        well_id => { validate => 'integer' },
        five_prime => {validate => 'non_empty_string', optional => 1 },
        three_prime => {validate => 'non_empty_string', optional => 1 },
        user => { validate => 'existing_user' },
    };
}

=head2 set_het_status

Sets a Het result for a well on either 5' or 3'. If both are set to true, well gets accepted as an override.

=cut
sub set_het_status {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_set_het_status );

    my $user = $validated_params->{'user'};
    delete $validated_params->{'user'};

    if ( $validated_params->{'five_prime'} ) {
        my $het_validation = $self->schema->resultset( 'WellHetStatus' )->update_or_create(
            { slice_def $validated_params, qw( well_id five_prime ) }
        );
    }
    if ( $validated_params->{'three_prime'} ) {
        my $het_validation = $self->schema->resultset( 'WellHetStatus' )->update_or_create(
            { slice_def $validated_params, qw( well_id three_prime ) }
        );
    }

    my $het = $self->schema->resultset( 'WellHetStatus' )->find(
            { well_id => $validated_params->{'well_id'} } );

    if ( $het->five_prime && $het->three_prime ) {
        my $override = $self->update_or_create_well_accepted_override({
            created_by  => $user,
            well_id     => $validated_params->{'well_id'},
            accepted    => 1,
        });
    } else {
        try {
            my $override = $self->delete_well_accepted_override({
                created_by  => $user,
                well_id     => $validated_params->{'well_id'},
            });
        };
    }

    return $het;
}


sub pspec_list_crispr_es_qc_runs {
    return {
        species    => { validate => 'existing_species' },
        sequencing_project => { validate => 'non_empty_string', optional => 1 },
        plate_name => { validate => 'non_empty_string',  optional => 1 },
        page       => { validate => 'integer', optional => 1, default => 1 },
        pagesize   => { validate => 'integer', optional => 1, default => 15 },
    };
}

sub list_crispr_es_qc_runs {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_list_crispr_es_qc_runs );

    my %search = (
        'me.species_id' => $validated_params->{species},
    );

    if ( $validated_params->{sequencing_project} ) {
        $search{'sequencing_project'} = { 'like', '%' . $validated_params->{sequencing_project} . '%' };
    }
    if ( $validated_params->{plate_name} ) {
        $search{'plate.name'} = { 'like', '%' . $validated_params->{plate_name} . '%' };
    }

    my $resultset = $self->schema->resultset('CrisprEsQcRuns')->search(
        { %search },
        {
            prefetch => [ 'created_by' ],
            join     => {'crispr_es_qc_wells' => { well => 'plate' }},
            order_by => { -desc => "me.created_at" },
            page     => $validated_params->{page},
            rows     => $validated_params->{pagesize},
            distinct => 1
        }
    );

    return ( [ map { $_->as_hash({ include_plate_name => 1}) } $resultset->all ], $resultset->pager );
}

# All QC runs for the specified project which do not already have a data version
# are updated to use the specified data version
sub _pspec_update_qc_runs_with_data_version{
    return {
        sequencing_project => { validate => 'non_empty_string' },
        sequencing_data_version => { validate => 'non_empty_string' },
    };
}

sub update_qc_runs_with_data_version{
    my ($self,$params) = @_;

    my $validated_params = $self->check_params($params, $self->_pspec_update_qc_runs_with_data_version);

    my @qc_runs = $self->schema->resultset('QcRunSeqProject')->search({
        qc_seq_project_id       => $validated_params->{sequencing_project},
        sequencing_data_version => undef,
    })->all;

    push @qc_runs, $self->schema->resultset('CrisprEsQcRuns')->search({
        sequencing_project      => $validated_params->{sequencing_project},
        sequencing_data_version => undef,
    })->all;

    foreach my $run (@qc_runs){
        my $version = $validated_params->{sequencing_data_version};

        $self->log->debug("Adding sequencing_data_version $version to QC run ".$run->id);
        $run->update({ sequencing_data_version => $version })->discard_changes;
    }

    return \@qc_runs;
}
1;

__END__
