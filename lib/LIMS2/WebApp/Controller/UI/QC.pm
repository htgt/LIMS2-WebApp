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

sub index :Path( '/ui/qc_run' ) :Args(0) {
    my ( $self, $c ) = @_;
    my $qc_run_results;

    try {
        $qc_run_results = $c->model('Golgi')->retrieve_qc_run_results( $c->request->params );
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
        qc_run   => $qc_run_results,
        template => 'ui/qc/qc_run.tt'
    );
}

#sub index :Path( '/ui/qc_runs' ) :Args(0) {
    #my ( $self, $c ) = @_;

    #my $qc_run = $c->model('Golgi')->txn_do(
        #sub {
            #shift->retrieve_qc_runs( $c->request->params );
        #}
    #);

    #my $entity;

    #if ( @{$templates} > 1 ) {
        #$entity = [
            #map {
                #+{
                    #id   => $_->{id},
                    #name => $_->{name},
                    #url  => $c->uri_for( '/api/qc/template', { id => $_->{id} } )
                #}
            #} @{$templates}
        #];
    #}
    #else {
        #$entity = $templates;
    #}

    #return $self->status_ok( $c, entity => $entity );

    #$c->stash(
        #plate    => $plate->as_hash,
        #template => 'ui/view_plate/index.tt'
    #);
#}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
