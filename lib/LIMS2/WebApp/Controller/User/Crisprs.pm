package LIMS2::WebApp::Controller::User::Crisprs;

use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' };

 sub browse_crisprs : Path( '/user/browse_crisprs' ) : Args(0) {
        my ( $self, $c ) = @_;
    }

 sub browse_crisprs_genoverse : Path( '/user/browse_crisprs_genoverse' ) : Args(0) {
        my ( $self, $c ) = @_;
    }

__PACKAGE__->meta->make_immutable;

1;
