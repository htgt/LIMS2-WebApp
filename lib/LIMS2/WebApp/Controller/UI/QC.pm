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

sub view_run :Path( '/ui/view_run' ) :Args(0) {
    my ( $self, $c ) = @_;
    my ( $qc_run, $results );

    try {
        ( $qc_run, $results ) = $c->model( 'Golgi' )->qc_run_results(
            { qc_run_id => $c->request->params->{qc_run_id} } );
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
        qc_run  => $qc_run->as_hash,
        results => $results,
    );
}

#TODO work out how we are dealing with csv download
sub download_run :Path('/ui/download_run') Args(0) {
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

sub view_run_summary :Path( '/ui/view_run_summary' ) Args(0) {
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

sub view_result :Path('/ui/view_result') Args(0) {
    my ( $self, $c ) = @_;

    my ( $qc_run, $seq_reads, $results, $qc_seq_well );
    try {
         ( $qc_seq_well, $seq_reads, $results ) = $c->model('Golgi')->qc_run_seq_well_results( {
              qc_run_id  => $c->req->params->{qc_run_id},
              plate_name => $c->req->params->{plate_name},
              well_name  => uc( $c->req->params->{well_name} ),
          } );
        $qc_run = $c->model('Golgi')->retrieve_qc_run( { id => $c->req->params->{qc_run_id} } );
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
        qc_run      => $qc_run->as_hash,
        qc_seq_well => $qc_seq_well,
        results     => $results,
        seq_reads   => [ sort { $a->primer_name cmp $b->primer_name } @{ $seq_reads } ]
    );
}

sub seq_reads :Path( '/ui/seq_reads' ) :Args(0) {
    my ( $self, $c ) = @_;
    my ( $filename, $formatted_seq );
    my $format = $c->req->params->{format} || 'fasta';

    try{
        ( $filename, $formatted_seq ) = $c->model('Golgi')->qc_seq_read_sequences(
            {
                qc_run_id  => $c->req->params->{qc_run_id},
                plate_name => $c->req->params->{plate_name},
                well_name  => uc( $c->req->params->{well_name} ),
                format     => $format,
            }
        );
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

    $c->response->content_type( 'chemical/seq-na-fasta' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
}

sub qc_eng_seq :Path( '/ui/qc_eng_seq' ) :Args(0) {
    my ( $self, $c ) = @_;
    my ( $filename, $formatted_seq );
    my $format = $c->req->params->{format} || 'genbank';

    try{
        ( $filename, $formatted_seq ) = $c->model('Golgi')->qc_eng_seq_sequence(
            {
                qc_test_result_id => $c->req->params->{qc_test_result_id},
                format => $format
            }
        );
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

    $c->response->content_type( 'chemical/seq-na-genbank' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
}

sub view_alignment :Path('/ui/view_alignment') :Args(0) {
    my ( $self, $c ) = @_;
    my $alignment_data;

    try {
        $alignment_data = $c->model('Golgi')->qc_alignment_result(
            { qc_alignment_id => $c->req->params->{qc_alignment_id} }
        );
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
        data       => $alignment_data,
        qc_run_id  => $c->req->params->{qc_run_id},
        plate_name => $c->req->params->{plate_name},
        well_name  => uc( $c->req->params->{well_name} ),
    );
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
