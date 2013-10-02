package LIMS2::Model::Util::QCTemplates;
use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            create_qc_template_from_wells
            )
    ]
};

use LIMS2::Exception;
use LIMS2::Model::Util::EngSeqParams qw( generate_well_eng_seq_params );
use Log::Log4perl qw( :easy );
use Hash::MoreUtils qw( slice_def );

sub pspec_qc_template_from_wells {
    return {
        template_name => { validate => 'plate_name' },
        species       => { validate => 'existing_species' },
        wells         => { validate => 'hashref' },
    };
}

sub create_qc_template_from_wells {
	my ( $model, $params ) = @_;

	my $validated_params = $model->check_params( $params, pspec_qc_template_from_wells );

	my $existing = $model->retrieve_qc_templates({ name => $params->{template_name} });
	if ( @$existing ){
        LIMS2::Exception->throw( "QC template " . $validated_params->{template_name}
                . " already exists. Cannot use this plate name." );
	}
    DEBUG( "Attempting to create qc template plate: " . $validated_params->{template_name} );

	my $wells;
    for my $name ( keys %{ $validated_params->{wells} } ) {
        my $datum = $validated_params->{wells}->{$name};

        my $well_params = { slice_def( $datum, qw( plate_name well_name well_id cassette backbone) ) };

        # If we have a phase matched cassette group then handle it here
        if ( my $phase_match_group = $datum->{phase_matched_cassette} ) {
            if ( $datum->{cassette} ) {
                LIMS2::Exception->throw(
                    "A new cassette AND phase matched cassette have been provided for well $name");
            }
            TRACE "Attempting to fetch phase matched cassette for well $name";
            my $new_cassette = $model->retrieve_well_phase_matched_cassette(
                { slice_def( $datum, qw(plate_name well_name well_id phase_matched_cassette ) ) } );
            if ($new_cassette) {
                $well_params->{cassette} = $new_cassette;
            }
            else {
                LIMS2::Exception->throw("No suitable phase matched cassette found for well $name");
            }
            TRACE "Phase matched cassette: $new_cassette";
        }

        # Recombinase, if defined, must be an arrayref
        my $recombinase = $datum->{recombinase};
        if ( $recombinase and ref $recombinase eq ref [] ) {
            $well_params->{recombinase} = $recombinase;
        }
        elsif ($recombinase) {
            $well_params->{recombinase} = [$recombinase];
        }

        my ( $method, $source_well_id, $esb_params )
            = generate_well_eng_seq_params( $model, $well_params );

        $wells->{$name}->{eng_seq_id}     = $esb_params->{display_id};
        $wells->{$name}->{well_name}      = $validated_params->{template_name} . "_$name";
        $wells->{$name}->{eng_seq_method} = $method;
        $wells->{$name}->{eng_seq_params} = $esb_params;
        $wells->{$name}->{source_well_id} = $source_well_id;

        # We also need to store the overrides for each QC template well
        $wells->{$name}->{cassette}    = $well_params->{cassette};
        $wells->{$name}->{backbone}    = $well_params->{backbone};
        $wells->{$name}->{recombinase} = $well_params->{recombinase};
    }

    my $template = $model->find_or_create_qc_template(
        {   name    => $validated_params->{template_name},
            species => $validated_params->{species},
            wells   => $wells,
        }
    );
    INFO( 'Created qc template plate: ' . $validated_params->{template_name} );

    return $template;
}

1;

__END__
