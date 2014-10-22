package LIMS2::Model::Schema::ResultSet::PlateChildWells;
use strict;
use warnings;

use List::MoreUtils qw( uniq none );
use List::Util qw( first );
use Try::Tiny;

use base 'DBIx::Class::ResultSet';

sub child_well_hash {
    my ( $self ) = @_;

    my %child_well_hash;
    while ( my $r = $self->next ) {
        push @{ $child_well_hash{ $r->parent_well_id } },
            $r->child_plate_name . '[' . $r->child_well_name . ']';
    }

    return \%child_well_hash;
}

sub child_well_by_type {
    my ( $self ) = @_;

    my %child_wells;
    while ( my $r = $self->next ) {
        $child_wells{ $r->parent_well_id }{ $r->child_plate_type }{count}++;
        if ( $r->child_well_accepted || $r->child_well_accepted_override ) {
            $child_wells{ $r->parent_well_id }{ $r->child_plate_type }{accepted}++;
        }
    }

    return \%child_wells;
}


1;
