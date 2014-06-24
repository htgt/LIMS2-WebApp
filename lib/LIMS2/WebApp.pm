package LIMS2::WebApp;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::VERSION = '0.210';
}
## use critic

use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use Log::Log4perl::Catalyst;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader
    Static::Simple
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    Authentication
    Authorization::Roles
    /;

extends 'Catalyst';

# Configure the application.
#
# Note that settings in lims2_webapp.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'LIMS2::WebApp',

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1,    # Send X-Catalyst header
    'View::HTML' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to( 'root', 'lib' ),
            __PACKAGE__->path_to( 'root', 'site' ),
            $ENV{SHARED_WEBAPP_TT_DIR} || '/opt/t87/global/software/perl/lib/perl5/WebAppCommon/shared_templates',
        ],
    },
    'Plugin::Session' => {
        expires => 28800,                                # 8 hours
        storage => $ENV{LIMS2_SESSION_STORE}
    },
    'static' => {
        include_path => [
            $ENV{SHARED_WEBAPP_STATIC_DIR} || '/opt/t87/global/software/perl/lib/perl5/WebAppCommon/shared_static',
            __PACKAGE__->path_to( 'root' ),
        ],
        ignore_extensions => [ qw{ tt } ],
    },
);

# Configure Log4perl
__PACKAGE__->log( Log::Log4perl::Catalyst->new( $ENV{LIMS2_LOG4PERL_CONFIG} ) );

# Start the application
__PACKAGE__->setup();

=head1 NAME

LIMS2::WebApp - Catalyst based application

=head1 SYNOPSIS

    script/lims2_webapp_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<LIMS2::WebApp::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
