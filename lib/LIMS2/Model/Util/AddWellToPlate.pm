package LIMS2::Model::Util::AddWellToPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::AddWellToPlate::VERSION = '0.523';
}
## use critic


use strict;
use warnings FATAL => 'all';
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [
        qw(
            add_well_create_well
            get_well
          )
    ]
};

my %PROCESS_TYPE_DATA = (
    'int_recom'              => [qw( process_cassette process_backbone )],
    'cre_bac_recom'          => [qw( process_cassette process_backbone )],
    '2w_gateway'             => [qw( process_cassette process_recombinases )],
    '3w_gateway'             => [qw( process_cassette process_backbone process_recombinases )],
    'recombinase'            => [qw( process_recombinases )],
    'clone_pick'             => [qw( process_recombinases )],
    'first_electroporation'  => [qw( process_cell_line process_recombinases )],
    'second_electroporation' => [qw( process_recombinases )],
    'crispr_ep'              => [qw( process_cell_line process_nuclease )],
    'crispr_vector'          => [qw( process_backbone )],
);

my %FIELD_NAMES = (
    process_backbone     => { relationship => "backbone",    column => "name" },
    process_cassette     => { relationship => "cassette",    column => "name" },
    process_recombinases => { relationship => "recombinase", column => "id"   },
    process_cell_line    => { relationship => "cell_line",   column => "name" },
    process_nuclease     => { relationship => "nuclease",    column => "name" },
);

sub pspec_add_well_create_well {
    return {
        target_plate    => { validate => 'existing_plate_name' },
        target_well     => { validate => 'well_name' },
        template_well   => { validate => 'well_name' },
        parent_plate    => { validate => 'existing_plate_name' },
        parent_well     => { validate => 'well_name' },
        user            => { validate => 'existing_user' },
        process_data    => { validate => 'hashref' },
        process         => { optional => 0 },
        plate           => { validate => 'existing_plate_name' },
        well            => { validate => 'well_name' },
        csv             => { validate => 'boolean', optional => 1 },
    };
}


sub add_well_create_well {
    my ($model, $params) = @_;

    my $validated_params = $model->check_params($params, pspec_add_well_create_well);

    foreach my $field ( @{ $PROCESS_TYPE_DATA{$validated_params->{process_data}->{type}} } ) {

        my @result = $validated_params->{process}->$field;

        my $relationship    = $FIELD_NAMES{$field}->{relationship};
        my $column          = $FIELD_NAMES{$field}->{column};

        foreach my $entry ( @result ) {
            if ( defined $validated_params->{process_data}->{$relationship} ) {
                if ( ref $validated_params->{process_data}->{$relationship} ne 'ARRAY' ) {
                    $validated_params->{process_data}->{$relationship} = [ $validated_params->{process_data}->{$relationship} ];
                }

                push @{ $validated_params->{process_data}->{$relationship} }, $entry->$relationship->$column;
            }
            else {
                $validated_params->{process_data}->{$relationship} = $entry->$relationship->$column;
            }
        }
    }

    return $model->txn_do(
        sub {
            my $well = $model->create_well( {
                plate_name      => $validated_params->{target_plate},
                well_name       => $validated_params->{target_well},
                process_data    => $validated_params->{process_data},
                created_by      => $validated_params->{user},
            } );

            return $well;
        }
    );
}

sub pspec_get_well {
    return {
        parent_plate    => { validate => 'existing_plate_name' },
        parent_well     => { validate => 'well_name' },
        target_well     => { validate => 'well_name' },
        target_plate    => { validate => 'existing_plate_name' },
        template_well   => { validate => 'well_name' },
        plate           => { validate => 'existing_plate_name' },
        well            => { validate => 'well_name' },
        user            => { validate => 'existing_user' },
        csv             => { validate => 'boolean', optional => 1 },
    };
}

sub get_well {
    my ($model, $params) = @_;
    my $well;
    my $stash;
    my $success = 1;
    my $result;
    my $validated_params;

    try {
        $validated_params = $model->check_params($params, pspec_get_well);
    }
    catch {
        $stash = $params;
        $stash->{error_msg} = "Unable to validate data.\n\n Error: $_";
        $success = 0;
    };

    $result = {
        stash   => $stash,
        success => $success,
    };

    return $result unless $success == 1;

    try {

        $well = $model->retrieve_well({
            plate_name  => $validated_params->{plate},
            well_name   => $validated_params->{well},
        });
        $stash = {
            parent_plate   => $validated_params->{parent_plate},
            parent_well    => $validated_params->{parent_well},
            target_plate   => $validated_params->{target_plate},
            target_well    => $validated_params->{target_well},
            template_well  => $validated_params->{template_well},
        };
        $success = 1;
    }
    catch {
        $stash = {
            parent_plate   => $validated_params->{parent_plate},
            parent_well    => $validated_params->{parent_well},
            target_plate   => $validated_params->{target_plate},
            target_well    => $validated_params->{target_well},
            template_well  => $validated_params->{template_well},
            error_msg      => "Unable to retrieve well: $params->{plate}_$params->{well}. \n\n Error: $_",
        };
        $success = 0;
    };

    $result = {
        well    => $well,
        stash   => $stash,
        success => $success,
    };

    return $result;
}

1;
