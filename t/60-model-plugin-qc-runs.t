#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use LIMS2::Model::DBConnect;
use YAML::Any;

use_ok 'LIMS2::Model';

ok my $schema = LIMS2::Model::DBConnect->connect( $ENV{LIMS2_DB}, 'tests' ),
    'connect to LIMS2_TEST';

ok my $model = LIMS2::Model->new( schema => $schema ), 'instantiate model';

my $params = Load( do { local $/ = undef; <DATA> } );

$model->txn_do(
    sub {
        can_ok $model, 'create_qc_run';

        ok my $qc_sequencing_project = $model->create_qc_sequencing_project(
            { name => 'PG00259_Z' }
        ), 'create_qc_sequencing_project should succeed';

        ok my $qc_template = $model->create_qc_template(
            { name => 'VTP00001' }
        ), 'create_qc_template should succeed';

        ok my $qc_run = $model->create_qc_run( $params )
            ,'create_qc_run should succeed';

        is $qc_run->id, '47291142-5BA3-11E1-8E63-B870F3CB94C8', '.. has right id';
        ok my $qc_run_sequencing_projects = $qc_run->qc_run_sequencing_projects
            , '.. can grab qc run sequencing projects';
        is $qc_run_sequencing_projects->count, 1, '.. has links to one sequencing project';
        my $linked_qc_sequencing_project = $qc_run_sequencing_projects->next;
        is $linked_qc_sequencing_project->qc_sequencing_project
            ,$qc_sequencing_project->name
                ,'.. belongs to correct qc sequencing project';

        can_ok $model, 'retrieve_qc_run';

        ok my $retrieved_qc_run = $model->retrieve_qc_run(
            { id => '47291142-5BA3-11E1-8E63-B870F3CB94C8'}
        ), 'retrieve qc run should succeed';

        is $retrieved_qc_run->id, '47291142-5BA3-11E1-8E63-B870F3CB94C8'
            ,'.. has right id';

        $model->txn_rollback;
    }
);
#TODO: Tests passing in a qc_template_created_before time

done_testing;

__DATA__
---
id: 47291142-5BA3-11E1-8E63-B870F3CB94C8
date: 2011-02-12T12:50:50
profile: eucomm-post-cre
software_version: 1.1.2
qc_sequencing_projects: PG00259_Z
qc_template_name: VTP00001
