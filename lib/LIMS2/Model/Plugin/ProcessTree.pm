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

my $QUERY_ANCESTORS_BY_PLATE_NAME = << 'QUERY_END';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
-- Non-recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id] 
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     WHERE pr_out.well_id IN (
	SELECT starting_well FROM well_list
     )	
     UNION ALL
-- Recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
),
well_list(starting_well) AS (
	SELECT platewells.id FROM wells platewells, plates
	WHERE plates.name =? 
	AND platewells.plate_id = plates.id
)
SELECT w.process_id, w.input_well_id, w.output_well_id, pd.design_id, w.path[1] "original_well", w.path
FROM well_hierarchy w, process_design pd
WHERE w.process_id = pd.process_id
--ORDER BY pd.design_id;
GROUP BY w.process_id, w.input_well_id, w.output_well_id, pd.design_id,"original_well", w.path;
QUERY_END

my $QUERY_ANCESTORS_BY_WELL_ID = << 'QUERY_END';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
-- Non-recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id] 
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
        WHERE pr_out.well_id = ?
     UNION ALL
-- Recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
)
SELECT w.process_id, w.input_well_id, w.output_well_id, pd.design_id, w.path[1] "original_well", w.path
FROM well_hierarchy w, process_design pd
WHERE w.process_id = pd.process_id
--ORDER BY pd.design_id;
GROUP BY w.process_id, w.input_well_id, w.output_well_id, pd.design_id,"original_well", w.path;
QUERY_END

sub pspec_paths_for_well_id_depth_first {
    return {
        well_id           => { validate   => 'integer', },
        direction         => { validate   => 'boolean', optional => 1 },
    };
}

sub get_paths_for_well_id_depth_first {
    my $self = shift;
    my ($params) = @_; 

    my $validated_params;

    $validated_params = $self->check_params( $params, $self->pspec_paths_for_well_id_depth_first  );

    my $sql_query = $validated_params->{'direction'} ? $QUERY_DESCENDANTS_BY_WELL_ID : $QUERY_ANCESTORS_BY_WELL_ID;

    my $sql_result =  $self->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( $sql_query );
         $sth->execute( $validated_params->{'well_id'} );
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

sub pspec_designs_for_plate {
    return {
        plate_name  =>{ validate => 'string', },
        direction => { validate => 'boolean', optional=> 1 },
    };
}

sub get_designs_for_plate {

}
1;
