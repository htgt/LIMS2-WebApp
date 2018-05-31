package LIMS2::Model::Plugin::WellBarcode;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::WellBarcode::VERSION = '0.504';
}
## use critic


use strict;
use warnings FATAL => 'all';
use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use Hash::Merge qw( merge );
use List::MoreUtils qw (any uniq);
use namespace::autoclean;
use Try::Tiny;

requires qw( schema check_params throw retrieve log trace );

sub pspec_retrieve_well_barcode {
    return {
        well_id           => { validate => 'integer', optional => 1 },
        barcode           => { validate => 'well_barcode', optional => 1 },
        REQUIRE_SOME      => { id_or_barcode => [ 1, qw( well_id barcode ) ] }
    };
}

sub retrieve_well_barcode {
    my ( $self, $params, $search_opts ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_well_barcode, ignore_unknown => 1 );

    return $self->retrieve_well($validated_params);
}

sub delete_well_barcode {
# only allowed if barcode has no events
}

sub pspec_create_well_barcode {
    return {
        well_id => { validate => 'integer' },
        barcode => { validate => 'well_barcode' },
        state   => { validate => 'alphanumeric_string' },
        comment => { validate => 'non_empty_string', optional => 1 },
        user    => { validate => 'existing_user', optional => 1 },
        DEPENDENCY_GROUPS => { comment_group => [qw( comment user )] },
    };
}

# The well_barcodes table has now been dropped and barcode and state added to wells
# This method has been kept for legacy reasons but it now just updates the well
# with barcode details and creates a barcode event
sub create_well_barcode {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params($params, $self->pspec_create_well_barcode);

    my $well = $self->retrieve_well({ id => $validated_params->{well_id }});

    my $create_params = {
        barcode => $validated_params->{barcode},
        barcode_state => $validated_params->{state},
    };

    my $well_barcode = $well->update($create_params);

    # Optionally create event with comment about new well barcode
    if($validated_params->{user}){
        $self->create_well_barcode_event({
            barcode     => $well_barcode->barcode,
            new_state   => $well_barcode->barcode_state->id,
            new_well_id => $well_barcode->well_id,
            user        => $validated_params->{user},
            comment     => $validated_params->{comment},
        });
    }

    return $well;
}

sub pspec_update_well_barcode {
    return {
        barcode       => { validate => 'well_barcode'},
        new_well_name => { validate => 'well_name', optional => 1 },
        new_plate_id  => { validate => 'existing_plate_id', optional => 1 },
        new_state     => { validate => 'alphanumeric_string', optional => 1 },
        comment       => { validate => 'non_empty_string', optional => 1 },
        user          => { validate => 'existing_user' },
        displace_existing => { validate => 'boolean', optional => 1, default => 0},
        MISSING_OPTIONAL_VALID => 1,
    };
}

sub update_well_barcode {

    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_well_barcode );

    my $well = $self->retrieve_well_barcode({ barcode => $validated_params->{barcode}})
        or $self->throw( NotFound => { entity_class => 'Well', search_params => $params } );

    my $old_state = $well->barcode_state->id;
    my $old_well_name = $well->name;
    my $old_plate_id = $well->plate_id;

    if(exists $validated_params->{new_well_name}){
        my $existing;
        my $new_location = {
            name     => $validated_params->{new_well_name},
            plate_id => $validated_params->{new_plate_id},
        };
        if(defined $new_location->{name}){
            # Check if there is another well already at the destination
            $existing = $self->schema->resultset('Well')->find( $new_location );
        }

        if($existing and $existing->id != $well->id){
            if($validated_params->{displace_existing}){
                if($existing->barcode){
                    # Move the existing barcoded well out of the way before updating
                    # the barcode to the new location
                    # We'll need to do this if wells have been swapped around on a plate
                    $self->update_well_barcode({
                        barcode       => $existing->barcode,
                        new_plate_id  => undef,
                        new_well_name => undef,
                        new_state     => 'checked_out',
                        comment       =>'barcode checked out to make space for '.$validated_params->barcode,
                        user          => $validated_params->user,
                    });
                    $well->update($new_location);
                }
                else{
                    $self->throw( InvalidState => "Cannot move barcode ".$validated_params->{barcode}
                                                ." to $existing because there is already a well here with no barcode" );
                }
            }
            else{
                $self->throw( InvalidState => "Cannot move barcode ".$validated_params->{barcode}
                                              ." to $existing because there is already a well here" );
            }
        }
        else{
            # There is nothing at the new location so we can safely make the update
            $well->update($new_location);
        }
    }

    if(defined $validated_params->{new_state}){
        $well->update({ barcode_state => $validated_params->{new_state} });
    }

    $self->create_well_barcode_event({
        barcode     => $validated_params->{barcode},
        old_state   => $old_state,
        new_state   => $well->barcode_state->id,
        old_well_name => $old_well_name,
        new_well_name => $well->name,
        old_plate_id  => $old_plate_id,
        new_plate_id  => $well->plate_id,
        user          => $validated_params->{user},
        comment       => $validated_params->{comment},
    });

    return $well;
}

sub pspec_create_well_barcode_event {
    return {
        barcode      => { validate => 'well_barcode'},
        old_state    => { validate => 'alphanumeric_string', optional => 1 },
        new_state    => { validate => 'alphanumeric_string', optional => 1 },
        old_plate_id => { validate => 'existing_plate_id', optional => 1 },
        new_plate_id => { validate => 'existing_plate_id', optional => 1 },
        old_well_name => { validate => 'well_name', optional => 1 },
        new_well_name => { validate => 'well_name', optional => 1 },
        comment      => { validate => 'non_empty_string', optional => 1 },
        user         => { validate => 'existing_user', rename => 'created_by', post_filter => 'user_id_for' },
    };
}

sub create_well_barcode_event {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_barcode_event );

    my $event = $self->schema->resultset('BarcodeEvent')->create($validated_params);

    return $event;
}

sub historical_barcodes_for_plate{
    my ($self, $params) = @_;

    # find current plate
    my $plate = $self->retrieve_plate($params);
    my @current_barcodes = grep { $_ } map { $_->barcode } $plate->wells;
    $self->log->debug(scalar(@current_barcodes)." barcodes found");

    # FIXME: for now we need to look for events linked to old versions of the
    # plate but this can be removed when plate versions have been deleted
    # find old versions of plates
    my @previous_versions = $self->schema->resultset('Plate')->search({
        name    => $plate->name,
        version => { '!=', undef },
    });
    $self->log->debug(scalar(@previous_versions)." previous plate versions found");

    # find all barcodes ever linked to this plate in barcode_events
    my @events = map { $_->barcode_events_new_plates, $_->barcode_events_old_plates } ($plate, @previous_versions);

    $self->log->debug(scalar(@events)." events found");

    # return all barcodes which are not on current plate version
    my @all_barcodes = uniq map { $_->barcode->barcode } @events;
    $self->log->debug(scalar(@all_barcodes)." barcodes found");

    my @historical_barcodes;

    foreach my $barcode (@all_barcodes){
        unless (grep { $barcode eq $_ } @current_barcodes){
            push @historical_barcodes, $self->retrieve_well_barcode({ barcode => $barcode });
        }
    }

    $self->log->debug(scalar(@historical_barcodes)." historical barcodes found");
    return \@historical_barcodes;
}

1;
