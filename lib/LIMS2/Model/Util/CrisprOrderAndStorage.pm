package LIMS2::Model::Util::CrisprOrderAndStorage;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CrisprOrderAndStorage::VERSION = '0.473';
}
## use critic


use Moose;
use Try::Tiny;

has model => (
    is         =>   'ro',
    isa        =>   'LIMS2::Model',
    required   =>   1
);

=head2 get_box_details

Get Crispr storage box info from database.

=cut
sub get_box_details {
    my ($self, $name) = @_;

    ## create 10x10 empty locations
    my @no_result = map { {} } 1..100;
    my @sql_result = @no_result;

    unless ($name) {
        my @names = $self->get_box_names();
        $name = $names[0];
    }

    my $box;
    my $box_creater_email = '';

    if ($name) {
        @sql_result = $self->model->schema->resultset('CrisprStorage')->search(
            { box_name => { '=', $name } },
            { order_by    => { -asc   => 'id'}, })->all;
    }

    ## box content is in the form of 10 arrays complementary to the box visualisations
    my @store = (); my $count = 0; my $indx = 1;
    foreach my $elem (@sql_result) {
        my %data;
        try {## if data is not empty
            %data = $elem->get_columns;
        };
        push @store, \%data;
        $count += 1;
        if ($count % 10 == 0) {
            @{$box->{$indx}} = @store;
            @store = ();
            $indx += 1;
        }
        try {## if data is not empty
            $box_creater_email = $elem->get_column('created_by_user');
        };
    }
    my @box_creater = split "@", $box_creater_email;

    return {
        name => $name,
        content => $box,
        box_creater => $box_creater[0]
    };

}

=head2 get_box_names

Get the names of Crispr stroage boxed in the database.

=cut
sub get_box_names{
    my $self = shift;

    my @sql_result = $self->model->schema->resultset('CrisprStorage')->search(
        {},
        {
            columns => [ qw/box_name/ ],
            distinct => 1
        })->all;

    return map {$_->box_name} @sql_result;
}

=head2 get_store_content

Get box content for the JQuery bxslider.

=cut
sub get_store_content{
    my $self = shift;

    my @box_result;
    my @names;

    @names = $self->get_box_names();

    foreach my $name (@names) {
      push @box_result, $self->get_box_details($name);
    }

    return \@box_result;
}

=head2 locate_crispr_in_store

Find the occirrences of a Crispr Id in store.

=cut
sub locate_crispr_in_store {
    my ($self, $crispr_id) = @_;

    my @boxes;
    try {
        my @records = $self->model->schema->resultset('CrisprStorage')->search(
            { crispr_id => $crispr_id },
            { distinct => 1 })->all;

        for my $rec (@records) {
            my %data = $rec->get_columns;
            push @boxes, \%data;
        }
    };

    return @boxes;
};

=head2 create_new_box

Create a new Crispr storage box.

=cut
sub create_new_box {
    my ($self, $created_by, $box_name) = @_;

    $box_name =~ s/^\s+//;
    $box_name =~ s/\s+$//;
    if ($box_name) {

    my @sql_result = $self->model->schema->resultset('CrisprStorage')->search(
        { box_name => $box_name },
        {
            columns => [ qw/box_name/ ],
            distinct => 1
        })->all;

    my @box_with_name = map {$_->box_name} @sql_result;

        if (scalar @box_with_name > 0) {
            return 1;
        }

        my @alphabets = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j');
        my @count = 1..10;
        foreach my $letter (@alphabets) {
            foreach my $digit (@count) {
                my $temp_letter = uc $letter;
                my $temp_digit = sprintf("%02d", $digit);
                my $compiled_tube_loc = $temp_letter . $temp_digit;
                my $db_trans = $self->model->schema->resultset('CrisprStorage')->create(
                    {
                        box_name => $box_name,
                        tube_location => $compiled_tube_loc,
                        created_by_user => $created_by
                    });
            }
        }
    }

    return;
}

=head2 discard_box

Discard a Crispr storage box.

=cut
sub discard_box {

    my ($self, $name) = @_;

    my @box_with_name = $self->model->schema->resultset('CrisprStorage')->search(
        { box_name => $name })->all;

    if (scalar @box_with_name > 0) {
        my $db_trans = $self->model->schema->resultset('CrisprStorage')->search(
            {box_name => $name})->delete();
        return;
    }

    return 1;
}

=head2 store_crispr

Store Crispr Id in box location.

=cut
sub store_crispr {
    my ($self, $stored_by, $box_name, $tube_locations, $crispr_ids) = @_;

    my @tube_locations = @{$tube_locations};
    my @crispr_ids = @{$crispr_ids};

    return 'No Crispr IDs were specified.' if scalar @crispr_ids == 0;

    ## validate that the locations specified by the user exist and are available
    for my $location (@tube_locations) {
        my $err;
        try {
            my @db_query = $self->model->schema->resultset('CrisprStorage')->search(
                {
                    box_name      => { '=', $box_name },
                    tube_location => $location,
                    crispr_id     => undef
                })->all;

            ## will cause an error if this empty location doesn't exist
            die if scalar @db_query == 0;
        } catch {
            $err = 1;
        };
        return "There was a problem with location: $location" if $err;
    }

    ## the number of the given tube locations should be less than or equal to the number of given Crispr IDs
    return 'The number of tube locations specified is larger than the number of Crispr IDs.' if (scalar @tube_locations > scalar @crispr_ids);

    ## storing the crispr/location pairs
    if (scalar @tube_locations) {
        my $counter = 0;
        foreach my $indx (0..$#tube_locations) {
            if ($self->validate_crispr_id($crispr_ids[$indx])) {
                my $err;
                try {
                    $self->model->schema->resultset('CrisprStorage')->find(
                        {
                            box_name => $box_name,
                            tube_location => $tube_locations[$indx]
                        })->update(
                        {
                            crispr_id => $crispr_ids[$indx],
                            stored_by_user => $stored_by,
                        });
                } catch {
                    $err = 1;
                };
                return 'Unable to store Crispr ID ' . $crispr_ids[$indx] if $err;
            } else {
                return 'Found invalid Crispr ID ' . $crispr_ids[$indx] . '. Will terminate the storage process at this ID.';
            }
            $counter++;
        }

        ## dealing with remaining Crispr IDs
        if (scalar @crispr_ids[$counter..$#crispr_ids]) {
            my @remaining_crisprs = @crispr_ids[$counter..$#crispr_ids];
            return $self->storage_overflow($stored_by, $box_name, \@remaining_crisprs);
        }
    } else {
        ## in case no tube locations have been specified by the user
        return $self->storage_overflow($stored_by, $box_name, \@crispr_ids);
    }

    return;
}

=head2 storage_overflow

Store crisprs when they exceed number of available locations.

=cut
sub storage_overflow {
    my ($self, $stored_by, $box_name, $crispr_ids) = @_;

    my @crispr_ids = @{$crispr_ids};
    my $crispr_remain = join ",", @crispr_ids;

    ## get available locations in box
    my @box_availables = $self->model->schema->resultset('CrisprStorage')->search(
        {
            box_name => $box_name,
            crispr_id => undef
        },
        {
            order_by => { -asc  => 'tube_location' }
        })->all;

    ## in case there are no available locations in the current box
    return "Remaining unstored crispr Ids: $crispr_remain . Navigate to a new box!" if scalar @box_availables == 0;

    my $available_locs = scalar @box_availables;

    if ($available_locs and scalar @crispr_ids > $available_locs) {
        ## case 1 - box does not have enough free locations

        ## store in currently available box locations
        foreach (0.. $#box_availables) {
            my $temp_box_obj = $box_availables[$_];
            my $row = $self->model->schema->resultset('CrisprStorage')->search(
                {
                    box_name => $box_name,
                    crispr_id => undef,
                    tube_location => $temp_box_obj->get_column('tube_location')
                })->single;

            if ($row and $self->validate_crispr_id($crispr_ids[$_])) {
                my $err;
                try {
                    $row->update(
                        {
                            crispr_id => $crispr_ids[$_],
                            stored_by_user => $stored_by,
                        });
                } catch {
                    $err = 1;
                };
                return 'Unable to store Crispr ID ' . $crispr_ids[$_] if $err;
            } else {
                return 'Found invalid Crispr ID ' . $crispr_ids[$_] . '. Will terminate the storage process at this ID.';
            }
        }

        $crispr_remain = join ",", @crispr_ids[$available_locs .. scalar @crispr_ids];
        return "Remaining unstored crispr Ids: $crispr_remain . Navigate to a new box!";

    } else {
        ## case 2 - box has enough empty locations

        foreach my $indx (0..$#crispr_ids) {
            my $row = $self->model->schema->resultset('CrisprStorage')->search(
                {
                    box_name => $box_name,
                    crispr_id => undef
                },
                {
                    order_by => 'tube_location',
                    rows => 1
                })->single;

            if ($self->validate_crispr_id($crispr_ids[$indx])) {
                my $err;
                try {
                    $row->update({
                        crispr_id => $crispr_ids[$indx],
                        stored_by_user => $stored_by,
                    });
                } catch {
                    $err = 1;
                };
                return 'Unable to store Crispr ID ' . $crispr_ids[$indx] if $err;
            } else {
                return 'Found invalid Crispr ID ' . $crispr_ids[$indx] . '. Will terminate the storage process at this ID.';
            }
        }
    }
    return;
}

=head2 reset_tube_location

Reset tube location in box.

=cut
sub reset_tube_location {
    my ($self, $box_name, $tube_location) = @_;

    my @tube_locations = @{$tube_location};
    try {
        foreach my $loc (@tube_locations) {
            $self->model->schema->resultset('CrisprStorage')->find(
                {
                    box_name => $box_name,
                    tube_location => $loc
                })->update(
                {
                    crispr_id => undef,
                    stored_by_user => undef
                });
        }
        return 1;
    };

    return;
}

=head2 get_box_metadata

Get metadata for a box.

=cut
sub get_box_metadata {
    my ($self, $box_name) = @_;

    my @data;
    try {
        my @db_query = $self->model->schema->resultset('CrisprStorage')->search(
            {
                box_name => { '=', $box_name }
            })->all;

        foreach my $rec (@db_query) {
            if ($rec->crispr_id) {
                my %data = $rec->get_columns;
                push @data, \%data;
            }
        }
    };

    return \@data;
}

=head2 validate_crispr_id

Validate that crispr Id exists.

=cut
sub validate_crispr_id {
    my ($self, $crispr_id) = @_;

    my @crispr_records;
    try {
        @crispr_records = $self->model->schema->resultset('Crispr')->search(
            {
                id => { '=', $crispr_id }
            })->all;
    };

    if (scalar @crispr_records) {
        return 1;
    }
    return;
}

1;

