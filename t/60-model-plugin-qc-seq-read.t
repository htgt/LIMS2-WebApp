#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use LIMS2::Model::DBConnect;
use YAML::Any;

use_ok 'LIMS2::Model';

ok my $schema = LIMS2::Model::DBConnect->connect( 'LIMS2_PROCESS_TEST', 'tests' ),
    'connect to LIMS2_TEST';

ok my $model = LIMS2::Model->new( schema => $schema ), 'instantiate model';

my $params = Load( do { local $/ = undef; <DATA> } );

$model->txn_do(
    sub {
        can_ok $model, 'create_qc_seq_read';

        ok my $qc_sequencing_project = $model->create_qc_sequencing_project( {
                name => 'PG00259_Z'
            }
        ), 'create_qc_sequencing_project should succeed';

        ok my $qc_seq_read = $model->create_qc_seq_read( $params )
            ,'create_qc_seq_read should succeed';

        is $qc_seq_read->id, 'PSA002_A_2d10.p1kaR3', '.. has right id';
        is $qc_seq_read->qc_sequencing_project
            ,$qc_sequencing_project->name
                ,'.. belongs to correct qc sequencing project';

        can_ok $model, 'retrieve_qc_seq_read';

        ok my $retrieved_qc_seq_read = $model->retrieve_qc_seq_read(
            { id => 'PSA002_A_2d10.p1kaR3' }
        ), 'retrieve qc seq read should succeed';

        is $retrieved_qc_seq_read->id, 'PSA002_A_2d10.p1kaR3'
            ,'.. has right id';

        $model->txn_rollback;
    }
);

done_testing;

__DATA__
---
id: PSA002_A_2d10.p1kaR3
qc_sequencing_project: PG00259_Z
description: bases 28 to 738 (QL to QR)
seq: CTATGAAAAAATTTTTTTCCCCCCCCGGGGGGGCGTAAGTCC
length: 42
