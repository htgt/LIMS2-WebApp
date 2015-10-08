package LIMS2::Model::Plugin::WellBarcode;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::WellBarcode::VERSION = '0.341';
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

    return $self->retrieve(
    	WellBarcode => { slice_def $validated_params, qw( well_id barcode ) },
    	$search_opts,
    );
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

sub create_well_barcode {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params($params, $self->pspec_create_well_barcode);

    my $well = $self->retrieve_well({ id => $validated_params->{well_id }});

    my $create_params = {
        barcode => $validated_params->{barcode},
        barcode_state => $validated_params->{state},
    };

    # Store PIQ well id on barcode so we do not have to traverse lengthy well heirarchy
    # to get back to root PIQ well when generating plate reports, etc
    if ($well->plate->type->id eq 'PIQ'){
        # parent well is probably the QC piq made by freeze_back so use this as root
        # but if the parent is not a piq then set current well as the root piq
        my ($parent) = $well->parent_wells;
        if($parent and $parent->plate->type->id eq 'PIQ'){
            $create_params->{root_piq_well_id} = $parent->id;
        }
        else{
            $create_params->{root_piq_well_id} = $well->id;
        }
    }

    my $well_barcode = $well->create_related( well_barcode => $create_params);

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

    return $well_barcode;
}

sub pspec_update_well_barcode {
    return {
        barcode      => { validate => 'well_barcode'},
        new_well_id  => { validate => 'integer', optional => 1 },
        new_state    => { validate => 'alphanumeric_string', optional => 1 },
        comment      => { validate => 'non_empty_string', optional => 1 },
        user         => { validate => 'existing_user' },
        REQUIRE_SOME => { new_well_id_or_state => [1, qw(new_well_id new_state)]},
    };
}

sub update_well_barcode {

    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_update_well_barcode );

    my $barcode = $self->retrieve_well_barcode({ barcode => $validated_params->{barcode}})
        or $self->throw( NotFound => { entity_class => 'WellBarcode', search_params => $params } );

    my $old_state = $barcode->barcode_state->id;
    my $old_well_id = $barcode->well_id;

    if(defined $validated_params->{new_well_id}){
        $barcode->update({ well_id => $validated_params->{new_well_id} });
    }

    if(defined $validated_params->{new_state}){
        $barcode->update({ barcode_state => $validated_params->{new_state} });
    }

    $self->create_well_barcode_event({
        barcode     => $validated_params->{barcode},
        old_state   => $old_state,
        new_state   => $barcode->barcode_state->id,
        old_well_id => $old_well_id,
        new_well_id => $barcode->well_id,
        user        => $validated_params->{user},
        comment     => $validated_params->{comment},
    });

    return $barcode;
}

sub pspec_create_well_barcode_event {
    return {
        barcode      => { validate => 'well_barcode'},
        old_state    => { validate => 'alphanumeric_string', optional => 1 },
        new_state    => { validate => 'alphanumeric_string', optional => 1 },
        old_well_id  => { validate => 'integer', optional => 1 },
        new_well_id  => { validate => 'integer', optional => 1 },
        comment      => { validate => 'non_empty_string', optional => 1 },
        user         => { validate => 'existing_user', rename => 'created_by', post_filter => 'user_id_for' },
    };
}

sub create_well_barcode_event {
    my ($self, $params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_well_barcode_event );

    my $event = $self->schema->resultset('BarcodeEvent')->create({
        slice_def(
            $validated_params,
            qw( barcode old_state new_state old_well_id new_well_id comment created_by )
        )
    });

    return $event;
}

sub historical_barcodes_for_plate{
    my ($self, $params) = @_;

    # find current plate
    my $plate = $self->retrieve_plate($params);
    my @current_barcodes = map { $_->well_barcode->barcode } grep {$_->well_barcode} $plate->wells;
    $self->log->debug(scalar(@current_barcodes)." barcodes found");

    # find old versions of plates
    my @previous_versions = $self->schema->resultset('Plate')->search({
        name    => $plate->name,
        version => { '!=', undef },
    });
    $self->log->debug(scalar(@previous_versions)." previous plate versions found");

    # find all wells on all versions
    my @wells = map { $_->wells } @previous_versions;
    $self->log->debug(scalar(@wells)." wells found");

    # find all barcodes ever linked to these wells in barcode_events
    my @events = map { $_->barcode_events_old_wells, $_->barcode_events_new_wells } @wells;
    $self->log->debug(scalar(@events)." events found");

    # return all barcodes which are not on current plate version
    my @all_barcodes = uniq map { $_->barcode->barcode } @events;
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
