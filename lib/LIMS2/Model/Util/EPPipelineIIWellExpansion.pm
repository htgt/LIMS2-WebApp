package LIMS2::Model::Util::EPPipelineIIWellExpansion;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::EPPipelineIIWellExpansion::VERSION = '0.532';
}
## use critic


use strict;
use warnings;

use LIMS2::Model::Util::Miseq qw(well_builder);
use List::Util qw(min);

use Sub::Exporter -setup => {
    exports => [
        qw(
            create_well_expansion
            )
    ]
};

sub pspec_create_well_expansion {
    return {
        plate_name        => { validate => 'ep_plate' },
        parent_well       => { validate => 'ep_well' },
        child_well_number => { validate => 'integer' },
        species           => { validate => 'existing_species' },
        created_by        => { validate => 'existing_user' },
    };
}

sub create_well_expansion {
    my ( $model, $params ) = @_;
    my $validated_params  = $model->check_params( $params, pspec_create_well_expansion );
    my $child_well_number = $validated_params->{child_well_number};
    my $letter_id         = 'A';
    my @freeze_plates_created;    #to store freeze plate names returned by create_96_well_plates
    while ( $child_well_number > 0 ) {
        my $plate_wells = min( 96, $child_well_number );

        #creates plates with a maximum of 96 wells
        my $plate_creator = create_96_well_plates( $model, $letter_id, $plate_wells, $validated_params );

        #create_96_well_plates returns false if plate with current letter id already exists
        if ($plate_creator) {
            $child_well_number -= $plate_wells;
            push @freeze_plates_created, $plate_creator;

            #only reduces number of wells left if plate is created
        }
        $letter_id++;
    }
    return \@freeze_plates_created;
}

sub create_96_well_plates {
    my ( $model, $letter_id, $plate_well_number, $validated_params ) = @_;
    my ($plate_index) = $validated_params->{plate_name}  =~ /^HUPEP(\d+)$/;
    my ($well_index)  = $validated_params->{parent_well} =~ /^A0?(\d+)$/;
    my @all_well_names = well_builder( { mod => 0, letters => [ 'A' .. 'H' ] } );
    my @plate_well_names = @all_well_names[ 0 .. ( $plate_well_number - 1 ) ];
    my $epd_name         = "HUPEPD${plate_index}${letter_id}${well_index}";
    my $fp_name          = "HUPFP${plate_index}${letter_id}${well_index}";

    if (   $model->schema->resultset('Plate')->find( { name => $epd_name } )
        || $model->schema->resultset('Plate')->find( { name => $fp_name } ) )
    {
        return 0;
    }
    my @epd_well_params = map {
        {   well_name    => $_,
            parent_plate => $validated_params->{plate_name},
            process_type => 'clone_pick',
            parent_well  => $validated_params->{parent_well}
        }
    } @plate_well_names;
    my $create_epd_plate_params = {
        name       => "$epd_name",
        species    => $validated_params->{species},
        type       => 'EP_PICK',
        created_by => $validated_params->{created_by},
        wells      => \@epd_well_params,
    };
    my $epd_plate = $model->create_plate($create_epd_plate_params);
    my @fp_well_params
        = map { { well_name => $_, parent_plate => $epd_plate->name, process_type => 'freeze', parent_well => $_ } }
        @plate_well_names;
    my $create_fp_plate_params = {
        name       => "$fp_name",
        species    => $validated_params->{species},
        type       => 'FP',
        created_by => $validated_params->{created_by},
        wells      => \@fp_well_params,
    };
    $model->create_plate($create_fp_plate_params);
    return $fp_name;
}

1;
