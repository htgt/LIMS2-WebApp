package LIMS2::t::Model::Plugin::CrisprEsQc;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test model => { classname => __PACKAGE__ }, 'test_data';

use strict;

=head1 NAME

LIMS2/t/Model/Plugin/CrisprEsQc.pm - test class for LIMS2::Model::Plugin::CrisprEsQc

=cut

sub update_crispr_well_damage : Tests(9) {
    note("Testing update_crispr_well_damage method");

    ok my $crispr_es_qc_well = model->schema->resultset('CrisprEsQcWell')->find( { id => 1 } ),
        'can get crispr es qc well';

    throws_ok{
        model->update_crispr_well_damage(
            {   well_id   => $crispr_es_qc_well->id,
                damage_type => 'foo'
            }
        )
    } qr/damage_type, is invalid/, 'throws error when invalid crispr damage type used';

    is $crispr_es_qc_well->crispr_damage_type_id, 'mosaic', 'current crispr damage type is mosaic';

    ok model->update_crispr_well_damage(
        {   id          => $crispr_es_qc_well->id,
            damage_type => 'frameshift'
        }
    ), 'can update crispr damage type to valid value';

    ok $crispr_es_qc_well->discard_changes, 'refresh row object from db';
    is $crispr_es_qc_well->crispr_damage_type_id, 'frameshift',
        'current crispr damage type has changed to frameshift';

    ok model->update_crispr_well_damage(
        {   id          => $crispr_es_qc_well->id,
        }
    ), 'can update crispr damage type to undef';

    ok $crispr_es_qc_well->discard_changes, 'refresh row object from db';
    is $crispr_es_qc_well->crispr_damage_type_id, undef,
        'current crispr damage type has changed to null';
}

1;

__END__

