package LIMS2::t::Model::Plugin::CrisprEsQc;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test model => { classname => __PACKAGE__ }, 'test_data';

use strict;

=head1 NAME

LIMS2/t/Model/Plugin/CrisprEsQc.pm - test class for LIMS2::Model::Plugin::CrisprEsQc

=cut

sub update_crispr_es_qc_well : Tests(26) {
    note("Testing update_crispr_es_qc_well method");

    ok my $crispr_es_qc_well = model->schema->resultset('CrisprEsQcWell')->find( { id => '1' } ),
        'can get crispr es qc well';

    throws_ok{
        model->update_crispr_es_qc_well(
            {   id   => $crispr_es_qc_well->id,
                damage_type => 'foo'
            }
        )
    } qr/damage_type, is invalid/, 'throws error when invalid crispr damage type used';

    is $crispr_es_qc_well->crispr_damage_type_id, 'mosaic', 'current crispr damage type is mosaic';

    ok model->update_crispr_es_qc_well(
        {   id          => $crispr_es_qc_well->id,
            damage_type => 'frameshift'
        }
    ), 'can update crispr damage type to valid value';

    ok $crispr_es_qc_well->discard_changes, 'refresh row object from db';
    is $crispr_es_qc_well->crispr_damage_type_id, 'frameshift',
        'current crispr damage type has changed to frameshift';

    ok model->update_crispr_es_qc_well(
        {   id          => $crispr_es_qc_well->id,
            damage_type => '',
        }
    ), 'can update crispr damage type to undef';

    ok $crispr_es_qc_well->discard_changes, 'refresh row object from db';
    is $crispr_es_qc_well->crispr_damage_type_id, undef,
        'current crispr damage type has changed to null';

    ok model->update_crispr_es_qc_well(
        {   id           => $crispr_es_qc_well->id,
            variant_size => -20,
        }
    ), 'can update variant size to -20';

    ok $crispr_es_qc_well->discard_changes, 'refresh row object from db';
    is $crispr_es_qc_well->variant_size, -20,
        'current variant_size has been updated to -20';

    ok model->update_crispr_es_qc_well(
        {   id           => $crispr_es_qc_well->id,
            variant_size => '',
            accepted     => 'true',
            damage_type  => 'frameshift',
        }
    ), 'can update accepted to true, variant_size to null and damage_type to frameshift';

    ok $crispr_es_qc_well->discard_changes, 'refresh row object from db';
    is $crispr_es_qc_well->variant_size, undef,
        'current variant_size has been updated to null';
    is $crispr_es_qc_well->accepted, 1,
        'current accepted has been updated to true';
    is $crispr_es_qc_well->crispr_damage_type_id, 'frameshift',
        'current damage_type has been updated to frameshift';

    # Test accepted logic
    $crispr_es_qc_well->well->update( { accepted => 1 } );

    ok model->update_crispr_es_qc_well(
        {   id           => $crispr_es_qc_well->id,
            damage_type  => 'mosaic',
        }
    ), 'can update damage type to mosaic';

    ok $crispr_es_qc_well->discard_changes, 'refresh row object from db';
    ok $crispr_es_qc_well->well->discard_changes, 'refresh row object from db';
    is $crispr_es_qc_well->crispr_damage_type_id, 'mosaic',
        'current damage_type has been updated to mosaic';
    is $crispr_es_qc_well->accepted, 0,
        'current accepted has been updated to false';
    is $crispr_es_qc_well->well->accepted, 0,
        'current parent well accepted has been updated to false';

    $crispr_es_qc_well->update( { accepted => 0 } );
    $crispr_es_qc_well->well->update( { accepted => 1 } );

    throws_ok{
        model->update_crispr_es_qc_well(
            {   id           => $crispr_es_qc_well->id,
                accepted     => 'true',
            }
        )
    } qr/Well already accepted in another run/, 'attempt to update accepted to true';

    ok $crispr_es_qc_well->discard_changes, 'refresh row object from db';
    is $crispr_es_qc_well->accepted, 0,
        'current accepted has NOT been updated to true because well is already accepted';
}

sub update_crispr_es_qc_run : Tests(6) {
    note("Testing validate_crispr_es_qc_run method");

    ok my $crispr_es_qc_run = model->schema->resultset('CrisprEsQcRuns')->find( { id => 'FBCCED08-81D9-11E4-86EF-3E2F7F98391B' } ),
        'can get crispr es qc run';
    is $crispr_es_qc_run->validated, 0,
        'validated set to false for crispr es qc run';

    throws_ok{
        model->update_crispr_es_qc_run( { id => '11610FFA-804A-11E4-BF41-116E489C5870' } )
    } 'LIMS2::Exception::NotFound', 'throws error when invalid crispr es qc run id used';

    lives_ok{
        model->update_crispr_es_qc_run( { id => $crispr_es_qc_run->id, validated => 'true' } )
    } 'can validate crispr_es_qc_run';

    ok $crispr_es_qc_run->discard_changes, 'refresh row object from db';
    is $crispr_es_qc_run->validated, 1,
        'validated set to true for crispr es qc run';
}

1;

__END__

