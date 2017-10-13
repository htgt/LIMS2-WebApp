package LIMS2::WebApp::Controller::User::CrisprLocateInStorage;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::CrisprLocateInStorage::VERSION = '0.478';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use Try::Tiny;
use List::MoreUtils qw(uniq);
use LIMS2::Model::Util::CrisprOrderAndStorage;

BEGIN { extends 'Catalyst::Controller' };

=head2 crispr_locate_in_storage

Returns Crispr ID locations in storage and is able to delete these locations if specified on the frontend.

=cut
sub crispr_locate_in_storage :Path( '/user/crispr_locate_in_storage' ) : {
    my ( $self, $c, $crispr_input ) = @_;

    my $storage_instance = LIMS2::Model::Util::CrisprOrderAndStorage->new({ model => $c->model('Golgi') });
    my $crispr_and_box;

    my @checkbox_vals = $c->request->param('selected_crispr');
    if (@checkbox_vals) {
        foreach my $checkbox (@checkbox_vals) {
            my @temp_params = split ",", $checkbox;
            my $temp_box_name = $temp_params[1];
            my $temp_tube_location = [$temp_params[2]];
            $storage_instance->reset_tube_location($temp_box_name, $temp_tube_location);
        }
    }

    my $crispr_id_str = $c->request->param('crispr_input');

    my @crispr_ids;
    if ($crispr_input) {
        @crispr_ids = split ",", $crispr_input;
    } elsif ($crispr_id_str) {
        @crispr_ids = split ",", $crispr_id_str;
    }

    @crispr_ids = uniq @crispr_ids;
    foreach my $crispr_id (@crispr_ids) {
        push @{$crispr_and_box}, $storage_instance->locate_crispr_in_store($crispr_id);
    }
    $c->stash({crispr_and_box => $crispr_and_box});
    $c->stash({crispr_location_input => join ",", @crispr_ids});
    $c->stash({crispr_input => join ",", @crispr_ids});

    return;
}

__PACKAGE__->meta->make_immutable;

1;

