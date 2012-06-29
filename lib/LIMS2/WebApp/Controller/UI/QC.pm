package LIMS2::WebApp::Controller::UI::QC;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::UI::QC - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub begin :Private {
    my ( $self, $c ) = @_;
    #$c->assert_user_roles( 'read' );
}

sub index :Path( '/ui/qc_runs' ) :Args(0) {
    my ( $self, $c ) = @_;
    my $qc_runs;

    try {
        $qc_runs = $c->model('Golgi')->retrieve_qc_runs( $c->request->params );
    }
    catch {
        if ( blessed( $_ ) and $_->isa( 'LIMS2::Model::Error' ) ) {
            $_->show_params( 0 );
            $c->stash( error_msg => $_->as_string );
            $c->detach( 'index' );
        }
        else {
            die $_;
        }
    };

    $c->stash(
        qc_runs => $qc_runs,
        profiles => $c->model('Golgi')->list_profiles,
    );
}

#TODO use chained actions
sub qc_run :Path( '/ui/qc_run' ) :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;
    my ( $qc_run, $results );

    try {
        ( $qc_run, $results ) = $c->model('Golgi')->qc_run_results( { id => $qc_run_id } );
    }
    catch {
        if ( blessed( $_ ) and $_->isa( 'LIMS2::Model::Error' ) ) {
            $_->show_params( 0 );
            $c->stash( error_msg => $_->as_string );
            $c->detach( 'index' );
        }
        else {
            die $_;
        }
    };

    $c->stash(
        qc_run => $qc_run->as_hash,
        results => $results,
    );

    if ( $c->req->param( 'view' ) eq 'csvdl' ) {
        my @primers = $qc_run->primers;
        my @columns = ( qw(
                              plate_name
                              well_name_384
                              well_name
                              marker_symbol
                              design_id
                              expected_design_id
                              pass
                              score
                              num_reads
                              num_valid_primers
                              valid_primers_score
                      ),
                        map( { $_.'_pass',
                               $_.'_critical_regions',
                               $_.'_target_align_length',
                               $_.'_read_length',
                               $_.'_score' } @primers ),
                        map( { $_.'_features' } @primers )
                    );

        $c->stash(
            template     => 'ui/qc/qc_run.csvtt',
            csv_filename => substr( $qc_run_id, 0, 8 ) . '.csv',
            columns      => \@columns
        );
    }
}

sub qc_run_summary :Path( '/ui/qc_run_summary' ) :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;
    my ( $qc_run, $results );

    try {
        ( $qc_run, $results ) = $c->model('Golgi')->qc_run_summary_results( { id => $qc_run_id } );
    }
    catch {
        if ( blessed( $_ ) and $_->isa( 'LIMS2::Model::Error' ) ) {
            $_->show_params( 0 );
            $c->stash( error_msg => $_->as_string );
            $c->detach( 'index' );
        }
        else {
            die $_;
        }
    };

    $c->stash(
        columns  => [ qw( design_id marker_symbol plate_name well_name pass valid_primers ) ],
        results  => $results,
        qc_run   => $qc_run->as_hash
    );

    if ( $c->req->param( 'view' ) eq 'csvdl' ) {
        $c->stash( csv_filename => substr( $qc_run_id, 0, 8 ) . '_summary.csv' );
    }
}

sub view_result :Path( '/ui/view_result' ) :Args(3) {
    my ( $self, $c, $qc_run_id, $plate_name, $well_name ) = @_;

    my ( $qc_run, $seq_reads, $results );

    try {
        ( $seq_reads, $results ) = $c->model('Golgi')->qc_run_seq_well_result( { qc_run_id => $qc_run_id, plate_name => $plate_name, well_name => uc( $well_name ) } );
        $qc_run = $c->model('Golgi')->retrieve_qc_run( { id => $qc_run_id } );
    }
    catch {
        if ( blessed( $_ ) and $_->isa( 'LIMS2::Model::Error' ) ) {
            $_->show_params( 0 );
            $c->stash( error_msg => $_->as_string );
            $c->detach( 'index' );
        }
        else {
            die $_;
        }
    };

    $c->stash(
        qc_run     => $qc_run->as_hash,
        plate_name => $plate_name,
        well_name  => $well_name,
        results    => $results,
        seq_reads  => [ sort { $a->primer_name cmp $b->primer_name } @{ $seq_reads } ]
    );
}

sub view_alignment :Path( '/ui/view_alignment' ) :Args(2) {
    my ( $self, $c, $qc_test_result_id, $qc_seq_read_id ) = @_;

    my $alignment_data;

    try {
        $alignment_data = $c->model('Golgi')->qc_alignment_result(
            { qc_test_result_id => $qc_test_result_id, qc_seq_read_id => $qc_seq_read_id } );
    }
    catch {
        if ( blessed( $_ ) and $_->isa( 'LIMS2::Model::Error' ) ) {
            $_->show_params( 0 );
            $c->stash( error_msg => $_->as_string );
            $c->detach( 'index' );
        }
        else {
            die $_;
        }
    };

    $c->stash( data => $alignment_data );
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
