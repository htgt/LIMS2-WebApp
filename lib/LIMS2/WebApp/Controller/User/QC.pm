package LIMS2::WebApp::Controller::User::QC;
use Moose;
use namespace::autoclean;
use HTTP::Status qw( :constants );
use Scalar::Util qw( blessed );
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

    unless ( $c->user ) {
        $c->stash( error_msg => 'Please login to access this system' );
        $c->go( 'Controller::Auth', 'login' );
    }

    $c->assert_user_roles( 'read' );
    return;
}

sub end :Private {
    my ( $self, $c ) = @_;
    # if we are running in debug mode we want to see the error in its full glory
    if ( $c->debug ) {
        return 1 if $c->response->status =~ /^3\d\d$/;
        return 1 if $c->response->body;
        $c->forward('LIMS2::WebApp::View::HTML');
    }

    if ( scalar @{ $c->error } ) {
        my @errors = @{ $c->error };
        $c->log->error($_) for @errors;
        $c->clear_errors;

        #assume first error most interesting
        my $error = $errors[0];

        if ( blessed( $error ) and $error->isa( 'LIMS2::Exception' ) ) {
            $self->handle_lims2_exception( $c, $error );
        }
        else {
            $self->error_status( $c, HTTP_INTERNAL_SERVER_ERROR, { error => "$error" } );
        }
    }

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }

    $c->forward('LIMS2::WebApp::View::HTML');
}

sub error_status :Private {
    my ( $self, $c, $status_code, $entity ) = @_;

    #TODO should we be setting response status?
    $c->response->status($status_code);

    $c->stash->{error_msg} = $entity->{error};
    return;
}

sub handle_lims2_exception {
    my ( $self, $c, $error ) = @_;

    #TODO: forward to custom error page
    my %entity = ( error => $error->message, class => blessed $error );

    if ( $error->isa('LIMS2::Exception::Authorization') ) {
        return $self->error_status( $c, HTTP_FORBIDDEN, \%entity );
    }

    if ( $error->isa('LIMS2::Exception::Validation') ) {
        if ( my $results = $error->results ) {
            $entity{missing} = [ $results->missing ]
                if $results->has_missing;
            $entity{invalid} = { map { $_ => $results->invalid($_) } $results->invalid }
                if $results->has_invalid;
            $entity{unknown} = [ $results->unknown ]
                if $results->has_unknown;
        }
        return $self->error_status( $c, HTTP_BAD_REQUEST, \%entity );
    }

    if ( $error->isa('LIMS2::Exception::InvalidState') ) {
        return $self->error_status( $c, HTTP_CONFLICT, \%entity );
    }

    if ( $error->isa('LIMS2::Exception::NotFound') ) {
        $entity{entity_class}  = $error->entity_class;
        $entity{search_params} = $error->search_params;
        return $self->error_status( $c, HTTP_NOT_FOUND, \%entity );
    }

    # Default to an internal server error
    return $self->error_status( $c, HTTP_INTERNAL_SERVER_ERROR, { error => $error->message } );
}

sub index :Path( '/user/qc_runs' ) :Args(0) {
    my ( $self, $c ) = @_;

    my ( $qc_runs, $pager ) = $c->model('Golgi')->retrieve_qc_runs( $c->request->params );

    my $pageset = LIMS2::WebApp::Pageset->new(
        {
            total_entries    => $pager->total_entries,
            entries_per_page => $pager->entries_per_page,
            current_page     => $pager->current_page,
            pages_per_set    => 5,
            mode             => 'slide',
            base_uri         => $c->request->uri
        }
    );

    $c->stash(
        qc_runs  => $qc_runs,
        pageset  => $pageset,
        profiles => $c->model('Golgi')->list_profiles,
    );
    return;
}

sub view_qc_run :Path( '/user/view_qc_run' ) :Args(0) {
    my ( $self, $c ) = @_;

    my ( $qc_run, $results ) = $c->model( 'Golgi' )->qc_run_results(
        { qc_run_id => $c->request->params->{qc_run_id} } );

    $c->stash(
        qc_run  => $qc_run->as_hash,
        results => $results,
    );
    return;
}

sub view_qc_result :Path('/user/view_qc_result') Args(0) {
    my ( $self, $c ) = @_;

    my ( $qc_seq_well, $seq_reads, $results ) = $c->model('Golgi')->qc_run_seq_well_results(
        {
            qc_run_id  => $c->req->params->{qc_run_id},
            plate_name => $c->req->params->{plate_name},
            well_name  => uc( $c->req->params->{well_name} ),
        }
    );

    my $qc_run = $c->model('Golgi')->retrieve_qc_run( { id => $c->req->params->{qc_run_id} } );

    $c->stash(
        qc_run      => $qc_run->as_hash,
        qc_seq_well => $qc_seq_well,
        results     => $results,
        seq_reads   => [ sort { $a->primer_name cmp $b->primer_name } @{ $seq_reads } ]
    );
    return;
}

sub qc_seq_reads :Path( '/user/qc_seq_reads' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $format = $c->req->params->{format} || 'fasta';

    my ( $filename, $formatted_seq ) = $c->model('Golgi')->qc_seq_read_sequences(
        {
            qc_run_id  => $c->req->params->{qc_run_id},
            plate_name => $c->req->params->{plate_name},
            well_name  => uc( $c->req->params->{well_name} ),
            format     => $format,
        }
    );

    $c->response->content_type( 'chemical/seq-na-fasta' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
    return;
}

sub qc_eng_seq :Path( '/user/qc_eng_seq' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $format = $c->req->params->{format} || 'genbank';

    my ( $filename, $formatted_seq ) = $c->model('Golgi')->qc_eng_seq_sequence(
        {
            qc_test_result_id => $c->req->params->{qc_test_result_id},
            format => $format
        }
    );

    $c->response->content_type( 'chemical/seq-na-genbank' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
    return;
}

sub view_qc_alignment :Path('/user/view_qc_alignment') :Args(0) {
    my ( $self, $c ) = @_;

    my $alignment_data = $c->model('Golgi')->qc_alignment_result(
        { qc_alignment_id => $c->req->params->{qc_alignment_id} }
    );

    $c->stash(
        data       => $alignment_data,
        qc_run_id  => $c->req->params->{qc_run_id},
        plate_name => $c->req->params->{plate_name},
        well_name  => uc( $c->req->params->{well_name} ),
    );
    return;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
