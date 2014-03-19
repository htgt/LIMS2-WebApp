package LIMS2::t::WebApp::Controller::User::Report;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::Report;

use LIMS2::Test model => { classname => __PACKAGE__ }, 'mech';
use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/Report.pm - test class for LIMS2::WebApp::Controller::User::Report

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $OFF );    
};

=head2 before

Code to run before every test

=cut

sub before : Test(setup)
{
    #diag("running before test");
};

=head2 after

Code to run after every test

=cut

sub after  : Test(teardown)
{
    #diag("running after test");
};


=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup)
{
    #diag("running before all tests");
};

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown  : Test(shutdown)
{
    #diag("running after all tests");
};

=head2 all_tests

Code to execute all tests

=cut

sub all_tests  : Test(32)
{
    my $mech = mech();

    {
    note('Human DesignPlate report ok');
    $mech->get_ok('/user/report/sync/DesignPlate?plate_id=5668');
    $mech->text_contains('Design Plate HG1');
    $mech->text_contains('POLK');
    $mech->text_contains('Human-Core/Mutation');
    }


    {
    note('CrisprPlate report ok');
    $mech->get_ok('/user/report/sync/CrisprPlate?plate_id=5670');
    $mech->text_contains('Crispr Plate HCL1');
    $mech->text_contains('POLK');
    $mech->text_contains('Human-Core/Mutation');  
    }

    {
    note('CrisprVectorPlate report ok');
    $mech->get_ok('/user/report/sync/CrisprVectorPlate?plate_id=5834');
    $mech->text_contains('Crispr Vector Plate HCL0001_A_7');
    $mech->text_contains('ERAP2');
    $mech->text_contains('Human-Core/Pathogen');    
    }

    {
    note('AssemblyPlate report ok');
    $mech->get_ok('/user/report/sync/AssemblyPlate?plate_id=5950');
    $mech->text_contains('Crispr Assembly Plate HG1_ASSEMBLY_TEST');
    $mech->text_contains('ERAP2');
    $mech->text_contains('Human-Core/Pathogen');
    $mech->text_contains('HCL1[A04]');      
    }    

    {
    note('CrisprEPPlate report ok');
    $mech->get_ok('/user/report/sync/CrisprEPPlate?plate_id=5952');
    $mech->text_contains('Crispr Electroporation Plate HG1_EP_TEST');
    $mech->text_contains('ERAP2');
    $mech->text_contains('Human-Core/Pathogen');
    $mech->text_contains('Cas9 Church D10A (+neo)');
    }

    {
    note('FinalVectorPlate report ok');
    $mech->get_ok('/user/report/sync/FinalVectorPlate?plate_id=5945');
    $mech->text_contains('Final Vector Plate HG1_FINAL_TEST');
    $mech->text_contains('ERAP2');
    $mech->text_contains('Human-Core/Pathogen');
    $mech->text_contains('[left:HCLS0001_B_1_A04-right:HCRS0001_A_1_A04]');
    } 

    {
    note('FinalVectorPickPlate report ok');
    $mech->get_ok('/user/report/sync/FinalPickVectorPlate?plate_id=5946');
    $mech->text_contains('Final Pick Vector Plate HG1_FINAL_PICK_TEST');
    $mech->text_contains('ERAP2');
    $mech->text_contains('Human-Core/Pathogen');
    $mech->text_contains('[left:HCLS0001_B_1_A04-right:HCRS0001_A_1_A04]');
    } 
}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

