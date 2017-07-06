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
$DB::single=1;
    my $validated_params = $self->check_params($params, pspec_miseq_plate_from_json);

    my $lims_plate_data = {
        name        => $validated_params->{name},
        species     => $validated_params->{species},
        type        => 'MISEQ',
        created_by  => $validated_params->{user},
        created_at  => $validated_params->{time},
    };

    my $plate_data = $c->model('Golgi')->create_plate($lims_plate_data);

    
    return;
}

1;

__END__
