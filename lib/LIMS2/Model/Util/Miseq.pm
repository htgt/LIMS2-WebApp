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
        data    => { validate => 'hashref' }
    };
}

# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub miseq_plate_from_json {
    my ( $self, $c, $params ) = @_;
$DB::single=1;
    my $data = decode_json $params;
    my $validated_params = $self->check_params( $data, pspec_miseq_plate_from_json );
    
    return;
}

1;

__END__
