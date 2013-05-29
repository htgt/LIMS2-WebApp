#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;

note('Testing the Creation crisprs');
my $create_crispr_data= test_data( 'create_crispr.yaml' );
my $crispr;
{

    ok $crispr = model->create_crispr( $create_crispr_data->{valid_crispr} )
        , 'can create new crispr';
    is $crispr->crispr_loci_type_id, 'Exonic', '.. crispr type is correct';
    is $crispr->seq, 'ATCGGCACACAGAGAG', '.. crispr seq is correct';

    ok my $locus = $crispr->loci->first, 'can retrieve crispr locus';
    is $locus->assembly_id, 'GRCm38', '.. locus assembly correct';
    is $locus->chr->name, 12, '.. locus chromosome correct';

    ok my $off_targets = $crispr->off_targets, 'can retreive off targets from crispr';
    is $off_targets->count, 2, '.. we have 2 off targets';
    ok my $off_target = $off_targets->find( { crispr_loci_type_id => 'Intronic' } ), 'can grab intron off target';
    is $off_target->assembly_id, 'GRCm38', '.. off target assembly correct';
    is $off_target->build_id, 70, '.. off target build correct';
    is $off_target->chr->name, 11, '.. off target chr correct';

    throws_ok {
        model->create_crispr( $create_crispr_data->{species_assembly_mismatch} )
    } qr/Assembly GRCm38 does not belong to species Human/
        , 'throws error when species and assembly do not match';

    # if we try to create duplicate crispr we just over-write the crisprs off targets
    ok my $duplicate_crispr = model->create_crispr( $create_crispr_data->{duplicate_crispr} )
        , 'can create dupliate crispr';
    is $duplicate_crispr->id, $crispr->id, 'we have the same crispr';
    ok my $new_off_targets = $duplicate_crispr->off_targets, 'can retrieve new off targets';
    is $new_off_targets->count, 1, '.. only 1 off target now';
    is $new_off_targets->first->chr->name, 15, '.. new off target has right chromosome';
}

note('Testing retrival of crispr');
{
    ok my $crispr = model->retrieve_crispr( { id => $crispr->id } ), 'retrieve newly created crispr';
    isa_ok $crispr, 'LIMS2::Model::Schema::Result::Crispr';
    ok my $h = $crispr->as_hash(), 'can call as_hash';
    isa_ok $h, ref {};
    ok $h->{off_targets}, '...has off targets';

    throws_ok {
        model->retrieve_crispr( { id => 123123123 } );
    }
    'LIMS2::Exception::NotFound', '..can not retreive deleted crispr';
}

note('Testing create crispr locus');
{
    my $crispr_locus_data = $create_crispr_data->{valid_crispr_locus};
    $crispr_locus_data->{crispr_id} = $crispr->id;

    ok my $crispr_locus = model->create_crispr_locus( $crispr_locus_data )
        , 'can create new crispr locus';

    is $crispr_locus->assembly_id, 'NCBIM37', '.. assembly is correct';
}

note('Testing create crispr off target');
{
    my $crispr_off_target_data = $create_crispr_data->{valid_crispr_off_target};
    $crispr_off_target_data->{crispr_id} = $crispr->id;

    ok my $crispr_off_target = model->create_crispr_off_target( $crispr_off_target_data )
        , 'can create new crispr off target';

    is $crispr_off_target->chr->name, 16, '.. crispr off target chromosome is correct';
}

note('Test finding crispr by sequence and locus');
my $find_crispr_data= test_data( 'find_crispr_by_seq.yaml' );
{
    my $valid_crispr_data = $find_crispr_data->{valid_find_crispr_by_seq};
    ok my $found_crispr = model->find_crispr_by_seq_and_locus( $valid_crispr_data )
        , 'can find crispr site by sequence and locus data';
    is $found_crispr->id, $crispr->id, '.. and we have found the same crispr';

    # throw error because missing locus info
    my $invalid_locus_crispr_data = $find_crispr_data->{non_existatant_locus};
    throws_ok {
        model->find_crispr_by_seq_and_locus( $invalid_locus_crispr_data )
    } qr/Can not find crispr locus information on assembly NCBIM36/
       , 'throws error because of missing locus information';

    # throw error because multiple identical crisprs
    my $duplicate_crispr_data = $create_crispr_data->{valid_crispr};
    $duplicate_crispr_data->{species_id} = 'Mouse';
    $duplicate_crispr_data->{crispr_loci_type_id} = 'Exonic';
    $duplicate_crispr_data->{off_target_outlier} = 0;
    ok $crispr = model->_create_crispr( $duplicate_crispr_data )
        , 'can create new duplicate crispr';

    throws_ok{
        model->find_crispr_by_seq_and_locus( $valid_crispr_data )
    } qr/Found multiple crispr sites/
        , 'throws correct error when multiple crispr sites with same sequence and locus';
}

note('Test deletion of cripr');
{
    ok model->delete_crispr( { id => $crispr->id } ), 'can delete newly created crispr';

    throws_ok{
        model->delete_crispr( { id => 11111111 } )
    } 'LIMS2::Exception::NotFound', 'can not delete non existant crispr';
}

done_testing;
