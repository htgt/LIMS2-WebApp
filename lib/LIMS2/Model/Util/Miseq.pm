package LIMS2::Model::Util::Miseq;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
              miseq_plate_from_json
              wells_generator
              convert_index_to_well_name
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Exception;
use JSON;

sub pspec_miseq_plate_from_json {
    return {
        name            => { validate => 'plate_name' },
        data            => { validate => 'hashref' },
        large           => { validate => 'boolean' },
        user            => { validate => 'existing_user' },
        time            => { validate => 'date_time' },
        species         => { validate => 'existing_species' },
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

    my $miseq_plate_data = {
        plate_id    => $lims_plate->id,
        is_384      => $validated_params->{large},
    };
   
    my $miseq_plate = $c->model('Golgi')->create_miseq_plate($miseq_plate_data);

    my $well_data = $validated_params->{data};
    my $miseq_well_hash;
    
    foreach my $fp (keys %{$well_data}) {
        my $process = $well_data->{$fp}->{process};
        foreach my $miseq_well_name (keys %{$well_data->{$fp}->{wells}}) {
            my $fp_well = $well_data->{$fp}->{wells}->{$miseq_well_name};
            $miseq_well_hash->{$process}->{$miseq_well_name}->{$fp} = $fp_well;
        }
    }

    my $process_types = {
        nhej    => 'miseq_no_template',
        oligo   => 'miseq_oligo',
        vector  => 'miseq_vector',
    };

    foreach my $process (keys %{$miseq_well_hash}) {
        miseq_well_relations($self, $c, $miseq_well_hash->{$process}, $validated_params->{name}, $validated_params->{user}, $validated_params->{time}, $process_types->{$process});
    }

    return $miseq_plate;
}

sub miseq_well_relations {
    my ($self, $c, $wells, $miseq_name, $user, $time, $process_type) = @_;
$DB::single=1;
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
            type => $process_type,
        };

        my $params = {
            plate_name      => $miseq_name,
            well_name       => $well,
            process_data    => $process,
            created_by      => $user,
            created_at      => $time,
        };
        my $lims_well = $c->model('Golgi')->create_well($params);
    }

    return;
}

sub convert_index_to_well_name {
    my $index = shift;

    my @wells = wells_generator();
    my $name = $wells[$index - 1];

    return $name;
}

sub wells_generator {
    my @well_names;
    my $quads = {
        '0' => {
            mod     => 0,
            letters => ['A','B','C','D','E','F','G','H'],
        },
        '1' => {
            mod     => 12,
            letters => ['A','B','C','D','E','F','G','H'],
        },
        '2' => {
            mod     => 0,
            letters => ['I','J','K','L','M','N','O','P'], 
        },
        '3' => {
            mod     => 12,
            letters => ['I','J','K','L','M','N','O','P'], 
        }
    };

    for (my $ind = 0; $ind < 4; $ind++) {
        @well_names = well_builder($quads->{$ind}, @well_names);
    }
    
    return @well_names;
}

sub well_builder {
    my ($mod, @well_names) = @_;
    
    foreach my $number (1..12) {
        my $well_num = $number + $mod->{mod};
        foreach my $letter ( @{$mod->{letters}} ) {
            my $well = sprintf("%s%02d", $letter, $well_num);
            push (@well_names, $well);
        }
    }

    return @well_names;
}



1;

__END__
