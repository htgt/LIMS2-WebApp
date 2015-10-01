package LIMS2::WebApp::View::HTML;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::View::HTML::VERSION = '0.339';
}
## use critic


use strict;
use warnings;

use base 'Catalyst::View::TT';

use Template::AutoFilter;

__PACKAGE__->config(
    CLASS              => 'Template::AutoFilter',
    TEMPLATE_EXTENSION => '.tt',
    WRAPPER            => 'wrapper.tt',
    render_die         => 1,
);

1;

__END__

=head1 NAME

LIMS2::WebApp::View::HTML - TT View for LIMS2::WebApp.

=head1 DESCRIPTION

TT View for LIMS2::WebApp. This is a subclass of L<Catalyst::View::TT>
that uses L<Template::AutoFilter> to automatically escape HTML,
protecting against cross-site scripting attacks.

=head1 SEE ALSO

L<LIMS2::WebApp>, L<Template::AutoFilter>

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
