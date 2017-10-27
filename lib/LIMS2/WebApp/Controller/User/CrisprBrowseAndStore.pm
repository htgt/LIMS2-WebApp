package LIMS2::WebApp::Controller::User::CrisprBrowseAndStore;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::CrisprBrowseAndStore::VERSION = '0.479';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use LIMS2::Model::Util::CrisprOrderAndStorage;
use List::MoreUtils qw(uniq);

BEGIN { extends 'Catalyst::Controller' };

=head2 dispatch_opts

Dispatch table for the View actions.

=cut
my $dispatch_opts = {
    create_box           =>   \&create_storage_box,
    discard_box          =>   \&discard_storage_box,
    view_box             =>   \&view_storage_box,
    view_location_box    =>   \&view_storage_box,
    reset_tube           =>   \&reset_tube_location,
    store_crispr         =>   \&store_crispr_in_location,
};

=head2 create_storage_box

Controller proxie method to create a Crispr storage box.

=cut
sub create_storage_box {
    my ($self, $c, $storage_instance) = @_;

    my $box_name = $c->request->param('box_name');
    my $res = $storage_instance->create_new_box($c->user->name, $box_name);

    if ($res) {
        $c->flash( info_msg => "Box name $box_name already exists. Choose another name!" );
    } else {
        $c->flash( info_msg => "Box $box_name has been created." );
    }

    return $c;
}

=head2 discard_storage_box

Controller proxie method to discard a Crispr storage box.

=cut
sub discard_storage_box {
    my ($self, $c, $storage_instance) = @_;

    my $box_name = $c->request->param('box_name');
    my $state = $storage_instance->discard_box($box_name);

    if ($state) {
        $c->flash( info_msg => "Request was not completed. Does $box_name exist?" );
    } else {
        $c->flash( info_msg => "Box $box_name was deleted successfully." );
    }

    return $c;
}

=head2 view_storage_box

Controller proxie method to get info about a Crispr storage box.

=cut
sub view_storage_box {
    my ($self, $c, $storage_instance) = @_;

    my $box_name = $c->request->param('box_name');
    my $box_content = $storage_instance->get_box_details($box_name);

    $c->stash({box_name => $box_content->{name}});
    $c->stash({ box_content => $box_content->{content}});
    $c->stash({ box_creater => $box_content->{box_creater}});

    return $c;
}

=head2 reset_tube_location

Controller proxie method to reset a location in a Crispr storage box.

=cut
sub reset_tube_location {
    my ($self, $c, $storage_instance) = @_;

    my $box_name = $c->request->param('box_name');
    my $tube_locations_str = $c->request->param('tube_reset_input');
    my @tube_locations = split ",", $tube_locations_str;
    @tube_locations = uniq @tube_locations;

    $storage_instance->reset_tube_location($box_name, \@tube_locations);

    return $c;
}

=head2 store_crispr_in_location

Controller proxie method to store a Crispr in a storage box.

=cut
sub store_crispr_in_location {
    my ($self, $c, $storage_instance) = @_;

    my $crispr_id_str = $c->request->param('crispr_input');
    my @crispr_ids = split ",", $crispr_id_str;

    my $box_name = $c->request->param('box_name');

    my $tube_locations_str = $c->request->param('tube_location_input');
    my @tube_locations = split ",", $tube_locations_str;

    my $storing_crispr = $storage_instance->store_crispr($c->user->name, $box_name, \@tube_locations, \@crispr_ids);
    if ($storing_crispr) {
        $c->flash( info_msg => $storing_crispr );
    }

    return $c;
}

=head2 crispr_browse_and_store

Controller method for the crispr_browse_and_store View path.

=cut
sub crispr_browse_and_store :Path( '/user/crispr_browse_and_store' ) : {
    my ( $self, $c, $box_name_arg ) = @_;

    my $storage_instance = LIMS2::Model::Util::CrisprOrderAndStorage->new({ model => $c->model('Golgi') });
    my $max_slides = 5;
    my $box_name;

    ## case: a button has been clicked in a form in crispr_browse_and_store
    my $frontend_action = $c->request->param('action');
    if ($frontend_action) {
        $c = $dispatch_opts->{$frontend_action}->($self, $c, $storage_instance);
    }

    ## case: landed on crispr_browse_and_store through the box link in the crispr_info View
    if ($box_name_arg) {
        $box_name = $box_name_arg;
    } else {
        $box_name = $c->request->param('box_name');
    }

    ## refresh the box_name variable
    if ($frontend_action and grep {$_ eq $frontend_action} ('discard_box', 'create_box')) {
        $box_name = '';
    }

    ## 1- render the current storage box view
    my $box_content = $storage_instance->get_box_details($box_name);
    $c->stash({box_name => $box_content->{name}});
    $c->stash({ box_content => $box_content->{content}});
    $c->stash({ box_creater => $box_content->{box_creater}});

    ## 2- render the box slider content
    my $store_content = $storage_instance->get_store_content();
    if (scalar @{$store_content} < 5) {
        $max_slides = scalar @{$store_content};
    }
    $c->stash({store_content => $store_content});
    $c->stash({total => scalar @{$store_content}});
    $c->stash({max_slides => $max_slides});

    ## 3- render the current storage box metadata content
    my $box_metadata = $storage_instance->get_box_metadata($box_content->{name});
    $c->stash({box_metadata => $box_metadata});

    return;
}

__PACKAGE__->meta->make_immutable;

1;

