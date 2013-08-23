package LIMS2::t::Model::Util::DataUpload;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::DataUpload qw( parse_csv_file upload_plate_dna_status );

use LIMS2::Test;
use Try::Tiny;
use IO::File;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/DataUpload.pm - test class for LIMS2::Model::Util::DataUpload

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

sub all_tests  : Test(12)
{

    note('Testing parse_csv_file');

    {
	note('Test files with different newline endings are parsed correctly');

	my @test_files = qw( csv_upload_linux csv_upload_win csv_upload_mac );

	for my $test_file ( @test_files ) {
	    my $data_fh = test_data( $test_file . '.csv' );

	    my $csv_data;
	    lives_ok {
		$csv_data = parse_csv_file( $data_fh )
	    } 'can parse csv file';

	    is_deeply $csv_data, [
		{ comments => 'this is a proper pass', dna_status_result => 'pass', well_name => 'B01' },
		{ dna_status_result => 'pass', well_name => 'E06' },
		{ dna_status_result => 'fail', well_name => 'G03' },
	    ], 'data array returned is as expected';

	}

	my $empty_test_file = IO::File->new_tmpfile or die('Could not create temp test file ' . $!);

	throws_ok {
	    parse_csv_file( $empty_test_file )
	} qr/Invalid csv file/;

	my $no_data_test_file = IO::File->new_tmpfile or die('Could not create temp test file ' . $!);
	$no_data_test_file->print('Test File');
	$no_data_test_file->seek( 0, 0 );
	throws_ok {
	    parse_csv_file( $no_data_test_file )
	} qr/No data in csv file/;

    }

    note('Testing upload_plate_dna_status');

    {
	my $data_fh = test_data('csv_upload_linux.csv');

	lives_ok {
	    upload_plate_dna_status( model,
		{   csv_fh     => $data_fh,
		    plate_name => 'MOHFAQ0001_A_2',
		    user_name  => 'test_user@example.org'
		}
	    );
	} 'can upload plate dna statuses';

	$data_fh->seek( 0,0 );
	throws_ok {
	    upload_plate_dna_status( model,
		{   csv_fh     => $data_fh,
		    plate_name => '111',
		    user_name  => 'test_user@example.org'
		}
	    );
	} qr/Invalid plate type DESIGN for plate 111, expected plates of type\(s\) DNA/;

	my $invalid_data_fh = test_data('invalid_csv_upload.csv');
	throws_ok {
	    upload_plate_dna_status( model,
		{   csv_fh     => $invalid_data_fh,
		    plate_name => 'MOHFAQ0001_A_2',
		    user_name  => 'test_user@example.org'
		}
	    );
	} qr/dna_status_result, is invalid: pass_or_fail/;

    }

    {
	lives_ok{
	    model->delete_well_dna_status( { plate_name => 'MOHFAQ0001_A_2', well_name => 'B01' } );
	    model->delete_well_dna_status( { plate_name => 'MOHFAQ0001_A_2', well_name => 'E06' } );
	    model->delete_well_dna_status( { plate_name => 'MOHFAQ0001_A_2', well_name => 'G03' } );
	} 'delete well dna statuses just added';

    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

