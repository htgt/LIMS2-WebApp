package LIMS2::WebApp::Controller::User::WellData;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::WellData::VERSION = '0.028';
}
## use critic

use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::WellData - Catalyst Controller

=head1 DESCRIPTION

Create, update or view specific plates well results.

=head1 METHODS

=cut

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return;
}

sub dna_status_update :Path( '/user/dna_status_update' ) :Args(0) {
    my ( $self, $c ) = @_;

    return unless $c->request->params->{update_dna_status};

    my $plate_name = $c->request->params->{plate_name};
    unless ( $plate_name ) {
        $c->stash->{error_msg} = 'You must specify a plate name';
        return;
    }
    $c->stash->{plate_name} = $plate_name;

    my $dna_status_data = $c->request->upload('datafile');
    unless ( $dna_status_data ) {
        $c->stash->{error_msg} = 'No csv file with dna status data specified';
        return;
    }

    my %params = (
        csv_fh     => $dna_status_data->fh,
        plate_name => $plate_name,
        species    => $c->session->{selected_species},
        user_name  => $c->user->name,
    );

    $c->model('Golgi')->txn_do(
        sub {
            try{
                my $msg = $c->model('Golgi')->update_plate_dna_status( \%params );
                $c->stash->{success_msg} = "Uploaded dna status information onto plate $plate_name:<br>"
                    . join("<br>", @{ $msg  });
                $c->stash->{plate_name} = '';
            }
            catch {
                $c->stash->{error_msg} = 'Error encountered while updating dna status data for plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
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
