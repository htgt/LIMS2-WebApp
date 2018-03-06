package LIMS2::t::Model::Util::EPPipelineIIPlate;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Plugin::Plate qw(create_plate);
use LIMS2::Test model => { classname => __PACKAGE__ };

use strict;

BEGIN
{
    # compile time requirements
};

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

sub ep_ii_plate : Test(6) {
    my @well_data = ({
            well_name    => 'A01',
            design_id    => 1002582,
            crispr_id    => 227040,
            nuclease     => 'eSpCas9_1.1 protein Sanger',
            guided_type  => 'crRNA/tracrRNA IDT',
            cell_line    => 10,
            process_type => 'ep_pipeline_ii'
        });
    my $plate_data = {
        name       => 'ep_ii_plate',
        species    => 'Human',
        type       => 'EP_PIPELINE_II',
        created_by => 'unknown',
        wells      => \@well_data
    };

    ok my $ep_ii_plate = model->create_plate( $plate_data ),
    'Successful EP II plate creation';

    my $well = model->schema->resultset( 'Well' )->search({plate_id => $ep_ii_plate->id}, { })->single;

    my $process = model->schema->resultset( 'ProcessOutputWell' )->search({well_id => $well->id}, { })->single;

    my $dpr = model->schema->resultset( 'ProcessDesign' )->search({process_id => $process->process_id}, { })->single;
    is($dpr->design_id, 1002582, 'Design ID was stored correctly');

    my $cpr = model->schema->resultset( 'ProcessCrispr' )->search({process_id => $process->process_id}, { })->single;
    is($cpr->crispr_id, 227040, 'Crispr ID was stored correctly');

    my $clpr = model->schema->resultset( 'ProcessCellLine' )->search({process_id => $process->process_id}, { })->single;
    is($clpr->cell_line_id, 10, 'Cell line was stored correctly');

    my $npr = model->schema->resultset( 'ProcessNuclease' )->search({process_id => $process->process_id}, { })->single;
    is($npr->nuclease_id, 10, 'Nuclease ID was stored correctly');

    my $gtpr = model->schema->resultset( 'ProcessGuidedType' )->search({process_id => $process->process_id}, { })->single;
    is($gtpr->guided_type_id, 1, 'Guided Type ID was stored correctly');

}

1;

__END__

