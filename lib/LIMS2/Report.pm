package LIMS2::Report;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ 'generator_for', 'generate_report', 'cached_report' ]
};

use Data::UUID;
use Try::Tiny;
use Text::CSV;
use IO::Pipe;
use Path::Class;
use Log::Log4perl qw( :easy );
use Scalar::Util qw( blessed );
use Fcntl qw( :DEFAULT :flock );
use LIMS2::Exception::System;
use LIMS2::Exception::Validation;

sub _cached_report_ok {
    my ( $work_dir, $cache_entry ) = @_;

    my $report_dir = $work_dir->subdir( $cache_entry->id );
    if ( $report_dir->stat && ! $report_dir->file('fail')->stat ) {
        return 1;
    }

    $cache_entry->delete;
    return;
}

sub cached_report {
    my %args = @_;

    my $generator = generator_for( $args{report}, $args{model}, $args{params} );

    # Take an exclusive lock to avoid race between interrogating table
    # and creating cache row. This ensures we don't set off concurrent
    # cache refreshes for the same report.
    my $lock_file = $args{output_dir}->file('lims2.cache.lock');
    my $lock_fh = $lock_file->open( O_RDWR|O_CREAT, oct(644) )
        or LIMS2::Exception::System->throw( "open $lock_file failed: $!" );
    flock( $lock_fh, LOCK_EX )
        or LIMS2::Exception::System->throw( "flock $lock_file failed: $!" );

    if ( my $in_cache = $generator->cached_report ) {
        if ( _cached_report_ok( $args{output_dir}, $in_cache ) ) {
            return $in_cache->id;
        }
    }

    my $cache_entry = $generator->init_cached_report( generate_report_id() );
    $lock_fh->close(); # End of critical code: release the lock

    my $work_dir = init_work_dir( $args{output_dir}, $cache_entry->id );
    run_in_background( $generator, $work_dir, $cache_entry );

    return $cache_entry->id;
}

sub generator_for {
    my ( $report, $model, $params ) = @_;

    my $generator = load_generator_class( $report )->new(
        +{ %{$params}, model => $model }
    );

    return $generator;
}

sub generate_report_id {
    return Data::UUID->new->create_str();
}

sub generate_report {
    my %args = @_;

    my $generator = generator_for( $args{report}, $args{model}, $args{params} );

    my $report_id = generate_report_id();

    INFO( "Generating $args{report} report $report_id" );

    my $work_dir = init_work_dir( $args{output_dir}, $report_id );

    if ( $args{async} ) {
        run_in_background( $generator, $work_dir );
    }
    else {
        run_in_foreground( $generator, $work_dir )
            or return;
    }

    return $report_id;
}

sub run_in_background {
    my ( $generator, $work_dir, $cache_entry ) = @_;

    local $SIG{CHLD} = 'IGNORE';

    defined( my $pid = fork() )
        or LIMS2::Exception::System->throw( "Fork failed: $!" );

    if ( $pid == 0 ) { # child
        Log::Log4perl->easy_init( { level => $WARN, file => $work_dir->file( 'log' ) } );
        $generator->model->clear_schema; # Force re-connect in child process        
        local $0 = 'Generate report ' . $generator->name;
        do_generate_report( $generator, $work_dir, $cache_entry );
        exit 0;
    }

    return;
}

sub run_in_foreground {
    my ( $generator, $work_dir, $cache_entry ) = @_;

    return do_generate_report( $generator, $work_dir, $cache_entry );
}

sub do_generate_report {
    my ( $generator, $work_dir, $cache_entry ) = @_;

    my $ok = 0;

    try {
        my $output_file = $work_dir->file( 'report.csv' );
        my $ofh = $output_file->openw;

        my $csv = Text::CSV->new( { eol => "\n" } );
        $csv->print( $ofh, $generator->columns );

        my $data = $generator->iterator();
        while ( my $datum = $data->next ) {
            $csv->print( $ofh, $datum )
                or LIMS2::Exception::System->throw( "Error writing to $output_file: $!" );
        }

        $ofh->close()
            or LIMS2::Exception::System->throw( "Error closing $output_file: $!" );

        write_report_name( $work_dir->file( 'name' ), $generator->name );

        $work_dir->file( 'done' )->touch;
        $cache_entry && $cache_entry->update( { complete => 1 } );
        $ok = 1;
    }
    catch {
        ERROR $_;
        $work_dir->file( 'failed' )->touch;
        $cache_entry && $cache_entry->delete;
    };

    return $ok;
}

sub write_report_name {
    my ( $file, $report_name ) = @_;

    my $ofh = $file->openw;
    $ofh->print( $report_name )
        or LIMS2::Exception::System->throw( "Error writing to $file: $!" );
    $ofh->close()
        or LIMS2::Exception::System->throw( "Error closing $file: $!" );

    return;
}

sub load_generator_class {
    my $report = shift;

    my $report_class = 'LIMS2::Report::' . $report;
    try {
        eval "require $report_class" or die $@;
    }
    catch {
        if ( m/^Can't locate/ ) {
            LIMS2::Exception::Validation->throw( "No such report $report_class" );
        }
        else {
            LIMS2::Exception::System->throw( "Failed to load $report_class: $_" );
        }
    };

    return $report_class;
}

sub init_work_dir {
    my ( $output_dir, $report_id ) = @_;

    my $work_dir = dir( $output_dir )->subdir( $report_id );
    $work_dir->mkpath;

    return $work_dir;
}

1;

__END__


