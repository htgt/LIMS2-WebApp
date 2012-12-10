package LIMS2::Model::Plugin::Well;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use LIMS2::Model::Util::ComputeAcceptedStatus qw( compute_accepted_status );
use namespace::autoclean;
use LIMS2::Model::ProcessGraph;
use LIMS2::Model::Util::EngSeqParams qw( fetch_design_eng_seq_params fetch_well_eng_seq_params add_display_id);
use LIMS2::Model::Util::RankQCResults qw( rank );
use Log::Log4perl qw( :easy );

requires qw( schema check_params throw retrieve log trace );

sub pspec_retrieve_well {
    return {
        id                => { validate   => 'integer',    optional => 1 },
        plate_name        => { validate   => 'plate_name', optional => 1 },
        well_name         => { validate   => 'well_name',  optional => 1 },
        DEPENDENCY_GROUPS => { name_group => [qw( plate_name well_name )] },
        REQUIRE_SOME      => { id_or_name => [ 1, qw( id plate_name well_name ) ] }
    };
}

sub retrieve_well {
    my ( $self, $params ) = @_;

    my $data = $self->check_params( $params, $self->pspec_retrieve_well, ignore_unknown => 1 );

    my %search;
    if ( $data->{id} ) {
        $search{'me.id'} = $data->{id};
    }
    if ( $data->{well_name} ) {
        $search{'me.name'} = $data->{well_name};
    }
    if ( $data->{plate_name} ) {
        $search{'plate.name'} = $data->{plate_name};
    }

    return $self->retrieve( Well => \%search, { join => 'plate', prefetch => 'plate' } );
}

sub pspec_create_well {
    return {
        plate_name   => { validate => 'existing_plate_name' },
        well_name    => { validate => 'well_name', rename => 'name' },
        process_data => { validate => 'hashref' },
        created_by => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    };
}

sub create_well {
    my ( $self, $params, $plate ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well );

    $plate ||= $self->retrieve_plate( { name => $validated_params->{plate_name} } );

    my $validated_well_params
        = { slice_def $validated_params, qw( name created_at created_by_id ) };

    my $well = $plate->create_related( wells => $validated_well_params );

    my $process_params = $validated_params->{process_data};
    $process_params->{output_wells} = [ { id => $well->id } ];

    $self->create_process($process_params);

    return $well;
}

sub delete_well {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well($params);

    if ( $well->input_processes > 0 ) {
        $self->throw( InvalidState => "Cannot delete a well that is an input to another process" );
    }

    for my $p ( $well->output_processes ) {
        if ( $p->output_wells == 1 ) {
            $self->delete_process( { id => $p->id } );
        }
    }

    my @related_resultsets = qw( well_accepted_override well_comments well_dna_quality well_dna_status
                                 well_qc_sequencing_result well_recombineering_results well_colony_counts well_primer_bands );

    for my $rs ( @related_resultsets ) {
        $well->search_related_rs( $rs )->delete;
    }

    $well->delete;
    return;
}

sub pspec_retrieve_well_accepted_override {
    return {
        well_id => { validate => 'integer' }
    }
}

sub retrieve_well_accepted_override {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_well_accepted_override );

    return $self->retrieve( WellAcceptedOverride => $validated_params );
}

sub pspec_create_well_accepted_override {
    return {
        plate_name => { validate => 'existing_plate_name', optional => 1 },
        well_name  => { validate => 'well_name',           optional => 1 },
        well_id    => { validate => 'integer',             optional => 1 },
        created_by => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        accepted   => { validate => 'boolean' }
    };
}

sub create_well_accepted_override {
    my ( $self, $params ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec_create_well_accepted_override );

    my $well = $self->retrieve_well(
        { slice_def $validated_params, qw( plate_name well_name well_id ) } );

    my $override = $well->create_related( well_accepted_override =>
            { slice_def $validated_params, qw( created_by_id created_at accepted ) } );

    if ( ! $well->assay_complete ) {
        $well->update( { assay_complete => $override->created_at } );
    }

    return $override;
}

sub pspec_update_well_accepted_override {
    return shift->pspec_create_well_accepted_override;
}

sub update_well_accepted_override {
    my ( $self, $params ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec_update_well_accepted_override );

    my $override = $self->retrieve(
        WellAcceptedOverride => {
            'plate.name' => $validated_params->{plate_name},
            'well.name'  => $validated_params->{well_name}
        },
        { join => { well => 'plate' } }
    );

    $self->throw( InvalidState => "Well already has accepted override with value "
                  . ( $validated_params->{accepted} ? 'TRUE' : 'FALSE' ) )
        unless $override->accepted xor $validated_params->{accepted};

    $override->update( { slice_def $validated_params, qw( created_by_id created_at accepted ) } );

    return $override;
}

sub pspec_create_well_recombineering_result {
    return {
        well_id      => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name   => { validate => 'existing_plate_name', optional => 1 },
        well_name    => { validate => 'well_name', optional => 1 },
        result_type  => { validate => 'existing_recombineering_result_type', rename => 'result_type_id' },
        result       => { validate => 'recombineering_result' },
        comment_text => { validate => 'non_empty_string', optional => 1 },
        created_by   => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at   => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    }
}

sub create_well_recombineering_result {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_recombineering_result );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    my $recombineering_result = $well->create_related(
        well_recombineering_results => { slice_def $validated_params, qw( result_type_id result comment_text created_by_id created_at ) }
    );

    return $recombineering_result;
}

sub retrieve_well_recombineering_results {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my @rec_results = $well->well_recombineering_results;

    if ( @rec_results == 0) {
        $self->throw( NotFound => { entity_class => 'WellRecombineeringResult', search_params => $params } );
    }

    return \@rec_results;
}

sub pspec_create_well_dna_status {
    return {
        well_id      => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name   => { validate => 'existing_plate_name', optional => 1 },
        well_name    => { validate => 'well_name', optional => 1 },
        pass         => { validate => 'boolean' },
        comment_text => { validate => 'non_empty_string', optional => 1 },
        created_by   => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at   => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    }
}

sub create_well_dna_status {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_dna_status );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    #will need to provide some method of changing the dna status level on a well
    if ( my $dna_status = $well->well_dna_status ) {
        $self->throw( Validation => "Well $well already has a dna status of "
                . ( $dna_status->pass == 1 ? 'pass' : 'fail' )
        );
    }

    my $dna_status = $well->create_related(
        well_dna_status => { slice_def $validated_params, qw( pass comment_text created_by_id created_at ) }
    );
    $self->log->debug( 'Well DNA status set to ' . $dna_status->pass . ' for well  ' . $dna_status->well_id );

    return $dna_status;
}

sub retrieve_well_dna_status {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my $dna_status = $well->well_dna_status
        or $self->throw( NotFound => { entity_class => 'WellDnaStatus', search_params => $params } );

    return $dna_status;
}

sub delete_well_dna_status {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $dna_status = $self->retrieve_well_dna_status( $params );

    $dna_status->delete;
    $self->log->debug( 'Well DNA status deleted for well  ' . $dna_status->well_id );

    return;
}

sub pspec_create_well_dna_quality {
    return {
        well_id      => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name   => { validate => 'existing_plate_name', optional => 1 },
        well_name    => { validate => 'well_name', optional => 1 },
        quality      => { validate => 'dna_quality' },
        comment_text => { validate => 'non_empty_string', optional => 1 },
        created_by   => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at   => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    }
}

sub create_well_dna_quality {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_dna_quality );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    my $dna_quality = $well->create_related(
        well_dna_quality => { slice_def $validated_params, qw( quality comment_text created_by_id created_at ) }
    );

    return $dna_quality;
}

sub retrieve_well_dna_quality {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my $dna_quality = $well->well_dna_quality
        or $self->throw( NotFound => { entity_class => 'WellDnaQuality', search_params => $params } );

    return $dna_quality;
}

sub pspec_create_well_qc_sequencing_result {
    return {
        well_id         => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name      => { validate => 'existing_plate_name', optional => 1 },
        well_name       => { validate => 'well_name', optional => 1 },
        valid_primers   => { validate => 'comma_separated_list', optional => 1 },
        mixed_reads     => { validate => 'boolean', optional => 1, default => 0 },
        pass            => { validate => 'boolean', optional => 1, default => 0 },
        test_result_url => { validate => 'absolute_url' },
        created_by      => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at      => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    }
}

sub create_well_qc_sequencing_result {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_qc_sequencing_result );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    my $qc_seq_result = $well->create_related(
        well_qc_sequencing_result => { slice_def $validated_params, qw( valid_primers mixed_reads pass test_result_url created_by_id created_at ) }
    );
    $self->log->debug( 'Well QC sequencing result created for well  ' . $qc_seq_result->well_id );

    return $qc_seq_result;
}

sub retrieve_well_qc_sequencing_result {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my $qc_seq_result = $well->well_qc_sequencing_result
        or $self->throw( NotFound => { entity_class => 'WellQcSequencingResult', search_params => $params } );

    return $qc_seq_result;
}

sub delete_well_qc_sequencing_result {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $qc_seq_result = $self->retrieve_well_qc_sequencing_result( $params );

    $qc_seq_result->delete;
    $self->log->debug( 'Well QC sequencing result deleted for well  ' . $qc_seq_result->well_id );

    return;
}

sub pspec_set_well_assay_complete {
    my $self = shift;
    return +{
        %{ $self->pspec_retrieve_well },
        completed_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    }
}

sub set_well_assay_complete {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_set_well_assay_complete );

    my $well = $self->retrieve_well( $validated_params );

    # XXX We aren't checking that the well doesn't already have
    # assay_complete set, we will just silently overwrite an existing
    # value.

    my $assay_complete = $validated_params->{completed_at} || \'CURRENT_TIMESTAMP';

    # XXX We aren't checking if the well has a well_accepted_override.
    # If it does, then the value set here is ignored. Arguably the
    # create_well_accepted_override() method should refuse to do
    # anything if assay_complete isn't already set.

    my $accepted = compute_accepted_status( $self, $well );

    $well->update(
        {
            assay_complete => $assay_complete,
            accepted       => $accepted
        }
    );

    return $well;
}

sub pspec_create_well_primer_bands {
    return {
        well_id           => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name        => { validate => 'existing_plate_name', optional => 1 },
        well_name         => { validate => 'well_name', optional => 1 },
        primer_band_type  => { validate => 'existing_primer_band_type', rename => 'primer_band_type_id' },
        pass              => { validate => 'boolean' },
        created_by        => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at        => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    }
}

sub create_well_primer_bands {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_primer_bands );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    my $primer_band = $well->create_related(
        well_primer_bands => { slice_def $validated_params, qw( primer_band_type_id pass created_by_id created_at ) }
    );

    return $primer_band;
}

sub retrieve_well_primer_bands {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my @primer_bands = $well->well_primer_bands;

    if ( @primer_bands == 0) {
        $self->throw( NotFound => { entity_class => 'WellPrimerBands', search_params => $params } );
    }

    return \@primer_bands;
}

sub pspec_create_well_colony_picks {
    return {
        well_id     => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name  => { validate => 'existing_plate_name', optional => 1 },
        well_name   => { validate => 'well_name', optional => 1 },
        colony_count_type => { validate => 'existing_colony_type', rename => 'colony_count_type_id' },
        colony_count       => { validate => 'integer' },
        created_by  => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at  => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    }
}

sub create_well_colony_picks {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_colony_picks );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    my $colony_picks = $well->create_related(
        well_colony_counts => {
            slice_def $validated_params,
            qw( colony_count_type_id colony_count created_by_id created_at )
        }
    );

    return $colony_picks;
}

sub retrieve_well_colony_picks {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my @colony_picks = $well->well_colony_counts;

    if ( @colony_picks == 0) {
        $self->throw( NotFound => { entity_class => 'WellColonyCount', search_params => $params } );
    }

    return \@colony_picks;
}

sub pspec_generate_eng_seq_params {
	return {
        plate_name  => { validate => 'existing_plate_name',     optional => 1 },
        well_name   => { validate => 'well_name',               optional => 1 },
        well_id     => { validate => 'integer', rename => 'id', optional => 1 },
        cassette    => { validate => 'existing_final_cassette', optional => 1 },
        backbone    => { validate => 'existing_backbone',       optional => 1 },
        recombinase => { validate => 'existing_recombinase', default => [], optional => 1 },
        targeted_trap => { validate => 'boolean', default => 0, optional => 1 },
	}
}

sub generate_well_eng_seq_params{

    my ( $self, $params ) = @_;

	my $validated_params = $self->check_params( $params, $self->pspec_generate_eng_seq_params );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( plate_name well_name id ) } );
    $self->throw( NotFound => { entity_class => 'Well', search_params => $params })
        unless $well;

    my $design = $well->design->as_hash;

    # Infer stage from plate type information
    my $plate_type_descr = $well->plate->type->description;
    my $stage = $plate_type_descr =~ /ES/ ? 'allele' : 'vector';

    my $loxp;
    $loxp = 1 if ($design->{type} eq 'conditional' and $params->{targeted_trap} and $stage ne 'allele');

    my $design_params = fetch_design_eng_seq_params($design, $loxp);

    my $input_params = {slice_def $validated_params, qw( cassette backbone recombinase targeted_trap)};
    $input_params->{is_allele} = 1 if $stage eq 'allele';
    $input_params->{design_type} = $design->{type};

    my ($method,$well_params) = fetch_well_eng_seq_params($well, $input_params );

    my $eng_seq_params = { %$design_params, %$well_params };
    add_display_id($stage, $eng_seq_params);

    return $method, $well->id, $eng_seq_params;
}

sub pspec_retrieve_well_phase_matched_cassette {
	return {
        plate_name  => { validate => 'existing_plate_name',     optional => 1 },
        well_name   => { validate => 'well_name',               optional => 1 },
        well_id     => { validate => 'integer', rename => 'id', optional => 1 },
        phase_matched_cassette => { rename => 'phase_match_group', optional => 0 },
	}
}

sub retrieve_well_phase_matched_cassette{
	my ( $self, $params ) = @_;

	my $validated_params = $self->check_params( $params, $self->pspec_retrieve_well_phase_matched_cassette);

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( plate_name well_name id ) } );
    $self->throw( NotFound => { entity_class => 'Well', search_params => $params })
        unless $well;

    my $phase = $well->design->phase;

    unless (defined $phase){
    	die "No phase specified for design for well ".$well->id;
    }

    # Cassettes for phase 0 have phase "undef" in cassettes table
    $phase = undef if $phase == 0;

    my $cassette = $self->schema->resultset('Cassette')->find({
    	phase_match_group => $validated_params->{phase_match_group},
    	phase             => $phase,
    });

    # Use phase 0 cassette if no k (-1) cassette available
    if (defined $phase and $phase == -1 and not defined $cassette){
        $cassette = $self->schema->resultset('Cassette')->find({
    	    phase_match_group => $validated_params->{phase_match_group},
    	    phase             => undef,
        });
    }

    return $cassette ? $cassette->name : undef;
}

# genotyping overall results methods
#
# well_targeting_pass
# well_chromosome_fail
#

sub pspec_create_well_targeting_pass {
    return {
        well_id     => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name  => { validate => 'existing_plate_name', optional => 1 },
        well_name   => { validate => 'well_name', optional => 1 },
        result      => { validate => 'genotyping_result_text' },
        overwrite   => { validate => 'boolean', optional => 1, default => 0 },
        created_by  => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at  => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    }
}

sub create_well_targeting_pass {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_targeting_pass );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    if ( my $targeting_pass = $well->well_targeting_pass ) {
         $self->throw( Validation => "Well $well already has a targeting pass value of "
                    . $targeting_pass->result );
    }

    my $targeting_pass = $well->create_related(
        well_targeting_pass => {
            slice_def $validated_params,
            qw( result created_by_id created_at )
        }
    );

    return $targeting_pass;
}


sub update_or_create_well_targeting_pass {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_targeting_pass );

    my $targeting_pass;

    my $well = $self->retrieve_well( { slice_def $validated_params,  qw( id plate_name well_name ) });
    if ( $targeting_pass = $well->well_targeting_pass ) {
       # Update the result if new result is "better" or if overwrite flag is set to true
       my $update_request = {slice_def $validated_params, qw( result )};
       if ( $validated_params->{overwrite} or rank( $update_request->{result} ) > rank( $targeting_pass ) ) {
           $targeting_pass->update( { result => $update_request->{result} });
       }
       else{
           $self->log->debug("Will not update result ".$targeting_pass->result." with result ".$update_request->{result});
       }
    }
    else {
        $targeting_pass = $well->create_related(
        well_targeting_pass => {
            slice_def $validated_params,
            qw( result created_by_id created_at )
        }
    );

    }

    return $targeting_pass;
}

sub retrieve_well_targeting_pass {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my $targeting_pass = $well->well_targeting_pass
        or $self->throw( NotFound => { entity_class => 'WellTargetingPass', search_params => $params } );

    return $targeting_pass;
}

sub delete_well_targeting_pass {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $targeting_pass = $self->retrieve_well_targeting_pass( $params );

    $targeting_pass->delete;
    $self->log->debug( 'Well targeting_pass result deleted for well  ' . $targeting_pass->well_id );

    return;
}


sub pspec_create_well_chromosome_fail {
    return {
        well_id     => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name  => { validate => 'existing_plate_name', optional => 1 },
        well_name   => { validate => 'well_name', optional => 1 },
        result      => { validate => 'chromosome_fail_text' },
        created_by  => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at  => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    }
}

sub create_well_chromosome_fail {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_chromosome_fail );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    if ( my $chromosome_fail = $well->well_chromosome_fail ) {
         $self->throw( Validation => "Well $well already has a chromosome fail value of "
                    . $chromosome_fail->result );
    }

    my $chromosome_fail = $well->create_related(
        well_chromosome_fail => {
            slice_def $validated_params,
            qw( result created_by_id created_at )
        }
    );

    return $chromosome_fail;
}

sub update_or_create_well_chromosome_fail {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_chromosome_fail );

    my $chromosome_fail;

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    if ( $chromosome_fail = $well->well_chromosome_fail ) {
        my $update_request = {slice_def $validated_params, qw( result )};
        $chromosome_fail->update( { result => $update_request->{result} } );
    }
    else {
        $chromosome_fail = $well->create_related(
        well_chromosome_fail => {
            slice_def $validated_params,
            qw( result created_by_id created_at )
        }
        );
    }

    return $chromosome_fail;
}

sub retrieve_well_chromosome_fail {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my $chromosome_fail = $well->well_chromosome_fail
        or $self->throw( NotFound => { entity_class => 'WellChromosomeFail', search_params => $params } );

    return $chromosome_fail;
}

sub delete_well_chromosome_fail {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $chromosome_fail = $self->retrieve_well_chromosome_fail( $params );

    $chromosome_fail->delete;
    $self->log->debug( 'Well chromosome_fail result deleted for well  ' . $chromosome_fail->well_id );

    return;
}

# Genotyping assay specific results

sub pspec_create_well_genotyping_result {
    return {
        well_id     => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name  => { validate => 'existing_plate_name', optional => 1 },
        well_name   => { validate => 'well_name', optional => 1 },
        genotyping_result_type_id =>
                       { validate => 'existing_genotyping_result_type' },
        call        => { validate => 'genotyping_result_text' },
        copy_number => { validate => 'copy_float', optional => 1 },
        copy_number_range =>
                       { validate => 'copy_float', optional => 1 },
        confidence  => { validate => 'confidence_float', optional => 1 },
        overwrite   => { validate => 'boolean', optional => 1, default => 0 },
        created_by  => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at  => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    }
}

sub create_well_genotyping_result {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_genotyping_result );

    my $well_params = { slice_def $validated_params, qw( id plate_name well_name ) };

    my $well = $self->retrieve_well( $well_params )
        or $self->throw( NotFound => { entity_class => 'Well', search_params => $well_params } );

    my $genotyping_result = $self->retrieve_well_genotyping_result({
    	                               well_id => $well->id,
    	                               genotyping_result_type_id => $validated_params->{genotyping_result_type_id},
                                   });

    if ($genotyping_result) {
         $self->throw( Validation => "Well $well already has a genotyping_results value of "
                    . $genotyping_result->call );
    }
    else{
    	$genotyping_result = $well->create_related(
        well_genotyping_results => {
            slice_def $validated_params,
            qw( call genotyping_result_type_id copy_number copy_number_range confidence created_by_id created_at )
        });
    }
    return $genotyping_result;
}

sub update_or_create_well_genotyping_result {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_genotyping_result );

    my $well_params = { slice_def $validated_params, qw( id plate_name well_name ) };

    my $well = $self->retrieve_well( $well_params )
        or $self->throw( NotFound => { entity_class => 'Well', search_params => $well_params } );

    my $genotyping_result = $self->retrieve_well_genotyping_result({
    	                               well_id => $well->id,
    	                               genotyping_result_type_id => $validated_params->{genotyping_result_type_id},
                                   });

    if ( $genotyping_result ) {
       my $update_request = {slice_def $validated_params,
           qw( genotyping_result_type_id call copy_number copy_number_range confidence )};
       # Update the result if new result is "better" or if overwrite flag is set to true
       if ( $validated_params->{overwrite} or rank( $update_request->{call} ) > rank( $genotyping_result->call ) ) {
           $genotyping_result->update( $update_request );
       }
       else{
           $self->log->debug("Will not update result ".$genotyping_result->call." with result ".$update_request->{call});
       }
    }
    else {
        $genotyping_result = $well->create_related(
        well_genotyping_results => {
            slice_def $validated_params,
            qw( call genotyping_result_type_id copy_number copy_number_range confidence created_by_id created_at )
        });

    }
    return $genotyping_result;
}

sub pspec_retrieve_well_genotyping_result {
    return {
        well_id     => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name  => { validate => 'existing_plate_name', optional => 1 },
        well_name   => { validate => 'well_name', optional => 1 },
        genotyping_result_type_id =>
                       { validate => 'existing_genotyping_result_type' },
    }
}

sub retrieve_well_genotyping_result {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_well_genotyping_result);

    my $well = $self->retrieve_well({ slice_def $validated_params, qw( plate_name well_name id ) });
    my $requested_row = {
        well_id => $well->id,
        genotyping_result_type_id => $validated_params->{genotyping_result_type_id},
    };
    my $genotyping_result = $self->schema->resultset('WellGenotypingResult')->find( $requested_row );

    return $genotyping_result;
}

sub delete_well_genotyping_result {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $genotyping_result = $self->retrieve_well_genotyping_result( $params );

    $genotyping_result->delete;
    $self->log->debug( 'Well genotyping_results deleted for well  ' . $genotyping_result->well_id );

    return;
}

1;

__END__
