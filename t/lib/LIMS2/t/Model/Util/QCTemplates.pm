package LIMS2::t::Model::Util::QCTemplates;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::QCTemplates qw( create_qc_template_from_wells qc_template_display_data eng_seq_data );
use LIMS2::Test;
use JSON;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/QCTemplates.pm - test class for LIMS2::Model::Util::QCTemplates

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN {

    # compile time requirements
    #{REQUIRE_PARENT}
}

=head2 before

Code to run before every test

=cut

sub before : Test(setup) {

    #diag("running before test");
}

=head2 after

Code to run after every test

=cut

sub after : Test(teardown) {

    #diag("running after test");
}

=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup) {

    #diag("running before all tests");
}

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown : Test(shutdown) {

    #diag("running after all tests");
}

=head2 all_tests

Code to execute all tests

=cut

sub all_tests : Test(1) {
    ok( 1, "Test of LIMS2::Model::Util::QCTemplates" );
}

sub qc_template_display_data_test : Test(4) {

    ok my $template = model->retrieve_qc_template( { id => 200 } ), 'can retrieve qc_template';
    ok my ( $well_data, $has_crispr_data )
        = qc_template_display_data( model, $template, 'mouse' ),
        'can call qc_template_display_data';

    ok !$has_crispr_data, 'not a qc template with crispr data';
    is_deeply $well_data,
        [
        {   backbone     => 'L3L4_pD223_DTA_T_spec',
            cassette     => 'L1L2_Bact_P',
            cassette_new => 'L1L2_Bact_P',
            id           => 3265,
            recombinase  => '',
            source_plate => 'PCS00148_A',
            source_well  => 'F02',
            well_name    => 'A01',
            design_id    => '372441',
            design_phase => '-1',
            gene_ids     => '',
            gene_symbols => '',
        },
        {   backbone     => 'L3L4_pD223_DTA_T_spec',
            cassette     => 'L1L2_Bact_P',
            cassette_new => 'L1L2_Bact_P',
            id           => 3266,
            recombinase  => '',
            source_plate => 'MOHPCS0001_A',
            source_well  => 'D04',
            well_name    => 'A02',
            design_id    => '372441',
            design_phase => '-1',
            gene_ids     => '',
            gene_symbols => '',
        }
        ],
        'we get expected data generated for qc_template';
}

sub eng_seq_data_test : Test(10) {

    ok my $template_well = model->retrieve_qc_template_well( { id => 3265 } ),
        'can retrieve qc_template_well';
    ok my $eng_seq_params = decode_json( $template_well->qc_eng_seq->params ),
        'can grab eng seq params from template well';

    my %info;
    lives_ok {
        eng_seq_data( $template_well, \%info, 1, $eng_seq_params )
    } 'can call eng_seq_data';

    is $info{cassette}, 'L1L2_Bact_P', 'cassette correct';
    is $info{backbone}, 'L3L4_pD223_DTA_T_spec', 'backbone correct';
    is $info{recombinase}, '', 'recombinase correct';

    my %info_2;
    lives_ok {
        eng_seq_data( $template_well, \%info_2, 0, $eng_seq_params )
    } 'can call eng_seq_data';

    is $info_2{cassette}, 'LoxP', 'cassette correct for design which is not cassette_first';
    is $info_2{backbone}, 'L3L4_pD223_DTA_T_spec', 'backbone still the same';
    is $info_2{recombinase}, '', 'recombinase still the same';

}

## use critic

1;

__END__
