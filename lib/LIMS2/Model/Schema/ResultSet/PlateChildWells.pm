package LIMS2::Model::Schema::ResultSet::PlateChildWells;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::ResultSet::PlateChildWells::VERSION = '0.434';
}
## use critic

use strict;
use warnings;

use List::MoreUtils qw( uniq none );
use List::Util qw( first );
use Try::Tiny;

use base 'DBIx::Class::ResultSet';

=head2 child_well_hash

Merge result rows into a hash keyed on well id, values are array refs
of full child well names

=cut
sub child_well_hash {
    my ( $self ) = @_;

    my %child_well_hash;
    while ( my $r = $self->next ) {
        push @{ $child_well_hash{ $r->parent_well_id } },
            $r->child_plate_name . '[' . $r->child_well_name . ']';
    }

    return \%child_well_hash;
}

=head2 child_well_by_type

Merge result rows into a hash keyed on well id, and then on child well plate type.
Values counts of wells of that type, and counts of accepted wells on that type.
For accepted first look to see if well accepted override value exists, if it does use that,
otherwise use the well accepted value.

=cut
sub child_well_by_type {
    my ( $self ) = @_;

    my %child_wells;
    while ( my $r = $self->next ) {
        $child_wells{ $r->parent_well_id }{ $r->child_plate_type }{count}++;
        if ( defined $r->child_well_accepted_override ) {
            if ( $r->child_well_accepted_override ) {
                $child_wells{ $r->parent_well_id }{ $r->child_plate_type }{accepted}++;
            }
        }
        else {
            if ( $r->child_well_accepted ) {
                $child_wells{ $r->parent_well_id }{ $r->child_plate_type }{accepted}++;
            }
        }
    }

    return \%child_wells;
}


1;
