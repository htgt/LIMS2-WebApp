use strict;
use warnings;

use Plack::Builder;
use LIMS2::WebApp;

my $app = LIMS2::WebApp->apply_default_middlewares(LIMS2::WebApp->psgi_app);

builder {
    enable "StackTrace";
    enable 'Debug';
    enable 'Debug::Parameters';
    $app;
};
