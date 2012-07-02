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
    $c->assert_user_roles( 'read' );
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
        qc_runs  => $qc_runs,
        profiles => $c->model('Golgi')->list_profiles,
    );
}

sub qc_run : Chained('/') PathPart( 'ui/qc_run' ) CaptureArgs(1) {
    my ( $self, $c, $qc_run_id ) = @_;
    my $qc_run;

    try {
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
        qc_run_obj => $qc_run,
        qc_run     => $qc_run->as_hash,
    );
}

sub view_run : Chained('qc_run') PathPart('view') Args(0) {
    my ( $self, $c ) = @_;

    my $results = $c->model( 'Golgi' )->qc_run_results( $c->stash->{qc_run_obj} );

    $c->stash(
        results => $results,
    );
}

#TODO work out how we are dealing with csv download
sub download_run : Chained('qc_run') PathPart('download') Args(0) {
    my ( $self, $c ) = @_;

    my $qc_run = $c->stash->{ qc_run_obj };
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
        csv_filename => substr( $qc_run->id, 0, 8 ) . '.csv',
        columns      => \@columns
    );

}

sub view_run_summary : Chained('qc_run') PathPart( 'view_summary' ) Args(0) {
    my ( $self, $c ) = @_;
    my $qc_run = $c->stash->{ qc_run_obj };
    my $results = $c->model('Golgi')->qc_run_summary_results( $qc_run );

    $c->stash(
        columns  => [ qw( design_id marker_symbol plate_name well_name pass valid_primers ) ],
        results  => $results,
    );

    # move to new sub
    if ( $c->req->param( 'view' ) eq 'csvdl' ) {
        $c->stash( csv_filename => substr( $qc_run->id, 0, 8 ) . '_summary.csv' );
    }
}

sub qc_seq_well : Chained('qc_run') PathPart('qc_seq_well') CaptureArgs(2) {
    my ( $self, $c, $plate_name, $well_name ) = @_;

    my $qc_seq_well;

    try {
          $qc_seq_well  = $c->model('Golgi')->retrieve_qc_seq_well( {
              qc_run_id => $c->stash->{qc_run_obj}->id,
              plate_name => $plate_name,
              well_name => uc( $well_name )
          } );
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
        plate_name  => $plate_name,
        well_name   => $well_name,
        qc_seq_well => $qc_seq_well,
    );
}

sub well_result : Chained('qc_seq_well') PathPart( 'results' ) :Args(0) {
    my ( $self, $c ) = @_;
    my ( $seq_reads, $results );

    try {
        ( $seq_reads, $results ) = $c->model('Golgi')->qc_run_seq_well_result( $c->stash->{qc_seq_well} );
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
        results    => $results,
        seq_reads  => [ sort { $a->primer_name cmp $b->primer_name } @{ $seq_reads } ]
    );
}

sub seq_reads : Chained('qc_seq_well') PathPart( 'seq_reads' ) :Args(0) {
    my ( $self, $c ) = @_;
    my ( $filename, $formatted_seq );
    my $format = $c->req->params->{format} || 'fasta';

    try{
        ( $filename, $formatted_seq )
            = $c->model('Golgi')->retrieve_qc_seq_read_sequences( $c->stash->{qc_seq_well}, $format );
    }
    catch{
        if ( blessed( $_ ) and $_->isa( 'LIMS2::Model::Error' ) ) {
            $_->show_params( 0 );
            $c->stash( error_msg => $_->as_string );
            $c->detach( 'index' );
        }
        else {
            die $_;
        }
    };

    $c->response->content_type( 'application/octet-stream' ); # XXX Is this an appropriate content type?
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
}

sub qc_eng_seq : Chained('qc_seq_well') PathPart( 'qc_eng_seq' ) :Args(1) {
    my ( $self, $c, $qc_test_result_id ) = @_;
    my ( $filename, $formatted_seq );
    my $format = $c->req->params->{format} || 'genbank';

    try{
        ( $filename, $formatted_seq )
            = $c->model('Golgi')->retrieve_qc_eng_seq( $qc_test_result_id, $format );
    }
    catch{
        if ( blessed( $_ ) and $_->isa( 'LIMS2::Model::Error' ) ) {
            $_->show_params( 0 );
            $c->stash( error_msg => $_->as_string );
            $c->detach( 'index' );
        }
        else {
            die $_;
        }
    };

    $c->response->content_type( 'application/octet-stream' ); # XXX Is this an appropriate content type?
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
}

sub view_alignment : Chained( 'qc_seq_well' ) PathPart('alignment') Args(2) {
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
