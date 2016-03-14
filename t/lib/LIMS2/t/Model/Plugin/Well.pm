package LIMS2::t::Model::Plugin::Well;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test;
use Try::Tiny;
use DateTime;
use Data::Dumper;
use YAML::Any qw(DumpFile);
use Hash::MoreUtils qw( slice_def );

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Plugin/Well.pm - test class for LIMS2::Model::Plugin::Well

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

sub all_tests : Tests {

    my $well_data = test_data('well.yaml');

    note("Testing well creation");
    {
        ok my $well = model->create_well( $well_data->{well_create} ), 'create_well should succeed';
        isa_ok $well, 'LIMS2::Model::Schema::Result::Well';
        is $well->created_by->name, 'test_user@example.org', 'well has correct created by user';
        is $well->name, 'B01', 'well has correct name';
        is $well->plate->name, 'PCS00177_A', 'well belongs to correct plate';

        ok my $retrieve_well = model->retrieve_well( { id => $well->id } ),
            'retrieve_well by id should succeed';
        is $well->id, $retrieve_well->id, 'has correct id';
    }

    note("Testing well retrieve");
    {
        ok my $well = model->retrieve_well( $well_data->{well_retrieve} ),
            'retrieve_plate by name should succeed';
        isa_ok $well, 'LIMS2::Model::Schema::Result::Well';
        is $well->name, 'B01', 'retrieved correct well';
        is $well->plate->name, 'PCS00177_A', '.. on correct plate';

        note("Test retrieving well by barcode");
        ok $well->update({ barcode => 'DOF123045' }), 'can add barcode to well';
        ok my $well2 = model->retrieve_well( $well_data->{well_retrieve_barcode} ),
            'retrieve_plate by barcode should succeed';
        is $well->id, $well2->id, 'and we have the correct well';

    }

    {
        note("Testing create well accepted override");
        ok my $well = model->retrieve_well( $well_data->{well_retrieve} ),
            'retrieve_plate by name should succeed';
        ok my $override
            = model->create_well_accepted_override( $well_data->{well_accepted_override_create} ),
            'create_well_accepted_override should succeed';
        isa_ok $override, 'LIMS2::Model::Schema::Result::WellAcceptedOverride';
        is $override->accepted, 0, 'override has correct value';
        is $override->well->id, $well->id, 'override belongs to correct well';

        note("Testing retrieve well accepted override");
        ok my $well2 = model->retrieve_well( $well_data->{well_accepted_override_create} ),
            'retrieve created well should succeed';
        ok my $override2 = model->retrieve_well_accepted_override( { well_id => $well2->id } ),
            'retrieve_well_accepted_override should succeed';
        is $override2->well->id, $well2->id, 'retrieved override belongs to correct well';

        note("Testing update well accepted override");
        ok my $updated_override
            = model->update_well_accepted_override( $well_data->{well_accepted_override_update} ),
            'update_well_accepted_override should succeed';
        is $updated_override->accepted, 1, 'override has correct value';

        throws_ok {
            model->update_well_accepted_override(
                $well_data->{well_accepted_override_update_same} );
        }
        qr/Well already has accepted override with value TRUE/;

        ok $override->delete, 'can delete override';
    }

    {
        note("Testing set_well_assay_complete");

        my $date_time = DateTime->new(
            year   => 2010,
            month  => 9,
            day    => 12,
            hour   => 10,
            minute => 5,
            second => 7
        );

        my %params = ( %{ $well_data->{well_retrieve} }, completed_at => $date_time->iso8601 );

        ok my $well = model->set_well_assay_complete( \%params ),
            'set_well_assay_complete should succeed';

        ok !$well->accepted, 'well is not automatically accepted';

        is $well->assay_complete, $date_time, 'assay_complete has expected datetime';

        ok model->create_well_qc_sequencing_result(
            {   well_id         => $well->id,
                valid_primers   => 'LR,PNF,R1R',
                pass            => 1,
                test_result_url => 'http://example.org/some/url/or/other',
                created_by      => 'test_user@example.org'
            }
            ),
            'create QC sequencing result';

        ok my $qc_seq = model->retrieve_well_qc_sequencing_result( { id => $well->id } ),
            'retrieve_well_qc_sequencing_result should succeed';
        isa_ok $qc_seq, 'LIMS2::Model::Schema::Result::WellQcSequencingResult';
        is $qc_seq->valid_primers, 'LR,PNF,R1R', 'qc valid primers correct';
        is $qc_seq->test_result_url, 'http://example.org/some/url/or/other',
            'qc test result url correct';

        $date_time = DateTime->now;

        ok $well
            = model->set_well_assay_complete(
            { id => $well->id, completed_at => $date_time->iso8601 } ),
            'set_well_assay_complete should succeed';

        ok $well->accepted, 'well is automatically accepted now that we have a sequencing pass';

        is $well->assay_complete, $date_time, 'assay_complete has expected datetime';

        lives_ok {
            model->delete_well_qc_sequencing_result( { id => $well->id } );
        }
        'delete well qc sequencing result';

        throws_ok {
            model->retrieve_well_qc_sequencing_result( { id => $well->id } );
        }
        qr/No WellQcSequencingResult entity found/;
    }

    {
        note("Testing well dna status create, retrieve and delete");

        throws_ok {
            model->create_well_dna_status(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    pass       => 1,
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/Well MOHFAQ0001_A_2_D04 already has a dna status of pass/;

        ok my $dna_status
            = model->retrieve_well_dna_status(
            { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } ),
            'can retrieve dna status for well';
        is $dna_status->pass, 1, 'dna status is pass';
        ok my $well = $dna_status->well, '.. can grab well from dna_status';
        is "$well", 'MOHFAQ0001_A_2_D04', '.. and dna_status is for right well';

        lives_ok {
            model->delete_well_dna_status( { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } );
        }
        'delete well dna status';

        throws_ok {
            model->retrieve_well_dna_status(
                { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } );
        }
        qr/No WellDnaStatus entity found/;

        ok my $new_dna_status = model->create_well_dna_status(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                pass       => 1,
                created_by => 'test_user@example.org'
            }
            ),
            'can create well dna status';
        is $new_dna_status->pass, 1, 'dna status is pass';
        is $well->id, $new_dna_status->well_id, '.. and dna_status is for right well';
    }

    {
        note("Testing well recombineering result create and retrieve");

        ok my $recomb
            = model->create_well_recombineering_result( $well_data->{well_recombineering_create} ),
            'create_well_recombineering_result should succeed';
        isa_ok $recomb, 'LIMS2::Model::Schema::Result::WellRecombineeringResult';
        is $recomb->result_type_id, 'pcr_u', 'recombineering result type correct';
        is $recomb->result,         'pass',  'recombineering result correct';

        ok my $rec_results
            = model->retrieve_well_recombineering_results(
            $well_data->{well_recombineering_create} ),
            'can retrieve recombineering results by name';
        isa_ok( $rec_results,      'ARRAY' );
        isa_ok( $rec_results->[0], 'LIMS2::Model::Schema::Result::WellRecombineeringResult' );

        throws_ok {
            model->create_well_recombineering_result(
                $well_data->{well_recombineering_create_bad} );
        }
        qr/is invalid: existing_recombineering_result_type/;
    }

    {
        note("Testing well colony picks create and retrieve");

        ok my $colony_picks
            = model->create_well_colony_picks( $well_data->{well_colony_picks_create} ),
            'create_well_colony_picks should succeed';
        isa_ok $colony_picks, 'LIMS2::Model::Schema::Result::WellColonyCount';
        is $colony_picks->colony_count_type_id, 'blue_colonies', 'colony pick type correct';
        is $colony_picks->colony_count, 40, 'colony picks correct';

        ok my $rec_colony_pick
            = model->retrieve_well_colony_picks( $well_data->{well_colony_picks_create} ),
            'can retrieve colony_picks by name';
        isa_ok( $rec_colony_pick,      'ARRAY' );
        isa_ok( $rec_colony_pick->[0], 'LIMS2::Model::Schema::Result::WellColonyCount' );

        throws_ok {
            model->create_well_colony_picks( $well_data->{well_colony_picks_create_bad} );
        }
        qr/is invalid: existing_colony_type/;
    }

    {
        note("Testing well primer bands create and retrieve");

        ok my $primer_bands
            = model->create_well_primer_bands( $well_data->{well_primer_bands_create} ),
            'create_well_primer bands should succeed';

        is $primer_bands->primer_band_type_id, 'gr1',  'primer band type correct';
        is $primer_bands->pass,                'pass', 'primer band correct';

        ok my $rec_primer_bands
            = model->retrieve_well_primer_bands( $well_data->{well_primer_bands_create} ),
            'can retrieve primer_bands by name';
        isa_ok( $rec_primer_bands,      'ARRAY' );
        isa_ok( $rec_primer_bands->[0], 'LIMS2::Model::Schema::Result::WellPrimerBand' );

        ok $primer_bands = model->update_or_create_well_primer_bands(
            {   plate_name       => 'MOHFAQ0001_A_2',
                well_name        => 'D04',
                primer_band_type => 'gf3',
                pass             => 'fail',
                created_by       => 'test_user@example.org',
            }
            ),
            'can create well primer band as part of update_or_create';
        is $primer_bands->pass, 'fail', 'well primer band pass is FAIL';
        ok $primer_bands = model->update_or_create_well_primer_bands(
            {   plate_name       => 'MOHFAQ0001_A_2',
                well_name        => 'D04',
                primer_band_type => 'gf3',
                pass             => 'pass',
                created_by       => 'test_user@example.org',
            }
            ),
            'can update well primer band';
        isa_ok( $primer_bands,      'ARRAY' );
        isa_ok( $primer_bands->[0], 'LIMS2::Model::Schema::Result::WellPrimerBand' );
        is $primer_bands->[0]->pass, 'pass', 'well primer band pass is now PASS';
        ok my $primer_band = model->delete_well_primer_band(
            {   plate_name       => 'MOHFAQ0001_A_2',
                well_name        => 'D04',
                primer_band_type => 'gf3',
                created_by       => 'test_user@example.org',
            }
            ),
            'can delete well primer band';

        throws_ok {
            model->create_well_primer_bands( $well_data->{well_primer_bands_create_bad} );
        }
        qr/is invalid: existing_primer_band_type/;
    }

    {
        note("Testing well dna quality create and retrieve");

        ok my $quality = model->create_well_dna_quality( $well_data->{well_dna_quality_create} ),
            'create_well_dna_quality should succeed';
        isa_ok $quality, 'LIMS2::Model::Schema::Result::WellDnaQuality';
        is $quality->quality, 'M', 'DNA quality is correct';

        ok model->retrieve_well_dna_quality( $well_data->{well_dna_quality_create} ),
            'retrieve_well_dna_quality should succeed';

        throws_ok {
            model->retrieve_well_dna_quality( { id => 845 } );
        }
        qr /No WellDnaQuality entity found/;
    }

    {
        note("Testing delete_well");

        lives_ok {
            model->delete_well( { plate_name => 'PCS00177_A', well_name => 'B01' } );
        }
        'delete well';
    }

    {
        note("Testing cassette phase");

        ok my $well_cassette = model->retrieve_well_phase_matched_cassette(
            { well_id => '855', phase_matched_cassette => 'L1L2_st?' } );

        my $design = model->retrieve_well( { id => '855' } )->design;
        is $design->phase, -1, 'well design phase match';
        is $well_cassette, 'L1L2_st0', 'well cassette phase match';

        ok my $well_cassette1 = model->retrieve_well_phase_matched_cassette(
            { well_id => '940', phase_matched_cassette => 'L1L2_gt?' } );

        my $design1 = model->retrieve_well( { id => '940' } )->design;
        is $design1->phase, 2, 'well design phase match';
        is $well_cassette1, 'L1L2_gt2', 'well cassette phase match';
    }

    {
        note("Testing well targeting_pass create, retrieve and delete");

        throws_ok {
            model->create_well_targeting_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    result     => 'junk',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/Parameter validation failed/;

        ok model->create_well_targeting_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'passb',
                created_by => 'test_user@example.org'
            }
            ),
            'targeting_pass result created successfully';

        throws_ok {
            model->create_well_targeting_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    result     => 'passb',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/Well MOHFAQ0001_A_2_D04 already has a well_targeting_pass value of passb/;

        ok my $targeting_pass
            = model->retrieve_well_targeting_pass(
            { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } ),
            'can retrieve targeting pass data for well';
        is $targeting_pass->result, 'passb', 'targeting fail result is passb';
        ok my $well = $targeting_pass->well, '.. can grab well from targeting_pass';
        is "$well", 'MOHFAQ0001_A_2_D04', '.. and targeting_pass is for right well';

        BEGIN { use_ok( "LIMS2::Model::Util::RankQCResults", "rank" ); }
        ok rank($targeting_pass) > rank('fail'), 'passb is better than fail';
        ok rank('pass') > rank($targeting_pass), 'pass is better than passb';

        ok $targeting_pass = model->update_or_create_well_targeting_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'pass',
                created_by => 'test_user@example.org'
            }
            ),
            'can update targeting pass well result';
        is $targeting_pass->result, 'pass', '..updated result is now pass';

        ok $targeting_pass = model->update_or_create_well_targeting_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'lrpcr_pass',
                created_by => 'test_user@example.org'
            }
            ),
            'can update targeting pass well result';
        is $targeting_pass->result, 'lrpcr_pass', '..updated result is now lrpcr_pass';

        lives_ok {
            model->delete_well_targeting_pass(
                { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } );
        }
        'delete well targeting pass';

        throws_ok {
            model->retrieve_well_targeting_pass(
                { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } );
        }
        qr/No WellTargetingPass entity found/;

        ok my $new_targeting_pass = model->create_well_targeting_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'passb',
                created_by => 'test_user@example.org'
            }
            ),
            'can create new well targeting pass';
        is $new_targeting_pass->result, 'passb', 'targeting pass status is passb';
        is $well->id, $new_targeting_pass->well_id, '.. and targeting_pass is for right well';
    }

    {
        note("Testing well targeting_puro_pass create, retrieve and delete");

        throws_ok {
            model->create_well_targeting_puro_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    result     => 'junk',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/Parameter validation failed/;

        ok model->create_well_targeting_puro_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'passb',
                created_by => 'test_user@example.org'
            }
            ),
            'targeting_puro_pass result created successfully';

        throws_ok {
            model->create_well_targeting_puro_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    result     => 'passb',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/Well MOHFAQ0001_A_2_D04 already has a well_targeting_puro_pass value of passb/;

        ok my $targeting_puro_pass
            = model->retrieve_well_targeting_puro_pass(
            { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } ),
            'can retrieve targeting pass data for well';
        is $targeting_puro_pass->result, 'passb', 'targeting-puro fail result is passb';
        ok my $well = $targeting_puro_pass->well, '.. can grab well from targeting_puro_pass';
        is "$well", 'MOHFAQ0001_A_2_D04', '.. and targeting_puro_pass is for right well';

        ok $targeting_puro_pass = model->update_or_create_well_targeting_puro_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'pass',
                created_by => 'test_user@example.org'
            }
            ),
            'can update targeting pass well result';
        is $targeting_puro_pass->result, 'pass', '..updated result is now pass';

        lives_ok {
            model->delete_well_targeting_puro_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    created_by => 'test_user@example.org'
                }
            );
        }
        'delete well targeting-puro pass';

        throws_ok {
            model->retrieve_well_targeting_puro_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/No WellTargetingPuroPass entity found/;

        ok my $new_targeting_puro_pass = model->create_well_targeting_puro_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'passb',
                created_by => 'test_user@example.org'
            }
            ),
            'can create new well targeting pass';
        is $new_targeting_puro_pass->result, 'passb', 'targeting pass status is passb';
        is $well->id, $new_targeting_puro_pass->well_id,
            '.. and targeting_puro_pass is for right well';
    }

    {
        note("Testing well targeting_neo_pass create, retrieve and delete");

        throws_ok {
            model->create_well_targeting_neo_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    result     => 'junk',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/Parameter validation failed/;

        ok model->create_well_targeting_neo_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'passb',
                created_by => 'test_user@example.org'
            }
            ),
            'targeting_neo_pass result created successfully';

        throws_ok {
            model->create_well_targeting_neo_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    result     => 'passb',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/Well MOHFAQ0001_A_2_D04 already has a well_targeting_neo_pass value of passb/;

        ok my $targeting_neo_pass
            = model->retrieve_well_targeting_neo_pass(
            { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } ),
            'can retrieve targeting pass data for well';
        is $targeting_neo_pass->result, 'passb', 'targeting-neo fail result is passb';
        ok my $well = $targeting_neo_pass->well, '.. can grab well from targeting_neo_pass';
        is "$well", 'MOHFAQ0001_A_2_D04', '.. and targeting_neo_pass is for right well';

        ok $targeting_neo_pass = model->update_or_create_well_targeting_neo_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'pass',
                created_by => 'test_user@example.org'
            }
            ),
            'can update targeting pass well result';
        is $targeting_neo_pass->result, 'pass', '..updated result is now pass';

        lives_ok {
            model->delete_well_targeting_neo_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    created_by => 'test_user@example.org'
                }
            );
        }
        'delete well targeting-neo pass';

        throws_ok {
            model->retrieve_well_targeting_neo_pass(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/No WellTargetingNeoPass entity found/;

        ok my $new_targeting_neo_pass = model->create_well_targeting_neo_pass(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => 'passb',
                created_by => 'test_user@example.org'
            }
            ),
            'can create new well targeting pass';
        is $new_targeting_neo_pass->result, 'passb', 'targeting pass status is passb';
        is $well->id, $new_targeting_neo_pass->well_id,
            '.. and targeting_neo_pass is for right well';
    }

    {
        note("Testing well chromosome_fail create, retrieve and delete");

        throws_ok {
            model->create_well_chromosome_fail(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    result     => '6',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/Parameter validation failed/;

        ok model->create_well_chromosome_fail(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => '3',
                created_by => 'test_user@example.org'
            }
            ),
            'chromosome_fail result created successfully';

        throws_ok {
            model->create_well_chromosome_fail(
                {   plate_name => 'MOHFAQ0001_A_2',
                    well_name  => 'D04',
                    result     => '3',
                    created_by => 'test_user@example.org'
                }
            );
        }
        qr/Well MOHFAQ0001_A_2_D04 already has a chromosome fail value of/;

        ok my $chromosome_fail
            = model->retrieve_well_chromosome_fail(
            { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } ),
            'can retrieve chromosome fail data for well';
        is $chromosome_fail->result, '3', 'chromosome fail result is 3';
        ok my $well = $chromosome_fail->well, '.. can grab well from chromosome_fail';
        is "$well", 'MOHFAQ0001_A_2_D04', '.. and chromosome_fail is for right well';

        ok $chromosome_fail = model->update_or_create_well_chromosome_fail(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => '4',
                created_by => 'test_user@example.org'
            }
            ),
            'can update chromosome fail well result';
        is $chromosome_fail->result, '4', '..updated result is now 4';

        lives_ok {
            model->delete_well_chromosome_fail(
                { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } );
        }
        'delete well chromosome fail result';

        throws_ok {
            model->retrieve_well_chromosome_fail(
                { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } );
        }
        qr/No WellChromosomeFail entity found/;

        ok my $new_chromosome_fail = model->create_well_chromosome_fail(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => '3',
                created_by => 'test_user@example.org'
            }
            ),
            'can create new well chromosome fail result';
        is $new_chromosome_fail->result, '3', 'chromosome fail result is 3';
        is $well->id, $new_chromosome_fail->well_id,
            '.. and chromosome_fail result is for right well';
    }

    {
        note("Testing well_genotyping_result create, update, retrieve and delete");

        throws_ok {
            model->create_well_genotyping_result(
                {   plate_name                => 'MOHFAQ0001_A_2',
                    well_name                 => 'D04',
                    genotyping_result_type_id => 'loacrit',
                    call                      => 'FF',
                    created_by                => 'test_user@example.org'
                }
            );
        }
        qr/Parameter validation failed/;

        my $result_input = {
            plate_name                => 'MOHFAQ0001_A_2',
            well_name                 => 'D04',
            genotyping_result_type_id => 'loacrit',
            call                      => 'fa',
            created_by                => 'test_user@example.org'
        };

        ok my $result = model->create_well_genotyping_result($result_input),
            'genotyping_results fa call - created successfully';
        is $result->call,                      'fa',      'new result has expected call';
        is $result->genotyping_result_type_id, 'loacrit', 'new result has expected assay type';
        throws_ok {
            model->create_well_genotyping_result($result_input);
        }
        qr/already has a genotyping_results value/;

        ok my $genotyping_result = model->update_or_create_well_genotyping_result(
            {   plate_name                => 'MOHFAQ0001_A_2',
                well_name                 => 'D04',
                genotyping_result_type_id => 'loacrit',
                call                      => 'pass',
                copy_number               => '2.4',
                copy_number_range         => '0.2',
                created_by                => 'test_user@example.org'
            }
            ),
            'can update well_genotyping_results';
        is $genotyping_result->id, $result->id, "..existing well has been updated";
        is $genotyping_result->call,        'pass', '..updated call attribute is now pass';
        is $genotyping_result->copy_number, '2.4',  '..updated copy_number attribute is now 2.4';
        is $genotyping_result->copy_number_range, '0.2', '..updated copy_number_range is now 0.2';

        ok $genotyping_result = model->update_or_create_well_genotyping_result(
            {   plate_name                => 'MOHFAQ0001_A_2',
                well_name                 => 'D04',
                genotyping_result_type_id => 'loacrit',
                call                      => 'fail',
                copy_number               => '3',
                created_by                => 'test_user@example.org',
            }
            ),
            'attempt to update with worse result runs without error';
        is $genotyping_result->call,        'pass', '..but result call is not updated';
        is $genotyping_result->copy_number, '2.4',  '..and copy number is not updated';

        ok $genotyping_result = model->update_or_create_well_genotyping_result(
            {   plate_name                => 'MOHFAQ0001_A_2',
                well_name                 => 'D04',
                genotyping_result_type_id => 'loacrit',
                call                      => 'fail',
                copy_number               => '3',
                created_by                => 'test_user@example.org',
                overwrite                 => 1,
            }
            ),
            'attempt to update with worse result runs using overwrite flag';
        is $genotyping_result->call, 'fail', '..and result call is updated';

        ok my $chromosome_fail
            = model->retrieve_well_chromosome_fail(
            { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } ),
            'can retrieve chromosome fail data for well';
        is $chromosome_fail->result, '3', 'chromosome fail result is 3';
        ok my $well = $chromosome_fail->well, '.. can grab well from chromosome_fail';
        is "$well", 'MOHFAQ0001_A_2_D04', '.. and chromosome_fail is for right well';

        ok $chromosome_fail = model->update_or_create_well_chromosome_fail(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => '4',
                created_by => 'test_user@example.org'
            }
            ),
            'can update chromosome fail well result';
        is $chromosome_fail->result, '4', '..updated result is now 4';

        lives_ok {
            model->delete_well_chromosome_fail(
                { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } );
        }
        'delete well chromosome fail result';

        throws_ok {
            model->retrieve_well_chromosome_fail(
                { plate_name => 'MOHFAQ0001_A_2', well_name => 'D04' } );
        }
        qr/No WellChromosomeFail entity found/;

        ok my $new_chromosome_fail = model->create_well_chromosome_fail(
            {   plate_name => 'MOHFAQ0001_A_2',
                well_name  => 'D04',
                result     => '3',
                created_by => 'test_user@example.org'
            }
            ),
            'can create new well chromosome fail result';
        is $new_chromosome_fail->result, '3', 'chromosome fail result is 3';
        is $well->id, $new_chromosome_fail->well_id,
            '.. and chromosome_fail result is for right well';
    }

    {
        note("well lab number tests: create, retrieve, update and delete");

        # create a PIQ plate and a well
        ok my $piq_plate = model->create_plate( $well_data->{piq_plate_create} ),
            'create PIQ plate should succeed';

        ok my $piq_well = model->create_well( $well_data->{piq_well_create_one} ),
            'create PIQ well should succeed';

        # check parameter validation
        throws_ok {
            model->create_well_lab_number( { well_id => $piq_well->id, } );
        }
        qr/Parameter validation failed/,
            'correctly throws parameter validation failure when parameters are incomplete';

        # check normal create
        ok model->create_well_lab_number( { well_id => $piq_well->id, lab_number => 'LAB 001', } ),
            'lab number created successfully';

        # check create fails when already exists
        throws_ok {
            model->create_well_lab_number( { well_id => $piq_well->id, lab_number => 'LAB 001', } );
        }
        qr/Well PIQTEST001_A01 already has a Lab Number, with a value of LAB 001/,
            'correctly throws create failure when well aleady has a lab number';

        # check can retrieve well number and details are correct
        ok my $lab_number
            = model->retrieve_well_lab_number( { plate_name => 'PIQTEST001', well_name => 'A01' } ),
            'can retrieve Lab Number data for well';

        is $lab_number->lab_number, 'LAB 001', 'lab number retrieved is correct';

        ok my $well = $lab_number->well, '.. can grab well from lab_number';

        is "$well", 'PIQTEST001_A01', '.. and lab_number is for right well';

        # check can update lab number
        ok $lab_number
            = model->update_or_create_well_lab_number(
            { well_id => $piq_well->id, lab_number => 'LAB 002' } ),
            'can update lab number when new Lab Number is unique';

        is $lab_number->lab_number, 'LAB 002', '..updated result is now LAB 002';

        # check update fails if lab number unchanged
        throws_ok {
            $lab_number = model->update_or_create_well_lab_number(
                { well_id => $piq_well->id, lab_number => 'LAB 002' } );
        }
        qr/Update unnecessary. Lab Number LAB 002 is unchanged/,
            'correctly throws update failure when lab number is unchanged';

        # check delete
        lives_ok {
            model->delete_well_lab_number( { plate_name => 'PIQTEST001', well_name => 'A01' } );
        }
        'delete well lab number should succeed';

        throws_ok {
            model->retrieve_well_lab_number( { plate_name => 'PIQTEST001', well_name => 'A01' } );
        }
        qr/No WellLabNumber entity found matching/, 'correctly throws retrieve failure';

        # check update or create
        ok $lab_number
            = model->update_or_create_well_lab_number(
            { well_id => $piq_well->id, lab_number => 'LAB 003' } ),
            'can create lab number when none exists for well';

        is $lab_number->lab_number, 'LAB 003', '..updated result is now LAB 003';

        # create a second well
        ok my $piq_well_two = model->create_well( $well_data->{piq_well_create_two} ),
            'creating a second PIQ well should succeed';

        # check cannot re-use an existing lab number
        throws_ok {
            my $lab_number_two = model->update_or_create_well_lab_number(
                { well_id => $piq_well_two->id, lab_number => 'LAB 003' } );
        }
        qr/Create failed. Lab Number LAB 003 has already been used in well PIQTEST001_A01/,
            'correctly throws create failure when lab number already used';

        # check cannot create an empty lab number
        throws_ok {
            my $lab_number_two = model->create_well_lab_number(
                { well_id => $piq_well_two->id, lab_number => '' } );
        }
        qr/Parameter validation failed/,
            'correctly throws create parameter validation failure when lab number empty';

        # check cannot update_or_create an empty lab number
        throws_ok {
            my $lab_number_two = model->update_or_create_well_lab_number(
                { well_id => $piq_well_two->id, lab_number => '' } );
        }
        qr/Parameter validation failed/,
            'correctly throws update_or_create parameter validation failure when lab number empty';

        # check can insert a valid lab number
        ok my $lab_number_two
            = model->update_or_create_well_lab_number(
            { well_id => $piq_well_two->id, lab_number => 'LAB 004' } ),
            'can insert a second well lab number';

        note("end of well lab number tests");
    }

    note("Add colony counts to a well");
    {
        my $colony_count_data = test_data('add_colony_count.yaml');
        lives_ok { model->update_well_colony_picks( $colony_count_data->{valid_input} ) }
        'should succeed for EP plate';
        ok my $colony_counts = model->get_well_colony_pick_fields_values(
            {   plate_name => $colony_count_data->{valid_input}{plate_name},
                well_name  => $colony_count_data->{valid_input}{well_name}
            }
            ),
            'return all colony count types with asociated values for that well';

        foreach my $colony_count_type ( map { $_->id }
            model->schema->resultset('ColonyCountType')->all )
        {
            is $colony_count_data->{valid_input}{$colony_count_type},
                $colony_counts->{$colony_count_type}{att_values},
                'should of returned the colony counts entered';
        }

        throws_ok {
            model->get_well_colony_pick_fields_values(
                {   plate_name => $colony_count_data->{invalid_input}{plate_name},
                    well_name  => $colony_count_data->{invalid_input}{well_name}
                }
            );
        }
        qr/invalid plate type; can only add colony data to EP, SEP and XEP plates/;
    }

    note("Testing adding colony counts using upload");
    {
        my $test_file = File::Temp->new or die( 'Could not create temp test file ' . $! );
        $test_file->print(
            "plate_name,well_name,total_colonies,picked_colonies,remaining_unstained_colonies\n"
                . "FEP0006,B01,30,20,10\n"
                . "FEP0006,C01,40,20,20\n" );
        $test_file->seek( 0, 0 );

        ok model->upload_well_colony_picks_file_data(
            $test_file, { created_by => 'test_user@example.org' }
            ),
            'should succeed';
    }

    note("Testing adding colony counts using upload fails if csv data is incorrect");
    {
        my $test_file = File::Temp->new or die( 'Could not create temp test file ' . $! );
        $test_file->print(
            "plate_name,well_name,total_colonies,picked_colonies,remaining_unstained_colonies\n"
                . "FEP0006,D01,30,20,10\n"
                . "FEPD0006_1,C01,10,5,5\n" );
        $test_file->seek( 0, 0 );

        throws_ok {
            model->upload_well_colony_picks_file_data( $test_file,
                { created_by => 'test_user@example.org' } );
        }
        qr/ERROR: invalid plate type; can only add colony data to EP, SEP and XEP plates/;
    }

}

## use critic

1;

__END__

