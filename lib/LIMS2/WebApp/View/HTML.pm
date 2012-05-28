package LIMS2::WebApp::View::HTML;

use strict;
use warnings;

use Moose;
use Template::AutoFilter;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    CLASS              => 'Template::AutoFilter',
    TEMPLATE_EXTENSION => '.tt',
    WRAPPER            => 'wrapper.tt',
    render_die         => 1,
);

__PACKAGE__->meta->make_immutable;

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
