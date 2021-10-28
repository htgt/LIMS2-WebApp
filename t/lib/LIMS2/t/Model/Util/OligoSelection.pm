package LIMS2::t::Model::Util::OligoSelection;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;

use LIMS2::Model::Util::OligoSelection qw/
        oligos_for_crispr_pair
        oligos_for_gibson
    /;
use LIMS2::Test model => { classname => __PACKAGE__ };


## no critic

=head1 NAME

LIMS2/t/Model/Util/OligoSelection.pm - test class for LIMS2::Model::Util::OligoSelection

=cut

sub a_test_oligos_for_gibson : Test(9) {

    my $design_id = '1002582';
    my $assembly = 'GRCm38';
    my $species = 'Mouse';

    ok my $gibson_rs =  LIMS2::Model::Util::OligoSelection::gibson_design_oligos_rs( model->schema, $design_id), 'Created resultset';
    is $gibson_rs->first->design_id, $design_id, 'can retrieve resultset for design_id ' . $design_id;

    ok my $genotyping_primer_hr = LIMS2::Model::Util::OligoSelection::oligos_for_gibson( model, { design_id => $design_id, assembly => $assembly } ), 'Generated oligo locations';
    is $genotyping_primer_hr->{'5F'}->{'chr_start'}, 141011760, '5F chromosome start co-ordinate correct';
    is $genotyping_primer_hr->{'3R'}->{'chr_start'}, 141008069, '3R chromosome start co-ordinate correct';

    ok my $gibson_design_oligos_rs = LIMS2::Model::Util::OligoSelection::gibson_design_oligos_rs( model->schema, $design_id ), 'Created resultset';
    my %gps;
    dies_ok { LIMS2::Model::Util::OligoSelection::update_primer_type( '3T', \%gps, $gibson_design_oligos_rs) } 'Searching for primer 3T fails';
    throws_ok { LIMS2::Model::Util::OligoSelection::update_primer_type( '3T', \%gps, $gibson_design_oligos_rs) } qr/No data returned/, 'Searching for primer 3T fails';

    ok my $ensembl_seq = LIMS2::Model::Util::OligoSelection::get_EnsEmbl_sequence( model, { design_id => $design_id } ), 'Sequences generated for forward and reverse strands';
}

sub b_test_oligos_for_gibson : Test(3) {

    my $design_id = '1002436';
    my $assembly = 'GRCh37';
    my $species = 'Human';

    ok my $gibson_rs =  LIMS2::Model::Util::OligoSelection::gibson_design_oligos_rs( model->schema, $design_id), 'Created resultset';
    is $gibson_rs->first->design_id, $design_id, 'can retrieve resultset for design_id ' . $design_id;
    
    #ok my $ensembl_seq = LIMS2::Model::Util::OligoSelection::get_EnsEmbl_sequence( model, { design_id => $design_id } ), 'Sequences generated for forward and reverse strands';

}

sub c_test_oligos_for_crispr_pair : Test(3) {

    my $crispr_pair_id = '19768';
    my $assembly = 'GRCh37';
    my $species = 'Human';

    ok my $crispr_pairs_rs =  LIMS2::Model::Util::OligoSelection::crispr_pair_oligos_rs( model->schema, $crispr_pair_id), 'Created crispr_pair resultset';
    is $crispr_pairs_rs->first->left_crispr_id, 65619, 'left crispr id is correct';

    #ok my $ensembl_seq = LIMS2::Model::Util::OligoSelection::get_EnsEmbl_sequence( model, { design_id => 1 } ), 'Sequences generated for forward and reverse strands';

}

sub test_pcr_genomic_check : Test(2) {
    my $species = 'Human';
    my $primer_data = {
        'left' => {'left_0' => {'seq' => 'TAGGTAGAAAACTCGCTGCT'},
            'left_1' => {'seq' => 'ACCTGATGAGATTCTCTGCTC'}},
	    'right' => {'right_0' => {'seq' => 'AGTTTCTGTGGCCATTCTCT'},
            'right_1' => {'seq' => 'TGAATGCTCAAAGGGATGAGA'}},
        'pair_count' => 2,
        'error_flag' => 'pass'
    };
    my $expected = {
        'left' => {},
        'right' => {},
        'pair_count' => 0,
        'error_flag' => 'pass'
    };
    $ENV{'BWA_GENOMIC_THRESHOLD'} = 30;
    is_deeply(LIMS2::Model::Util::OligoSelection::pcr_genomic_check($species, $primer_data), $expected, 'pcr_genomic_check returns expected data with no primers when BWA score threshold too high');
    $primer_data = {
        'left' => {'left_0' => {'seq' => 'TAGGTAGAAAACTCGCTGCT'},
            'left_1' => {'seq' => 'ACCTGATGAGATTCTCTGCTC'}},
	    'right' => {'right_0' => {'seq' => 'AGTTTCTGTGGCCATTCTCT'},
            'right_1' => {'seq' => 'TGAATGCTCAAAGGGATGAGA'}},
        'pair_count' => 2,
        'error_flag' => 'pass'
    };
    $expected = {
        'left' => {
            'left_0' => {
                'seq' => 'TAGGTAGAAAACTCGCTGCT',
                'mapped' => {
                    'start' => 158181283,
                    'sub_opt_hits' => 'X1:i:0',
                    'score' => '25',
                    'hits' => 1,
                    'chr' => '1',
                    'unique_alignment' => 1
                }
            },
            'left_1' => {
                'seq' => 'ACCTGATGAGATTCTCTGCTC',
                'mapped' => {
                    'start' => 158181803,
                    'sub_opt_hits' => 'X1:i:0',
                    'score' => '25',
                    'hits' => 1,
                    'chr' => '1',
                    'unique_alignment' => 1
                }
            }
        },
	    'right' => {
            'right_0' => {
                'seq' => 'AGTTTCTGTGGCCATTCTCT',
                'mapped' => {
                    'start' => 158181762,
                    'sub_opt_hits' => 'X1:i:0',
                    'score' => '25',
                    'hits' => 1,
                    'chr' => '1',
                    'unique_alignment' => 1
                }
            },
            'right_1' => {
                'seq' => 'TGAATGCTCAAAGGGATGAGA',
                'mapped' => {
                    'start' => 158182379,
                    'sub_opt_hits' => 'X1:i:0',
                    'score' => '25',
                    'hits' => 1,
                    'chr' => '1',
                    'unique_alignment' => 1
                }
            }
        },
        'pair_count' => 2,
        'error_flag' => 'pass'
    };
    $ENV{'BWA_GENOMIC_THRESHOLD'} = 20;
    is_deeply(LIMS2::Model::Util::OligoSelection::pcr_genomic_check($species, $primer_data), $expected, 'pcr_genomic_check returns expected data including primers when they meet the BWA score threshold');
}


## use critic

1;

__END__
