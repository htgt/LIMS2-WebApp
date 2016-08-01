package LIMS2::t::Model::Schema::Result::Well;
use strict;

use base qw(Test::Class);
use Test::Most;
use LIMS2::Test model => { classname => __PACKAGE__ };

=head1 NAME

LIMS2/t/Model/Schema/Result/Well.pm - test class for LIMS2::Model::Schema::Result::Well

=head1 DESCRIPTION

Test module structured for running under Test::Class

=cut

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

sub get_output_wells_as_string : Tests(3) {
    ok my $well = model->retrieve_well( { plate_name => 'CEPD0024_1', well_name => 'F08' } ),
        'can retrieve test well';
    ok my $children = $well->get_output_wells_as_string, 'can call get_output_wells_as_string';
    is( $children, 'FP4734[F08]', "Checking well child" );
}

sub design : Tests(7) {
    ok my $well = model->retrieve_well( { plate_name => 'PCS00037_A', well_name => 'A03' } ),
        'can retrive test well';

    ok my $design = $well->design, "can retrieve design from $well";
    is $design->id, 42232, 'we get expected design from well';

    ok my $well2 = model->retrieve_well( { plate_name => 'SHORTEN_ARM_INT', well_name => 'F08' } ),
        'can retrive test well with short arm design';

    ok my $design2 = $well2->design, "can retrieve a design from well $well2";
    is $design2->id, 99992, 'we get expected design from well';
    is $design2->global_arm_shortened, $design->id, '.. and this is the right short arm design';
}

sub designs : Tests(9) {
    ok my $well = model->retrieve_well( { plate_name => 'PCS00037_A', well_name => 'A03' } ),
        'can retrive test well';

    ok my @designs = $well->designs, "can call designs from $well";
    is scalar( @designs ), 1, 'we only have one design';
    is $designs[0]->id, 42232, '.. and that is the correct design';

    ok my $sep_well= model->retrieve_well( { plate_name => 'SEP0029_7', well_name => 'A01' } ),
        'can retrive sep test well';

    ok my @sep_designs = $sep_well->designs, "can call designs from $sep_well";
    is scalar( @sep_designs ), 2, 'we have two designs from the sep well';
    is $sep_designs[0]->id, 95204, '.. first design is correct';
    is $sep_designs[1]->id, 95204, '.. second design is correct';
}

sub final_pick_dna_well_status : Tests(16) {
    my %well_hash = ( plate_name => 'ETGRQ0007_A_1', well_name => 'C01' );
    my %parent_hash = ( plate_name => 'ETGRD0007_A_1', well_name => 'C01' );

    ok my $well = model->retrieve_well({ %well_hash }) ,
        'got well from DNA plate';
    ok my $parent_well = model->retrieve_well({ %parent_hash }) ,
        'got well from FINAL_PICK parent plate';
    is $well->well_dna_status, undef, 'DNA well has no dna_status';
    is $well->well_dna_quality, undef, 'DNA well has no dna_quality';
    is $parent_well->well_qc_sequencing_result, undef, 'Parent well has no qc seq result';
    $well->compute_final_pick_dna_well_accepted();
    is $well->accepted, 0, 'well is not accepted';

    # Add related DNA and QC scores
    ok model->create_well_qc_sequencing_result({ %parent_hash, pass => '1', created_by => 'test_user@example.org', test_result_url =>'http://www.test.com/stuff' }),
        'created parent well qc seq result';
    $well->compute_final_pick_dna_well_accepted();
    $well = model->retrieve_well({ %well_hash });
    is $well->accepted, 0, 'well is not accepted';

    # compute_final_pick_dna_well_accepted will be run by create_well_dna_status
    ok model->create_well_dna_status({ %well_hash, pass => '1', created_by => 'test_user@example.org'}),
        'created well dna status';
    $well = model->retrieve_well({ %well_hash });
    is $well->accepted, 0, 'well is not accepted';

    # compute_final_pick_dna_well_accepted will be run by create_well_dna_quality
    ok model->create_well_dna_quality({ %well_hash, egel_pass => 1, created_by => 'test_user@example.org'}),
        'created well dna quality';
    $well = model->retrieve_well({ %well_hash });
    is $well->accepted, 1, 'well is accepted';

    model->delete_well_dna_status({ %well_hash });
    ok model->create_well_dna_status({ %well_hash, pass => '0', created_by => 'test_user@example.org'}),
        'created fail well dna status';
    $well = model->retrieve_well({ %well_hash });
    is $well->accepted, 0, 'well is not accepted';

    ok my $well2 = model->retrieve_well( { plate_name => 'PCS00037_A', well_name => 'A03' } ),
        'can retrieve non-DNA test well';
    $well2->compute_final_pick_dna_well_accepted();
    is $well2->accepted, 0, 'well is not accepted';

}
1;

__END__

