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
        user    => { validate => 'existing_user_id' },
        time    => { validate => 'psql_date' },
        species => { validate => 'existing_species' },
    };
}

sub miseq_plate_from_json {
    my ( $self, $c, $params ) = @_;
$DB::single=1;
    my $validated_params = $self->check_params($params, pspec_miseq_plate_from_json);

    
    return;
}

1;

__END__
