package LIMS2::WebApp::View::HTML;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH       => [
        LIMS2::WebApp->path_to( 'root', 'lib' ),
        LIMS2::WebApp->path_to( 'root', 'site' )
    ],
    WRAPPER            => 'wrapper.tt',
    render_die         => 1,
);

=head1 NAME

LIMS2::WebApp::View::HTML - TT View for LIMS2::WebApp

=head1 DESCRIPTION

TT View for LIMS2::WebApp.

=head1 SEE ALSO

L<LIMS2::WebApp>

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
