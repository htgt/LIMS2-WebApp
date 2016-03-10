package LIMS2::Model::Schema::Result::PlateProcess;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::PlateProcess::VERSION = '0.382';
}
## use critic


=head1 NAME

LIMS2::Model::Schema::Result::PlateProcess;

=head1 DESCRIPTION

Custom resultset to retrieve the processes linked to a plate

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'plate_process' );

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
WITH RECURSIVE process_hierarchy(id, type_id, dna_template) AS (
    SELECT id, type_id, dna_template FROM processes WHERE id IN (
        SELECT DISTINCT COALESCE( process_input_well.process_id, process_output_well.process_id )
        FROM process_input_well
        FULL OUTER JOIN process_output_well
        ON process_input_well.process_id=process_output_well.process_id
        WHERE process_input_well.well_id IN (
            SELECT id FROM wells WHERE plate_id = ?
        )
        OR process_output_well.well_id IN (
            SELECT id FROM wells WHERE plate_id = ?
        )
    )
)
SELECT p.*
FROM process_hierarchy p
ORDER BY id
EOT

__PACKAGE__->add_columns(
    qw( id
        type_id
        dna_template
    )
);

__PACKAGE__->set_primary_key( "id" );

__PACKAGE__->belongs_to(
    "plate",
    "LIMS2::Model::Schema::Result::Plate",
    { id => "id" },
);

sub as_hash {
    my $self = shift;
    return { map { $_ => $self->$_ } $self->columns };
}

__PACKAGE__->meta->make_immutable;

1;
