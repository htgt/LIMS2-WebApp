package LIMS2::t::Model::Plugin::Crispr;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Plugin::Crispr;

use LIMS2::Test;
use Data::Dumper;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Plugin/Crispr.pm - test class for LIMS2::Model::Plugin::Crispr

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

sub all_tests : Test(48) {

    note('Testing the Creation crisprs');
    my $create_crispr_data = test_data('create_crispr.yaml');
    my $crispr;
    {

        ok $crispr = model->create_crispr( $create_crispr_data->{valid_crispr} ),
            'can create new crispr';
        is $crispr->crispr_loci_type_id, 'Exonic',           '.. crispr type is correct';
        is $crispr->seq,                 'ATCGGCACACAGAGAG', '.. crispr seq is correct';

        ok my $locus = $crispr->loci->first, 'can retrieve crispr locus';
        is $locus->assembly_id, 'GRCm38', '.. locus assembly correct';
        is $locus->chr->name, 12, '.. locus chromosome correct';

        ok my $off_targets = $crispr->off_targets, 'can retreive off targets from crispr';
        is $off_targets->count, 1, '.. we have 1 off targets';
        ok my $off_target = $off_targets->first, 'can grab off target';
        is $off_target->crispr_id,    $crispr->id, '.. has correct crispr id';
        is $off_target->off_target_crispr_id, 200, '.. has correct crispr off target id';
        is $off_target->mismatches,             3, '.. has correct mismatch number';

        is $crispr->off_target_summaries->count, 1, 'We have only one off target summary';
        my $off_target_summary = $crispr->off_target_summaries->first;
        is $off_target_summary->algorithm, 'strict', '.. correct algorithm';
        is $off_target_summary->outlier,   0,        '.. correct outlier';
        is $off_target_summary->summary, '{Exons: 5, Introns:10, Intergenic: 15}',
            '.. correct summary';

        throws_ok {
            model->create_crispr( $create_crispr_data->{species_assembly_mismatch} );
        }
        qr/Assembly GRCm38 does not belong to species Human/,
            'throws error when species and assembly do not match';

        ok $off_target->delete, 'delete off target record';
    }

    note('Create dupliate crispr with same off target algorithm data');
    {

        # with same off target algorithm
        ok my $duplicate_crispr = model->create_crispr(
            $create_crispr_data->{duplicate_crispr_same_off_target_algorithm}
            ),
            'can create dupliate crispr';
        is $duplicate_crispr->id, $crispr->id, 'we have the same crispr';

        is $duplicate_crispr->off_target_summaries->count, 1,
            'We still only have one off target summary';
        my $off_target_summary = $duplicate_crispr->off_target_summaries->first;
        is $off_target_summary->algorithm, 'strict', '.. correct algorithm';
        is $off_target_summary->outlier,   1,        '.. correct outlier';
    }

    note('Create dupliate crispr with different off target algorithm data');
    {

        ok my $duplicate_crispr = model->create_crispr(
            $create_crispr_data->{duplicate_crispr_different_off_target_algorithm}
            ),
            'can create dupliate crispr';
        is $duplicate_crispr->id, $crispr->id, 'we have the same crispr';

        is $duplicate_crispr->off_target_summaries->count, 2,
            'We have two off target summaries now';
        ok my $easy_off_target_summary
            = $duplicate_crispr->off_target_summaries->find( { algorithm => 'easy' } ),
            'can find off target summary for easy algorithm';
        is $easy_off_target_summary->algorithm, 'easy', '.. correct algorithm';
        is $easy_off_target_summary->outlier,   0,      '.. correct outlier';
    }

    note('Testing retrival of crispr');
    {
        ok my $crispr = model->retrieve_crispr( { id => $crispr->id } ),
            'retrieve newly created crispr';
        isa_ok $crispr, 'LIMS2::Model::Schema::Result::Crispr';
        ok my $crispr_2 = model->retrieve_crispr_collection( { crispr_id => $crispr->id } ),
            'can retrieve_crispr_collection (single crispr)';
        isa_ok $crispr_2, 'LIMS2::Model::Schema::Result::Crispr';
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

        ok my $crispr_locus = model->create_crispr_locus($crispr_locus_data),
            'can create new crispr locus';

        is $crispr_locus->assembly_id, 'NCBIM37', '.. assembly is correct';
    }


    note('Test finding crispr by sequence and locus');
    my $find_crispr_data = test_data('find_crispr_by_seq.yaml');
    {
        my $valid_crispr_data = $find_crispr_data->{valid_find_crispr_by_seq};
        ok my $found_crispr = model->find_crispr_by_seq_and_locus($valid_crispr_data),
            'can find crispr site by sequence and locus data';
        is $found_crispr->id, $crispr->id, '.. and we have found the same crispr';

        # throw error because missing locus info
        my $invalid_locus_crispr_data = $find_crispr_data->{non_existatant_locus};
        throws_ok {
            model->find_crispr_by_seq_and_locus($invalid_locus_crispr_data);
        }
        qr/Can not find crispr locus information on assembly NCBIM36/,
            'throws error because of missing locus information';

        # throw error because multiple identical crisprs
        my $duplicate_crispr_data = $create_crispr_data->{valid_crispr};
        $duplicate_crispr_data->{species_id}          = 'Mouse';
        $duplicate_crispr_data->{crispr_loci_type_id} = 'Exonic';
        $duplicate_crispr_data->{off_target_outlier}  = 0;
        ok $crispr = model->_create_crispr($duplicate_crispr_data),
            'can create new duplicate crispr';

        throws_ok {
            model->find_crispr_by_seq_and_locus($valid_crispr_data);
        }
        qr/Found multiple crispr sites/,
            'throws correct error when multiple crispr sites with same sequence and locus';
    }

    note('Test deletion of crispr');
    {

        #add process with crispr
        my $process = model->schema->resultset('Process')->create( { type_id => 'create_crispr' } );
        $process->create_related( process_crispr => { crispr_id => $crispr->id } );

        throws_ok {
            model->delete_crispr( { id => $crispr->id } );
        }
        qr/Crispr \d+ has been used in one or more processes/,
            'fail to delete crispr that belongs to a create_crispr process';

        ok $process->process_crispr->delete, 'can delete process crispr';
        ok model->delete_crispr( { id => $crispr->id } ), 'can delete newly created crispr';

        throws_ok {
            model->delete_crispr( { id => 11111111 } );
        }
        'LIMS2::Exception::NotFound', 'can not delete non existant crispr';
    }

}

sub create_crispr_off_target : Tests() {
    note('Testing create crispr off target');

    my $create_crispr_ot_data = test_data('create_crispr_off_target.yaml');

    ok my $crispr = model->create_crispr( $create_crispr_ot_data->{valid_crispr_and_off_target} ),
        'can create new crispr with off target';

    ok my $off_targets = $crispr->off_targets, 'can retreive off targets from crispr';
    is $off_targets->count, 1, '.. we have 1 off targets';
    ok my $off_target = $off_targets->first, 'can grab off target';
    is $off_target->crispr_id,    $crispr->id, '.. has correct crispr id';
    is $off_target->off_target_crispr_id, 200, '.. has correct crispr off target id';
    is $off_target->mismatches,             2, '.. has correct mismatch number';

    throws_ok {
        model->create_crispr( $create_crispr_ot_data->{valid_crispr_and_off_target} ),
    }
    qr/Crispr \d+ has off targets stored in database/, 'can not update off targets of pre existing crispr';

    my %new_off_target_data = (
        crispr_id    => $crispr->id,
        ot_crispr_id => 113,
        mismatches   => 1,
    );
    ok my $off_target = model->create_crispr_off_target( \%new_off_target_data, $crispr ),
        'can create new off target';
    is $off_target->off_target_crispr_id, 113, 'new off target record has correct ot crispr id';

    throws_ok {
         model->create_crispr_off_target( \%new_off_target_data, $crispr )
    }
    qr/Crispr already has off target/, 'does not allow duplication of crispr off targets';

    $new_off_target_data{ot_crispr_id} = $crispr->id;
    throws_ok {
         model->create_crispr_off_target( \%new_off_target_data, $crispr )
    }
    qr/Crispr can not be its own off target/, 'does not allow crispr to be its own off target';
}


sub crispr_importer : Test(8) {
    my $species = 'Human';
    my $assembly
        = model->schema->resultset('SpeciesDefaultAssembly')->find( { species_id => $species } )
        ->assembly_id;

    ok my @crisprs = model->import_wge_crisprs( [245377753], $species, $assembly ),
        'can import crispr';

    throws_ok {
        model->import_wge_crisprs( [245377753], 'Mouse', 'GRCm38' );
    }
    'LIMS2::Exception', 'species mismatch throws error';

    throws_ok {
        model->import_wge_crisprs( ['zz'], $species, $assembly );
    }
    'LIMS2::Exception', 'invalid crispr creates error';

    ok my @pairs = model->import_wge_pairs( ['245377753_245377762'], $species, $assembly ),
        'can import crispr pair';

    #make sure crisprs with the same id dont get imported twice
    use Data::Dumper;
    is $crisprs[0]->{lims2_id}, $pairs[0]->{left_id}, 'Same imported crispr has correct id';
    ok my $pair = model->retrieve_crispr_collection( { crispr_pair_id => $pairs[0]->{lims2_id} } ),
        'can retrieve_crispr_collection (pair)';
    isa_ok $pair, 'LIMS2::Model::Schema::Result::CrisprPair';

    throws_ok {
        ok model->import_wge_pairs( ['245377753_245377762'], 'Mouse', 'GRCm38' );
    }
    'LIMS2::Exception', 'species mismatch throws error';

}

=head1 AUTHOR

Team 87

=cut

## use critic

1;

__END__

