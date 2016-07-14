package LIMS2::WebApp::View::HTML_fragment;

use strict;
use warnings;

use base 'Catalyst::View::TT';

use Template::AutoFilter;

__PACKAGE__->config(
    CLASS              => 'Template::AutoFilter',
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
);

1;

__END__