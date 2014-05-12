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

sub get_output_wells_as_string : Tests(3) {
    ok my $well = model->retrieve_well( { plate_name => 'CEPD0024_1', well_name => 'F08' } ),
        'can retrieve test well';
    ok my $children = $well->get_output_wells_as_string, 'can call get_output_wells_as_string';
    is( $children, 'FP4734[F08]', "Checking well child" );
}

sub design : Tests() {
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

sub designs : Tests() {
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

1;

__END__

