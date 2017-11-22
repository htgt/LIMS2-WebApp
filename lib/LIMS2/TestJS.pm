package LIMS2::TestJS;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::TestJS::VERSION = '0.482';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
             setup_user
             setup_public
          )
    ],
};

use Selenium::Firefox;
use feature qw(say);
use Path::Class;
use Log::Log4perl qw( :easy );
use WebAppCommon::Testing::JS qw( setup find_by );

BEGIN {
    #try not to override the lims2 logger
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->easy_init( { level => $OFF } );
    }
}

sub setup_user {
    my $driver = setup();

    find_by($driver, 'class', 'navbar-btn');

    ## no critic (ProhibitImplicitNewLines)
    my $login = q{
        $('#username_field').val('test_user@example.org');
        $('#password_field').val('ahdooS1e');
        return;
    };
    ## use critic
    $driver->execute_script($login);
    find_by($driver, 'id', 'login_button');
    say $driver->get_title();

    return $driver;
}

sub setup_public {
    my $driver = setup();

    return $driver;
}

1;
