package LIMS2::Model::Util::AddWellToPlate;

use strict;
use warnings FATAL => 'all';
use Smart::Comments;
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [
        qw(
            create_well
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
    process_recombinases => { relationship => "recombinase", column => "id"},
    process_cell_line    => { relationship => "cell_line",   column => "name"},
    process_nuclease     => { relationship => "nuclease",    column => "name" },
);


sub create_well {
    my ($model, $params) = @_;

    foreach my $field ( @{ $PROCESS_TYPE_DATA{$params->{process_data}->{type}} } ) {

        my @result = $params->{process}->$field;

        my $relationship    = $FIELD_NAMES{$field}->{relationship};
        my $column          = $FIELD_NAMES{$field}->{column};

        foreach my $entry ( @result ) {
            if ( defined $params->{process_data}->{$relationship} ) {
                if ( ref $params->{process_data}->{$relationship} ne 'ARRAY' ) {
                    $params->{process_data}->{$relationship} = [ $params->{process_data}->{$relationship} ];
                }

                push @{ $params->{process_data}->{$relationship} }, $entry->$relationship->$column;
            }
            else {
                $params->{process_data}->{$relationship} = $entry->$relationship->$column;
            }
        }
    }

    return $model->txn_do(
        sub {
            my $well = $model->create_well( {
                plate_name  => $params->{params}->{target_plate},
                well_name   => $params->{params}->{target_well},
                process_data    => $params->{process_data},
                created_by      => $params->{params}->{user},
            } );

            return $well;
        }
    );
}

sub get_well {
    my ($model, $params) = @_;
    my $well;
    my $stash;
    my $success = 1;
    my $result;
    my $data = $params->{params};

    try {
        $well = $model->retrieve_well({
            plate_name  => $params->{plate},
            well_name   => $params->{well},
        });
    }
    catch {
        $stash = {
            parent_plate   => $data->{parent_plate},
            parent_well    => $data->{parent_well},
            target_plate   => $data->{target_plate},
            target_well    => $data->{target_well},
            template_well  => $data->{template_well},
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