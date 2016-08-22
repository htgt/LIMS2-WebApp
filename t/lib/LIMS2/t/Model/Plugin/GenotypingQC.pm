package LIMS2::t::Model::Plugin::GenotypingQC;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Plugin::GenotypingQC;

use LIMS2::Test;
use Try::Tiny;
use File::Temp ':seekable';

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Plugin/GenotypingQC.pm - test class for LIMS2::Model::Plugin::GenotypingQC

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

sub all_tests  : Test(21)
{

    note( "Testing Genotyping QC data update");
    {

	    ok my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);

	    my $plate = "SEP0006";
	    my $well = "A01";

	    $test_file->print(join ",", "well_name",      "targeting_pass", "targeting-puro_pass", "chromosome_fail", "random");
	    $test_file->print("\n");
	    $test_file->print(join ",", $plate."_".$well, "pass"          , "pass b"             ,  "3"             , "nonsense");

	    my $name = $test_file->filename;
	    $test_file->close;
	open (my $fh, "<", $name);

	ok my $messages = model->update_genotyping_qc_data({ csv_fh => $fh, created_by => 'test_user@example.org' }),
	    "overall genotyping results updated from CSV file";

	    # test for ignored columns message
	    my $message_string = join " ", @$messages;
	    like $message_string, qr/The following unrecognized columns were ignored: random/,
		"column named random was ignored";

	    # test targ pass, targ puro pass, chromosome fail update
	    my $well_params = { plate_name => $plate, well_name => $well };
	    ok my $targ_pass = model->retrieve_well_targeting_pass($well_params), "targeting pass exists";
	    is $targ_pass->result, "pass", "targeting pass result == pass";

	ok my $puro_pass = model->retrieve_well_targeting_puro_pass($well_params), "targeting-puro pass exists";
	is $puro_pass->result, "passb", "targeting-puro pass result == passb";

	ok my $chr_fail = model->retrieve_well_chromosome_fail($well_params), "chromosome fail exists";
	is $chr_fail->result, "3", "chromosome fail == 3";

	    # test assay result upload with invalid data
	    ok my $test_file2 = File::Temp->new or die('Could not create temp test file ' . $!);
	    $test_file2->print(join ",", "well_name",      "loxp_pass", "loxp_copy_number, loxp_copy_number_range");
	    $test_file2->print("\n");
	    $test_file2->print(join ",", $plate."_".$well, "pass"     , "2.1",             'Failed'             );

	    my $name2 = $test_file2->filename;
	    $test_file2->close;
	open (my $fh2, "<", $name2);

	throws_ok{
	    model->update_genotyping_qc_data({ csv_fh => $fh2, created_by => 'test_user@example.org' })
	}qr/must be a number for well/;

	    # test assay result upload with complete data
	    ok my $test_file3 = File::Temp->new or die('Could not create temp test file ' . $!);
	    $test_file3->print(join ",", "well_name",      "loxp_pass", "loxp_copy_number", "loxp_copy_number_range");
	    $test_file3->print("\n");
	    $test_file3->print(join ",", $plate."_".$well, "pass"     , "2.1"             , "0.5"                   );

	    my $name3 = $test_file3->filename;
	    $test_file3->close;
	open (my $fh3, "<", $name3);

	ok my $messages3 = model->update_genotyping_qc_data({ csv_fh => $fh3, created_by => 'test_user@example.org'}),
	    "loxp genotyping results updated from CSV file";
	ok my $loxp = model->retrieve_well_genotyping_result({ %$well_params, genotyping_result_type_id => "loxp"}),
	    "loxp genotyping result exists";
	is $loxp->copy_number, "2.1", "loxp copy_number value as expected";

	    # test well primer band update
	    ok my $test_file4 = File::Temp->new or die('Could not create temp test file ' . $!);
	    $test_file4->print(join ",", "well_name",      "gf4", "gr3", "lr_pcr_pass");
	    $test_file4->print("\n");
	    $test_file4->print(join ",", $plate."_".$well, "pass", "pass", "pass");

	    my $name4 = $test_file4->filename;
	    $test_file4->close;
	open (my $fh4, "<", $name4);

	ok my $messages4 = model->update_genotyping_qc_data({ csv_fh => $fh4, created_by => 'test_user@example.org'}),
	    "primer bands updated from CVS file";
	ok my $bands = model->retrieve_well_primer_bands($well_params), "primer bands found";
	my ($gf4) = grep { $_->primer_band_type_id eq "gf4" } @$bands;
	my ($gr3) = grep { $_->primer_band_type_id eq "gr3" } @$bands;
    my ($lr_pcr_pass) = grep { $_->primer_band_type_id eq "lr_pcr_pass" } @$bands;
	is $gf4->pass, 'pass', "gf4 primer band created";
	is $gr3->pass, 'pass', "gr3 primer band created";
    is $lr_pcr_pass->pass, 'pass', "lr_pcr_pass created";

    }

}

sub more_tests : Test(6)
{
    note( 'Testing more aspects of Genotyping QC data update');
    my $hash_ref;
    $hash_ref->{'Keys Should be Lowercase'} = 1;
    ok my $hash_ref_returned = model->hash_keys_to_lc( $hash_ref ), 'converting hash keys to lowercase';
    my @key = keys(%{$hash_ref_returned});

    is $key[0], 'keys should be lowercase', 'hash keys converted to lowercase';

    my $plate = 'SEP0006';
    my $well  = 'A01';
    my $well_params = { plate_name => $plate, well_name => $well };

    ok my $test_file = (File::Temp->new or die('Could not create temp test file ' . $!)), 'temporary test file created';
	    $test_file->print(join ',', 'well_name',      'Neo_pass', 'Neo_copy_number', 'Neo_copy_number_range');
	    $test_file->print("\n");
	    $test_file->print(join ',', $plate.'_'.$well, 'absent'  , '2.1'            , '0.5'                  );
	my $name = $test_file->filename;
	    $test_file->close;
	open (my $fh, '<', $name);

	ok my $messages = model->update_genotyping_qc_data({ csv_fh => $fh, created_by => 'test_user@example.org'}),
	    'Neo genotyping results updated from CSV file';
    close $fh;
	ok my $neo = model->retrieve_well_genotyping_result({ %$well_params, genotyping_result_type_id => "neo"}),
	    'neo genotyping result exists';
	is $neo->call, 'absent', "neo pass value is 'absent'";


}


sub lrpcr_tests : Test(4)
{
    note( 'Testing LRPCR aspects of Genotyping QC data update');

    my $plate = 'SEP0006';
    my $well  = 'A01';
    my $well_params = { plate_name => $plate, well_name => $well };

    ok my $test_file = (File::Temp->new or die('Could not create temp test file ' . $!)), 'temporary test file created';
        $test_file->print(join ",", "well_name",      "targeting_pass", "targeting-puro_pass", "chromosome_fail", "random");
        $test_file->print("\n");
        $test_file->print(join ",", $plate."_".$well, "lrpcr_pass"          , "pass b"             ,  "3"             , "nonsense");
    my $name = $test_file->filename;
        $test_file->close;
    open (my $fh, '<', $name);

    ok my $messages = model->update_genotyping_qc_data({ csv_fh => $fh, created_by => 'test_user@example.org'}),
        'lrpcr_pass genotyping results updated from CSV file';
    close $fh;
    ok my $targ_pass = model->retrieve_well_targeting_pass($well_params), "targeting pass exists";
    is $targ_pass->result, "lrpcr_pass", "targeting pass result == lrpcr_pass";

}
=head1 AUTHOR

Anna Farne
David Parry-Smith
Lars G. Erlandsen

=cut

## use critic

1;

__END__

