package LIMS2::Model::Util::ComputeAcceptedStatus;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::ComputeAcceptedStatus::VERSION = '0.355';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ 'compute_accepted_status' ]
};

use LIMS2::Exception::Implementation;

# XXX We are dispatching on plate type, which gets us by for now, but
# this may need to cater in the future for dispatch on plate type,
# process type, and/or pipeline.

my %HANDLER_FOR = (
    DESIGN     => \&has_recombineering_pass,
    INT        => \&has_sequencing_pass,
    POSTINT    => \&has_sequencing_pass,
    FINAL      => \&has_sequencing_pass,
    FINAL_PICK => \&has_sequencing_pass,
    DNA        => \&has_dna_pass,
);

sub compute_accepted_status {
    my ( $model, $well ) = @_;

    my $plate_type = $well->plate->type_id;

    my $handler;
    if ( exists $HANDLER_FOR{$plate_type} ) {
        $handler = $HANDLER_FOR{$plate_type};
    }
    else {
        LIMS2::Exception::Implementation->throw(
            "No handler defined for computing accepted status of $plate_type well"
        );
    }

    return $handler->( $model, $well ) ? 1 : 0;
}

sub has_recombineering_pass {
    my ( $model, $well ) = @_;

    my $res = $well->recombineering_result( 'rec_result' );

    return $res && $res->result eq 'pass';
}

sub has_sequencing_pass {
    my ( $model, $well ) = @_;

    my $res = $well->well_qc_sequencing_result;

    return $res && $res->pass;
}

sub has_dna_pass {
    my ( $model, $well ) = @_;

    my $res = $well->well_dna_status;

    return $res && $res->pass;
}

1;

__END__
