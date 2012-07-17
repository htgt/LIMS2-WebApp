package LIMS2::Report;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::VERSION = '0.007';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ 'generator_for', 'generate_report' ]
};

use Data::UUID;
use Try::Tiny;
use Text::CSV;
use IO::Pipe;
use Path::Class;
use Log::Log4perl qw( :easy );
use LIMS2::Exception::System;
use LIMS2::Exception::Validation;

sub generator_for {
    my ( $report, $model, $params ) = @_;

    my $generator = load_generator_class( $report )->new(
        +{ %{$params}, model => $model }
    );

    return $generator;
}

sub generate_report {
    my %args = @_;

    my $generator = generator_for( $args{report}, $args{model}, $args{params} );

    my $report_id =  Data::UUID->new->create_str();

    INFO( "Generating $args{report} report $report_id" );

    my $work_dir = init_work_dir( $args{output_dir}, $report_id );

    if ( $args{async} ) {
        run_in_background( $generator, $work_dir );
    }
    else {
        run_in_foreground( $generator, $work_dir );
    }

    return $report_id;
}

sub run_in_background {
    my ( $generator, $work_dir ) = @_;

    local $SIG{CHLD} = 'IGNORE';

    defined( my $pid = fork() )
        or LIMS2::Exception::System->throw( "Fork failed: $!" );

    if ( $pid == 0 ) { # child
        Log::Log4perl->easy_init( { level => $WARN, file => $work_dir->file( 'log' ) } );
        do_generate_report( $generator, $work_dir );
        exit 0;
    }

    return;
}

sub run_in_foreground {
    my ( $generator, $work_dir ) = @_;

    do_generate_report( $generator, $work_dir );

    return;
}

sub do_generate_report {
    my ( $generator, $work_dir ) = @_;

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
    }
    catch {
        ERROR $_;
        $work_dir->file( 'failed' )->touch;
    };

    return;
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


