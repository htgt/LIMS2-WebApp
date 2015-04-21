package LIMS2::WebApp::Controller::PublicAPI;
use Moose;
use LIMS2::Report;
use Try::Tiny;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::PublicAPI- Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller - API for public, no login required

=cut

# CHECK
# check if a report being generated is ready.
sub report_ready :Path( '/public_api/report_ready' ) :Args(1) :ActionClass('REST') {
}

sub report_ready_GET {
    my ( $self, $c, $report_id ) = @_;

    my $status = LIMS2::Report::get_report_status( $report_id );
    return $self->status_ok( $c, entity => { status => $status } );
}

sub experiment : Path( '/public_api/experiment' ) : Args(0) : ActionClass( 'REST' ){
}

sub experiment_GET{
    my ($self, $c) = @_;

    my $project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->retrieve_experiment( { id => $c->request->param( 'id' ) } );
        }
    );

    return $self->status_ok( $c, entity => $project->as_hash_with_detail );
}

# keeping url to api and not public_api for now as I believe it is being used
# by external groups
sub well_genotyping_crispr_qc :Path('/api/fetch_genotyping_info_for_well') :Args(1) :ActionClass('REST') {
}

sub well_genotyping_crispr_qc_GET {
    my ( $self, $c, $barcode ) = @_;

    #if this is slow we should use processgraph instead of 1 million traversals
    my $well = $c->model('Golgi')->retrieve_well( { barcode => $barcode } );

    return $self->status_bad_request( $c, message => "Barcode $barcode doesn't exist" )
        unless $well;

    my ( $data, $error );
    try {
        #needs to be given a method for finding genes
        $data = $well->genotyping_info( sub { $c->model('Golgi')->find_genes( @_ ); } );
    }
    catch {
        #get string representation if its a lims2::exception
        $error = ref $_ && $_->can('as_string') ? $_->as_string : $_;
    };

    return $error ? $self->status_bad_request( $c, message => $error )
                  : $self->status_ok( $c, entity => $data );
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
