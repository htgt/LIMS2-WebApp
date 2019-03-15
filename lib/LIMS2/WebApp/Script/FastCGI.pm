package LIMS2::WebApp::Script::FastCGI;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Script::FastCGI::VERSION = '0.531';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends qw( Catalyst::Script::FastCGI );

has '+manager' => ( default => 'FCGI::ProcManager::Constrained' );

__PACKAGE__->meta->make_immutable;

1;
