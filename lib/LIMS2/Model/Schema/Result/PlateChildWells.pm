package LIMS2::Model::Schema::Result::PlateChildWells;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::PlateChildWells::VERSION = '0.407';
}
## use critic


=head1 NAME

LIMS2::Model::Schema::Result::PlateChildWells

=head1 DESCRIPTION

Custom resultset that grabs all the child wells from a given plate.
Also grabs the child well accepted data.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'plate_child_wells' );

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
SELECT
    pw.id as parent_well_id,
    p.name as parent_plate_name,
    pw.name as parent_well_name,
    cw.id as child_well_id,
    cp.name as child_plate_name,
    cp.type_id as child_plate_type,
    cw.name as child_well_name,
    cw.accepted as child_well_accepted,
    wao.accepted as child_well_accepted_override
FROM plates p
INNER JOIN wells pw ON pw.plate_id = p.id
INNER JOIN process_input_well piw ON piw.well_id = pw.id
INNER JOIN process_output_well pow ON pow.process_id = piw.process_id
INNER JOIN wells cw ON cw.id = pow.well_id
LEFT JOIN well_accepted_override wao ON wao.well_id = cw.id
INNER JOIN plates cp on cp.id = cw.plate_id
WHERE
    p.id = ?
EOT

__PACKAGE__->add_columns(
    qw(  parent_well_id
         parent_plate_name
         parent_well_name
         child_well_id
         child_plate_name
         child_plate_type
         child_well_name
         child_well_accepted
         child_well_accepted_override
    )
);

__PACKAGE__->set_primary_key( "parent_well_id" );

__PACKAGE__->belongs_to(
    "parent_well",
    "LIMS2::Model::Schema::Result::Well",
    { id => "parent_well_id" },
);

__PACKAGE__->belongs_to(
    "child_well",
    "LIMS2::Model::Schema::Result::Well",
    { id => "child_well_id" },
);

sub as_hash {
    my $self = shift;

    return { map { $_ => $self->$_ } $self->columns };
}

__PACKAGE__->meta->make_immutable;

1;


