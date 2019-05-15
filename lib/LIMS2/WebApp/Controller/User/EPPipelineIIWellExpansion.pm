package LIMS2::WebApp::Controller::User::EPPipelineIIWellExpansion;
use Moose;
use namespace::autoclean;
use Carp;
use Try::Tiny;
use LIMS2::Model::Util::EPPipelineIIWellExpansion qw(create_well_expansion);
BEGIN { extends 'Catalyst::Controller' }

sub expansion : Path( '/user/epII/expansion' ) : Args(0) {
    my ( $self, $c ) = @_;

    my @parent_well_list;
    my @child_well_num_list;
    my $parent_well;
    my $child_well_number;
    my @new_plates;
    my @errors;

    if (ref($c->request->parameters->{'well_names[]'}) eq "ARRAY") {
        @parent_well_list = @{$c->request->parameters->{'well_names[]'}};
        @child_well_num_list = @{$c->request->parameters->{'child_well_numbers[]'}};
    }
    else {
        @parent_well_list = $c->request->parameters->{'well_names[]'};
        @child_well_num_list = $c->request->parameters->{'child_well_numbers[]'};
    }
    foreach my $index (0 .. $#parent_well_list) {
        $parent_well = $parent_well_list[$index];
        $child_well_number = $child_well_num_list[$index];

        my $parameters = {
            plate_name        => $c->request->parameters->{'plate_name'},
            parent_well       => $parent_well,
            child_well_number => $child_well_number,
            species           => $c->session->{selected_species},
            created_by        => $c->user->name,
        };
        try {
            my $freeze_plates_created = create_well_expansion( $c->model('Golgi'), $parameters );
        foreach my $freeze_plate (@$freeze_plates_created) {
            push @new_plates, $freeze_plate;
        }}
        catch {
            push @errors, "$_";
        };
    }
    $c->stash->{json_data} = {plates => \@new_plates, errors => \@errors};
    $c->forward('View::JSON');
    return;
}

__PACKAGE__->meta->make_immutable;

1;
