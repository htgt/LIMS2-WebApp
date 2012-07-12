use strict;
use warnings;
use LIMS2::WebApp;
use Plack::Builder;

my $app = LIMS2::WebApp->psgi_app(@_);

builder {
    enable 'Debug::DBIProfile', profile => 2;
    enable 'Debug', panels => [qw( DBIProfile DBITrace Timer Memory Environment Response )];

    $app;
};

