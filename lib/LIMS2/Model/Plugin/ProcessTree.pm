package LIMS2::Model::Plugin::ProcessTree;

use Moose::Role;
use LIMS2::Model;
use feature qw/ say /;
use strict;
use warnings;


=pod
=head1 ProcessTree 
This Plugin module for LIMS2 provides an interface to the process graph data
structure. In this implementation, which should be used in place of ProcessGraph,
we use the PostgreSQL database to traverse the tree of input/output wells ni the
process

Note that this is PostgreSQL specific because it uses the WITH RECURSIVE statement
and retains path information
DJP-S
=cut

my $QUERY_DESCENDANTS_BY_PLATE_TYPE = << 'QUERY_END';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id IN (
        SELECT starting_well FROM well_list;
    )
    UNION ALL
    SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
),
well_list(starting_well) AS (
	SELECT wells.id from wells, plates
	where wells.plate_id = plates.id
	and plates.type_id = ?
)
SELECT w.process_id, w.input_well_id, w.output_well_id, w.path[1] "original_well", w.path
FROM well_hierarchy w;
QUERY_END

my $QUERY_DESCENDANTS_BY_WELL_ID = << 'QUERY_END';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id = ?
    UNION ALL
    SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT distinct w.path
FROM well_hierarchy w, process_input_well
WHERE w.output_well_id NOT IN (SELECT well_id FROM process_input_well) ;
QUERY_END



sub get_paths_for_well_id_depth_first {
    my $self = shift;
    my $well_id = shift;

    my $sql_query = $QUERY_DESCENDANTS_BY_WELL_ID;

    my $sql_result =  $self->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( $sql_query );
         $sth->execute( $well_id );
         $sth->fetchall_arrayref();
        }
    );
# The paths come back as arrays so we need to unpack the arrayref a bit
#
    my @paths;

    foreach my $path_array ( @{$sql_result} ) {
        foreach my $p ( @{$path_array} ) {
            push @paths, $p;
        }
    }
    return \@paths;
}
1;
