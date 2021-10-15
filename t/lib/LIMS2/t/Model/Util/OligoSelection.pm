package LIMS2::t::Model::Util::OligoSelection;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;

use LIMS2::Model::Util::OligoSelection qw/
        oligos_for_crispr_pair
    /;
        #oligos_for_gibson
use LIMS2::Test model => { classname => __PACKAGE__ };


## no critic

=head1 NAME

LIMS2/t/Model/Util/OligoSelection.pm - test class for LIMS2::Model::Util::OligoSelection

=cut

sub a_test_oligos_for_gibson : Test(11) {

    my $design_id = '1002582';
    my $assembly = 'GRCm38';
    my $species = 'Mouse';

    ok my $gibson_rs =  LIMS2::Model::Util::OligoSelection::gibson_design_oligos_rs( model->schema, $design_id), 'Created resultset';
    is $gibson_rs->first->design_id, $design_id, 'can retrieve resultset for design_id ' . $design_id;

    #ok my $genotyping_primer_hr = LIMS2::Model::Util::OligoSelection::oligos_for_gibson(
        #{ schema => model->schema, design_id => $design_id, assembly => $assembly }
    #), 'Generated oligo locations';
    #is $genotyping_primer_hr->{'5F'}->{'chr_start'}, 141011760, '5F chromosome start co-ordinate correct';
    #is $genotyping_primer_hr->{'3R'}->{'chr_start'}, 141008069, '3R chromosome start co-ordinate correct';

    ok my $gibson_design_oligos_rs = LIMS2::Model::Util::OligoSelection::gibson_design_oligos_rs( model->schema, $design_id ), 'Created resultset';
    my %gps;
    #dies_ok { LIMS2::Model::Util::OligoSelection::update_primer_type( '3T', \%gps, $gibson_design_oligos_rs) } 'Searching for primer 3T fails';
    throws_ok { LIMS2::Model::Util::OligoSelection::update_primer_type( '3T', \%gps, $gibson_design_oligos_rs) } qr/No data returned/, 'Searching for primer 3T fails';

    #ok my $ensembl_seq = LIMS2::Model::Util::OligoSelection::get_EnsEmbl_sequence({ schema => model->schema, design_id => $design_id }), 'Sequences generated for forward and reverse strands';
    #ok my $primer_results = LIMS2::Model::Util::OligoSelection::pick_genotyping_primers({
    #'schema' => model->schema,
    #'design_id' => $design_id,
    #'species' => $species
    #}), 'Running primer3';
    #is $primer_results->{'pair_count'}, 6, 'Correct number of primer pairs found';
    #is $primer_results->{'left'}->{'left_1'}->{'seq'}, 'AACCAGAAAAATGTCAGGACAAGAC', 'Left rank 1 primer correct';
}

sub b_test_oligos_for_gibson : Test(6) {

    my $design_id = '1002436';
    my $assembly = 'GRCh37';
    my $species = 'Human';

    ok my $gibson_rs =  LIMS2::Model::Util::OligoSelection::gibson_design_oligos_rs( model->schema, $design_id), 'Created resultset';
    is $gibson_rs->first->design_id, $design_id, 'can retrieve resultset for design_id ' . $design_id;
    
    #ok my $ensembl_seq = LIMS2::Model::Util::OligoSelection::get_EnsEmbl_sequence({ schema => model->schema, design_id => $design_id }), 'Sequences generated for forward and reverse strands';
    #ok my $primer_results = LIMS2::Model::Util::OligoSelection::pick_genotyping_primers({
    # 'schema' => model->schema,
    #'design_id' => $design_id,
    #'species' => $species
    #}), 'Running primer3';
    #is $primer_results->{'pair_count'}, 6, 'Correct number of primer pairs found';
    #is $primer_results->{'left'}->{'left_0'}->{'seq'}, 'ATGTTATTTCCCCTATGAGCTCCAG', 'Left rank 0 primer correct';

}

sub c_test_oligos_for_crispr_pair : Test(2) {

    my $crispr_pair_id = '19768';
    my $assembly = 'GRCh37';
    my $species = 'Human';

    ok my $crispr_pairs_rs =  LIMS2::Model::Util::OligoSelection::crispr_pair_oligos_rs( model->schema, $crispr_pair_id), 'Created crispr_pair resultset';
    is $crispr_pairs_rs->first->left_crispr_id, 65619, 'left crispr id is correct';
    
    #ok my $ensembl_seq = LIMS2::Model::Util::OligoSelection::get_EnsEmbl_sequence({ schema => model->schema, design_id => $design_id }), 'Sequences generated for forward and reverse strands';
    #ok my $primer_results = LIMS2::Model::Util::OligoSelection::pick_genotyping_primers( model->schema, $design_id, $species ), 'Running primer3';
    #is $primer_results->{'pair_count'}, 6, 'Correct number of primer pairs found';
    #is $primer_results->{'left'}->{'left_0'}->{'seq'}, 'ATGTTATTTCCCCTATGAGCTCCAG', 'Left rank 0 primer correct';

}

## use critic

1;

__END__
