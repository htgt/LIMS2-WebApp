package LIMS2::WebApp::Controller::User::EditWells;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::EditWells::VERSION = '0.460';
}
## use critic


use Moose;
use Data::Dump 'pp';
use Try::Tiny;
use Const::Fast;
use Text::CSV;
use LIMS2::Model::Constants qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS );
use namespace::autoclean;
use LIMS2::Model::Util::AddWellToPlate qw( add_well_create_well get_well );

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return;
}

sub add_well : Path( '/user/add_well' ) : Args(0) :ActionClass( 'REST' ) {
}

sub add_well_GET {
    # body...
}

sub add_well_POST {
    my ( $self, $c ) = @_;

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
    my $csv_h = Text::CSV->new();
    my $fh;

    open $fh, "<:encoding(utf8)", $csv->tempname or die;
    @ids = $self->_add_well_extract_data($c, $csv_h, $fh, @ids);
    close $fh;
    if ($c->stash->{error_msg}) {
        return;
    }

    if (scalar @ids > 0) {
        my $created_ids = join(', ', @ids);
        $c->flash( success_msg => "Successfully created wells: " . $created_ids );
    } else {
        $c->flash( info_msg => "No wells were created." );
    }

    return $c->response->redirect( $c->uri_for('/user/add_well') );
}

sub _add_well_extract_data {
    my ($self, $c, $csv_h, $file_h, @ids) = @_;

    my $result;

    $csv_h->column_names( @{ $csv_h->getline( $file_h ) } );

    my @columns_array = $csv_h->column_names;
    my %columns = map { $_ => 1 } @columns_array;

    unless (exists($columns{'template_well'}) && exists($columns{'parent_well'}) && exists($columns{'target_well'})) {
        $c->stash->{error_msg} = 'Invalid file. The file must be a csv containing the headers "template_well", "target_well" and "parent_well".';
        return;
    }
    while ( my $data = $csv_h->getline_hr( $file_h ) ) {
        $c->log->debug( 'Creating well data for: ' . $data->{target_plate} . ' ' . $data->{target_well} );


        my $params = $data;

        $params->{user} = $c->user->name;

        $result = $self->_create_well($c, $params);

        if ($c->stash->{error_msg}) {
            return;
        }
        else {
            push @ids, $result->{well_id};
        }
    }
    return @ids;
}

sub add_well_single {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;
    $params->{user} = $c->user->name;

    my $result = $self->_create_well($c, $params);

    if ($c->stash->{error_msg}) {
        return;
    }

    $c->flash( success_msg => "ID: " . $result->{well_id} . " - Well successfully added" );

    return $c->response->redirect( $c->uri_for('/user/add_well') );

}

sub _create_well {
    my ($self, $c, $params) = @_;

    my $well;
    my $result;
    my $success = 0;

    $params->{plate} = $params->{target_plate};
    $params->{well}  = $params->{template_well};
    $result = get_well($c->model('Golgi'), $params);

    $well = $result->{well};

    unless ($result->{success} == 1) {
        $c->stash->{error_msg} = $result->{stash}->{error_msg};
        return;
    }
    $result->{success} = 0;

    $params->{plate} = $params->{parent_plate};
    $params->{well}  = $params->{parent_well};
    $result = get_well($c->model('Golgi'), $params);

    unless ($result->{success} == 1) {
        $c->stash->{error_msg} = $result->{stash}->{error_msg};
        return;
    }
    $result->{success} = 0;

    unless ($params->{target_well} =~ m{^[A-H](0[1-9]|1[0-2])$}) {
        $c->stash->{error_msg} = "Well will not fit in a 96 well plate: $params->{target_well}";
        return;
    }

    $params->{process} = ($well->parent_processes)[0];

    my $process_data_ref = {
        type            => $params->{process}->type_id,
        input_wells     => [ { plate_name => $params->{parent_plate}, well_name => $params->{parent_well} } ],
        output_wells    => [ { plate_name => $params->{target_plate}, well_name => $params->{target_well} } ],
    };

    $params->{process_data} = $process_data_ref;
    try {
        my $created_well = add_well_create_well( $c->model('Golgi'), $params);

        $result->{well_id} = $created_well->id;
        $result->{success} = 1;
    }
    catch {
        $c->stash->{error_msg} = "Error creating well: \n\n$_";
    };
    return $result;

}

sub move_well : Path( '/user/move_well' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        stages_complete  => $c->request->param('stages_complete') || '0',
    );

    return unless $c->request->method eq 'POST';

    if      ( $c->request->param('stages_complete') == 0 ) {
        my $result = $self->edit_well_retrieve_well($c);
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


sub edit_well_retrieve_well {
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
