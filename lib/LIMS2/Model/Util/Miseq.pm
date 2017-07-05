package LIMS2::Model::Util::Miseq;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
              miseq_plate_from_json
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Exception;


sub pspec_create_plate_well {
    return {
        well_name    => { validate => 'well_name' },
        process_type => { validate => 'existing_process_type' },
        accepted     => { validate => 'boolean', optional => 1 },
    };
}

# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub create_plate_well {
    my ( $model, $params, $plate ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec_create_plate_well, ignore_unknown => 1 );
    my $parent_well_ids = find_parent_well_ids( $model, $params );

    my %well_params = (
        plate_name => $plate->name,
        well_name  => $validated_params->{well_name},
        created_by => $plate->created_by->name,
        created_at => $plate->created_at->iso8601,
        accepted   => $validated_params->{accepted},
    );

    # the remaining params are specific to the process
    delete @{$params}{qw( well_name process_type accepted )};

    $well_params{process_data} = $params;
    $well_params{process_data}{type} = $validated_params->{process_type};
    $well_params{process_data}{input_wells} = [ map { { id => $_ } } @{$parent_well_ids} ];

    $model->create_well( \%well_params, $plate );

    return;
}

1;

__END__
