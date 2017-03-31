package LIMS2::Model::Util;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::VERSION = '0.453';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use LIMS2::Exception::Validation;
use Sub::Exporter -setup => {
    exports => [ qw( sanitize_like_expr well_id_for random_string) ]
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
        my $message = 'Can not find parent well ' . $data->{plate_name} . '[' . $data->{well_name} . ']' ;
        if($data->{plate_version}){
            $message = 'Can not find parent well ' . $data->{plate_name}
                       . '(version: '.$data->{plate_version}.')'
                       .'[' . $data->{well_name} . ']' ;
        }
        LIMS2::Exception::Validation->throw( $message );
    };

    return $well->id;
}

sub random_string{
    my ( $length ) = @_;

    $length ||= 6;
    my @chars=('a'..'z','A'..'Z','0'..'9');
    my $random_name;
    for(1..$length){
        # rand @chars will generate a random
        # number between 0 and scalar @chars
        $random_name.=$chars[rand @chars];
    }
    return $random_name;
}

1;

__END__
