#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use LIMS2::Model::DBConnect;

use_ok 'LIMS2::Model';

ok my $schema = LIMS2::Model::DBConnect->connect( 'LIMS2_PROCESS_TEST', 'tests' ),
    'connect to LIMS2_TEST';

ok my $model = LIMS2::Model->new( schema => $schema ), 'instantiate model';

$model->txn_do(
    sub {
        can_ok $model, 'create_qc_sequencing_project';

        ok my $qc_sequencing_project = $model->create_qc_sequencing_project( {
                name => 'PG00259_Z'
            }
        ), 'create_qc_sequencing_project should succeed';

        is $qc_sequencing_project->name, 'PG00259_Z', '.. has correct name';

        $model->txn_rollback;
    }
);

done_testing;
