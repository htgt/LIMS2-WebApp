package LIMS2::Model::Plugin::ProcessTree;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::ProcessTree::VERSION = '0.430';
}
## use critic


use Moose::Role;
use LIMS2::Model;
use feature qw/ say /;
use strict;
use warnings;
use Log::Log4perl qw( :easy );

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

sub query_descendants_by_plate_type {
    return << 'QUERY_END';
-- Descendants by plate_type
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id IN (
        SELECT starting_well FROM well_list
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
}

sub query_descendants_by_well_id {
    return << 'QUERY_END';
-- Descendants by well_id
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    -- Non-recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id = ?
    UNION ALL
-- Recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT distinct w.path
FROM well_hierarchy w
--WHERE w.output_well_id NOT IN (SELECT well_id FROM process_input_well) ;
LEFT OUTER JOIN process_input_well piw ON piw.well_id = w.output_well_id
WHERE piw.well_id IS NULL
QUERY_END
}

sub query_ancestors_by_plate_name {
    return << 'QUERY_END';
-- Ancestors by plate_name
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
}

sub query_ancestors_by_well_id_with_paths {
    return << 'QUERY_END';
-- Ancestors by well_id with paths
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
}

sub query_ancestors_by_well_id {
    return << 'QUERY_END';
-- Ancestors by well_id
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
SELECT distinct w.path
FROM well_hierarchy w, process_design pd
WHERE w.process_id = pd.process_id
QUERY_END
}

sub query_ancestors_by_well_id_list {
    my $self = shift;
    my $well_array_ref = shift;

    my $well_list = join q{,}, @{$well_array_ref};

    return << "QUERY_END";
-- Ancestors by well_id
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
-- Non-recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
        WHERE pr_out.well_id IN (
        $well_list
     )
     UNION ALL
-- Recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
)
SELECT distinct w.path
FROM well_hierarchy w, process_design pd
WHERE w.process_id = pd.process_id
QUERY_END
}

sub pspec_paths_for_well_id_depth_first {
    return {
        well_id           => { validate   => 'integer', },
        direction         => { validate   => 'boolean', optional => 1 },
    };
}

=heading1 get_paths_for_well_id_depth_first

returns paths as well_ids
=cut

sub get_paths_for_well_id_depth_first {
    my $self = shift;
    my ($params) = @_;

    my $validated_params;
    $validated_params = $self->check_params( $params, $self->pspec_paths_for_well_id_depth_first  );

    my $sql_query = $validated_params->{'direction'} ? $self->query_descendants_by_well_id : $self->query_ancestors_by_well_id;

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


sub pspec_get_wells_for_design_well_id {
    return {
        well_id           => { validate   => 'integer', },
    };
}

sub get_wells_for_design_well_id {
    my $self = shift;
    my ($params) = @_;
    my $validated_params;
    $validated_params = $self->check_params( $params, $self->pspec_get_wells_for_design_well_id );

    my $paths = $self->get_paths_for_well_id_depth_first(
        {
            'well_id' => $validated_params->{'well_id'},
            'direction' => 1
        }
    );

    my %uniq_wells;
    foreach my $path ( @{$paths} ) {
        foreach my $well_id ( @{$path} ) {
            $uniq_wells{$well_id} += 1;
        }
    }
    my @well_ids = keys %uniq_wells;
    my $rs = $self->schema->resultset( 'Well' )->search(
        {
            'me.id' => { '-in' => \@well_ids }
        },
        {
            prefetch => [ 'plate' ]
        }
    );

    return $rs;
}


sub pspec_design_wells_for_well_id {
    return {
        well_id           => { validate   => 'integer', },
    };
}

=heading1 get_design_wells_for_well_id

=cut

sub get_design_wells_for_well_id {
    my $self = shift;
    my ($params) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_design_wells_for_well_id);

    my $sql_query = $self->query_ancestors_by_well_id;
    my $sql_result =  $self->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( $sql_query );
         $sth->execute( $validated_params->{'well_id'} );
         $sth->fetchall_arrayref();
        }
    );

    my $result_hash;

    foreach my $result ( @{$sql_result} ) {
        $result_hash->{$result->[2]} = {
            'design_well_id' => $result->[0],
            'design_id'      => $result->[1],
        }
    }

    return $result_hash;
}


sub pspec_design_wells_for_well_id_list {
    return {
         'wells'  ,
    };
}


sub query_ancestors_by_well_list {
    my $self = shift;
    my $well_array_ref = shift;

    my $well_list = join q{,}, @{$well_array_ref};

    return << "QUERY_END";
-- Ancestors by well list
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
-- Non-recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     WHERE pr_out.well_id IN (
        $well_list
     )
     UNION ALL
-- Recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
)
SELECT w.output_well_id, pd.design_id, w.path[1] "original_well", gd.gene_id
FROM well_hierarchy w, process_design pd, gene_design gd
WHERE w.process_id = pd.process_id
AND pd.design_id = gd.design_id
GROUP BY w.output_well_id, pd.design_id,"original_well", gd.gene_id;
QUERY_END
}

# TODO will not work with short arm designs
sub get_design_data_for_well_id_list {
    my $self = shift;
    my $wells = shift;


    my $sql_query = $self->query_ancestors_by_well_list( $wells );
    my $sql_result = $self->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( $sql_query );
         $sth->execute();
         $sth->fetchall_arrayref();
        }
    );

    my $result_hash;
    foreach my $result ( @{$sql_result} ) {
        $result_hash->{$result->[2]} = {
            'design_well_id' => $result->[0],
            'design_id'      => $result->[1],
            'gene_id'        => $result->[3],
        }
    }
    # The format of the resulting hash is:
    # well_id => {
    # design_well_id => integer_id,
    # design_id => integer_id,
    # gene_id => accession_id
    # }
    return $result_hash;
}

sub query_short_arm_ancestors_by_well_list {
    my $self = shift;
    my $well_array_ref = shift;

    my $well_list = join q{,}, @{$well_array_ref};

    return << "QUERY_END";
-- Ancestors by well list
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
-- Non-recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     WHERE pr_out.well_id IN (
        $well_list
     )
     UNION ALL
-- Recursive term
     SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
)
SELECT w.output_well_id, pd.design_id, w.path[1] "original_well", gd.gene_id
FROM well_hierarchy w, process_global_arm_shortening_design pd, gene_design gd
WHERE w.process_id = pd.process_id
AND pd.design_id = gd.design_id
GROUP BY w.output_well_id, pd.design_id,"original_well", gd.gene_id;
QUERY_END
}

# This will only bring back short arm designs
sub get_short_arm_design_data_for_well_id_list {
    my $self = shift;
    my $wells = shift;


    my $sql_query = $self->query_short_arm_ancestors_by_well_list( $wells );
    my $sql_result = $self->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( $sql_query );
         $sth->execute();
         $sth->fetchall_arrayref();
        }
    );

    my $result_hash;

    foreach my $result ( @{$sql_result} ) {
        $result_hash->{$result->[2]} = {
            'design_well_id' => $result->[0],
            'design_id'      => $result->[1],
            'gene_id'        => $result->[3],
        }
    }
    # The format of the resulting hash is:
    # well_id => {
    # design_well_id => integer_id,
    # design_id => integer_id,
    # gene_id => accession_id
    # }
    return $result_hash;
}

sub get_ancestors_for_well_id_list {
    my $self = shift;
    my $wells = shift;

    my $sql_query = $self->query_ancestors_by_well_id_list( $wells );
    my $sql_result =  $self->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( $sql_query );
         $sth->execute();
         $sth->fetchall_arrayref();
        }
    );
    return $sql_result;
}
sub query_descendants_by_well_id_list {
    my $self = shift;
    my $well_array_ref = shift;

    my $well_list = join q{,}, @{$well_array_ref};

    return << "QUERY_END";
-- Descendants by well_id
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    -- Non-recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id in ( $well_list )
    UNION ALL
-- Recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT distinct w.path
FROM well_hierarchy w
--WHERE w.output_well_id NOT IN (SELECT well_id FROM process_input_well) ;
LEFT OUTER JOIN process_input_well piw ON piw.well_id = w.output_well_id
WHERE piw.well_id IS NULL
QUERY_END
}

sub get_descendants_for_well_id_list {
    my $self = shift;
    my $wells = shift;

    my $sql_query = $self->query_descendants_by_well_id_list( $wells );
    my $sql_result =  $self->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( $sql_query );
         $sth->execute();
         $sth->fetchall_arrayref();
        }
    );
    return $sql_result;
}

sub fast_get_well_ancestors{
    my ($self, @well_id_list) = @_;



    my $query = << "QUERY_END";
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
     SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
QUERY_END

    if(@well_id_list){
        my $well_list = join q{,}, @well_id_list;
        $query.=" WHERE pr_out.well_id in ($well_list) ";
    }
    else{
        DEBUG "No well ID list passed to fast_get_well_ancestors - getting ancestors for ALL wells";
    }

    $query.= << "QUERY_END";

     UNION
     SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
)
SELECT process_id, input_well_id, output_well_id,path[1] "well_id"
FROM well_hierarchy;
QUERY_END

    DEBUG "Running batch well ancestor query for ".(scalar @well_id_list || "all")." wells";
    my $sql_result =  $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare_cached( $query );
            $sth->execute();
            $sth->fetchall_arrayref();
        }
    );
    DEBUG "ancestor query done";

    my $edges_for_well = {};
    foreach my $edge (@{ $sql_result }){
        my $well_id = $edge->[3];
        $edges_for_well->{$well_id} ||= [];
        push @{ $edges_for_well->{$well_id} }, [ @{ $edge }[0,1,2] ];
    }
    return $edges_for_well;
}

sub fast_get_well_descendant_paths{
    my ($self, $well_id_list) = @_;

    DEBUG "Running batch descendant path query for ".(scalar @$well_id_list )." wells";
    my $sql_result = $self->get_descendants_for_well_id_list($well_id_list);
    DEBUG "descendant path query done";

    # The paths come back as arrays so we need to unpack and store by start well id
    DEBUG "Storing paths by start well ID";
    my $paths_for_well_id = {};
    foreach my $path_array ( @{$sql_result} ) {
        foreach my $path ( @{$path_array} ) {
            my $start_well_id = $path->[0];
            $paths_for_well_id->{$start_well_id} ||= [];
            push @{ $paths_for_well_id->{$start_well_id} }, $path;
        }
    }
    DEBUG "path storing done";

    return $paths_for_well_id;
}

sub create_well_descendant_paths_temp_table{
    my ($self, $well_id_list) = @_;

    my $well_list = join q{,}, @{$well_id_list};
    my $table_name = "descendant_paths_temp";
    my $query = << "QUERY_END";
DROP TABLE IF EXISTS $table_name;
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
    -- Non-recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id in ( $well_list )
    UNION ALL
-- Recursive term
    SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT distinct w.path[1] "well_id", w.path
INTO $table_name
FROM well_hierarchy w
--WHERE w.output_well_id NOT IN (SELECT well_id FROM process_input_well) ;
LEFT OUTER JOIN process_input_well piw ON piw.well_id = w.output_well_id
WHERE piw.well_id IS NULL
QUERY_END

    DEBUG "Running batch descendant path query to temp table for ".(scalar @$well_id_list )." wells";
    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare_cached( $query );
            $sth->execute();
        }
    );
    DEBUG "temporary descendant path table created";

    return $table_name;
}

sub create_well_ancestors_temp_table{
    my ($self) = @_;

    my $table_name = "well_ancestors_temp";

    my $query = << "QUERY_END";
DROP TABLE IF EXISTS $table_name;
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, path) AS (
     SELECT pr.id, pr_in.well_id, pr_out.well_id, ARRAY[pr_out.well_id]
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     UNION
     SELECT pr.id, pr_in.well_id, pr_out.well_id, path || pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
)
SELECT process_id, input_well_id, output_well_id,path[1] "well_id"
INTO $table_name
FROM well_hierarchy;
QUERY_END

    DEBUG "Running batch ancestor query to temp table for all wells";
    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare_cached( $query );
            $sth->execute();
        }
    );
    DEBUG "temporary ancestor table created";

    return $table_name;
}
1;
