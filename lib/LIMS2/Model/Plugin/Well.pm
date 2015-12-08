package LIMS2::Model::Plugin::Well;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Well::VERSION = '0.357';
}
## use critic


use strict;
use warnings FATAL => 'all';
use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use Hash::Merge qw( merge );
use List::MoreUtils qw (any uniq);
use LIMS2::Model::Util::ComputeAcceptedStatus qw( compute_accepted_status );
use namespace::autoclean;
use LIMS2::Model::ProcessGraph;
use LIMS2::Model::Util::RankQCResults qw( rank );
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use LIMS2::Model::Util::CreateProcess qw( create_process_aux_data_recombinase );
use Try::Tiny;

requires qw( schema check_params throw retrieve log trace );

sub pspec_retrieve_well {
    return {
        id                => { validate => 'integer', optional => 1 },
        plate_name        => { validate => 'plate_name', optional => 1 },
        plate_version     => { validate => 'integer', optional => 1, default => undef },
        well_name         => { validate => 'well_name', optional => 1 },
        barcode           => { validate => 'alphanumeric_string', optional => 1 },
        DEPENDENCY_GROUPS => { name_group => [qw( plate_name well_name )] },
        REQUIRE_SOME      => { id_or_name_or_barcode => [ 1, qw( id plate_name well_name barcode ) ] }
    };
}

sub retrieve_well {
    my ( $self, $params ) = @_;

    my $data = $self->check_params( $params, $self->pspec_retrieve_well, ignore_unknown => 1 );

    my %search;
    my %joins = (
        join     => 'plate',
        prefetch => 'plate',
     );

    if ( $data->{id} ) {
        $search{'me.id'} = $data->{id};
    }
    if ( $data->{well_name} ) {
        $search{'me.name'} = $data->{well_name};
    }
    if ( $data->{plate_name} ) {
        $search{'plate.name'} = $data->{plate_name};
        # Include plate version in search. undef indicates we want current version
        $search{'plate.version'} = $data->{plate_version};
    }
    if ( $data->{barcode} ) {
        $search{'well_barcode.barcode'} = $data->{barcode};
        $joins{join} = [ 'plate', 'well_barcode' ];
    }

    return $self->retrieve( Well => \%search, \%joins );
}

sub pspec_retrieve_well_from_old_plate_version{
    return {
        plate_name        => { validate => 'plate_name' },
        well_name         => { validate => 'well_name' },
    };
}

# Search for a well which exists on an old version of the plate
# Return the well on the latest version of the plate that can be found
sub retrieve_well_from_old_plate_version{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_well_from_old_plate_version);

    my $search = {
        'me.name'    => $validated_params->{well_name},
        'plate.name' => $validated_params->{plate_name},
        'plate.version' => { '!=', undef },
    };

    my $attrs = {
        join     => 'plate',
        prefetch => 'plate',
        order_by => { -desc => 'plate.version' },
    };

    my $well = $self->schema->resultset('Well')->search($search, $attrs)->first
        or $self->throw( NotFound => { entity_class => 'Well', search_params => $search } );

    $self->log->debug("Found well on version ".$well->plate->version." of plate");
    return $well;
}

sub pspec_create_well {
    return {
        plate_name   => { validate => 'existing_plate_name' },
        well_name    => { validate => 'well_name', rename => 'name' },
        accepted     => { validate => 'boolean', optional => 1 },
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

    my $process_type = $params->{ 'process_data' }->{ 'type' };

    my $validated_params = $self->check_params( $params, $self->pspec_create_well );

    $plate ||= $self->retrieve_plate( { name => $validated_params->{plate_name} } );

    my $validated_well_params
        = { slice_def $validated_params, qw( name created_at created_by_id accepted) };

    my $well = $plate->create_related( wells => $validated_well_params );

    my $process_params = $validated_params->{process_data};
    $process_params->{output_wells} = [ { id => $well->id } ];

    $self->create_process($process_params);

    # add piq plate type lab number insert here
    if ( $process_type eq 'dist_qc' or $process_type eq 'rearray' ) {
        if ( defined $process_params->{ 'lab_number' } ) {

            my $created_well_id = $well->id;
            my $lab_num = $process_params->{ 'lab_number' };

            $self->create_well_lab_number( { 'well_id' => $created_well_id, 'lab_number' => $lab_num, } );
        }
    }

    return $well;
}

sub delete_well {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well($params);

    if ( $well->input_processes > 0 ) {
        $self->throw( InvalidState => "Cannot delete a well that is an input to another process" );
    }

    if ( my @qc_template_wells = $well->qc_template_wells){
    	my @qc_templates = map { $_->qc_template->name } @qc_template_wells;
    	$self->throw( InvalidState => "Cannot delete well ".$well->name." as it is used by QC templates: "
    	                              .(join ", ", uniq @qc_templates )
    	                              .". Delete the QC template first" );
    }

    for my $p ( $well->output_processes ) {
        if ( $p->output_wells == 1 ) {
            $self->delete_process( { id => $p->id } );
        }
    }

    # Delete any related barcode events
    if (my $barcode = $well->well_barcode){
        $barcode->search_related_rs('barcode_events')->delete;
    }

    my @related_resultsets = qw( well_accepted_override well_comments well_dna_quality well_dna_status
                                 well_qc_sequencing_result well_recombineering_results well_colony_counts
                                 well_primer_bands well_chromosome_fail well_genotyping_results
                                 well_targeting_pass well_targeting_puro_pass well_targeting_neo_pass
                                 well_lab_number well_barcode
                               );

    for my $rs ( @related_resultsets ) {
        $well->search_related_rs( $rs )->delete;
    }

    $well->delete;
    return;
}

sub retrieve_well_accepted_override {
    my ( $self, $params ) = @_;

    $params->{'id'} = delete $params->{'well_id'} if exists $params->{'well_id'};
    my $well = $self->retrieve_well( $params );
    my $accepted_override = $well->well_accepted_override
        or $self->throw( NotFound => { entity_class => 'WellChromosomeFail', search_params => $params } );;
    return $accepted_override;
}

sub delete_well_accepted_override {
    my( $self, $params ) = @_;

    my $accepted_override = $self->retrieve_well_accepted_override( $params );
    $accepted_override->delete;
    $self->log->debug( 'Well accepted_override deleted for well ' . $accepted_override->well_id );

    return;
}

sub pspec_create_well_accepted_override {
    return {
        plate_name => { validate => 'existing_plate_name', optional => 1 },
        well_name  => { validate => 'well_name',           optional => 1 },
        well_id    => { validate => 'integer',             optional => 1, rename => 'id' },
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

sub update_or_create_well_accepted_override {
    my ($self, $params ) = @_;

    my $message;
    my $validated_params = $self->check_params( $params, $self->pspec_create_well_accepted_override);

    my $accepted_override;

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name )} );

    if ( $accepted_override = $well->well_accepted_override ) {
        my $update_request = { slice_def $validated_params, qw( accepted )};
        my $previous = $accepted_override->accepted;
        $accepted_override->update( { accepted => $update_request->{'accepted'} } );
        $message = 'Well_accepted_override update from ' . $previous . ' to ' . $accepted_override->accepted;
    }
    else {
        # create a new entry
        $accepted_override = $well->create_related(
            well_accepted_override => {
                slice_def $validated_params,
                    qw( accepted created_by_id created_at )
            }
        );
        $message = 'Well_accepted_override created with result ' . $accepted_override->accepted;
    }
    $self->log->debug( $message );
    return wantarray ? ( $accepted_override, $message) : $accepted_override;
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

sub pspec_update_well_accepted {
    return {
        well_id                => { validate => 'integer',             rename => 'id' },
        accepted               => { validate => 'boolean'                             },
        accepted_rules_version => { validate => 'non_empty_string',    optional => 1  },
    };
}

sub update_well_accepted {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_well_accepted );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id )} );

    $well->update( { slice_def $validated_params, qw( accepted accepted_rules_version ) } );

    return $well;
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
        concentration_ng_ul => { validate => 'signed_float', optional => 1 },
        comment_text => { validate => 'non_empty_string', optional => 1 },
        created_by   => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at   => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    }
}

sub create_well_dna_status {
    my ( $self, $params ) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_create_well_dna_status );

    my $well;
    my $dna_status;
    # If the well does not exist on the target plate, we assume that the well in the spreadsheet is
    # empty (water or buffer solution only). These wells are not recorded in LIMS2 as it is not
    # possible to parent empty wells.
    # DJP-S 6/3/13
    #
    try {
        $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );
    }
    catch {
        # If the well doesn't exist make it undef and carry on
        $well = undef;
    };

    #will need to provide some method of changing the dna status level on a well
    if ( $well ) {
        if ( $dna_status = $well->well_dna_status ) {
            $self->throw( Validation => "Well $well already has a dna status of "
                    . ( $dna_status->pass == 1 ? 'pass' : 'fail' )
            );
        }

        $dna_status = $well->create_related(
            well_dna_status => { slice_def $validated_params, qw( pass concentration_ng_ul comment_text created_by_id created_at ) }
        );

        # acs - 20_05_13 - redmine 10328 - update well accepted flag
        $well->accepted($dna_status->pass);
        $well->update();

        # If this DNA well was generated from a FINAL_PICK then the accepted flag
        # will be computed according to a more complex set of rules
        # redmine ticket #11642
        $well->compute_final_pick_dna_well_accepted();

        $self->log->debug( 'Well DNA status set to ' . $dna_status->pass . ' for well  ' . $dna_status->well_id );
    }
    else {
        $dna_status = undef;
    }

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
        quality      => { validate => 'dna_quality', optional => 1 },
        egel_pass    => { validate => 'boolean', optional => 1 },
        comment_text => { validate => 'non_empty_string', optional => 1 },
        created_by   => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at   => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        REQUIRE_SOME => { quality_or_egel_pass => [ 1, qw(quality egel_pass) ] },
    }
}

sub create_well_dna_quality {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_dna_quality );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    my $dna_quality = $well->create_related(
        well_dna_quality => { slice_def $validated_params, qw( quality egel_pass comment_text created_by_id created_at ) }
    );

    # If this DNA well was generated from a FINAL_PICK then the accepted flag
    # will be computed
    # redmine ticket #11642
    $well->compute_final_pick_dna_well_accepted();

    return $dna_quality;
}

sub update_or_create_well_dna_quality {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_dna_quality );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    my $dna_quality = $well->update_or_create_related(
        well_dna_quality => { slice_def $validated_params, qw( quality egel_pass comment_text created_by_id created_at ) }
    );

    # If this DNA well was generated from a FINAL_PICK then the accepted flag
    # will be computed
    # redmine ticket #11642
    $well->compute_final_pick_dna_well_accepted();

    return $dna_quality;
}

sub toggle_to_report {
    my ( $self, $params ) = @_;

    my $well = $self->retrieve_well({ id => $params->{'id'} });

    my $to_report = $params->{'to_report'};

    propagate_to_report($self, $well, $to_report);

    return $well;
}

sub propagate_to_report {
    my ( $self, $well, $to_report, $seen) = @_;

    $self->log->info( "Setting to_report to $to_report on well " . $well->as_string  );
    $well->update( { to_report => $to_report });

    $seen ||= {};

    return if $seen->{$well->as_string};

    $seen->{$well->as_string}++;

    foreach my $process ($well->child_processes){
        foreach my $child ($process->output_wells){
            propagate_to_report( $self, $child, $to_report, $seen);
        }
    }
    return;
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
    my ( $self, $params, $well ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_qc_sequencing_result );

    $well //= $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

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

# lr_pcr_pass was original pass, but required (pass, passb, fail) values, so it had to be changed from a boolean to a new type
sub pspec_create_well_primer_bands {
    return {
        well_id           => { validate => 'integer', optional => 1, rename => 'id' },
        plate_name        => { validate => 'existing_plate_name', optional => 1 },
        well_name         => { validate => 'well_name', optional => 1 },
        primer_band_type  => { validate => 'existing_primer_band_type', rename => 'primer_band_type_id' },
        pass              => { validate => 'passorfail' },
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

sub delete_well_primer_band {
    my ( $self, $params ) = @_;

    my $pspec = $self->pspec_create_well_primer_bands;
    delete $pspec->{'pass'};

    my $validated_params = $self->check_params( $params, $pspec );
    my $well = $self->retrieve_well( $validated_params );
    my $requested_row = {
        well_id => $well->id,
        primer_band_type_id => $validated_params->{primer_band_type_id},
    };
    my $primer_band_tag = $self->schema->resultset('WellPrimerBand')->find( $requested_row );
    my $result;
    if ( $primer_band_tag ) {
        $result = $primer_band_tag->delete;
    }
    else {
        $self->log->debug( $requested_row->{well_id} . ':' . $requested_row->{primer_band_type_id}
            . ' does not exist' );
    }
    $self->log->debug( 'Well primer band '
        . $validated_params->{primer_band_type_id}
        . ' result deleted for well '
        . $well->id
    );

    return $result;
}


sub update_or_create_well_primer_bands {
    my ( $self, $params ) = @_;
    my $message;



    my $validated_params = $self->check_params( $params, $self->pspec_create_well_primer_bands );
    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    my $requested_row = {
        well_id => $well->id,
        primer_band_type_id => $validated_params->{primer_band_type_id},
    };
    my $primer_band_tag = $self->schema->resultset('WellPrimerBand')->find( $requested_row );
    my $primer_band;
    if ( $primer_band_tag ) {
        my $update_request = {slice_def $validated_params, qw( primer_band_type_id pass ) };
        $primer_band_tag->update({
                primer_band_type_id => $update_request->{primer_band_type_id},
                pass => $update_request->{pass}
            });
        my @primer_bands = $well->well_primer_bands;
        $message = 'Well ' . $well->id . ' primer band '
                    . $update_request->{primer_band_type_id}
                    . ' updated to '
                    . $update_request->{pass};
        $primer_band = \@primer_bands;
    }
    else {
        $primer_band = $well->create_related(
            well_primer_bands => { slice_def $validated_params, qw( primer_band_type_id pass created_by_id created_at ) }
        );
        $message = 'Well ' . $well->id . ' primer band '
                    . $primer_band->primer_band_type_id
                    . ' did not exist and has been created with pass value of '
                    . $primer_band->pass;
    }
    $self->log->debug( $message );
    return wantarray ? ($primer_band, $message) : $primer_band;
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

sub pspec_update_well_colony_picks {
    return {
        plate_name  => { validate => 'existing_plate_name' },
        well_name   => { validate => 'well_name' },
        created_by  => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at  => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
    }
}

sub update_well_colony_picks{
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_well_colony_picks,
        ignore_unknown => 1 );

    my @colony_types = map { $_->id } $self->schema->resultset('ColonyCountType')->all;
    my $well = $self->retrieve_well(
        {   plate_name => $validated_params->{plate_name},
            well_name  => $validated_params->{well_name}
        }
    );
    $self->throw( Validation => "invalid plate type; can only add colony data to EP, SEP and XEP plates" )
    unless any {$well->plate->type_id eq $_} qw(EP XEP SEP CRISPR_EP);

    foreach my $colony_type (@colony_types){
        if (exists $params->{$colony_type} and $params->{$colony_type} =~ /^\d+$/){
            $well->update_or_create_related( 'well_colony_counts' => {
                  colony_count_type_id => $colony_type,
                  colony_count      => $params->{$colony_type},
                  created_by_id     => $validated_params->{created_by_id},
            }, { key => 'primary'});
        }
    }
    return;
}

sub upload_well_colony_picks_file_data {
    my ( $self, $well_colony_picks_data_fh, $const_params ) = @_;
    my $well_colony_picks_data = parse_csv_file( $well_colony_picks_data_fh );
    my $error_log;
    my $line = 1;

    foreach my $well_colony_picks (@{$well_colony_picks_data}){
        $line++;
        try{
            update_well_colony_picks( $self, merge( $well_colony_picks, $const_params) );
        }
        catch{
            $error_log
                .= "line "
                . $line
                . ": plate "
                . $well_colony_picks->{plate_name}
                . ", well "
                . $well_colony_picks->{well_name}
                . " ERROR: $_";
        };
    }

    LIMS2::Exception::Validation->throw(

        "$error_log"
    )if $error_log;

    return 1;
}

sub get_well_colony_pick_fields_values {
    my ( $self, $params ) = @_;

    my @colony_data;
    my %fields = map { $_->id => { label => $_->id, name => $_->id } }
        $self->schema->resultset('ColonyCountType')->all;

    if (exists $params->{plate_name} && exists $params->{well_name}){
        my $well = $self->retrieve_well( $params );

        $self->throw( Validation => "invalid plate type; can only add colony data to EP, SEP and XEP plates" )
        unless any {$well->plate->type_id eq $_} qw(EP XEP SEP CRISPR_EP);

        @colony_data = $well->well_colony_counts;

        if (@colony_data) {
            foreach (@colony_data){
                $fields{$_->colony_count_type_id}{att_values} = $_->colony_count;
            }
        }
    }
    return \%fields;
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
        type        => { optional => 0, default => 'well_targeting_pass' },
    }
}

# Inputs and login for updating/creating targeting_pass and targeting_puro_pass are identical
# so we use the same methods but add a flag to indicate which type of targeting pass we are setting
sub create_well_targeting_puro_pass {
    my ( $self, $params ) = @_;

    $params->{type} = 'well_targeting_puro_pass';

    return $self->create_well_targeting_pass( $params );
}

sub create_well_targeting_neo_pass {
    my ( $self, $params ) = @_;

    $params->{type} = 'well_targeting_neo_pass';

    return $self->create_well_targeting_pass( $params );
}

sub create_well_targeting_pass {
    my ( $self, $params ) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_create_well_targeting_pass );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    my $targ_pass_type = $validated_params->{type};

    if ( my $targeting_pass = $well->$targ_pass_type ) {
         $self->throw( Validation => "Well $well already has a $targ_pass_type value of "
                    . $targeting_pass->result );
    }

    my $targeting_pass = $well->create_related(
        $targ_pass_type => {
            slice_def $validated_params,
            qw( result created_by_id created_at )
        }
    );

    return $targeting_pass;
}

sub update_or_create_well_targeting_puro_pass {
	my ( $self, $params ) = @_;

    $params->{type} = 'well_targeting_puro_pass';

	return $self->update_or_create_well_targeting_pass( $params );
}

sub update_or_create_well_targeting_neo_pass {
    my ( $self, $params ) = @_;

    $params->{type} = 'well_targeting_neo_pass';

    return $self->update_or_create_well_targeting_pass( $params );
}

sub update_or_create_well_targeting_pass {
    my ( $self, $params ) = @_;
    my $message;
    my $validated_params = $self->check_params( $params, $self->pspec_create_well_targeting_pass );

    my $targ_pass_type = $validated_params->{type};

    my $targeting_pass;

    my $well = $self->retrieve_well( { slice_def $validated_params,  qw( id plate_name well_name ) });
    if ( $targeting_pass = $well->$targ_pass_type ) {
       # Update the result if new result is "better" or if overwrite flag is set to true
       my $update_request = {slice_def $validated_params, qw( result )};
       my $previous = $targeting_pass->result;
       if ( $validated_params->{overwrite} or rank( $update_request->{result} ) > rank( $previous) ) {
           $targeting_pass->update( { result => $update_request->{result} });
           $message = "$targ_pass_type updated from $previous to ".$targeting_pass->result;
       }
       else{
       	   $message = "Will not update $targ_pass_type result $previous with result ".$update_request->{result};
           $self->log->debug($message);
       }
    }
    else {
        $targeting_pass = $well->create_related(
        $targ_pass_type => {
            slice_def $validated_params,
            qw( result created_by_id created_at )
        });
        $message = "$targ_pass_type created with result ".$targeting_pass->result;
    }

    return wantarray ? ($targeting_pass, $message) : $targeting_pass ;
}

sub retrieve_well_targeting_puro_pass {
    my ( $self, $params ) = @_;

    $params->{'id'} = delete $params->{'well_id'} if exists $params->{'well_id'};
    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my $targeting_pass = $well->well_targeting_puro_pass
        or $self->throw( NotFound => { entity_class => 'WellTargetingPuroPass', search_params => $params } );

    return $targeting_pass;
}

sub retrieve_well_targeting_neo_pass {
    my ( $self, $params ) = @_;

    $params->{'id'} = delete $params->{'well_id'} if exists $params->{'well_id'};
    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my $targeting_pass = $well->well_targeting_neo_pass
        or $self->throw( NotFound => { entity_class => 'WellTargetingNeoPass', search_params => $params } );

    return $targeting_pass;
}


sub retrieve_well_targeting_pass {
    my ( $self, $params ) = @_;

    $params->{'id'} = delete $params->{'well_id'} if exists $params->{'well_id'};
    # retrieve_well() will validate the parameters
    my $well = $self->retrieve_well( $params );

    my $targeting_pass = $well->well_targeting_pass
        or $self->throw( NotFound => { entity_class => 'WellTargetingPass', search_params => $params } );

    return $targeting_pass;
}

sub delete_well_targeting_puro_pass {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $targeting_pass = $self->retrieve_well_targeting_puro_pass( $params );

    $targeting_pass->delete;
    $self->log->debug( 'Well targeting-puro_pass result deleted for well  ' . $targeting_pass->well_id );

    return;
}

sub delete_well_targeting_neo_pass {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $targeting_pass = $self->retrieve_well_targeting_neo_pass( $params );

    $targeting_pass->delete;
    $self->log->debug( 'Well targeting-neo_pass result deleted for well  ' . $targeting_pass->well_id );

    return;
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

    my $message;
    my $validated_params = $self->check_params( $params, $self->pspec_create_well_chromosome_fail );

    my $chromosome_fail;

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    if ( $chromosome_fail = $well->well_chromosome_fail ) {
        my $update_request = {slice_def $validated_params, qw( result )};
        my $previous = $chromosome_fail->result;
        $chromosome_fail->update( { result => $update_request->{result} } );
        $message = "Chromosome fail updated from $previous to ".$chromosome_fail->result;
    }
    else {
        $chromosome_fail = $well->create_related(
        well_chromosome_fail => {
            slice_def $validated_params,
            qw( result created_by_id created_at )
        }
        );
        $message = "Chromosome fail created with result ".$chromosome_fail->result;
    }

    return wantarray ? ($chromosome_fail, $message) : $chromosome_fail ;
}

sub retrieve_well_chromosome_fail {
    my ( $self, $params ) = @_;

    $params->{'id'} = delete $params->{'well_id'} if exists $params->{'well_id'};
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
        vic         => { validate => 'copy_float', optional => 1 },
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
            qw( call genotyping_result_type_id copy_number copy_number_range confidence vic created_by_id created_at )
        });
    }
    return $genotyping_result;
}

sub update_or_create_well_genotyping_result {
    my ( $self, $params ) = @_;
    my $message = 'No message defined yet';
    my $pspec = $self->pspec_create_well_genotyping_result;
    # The call is obligatory in the standard pspec, so set it to optional here
    # because we can update a single value that is any value assicated with the assay,
    # not just call.
    $pspec->{call}{optional} = 1;
    my $validated_params = $self->check_params( $params, $pspec );

    my $well_params = { slice_def $validated_params, qw( id plate_name well_name ) };

    my $well = $self->retrieve_well( $well_params )
        or $self->throw( NotFound => { entity_class => 'Well', search_params => $well_params } );

    my $genotyping_result = $self->retrieve_well_genotyping_result({
    	                               well_id => $well->id,
    	                               genotyping_result_type_id => $validated_params->{genotyping_result_type_id},
                                   });
    if ( $genotyping_result ) {
       my $update_request = {slice_def $validated_params,
           qw( genotyping_result_type_id call copy_number copy_number_range confidence vic )};
       if ( $update_request->{call} ) {
           # Update the result if new result is "better" or if overwrite flag is set to true
           my $previous = $genotyping_result->call;
           if ( $validated_params->{overwrite} or rank( $update_request->{call} ) > rank( $previous ) ) {
               if ($update_request->{call} eq "na" or $update_request->{call} eq "fa"){
                   # Make sure we overwrite any existing values with nulls
                   $update_request->{copy_number} = undef;
                   $update_request->{copy_number_range} = undef;
                   $update_request->{confidence} = undef;
                   $update_request->{vic} = undef;
               }
               $genotyping_result->update( $update_request );
               $message = "Genotyping result for ".$validated_params->{genotyping_result_type_id}
                         ." updated from ".$previous." to ".$genotyping_result->call;
           }
           else {
               $message = "Will not update ".$validated_params->{genotyping_result_type_id}
                         ." result ".$previous." with result ".$update_request->{call};
           }
       }
       else {
            # The assay parameter to update is not a 'call', so no ranking needs to be applied
            my $assay_field_slice = { slice_def( $validated_params, qw/ copy_number copy_number_range confidence vic / )};
            my ( $assay_field, $assay_value ) = each %{$assay_field_slice};

            my $previous = $genotyping_result->$assay_field // 'undefined';

            $genotyping_result->update( $update_request );
            $message = 'Genotyping result for ' . $validated_params->{genotyping_result_type_id} . '/' . $assay_field
                . ' updated from ' . $previous . ' to ' . $genotyping_result->$assay_field;
       }
    }
    else {
        # We can only create a genotyping result row if there we can set the 'call' field.
        $genotyping_result = $well->create_related(
        well_genotyping_results => {
            slice_def $validated_params,
            qw( call genotyping_result_type_id copy_number copy_number_range confidence vic created_by_id created_at )
        });
        $message = "Genotyping result for ".$validated_params->{genotyping_result_type_id}
                  ." created with result ".$genotyping_result->call;
    }
    $self->log->debug( $message );
    return wantarray ? ($genotyping_result, $message) : $genotyping_result;
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
    $params->{'id'} = delete $params->{'well_id'} if exists $params->{'well_id'};
    $self->log->debug( 'Well genotyping_results deleted for well  ' . $genotyping_result->well_id );

    return;
}

sub pspec_create_well_lab_number {
    return {
        well_id     => { validate => 'integer', optional => 0, rename => 'id' },
        lab_number  => { validate => 'non_empty_string', optional => 0 },
        created_by  => { validate => 'non_empty_string', optional => 1 },
    }
}

sub create_well_lab_number {
    my ( $self, $params ) = @_;

    # check parameters are valid
    my $validated_params = $self->check_params( $params, $self->pspec_create_well_lab_number );

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    # check plate type is PIQ
    if ( $well->plate->type_id ne 'PIQ' ) {
        $self->throw( Validation => 'Well' . $well . ' must have a plate type of PIQ, this plate is type '
                    . $well->plate->type_id );
    }

    # check that well does not already have an attached lab number
    if ( $well->well_lab_number && ( my $well_lab_number_existing = $well->well_lab_number ) ) {
         $self->throw( Validation => 'Well ' . $well . ' already has a Lab Number, with a value of '
                    . $well_lab_number_existing->lab_number );
    }

    # check that lab number has not already been used
    my $existing_lab_number_rs = $self->schema->resultset('WellLabNumber')->search({
        'lab_number' => $validated_params->{'lab_number'},
    });

    my $existing_lab_number = $existing_lab_number_rs->single;

    if ( defined $existing_lab_number ) {
        my $lab_num = $existing_lab_number->lab_number;
        my $used_on_well_name = $existing_lab_number->well->as_string;

        $self->throw( Validation => 'Lab Number ' . $lab_num . ' has already been used in well ' . $used_on_well_name );
    }

    # ok to go ahead and create the related lab number
    my $well_lab_number = $well->create_related(
        well_lab_number => {
            slice_def $validated_params,
            qw( lab_number )
        }
    );

    return $well_lab_number;
}

sub update_or_create_well_lab_number {
    my ( $self, $params ) = @_;

    if ( $params->{'result'} ) {
        $params->{'lab_number'} = $params->{'result'};
        delete $params->{'result'};
    }

    my $message;
    my $validated_params = $self->check_params( $params, $self->pspec_create_well_lab_number );

    my $lab_number;

    my $well = $self->retrieve_well( { slice_def $validated_params, qw( id plate_name well_name ) } );

    if ( $lab_number = $well->well_lab_number ) {
        # existing lab number
        my $previous = $lab_number->lab_number;

        # check new lab number different from existing
        if ( $previous eq $validated_params->{'lab_number'} ) {
            $self->throw( Validation => 'Update unnecessary. Lab Number ' . $previous . ' is unchanged' );
        }

        # check new lab number is not already in use
        my $existing_lab_number_rs = $self->schema->resultset('WellLabNumber')->search({
            'lab_number' => $validated_params->{'lab_number'},
        });

        my $existing_lab_number = $existing_lab_number_rs->single;

        if ( defined $existing_lab_number ) {
            my $lab_num = $existing_lab_number->lab_number;
            my $used_on_well_name = $existing_lab_number->well->as_string;

            $self->throw( Validation => 'Update failed. Lab Number ' . $lab_num . ' has already been used in well ' . $used_on_well_name );
        }

        # update where there is an existing lab number
        my $update_request = {slice_def $validated_params, qw( lab_number )};

        # ok to update the existing lab number
        $lab_number->update( { 'lab_number' => $update_request->{ 'lab_number' } } );

        $message = 'Update succeeded. Lab Number updated from ' . $previous . ' to ' . $lab_number->lab_number;
    }
    else {
        # check that lab number has not already been used
        my $existing_lab_number_rs = $self->schema->resultset('WellLabNumber')->search({
            'lab_number' => $validated_params->{'lab_number'},
        });

        my $existing_lab_number = $existing_lab_number_rs->single;

        if ( defined $existing_lab_number ) {
            my $lab_num = $existing_lab_number->lab_number;
            my $used_on_well_name = $existing_lab_number->well->as_string;

            $self->throw( Validation => 'Create failed. Lab Number ' . $lab_num . ' has already been used in well ' . $used_on_well_name );
        }

        # ok to go ahead and create the related lab number
        $lab_number = $well->create_related(
            well_lab_number => {
                slice_def $validated_params,
                qw( lab_number )
            }
        );
        $message = 'Create succeeded. Lab Number ' . $lab_number->lab_number . ' created for well ' . $well->as_string;
    }
    return wantarray ? ($lab_number, $message) : $lab_number ;
}

sub retrieve_well_lab_number {
    my ( $self, $params ) = @_;

    $params->{'id'} = delete $params->{'well_id'} if exists $params->{'well_id'};
    my $well = $self->retrieve_well( $params );
    my $lab_number = $well->well_lab_number
        or $self->throw( NotFound => { entity_class => 'WellLabNumber', search_params => $params } );
    return $lab_number;
}

sub delete_well_lab_number {
    my ( $self, $params ) = @_;

    # retrieve_well() will validate the parameters
    my $lab_number = $self->retrieve_well_lab_number( $params );

    $lab_number->delete;
    $self->log->debug( 'Delete successful. Lab Number deleted for well  ' . $lab_number->well->as_string );

    return;
}

1;

__END__
