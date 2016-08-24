package LIMS2::TestJS;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
             setup_user
             setup_public
             run_all_tests
             find_by
             cycle_windows
             close_additional_windows
          )
    ],
};

use Selenium::Firefox;
use feature qw(say);
use Path::Class;
use Log::Log4perl qw( :easy );

BEGIN {
    #try not to override the lims2 logger
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->easy_init( { level => $OFF } );
    }
}

sub setup_user {
    my ($driver) = @_;
    _setup($driver);

    find_by($driver, 'class', 'navbar-btn');

    ## no critic (ProhibitImplicitNewlines)
    my $login = q{
        $('#username_field').val('test_user@example.org');
        $('#password_field').val('ahdooS1e');
        return;
    };
    ## use critic
    $driver->execute_script($login);
    find_by($driver, 'id', 'login_button');
    say $driver->get_title();

    return;
}

sub setup_public {
    my ($driver) = @_;

    _setup($driver);

    return;
}


sub _setup {
    my ($driver) = @_;

    unless ($driver) {
        say "Driver uninitialised";
        return;
    }

    $driver->get('t87-dev.internal.sanger.ac.uk:' . $ENV{LIMS2_WEBAPP_SERVER_PORT});
    say $driver->get_title();
    $driver->set_implicit_wait_timeout(10);
    $driver->maximize_window;

    return;
}

sub find_by {
    my ($driver, $type, $value) = @_;
    #Specify which type you'll be using
    #Types include: class, class_name, css, id, link, link_text, name, partial_link_text, tag_name, xpath

    $type = 'find_element_by_' . $type;
    my $elem = $driver->$type($value);
    $driver->mouse_move_to_location(element => $elem);
    $driver->click;

    return 1;
}

sub cycle_windows {
    my ($driver) = @_;

    my $focus = $driver->get_current_window_handle;
    my @handles = @{ $driver->get_window_handles };
    my $next;
    for (my $inc = 0; $inc < scalar @handles; $inc++) {
        if ($focus eq $handles[$inc] && $inc < scalar @handles) {
            $next = $inc + 1;
        }
        elsif ($focus eq $handles[$inc] && $inc == scalar @handles) {
            $next = 0;
        }
    }

    $driver->switch_to_window($handles[$next]);
    return 1;
}

sub close_additional_windows {
    my ($driver) = @_;

    my $focus = $driver->get_current_window_handle;
    my @handles = @{ $driver->get_window_handles };
    for (my $inc = 0; $inc < scalar @handles; $inc++) {
        if ($focus ne $handles[$inc]) {
            $driver->switch_to_window($handles[$inc]);
            $driver->close();
        }
    }
    $driver->switch_to_window($focus);
    return 1;
}

1;
