package LIMS2::WebApp::Pageset;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Pageset::VERSION = '0.312';
}
## use critic


use strict;
use warnings FATAL => 'all';

use base 'Data::Pageset';

use Scalar::Util qw( blessed );
use Carp qw( confess );
use URI;
use URI::QueryParam;

sub new {
    my ( $class, $conf ) = @_;

    $class = ref( $class ) || $class;

    my $base_uri = delete $conf->{base_uri};
    my $self = bless $class->SUPER::new( $conf ), $class;

    if ( $base_uri ) {
        $self->base_uri( $base_uri );
    }

    return $self;
}

sub base_uri {
    my ( $self, $uri ) = @_;

    if ( defined $uri ) {
        if ( blessed $uri and $uri->isa( 'URI' ) ) {
            $self->{base_uri} = $uri->clone;
        }
        else {
            $self->{base_uri} = URI->new( $uri );
        }
    }

    return $self->{base_uri};
}

sub uri {
    my ( $self, $page ) = @_;

    my $base_uri = $self->base_uri()
        or confess "base_uri must be specified before calling uri()";

    my $uri = $base_uri->clone;

    if ( $page ) {
        $uri->query_param( page => $page );
    }

    return $uri;
}

1;

__END__
