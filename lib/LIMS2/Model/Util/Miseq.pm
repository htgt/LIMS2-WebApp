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
use JSON;

sub pspec_miseq_plate_from_json {
    return {
        name    => { validate => 'plate_name' },
        data    => { validate => 'hashref' },
        large   => { validate => 'boolean' },
        user    => { validate => 'existing_user' },
        time    => { validate => 'date_time' },
        species => { validate => 'existing_species' },
    };
}

sub miseq_plate_from_json {
    my ( $self, $c, $params ) = @_;

    my $validated_params = $self->check_params($params, pspec_miseq_plate_from_json);

    my $lims_plate_data = {
        name        => $validated_params->{name},
        species     => $validated_params->{species},
        type        => 'MISEQ',
        created_by  => $validated_params->{user},
        created_at  => $validated_params->{time},
    };

    my $lims_plate = $c->model('Golgi')->create_plate($lims_plate_data);
$DB::single=1;
    my $miseq_plate_data = {
        plate_id    => $lims_plate->id,
        is_384      => $validated_params->{large},
    };
   
    my $miseq_plate = $c->model('Golgi')->create_miseq_plate($miseq_plate_data);

    my $well_data = $validated_params->{data};
    my $miseq_well_hash;
    
    foreach my $fp (keys %{$well_data}) {
        foreach my $miseq_well_name (keys %{$well_data->{$fp}}) {
            my $fp_well = $well_data->{$fp}->{$miseq_well_name};
            $miseq_well_hash->{$miseq_well_name}->{$fp} = $fp_well;
        }
    }

    miseq_well_relations($self, $c, $miseq_well_hash, $validated_params->{name}, $validated_params->{user}, $validated_params->{time});

    return $miseq_plate;
}

sub miseq_well_relations {
    my ($self, $c, $wells, $miseq_name, $user, $time) = @_;

    foreach my $well (keys %{$wells}) {
        my @parent_wells;
        foreach my $fp (keys %{$wells->{$well}}) {
            my $parent_well = {
                plate_name  => $fp,
                well_name   => $wells->{$well}->{$fp},
            };
            push (@parent_wells, $parent_well);
        }
        my $process = {
            input_wells => \@parent_wells,
            output_wells => [{
                plate_name  => $miseq_name,
                well_name   => $well,
            }],
            type => 'miseq',
        };

        my $params = {
            plate_name      => $miseq_name,
            well_name       => $well,
            process_data    => $process,
            created_by      => $user,
            created_at      => $time,
        };
        my $lims_well = $c->model('Golgi')->create_well($params);
        
        my $miseq_well_params = {
            well_id     => $lims_well->id,
            status      => 'Plated',
        };

        my $miseq_well = $c->model('Golgi')->create_miseq_well($miseq_well_params);
    }

    return;
}

1;

__END__
