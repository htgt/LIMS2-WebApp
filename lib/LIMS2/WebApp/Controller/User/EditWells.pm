package LIMS2::WebApp::Controller::User::EditWells;

use Moose;
use Data::Dump 'pp';
use Try::Tiny;
use Const::Fast;
use Smart::Comments;
use LIMS2::Model::Constants qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS );
use namespace::autoclean;
use LIMS2::Model::Util::AddWellToPlate qw( create_well get_well );

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return;
}

sub add_well : Path( '/user/add_well' ) : Args(0) {
    my ( $self, $c ) = @_;

    return unless $c->request->method eq 'POST';

    if ( $c->request->param('csv') ) {
        my $result = $self->add_well_csv($c);
        return $result;
    }
    else {
        my $result = $self->add_well_single($c);
        return $result;
    }
}

sub add_well_csv {
    my ( $self, $c ) = @_;

    my $csv = $c->request->upload('csv_upload');
    my @ids;

    my $data = $csv->fh;

    while (my $line = <$data>) {
        chomp $line;

        my @values = split(",", $line);

        my $params = {
            parent_plate    => $values[0],
            parent_well     => $values[1],
            target_plate    => $values[2],
            template_well   => $values[3],
            target_well     => $values[4],
            user            => $c->user->name,
        };

        my $result = $self->_create_well($c, $params);

        unless ($result->{success} == 1) {
            $c->stash( $result->{stash} );
            return;
        }
        else {
            push @ids, $result->{well_id};
        }


    }

    close $data;
    my $created_ids = join(', ', @ids);

    $c->flash( success_msg => "Successfully created wells: " . $created_ids );

    return $c->response->redirect( $c->uri_for('/user/add_well') );
}

sub add_well_single {
    my ( $self, $c ) = @_;

    my $params = {
        parent_plate    => $c->request->param('parent_plate'),
        parent_well     => $c->request->param('parent_well'),
        target_plate    => $c->request->param('target_plate'),
        target_well     => $c->request->param('target_well'),
        template_well   => $c->request->param('template_well'),
        user            => $c->user->name,
    };

    my $result = $self->_create_well($c, $params);

    unless ($result->{success} == 1) {
        $c->stash( $result->{stash} );
        return;
    }

    $c->flash( success_msg => "ID: " . $result->{well_id} . " - Well successfully added" );

    return $c->response->redirect( $c->uri_for('/user/add_well') );

}

sub _create_well {
    my ($self, $c, $params) = @_;

    my $well;
    my $result;
    my $success = 1;

    $result = get_well($c->model('Golgi'), {
        plate   => $params->{target_plate},
        well    => $params->{template_well},
        params  => $params,
    });

    $well = $result->{well};

    return $result unless $result->{success} == 1;

    $result = get_well($c->model('Golgi'), {
        plate  => $params->{parent_plate},
        well   => $params->{parent_well},
        params  => $params,
    });

    return $result unless $result->{success} == 1;

    $params->{process} = ($well->parent_processes)[0];

    my $process_data_ref = {
        type            => $params->{process}->type_id,
        input_wells     => [ { plate_name => $params->{parent_plate}, well_name => $params->{parent_well} } ],
        output_wells    => [ { plate_name => $params->{target_plate}, well_name => $params->{target_well} } ],
    };

    my $created_well = create_well( $c->model('Golgi'), {
        process_data => $process_data_ref,
        process => $params->{process},
        params => $params,
    });

    $result->{well_id} = $created_well->id;

    return $result;

}

sub move_well : Path( '/user/move_well' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        stages_complete  => $c->request->param('stages_complete') || '0',
    );

    return unless $c->request->method eq 'POST';

    if      ( $c->request->param('stages_complete') == 0 ) {
        my $result = $self->retrieve_well($c);
        return $result;
    }
    elsif   ( $c->request->param('stages_complete') == 1 ) {
        my $result = $self->retrieve_plate($c);
        return $result;
    }
    elsif   ( $c->request->param('stages_complete') == 2 ) {
        my $result = $self->commit_move($c);
        $c->stash( stages_complete  => '0' );
        return $result;
    }
}


sub retrieve_well {
    my ( $self, $c ) = @_;

    my $plate = $c->request->param('source_plate');
    my $well = $c->request->param('source_well');
    my $result;

    try {
        $result->{well} = $c->model('Golgi')->retrieve_well({
            plate_name  => $plate,
            well_name   => $well,
        });
        $result->{stash} = {
            source_plate    => $plate,
            source_well     => $well,
            stages_complete    => '1',
            success_msg     => "Successfully retrieved well: $plate $well.",
        };

    }
    catch {
        $result->{stash} = {
            error_msg => "Unable to retrieve well: $plate $well. \n\n Error: $_",
            source_plate    => $plate,
            source_well     => $well,
            stages_complete => '0',
        };
    };

    $c->stash( $result->{stash} );
    return $result;

}

sub retrieve_plate {
    my ( $self, $c ) = @_;

    my $plate = $c->request->param('destination_plate');
    my $result;

    try {
        $result->{plate} = $c->model('Golgi')->retrieve_plate({
            name => $plate,
        });
        $result->{stash} = {
            source_well         => $c->request->param('source_well'),
            source_plate        => $c->request->param('source_plate'),
            destination_plate   => $plate,
            stages_complete     => '2',
            success_msg         => "Successfully retrieved plate: $plate.",
        };
    }
    catch {
        $result->{stash} = {
            source_well         => $c->request->param('source_well'),
            source_plate        => $c->request->param('source_plate'),
            destination_plate   => $plate,
            stages_complete     => '1',
            error_msg         => "Unable to retrieve plate: $plate. \n\n Error: $_",
        };
    };

    $c->stash( $result->{stash} );
    return $result;
}

sub commit_move {
    my ( $self, $c ) = @_;

    my $dest_plate      = $c->request->param('destination_plate');
    my $source_plate    = $c->request->param('source_plate');
    my $well            = $c->request->param('source_well');
    my $result;

    $result->{plate} = $c->model('Golgi')->retrieve_plate({
        name => $dest_plate,
    });

    $result->{well} = $c->model('Golgi')->retrieve_well({
        plate_name  => $source_plate,
        well_name   => $well,
    });

    try {

        $result->{well} = $result->{well}->update({ plate_id => $result->{plate}->id });
        $result->{stash} = {
            success_msg     => "Successfully updated plate $dest_plate with well $well",
            stages_complete => '0',
        };
    }
    catch {
        $result->{stash} = {
            source_well         => $c->request->param('source_well'),
            source_plate        => $c->request->param('source_plate'),
            destination_plate   => $dest_plate,
            stages_complete     => '2',
            error_msg         => "Unable to update well: $source_plate $well. \n\n Error: $_",
        };
    };

    $c->stash( $result->{stash} );
    return $result;

}


=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
