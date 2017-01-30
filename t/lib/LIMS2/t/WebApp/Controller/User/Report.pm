package LIMS2::t::WebApp::Controller::User::Report;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test model => { classname => __PACKAGE__ }, 'mech';
use strict;

=head1 NAME

LIMS2/t/WebApp/Controller/User/Report.pm - test class for LIMS2::WebApp::Controller::User::Report

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($OFF);
}

sub all_tests : Test(40) {
    my $mech = mech();

    {
        note('Human DesignPlate report ok');
        $mech->get_ok('/user/report/sync/DesignPlate?plate_id=5668');
        $mech->text_contains('Design Plate HG1');
        $mech->text_contains('HGNC:253');
        $mech->text_contains('All/Mutation');
    }

    {
        note('CrisprPlate report ok');
        $mech->get_ok('/user/report/sync/CrisprPlate?plate_id=5670');
        $mech->text_contains('Crispr Plate HCL1');
        $mech->text_contains('HGNC:253');
        $mech->text_contains('All/Mutation');
    }

    {
        note('CrisprVectorPlate report ok');
        $mech->get_ok('/user/report/sync/CrisprVectorPlate?plate_id=5834');
        $mech->text_contains('Crispr Vector Plate HCL0001_A_7');
        $mech->text_contains('HGNC:29499');
        $mech->text_contains('All/Pathogen');
    }

    {
        note('DNAPlate report ok for final pick derived plate');
        $mech->get_ok('/user/report/sync/DNAPlate?plate_id=5960');
        $mech->text_contains('DNA Plate HG1_DNA');
        $mech->text_contains('HGNC:29499');
        $mech->text_contains('All/Pathogen');
    }

    {
        note('DNAPlate report ok for crispr_v derived plate');
        $mech->get_ok('/user/report/sync/DNAPlate?plate_id=5961');
        $mech->text_contains('DNA Plate HCL_DNA');
        $mech->text_contains('HGNC:29499');
        $mech->text_contains('All/Pathogen');
    }

    {
        note('AssemblyPlate report ok');
        $mech->get_ok('/user/report/sync/AssemblyPlate?plate_id=5965');
        $mech->text_contains('Crispr Assembly Plate HG1_DNA_ASSEMBLY');
        $mech->text_contains('HGNC:29499');
        $mech->text_contains('All/Pathogen');
        $mech->text_contains('HCL1_A04');
    }

    {
        note('CrisprEPPlate report ok');
        $mech->get_ok('/user/report/sync/CrisprEPPlate?plate_id=5967');
        $mech->text_contains('Crispr Electroporation Plate HG1_EP_TEST');
        $mech->text_contains('HGNC:29499');
        $mech->text_contains('All/Pathogen');
        $mech->text_contains('Cas9 Church D10A (+bsd)');
    }

    {
        note('FinalVectorPlate report ok');
        $mech->get_ok('/user/report/sync/FinalVectorPlate?plate_id=5945');
        $mech->text_contains('Final Vector Plate HG1_FINAL_TEST');
        $mech->text_contains('HGNC:29499');
        $mech->text_contains('All/Pathogen');
        $mech->text_contains('[left:HCLS0001_B_1_A04-right:HCRS0001_A_1_A04]');
    }

    {
        note('FinalVectorPickPlate report ok');
        $mech->get_ok('/user/report/sync/FinalPickVectorPlate?plate_id=5946');
        $mech->text_contains('Final Pick Vector Plate HG1_FINAL_PICK_TEST');
        $mech->text_contains('HGNC:29499');
        $mech->text_contains('All/Pathogen');
        $mech->text_contains('[left:HCLS0001_B_1_A04-right:HCRS0001_A_1_A04]');
    }
}

1;

__END__

