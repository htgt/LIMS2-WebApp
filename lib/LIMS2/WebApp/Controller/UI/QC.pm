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
    my $qc_run;

    try {
        $qc_run = $c->model('Golgi')->retrieve_qc_run_results( { id => $qc_run_id } );
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

    unless ( $qc_run ) {
        $c->stash( error_msg => "QC run $qc_run_id not found" );
        return $c->go( 'index' );
    }

    $c->stash(
        qc_run => $qc_run,
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
