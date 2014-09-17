package LIMS2::Model::Util;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::VERSION = '0.243';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use LIMS2::Exception::Validation;
use Sub::Exporter -setup => {
    exports => [ qw( sanitize_like_expr well_id_for ) ]
};

=head2 sanitize_like_expr

Sanitize input for SQL 'like' statement. Need to escape backslashes
first, then underscores and percent signs.

=cut

sub sanitize_like_expr {
    my ( $expr ) = @_;

    for ( $expr ) {
        s/\\/\\\\/g; s/_/\\_/g;
        s/\%/\\%/g;
    }

    return $expr;
}

sub well_id_for {
    my ( $model, $data ) = @_;

    my $well = try { $model->retrieve_well($data) }
    catch {
        LIMS2::Exception::Validation->throw(
            'Can not find parent well ' . $data->{plate_name} . '[' . $data->{well_name} . ']' );
    };

    return $well->id;
}

1;

__END__
