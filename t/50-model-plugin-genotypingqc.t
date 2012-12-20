#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most;
use Try::Tiny;
use Data::Dumper;
use File::Temp ':seekable';

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
    
	# test assay result upload with missing data
	ok my $test_file2 = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file2->print(join ",", "well_name",      "loxp_pass", "loxp_copy_number");
	$test_file2->print("\n");
	$test_file2->print(join ",", $plate."_".$well, "pass"     , "2.1"             );
	
	my $name2 = $test_file2->filename;
	$test_file2->close;
    open (my $fh2, "<", $name2);
    
    throws_ok{
    	model->update_genotyping_qc_data({ csv_fh => $fh2, created_by => 'test_user@example.org' })
    }qr/No loxp .* value found/;
    	
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
	$test_file4->print(join ",", "well_name",      "gf4", "gr3");
	$test_file4->print("\n");
	$test_file4->print(join ",", $plate."_".$well, "yes", "yes"       );
	
	my $name4 = $test_file4->filename;
	$test_file4->close;
    open (my $fh4, "<", $name4);
    
    ok my $messages4 = model->update_genotyping_qc_data({ csv_fh => $fh4, created_by => 'test_user@example.org'}),
        "primer bands updated from CVS file";
    ok my $bands = model->retrieve_well_primer_bands($well_params), "primer bands found";
    my ($gf4) = grep { $_->primer_band_type_id eq "gf4" } @$bands;
    my ($gr3) = grep { $_->primer_band_type_id eq "gr3" } @$bands;
    is $gf4->pass, 1, "gf4 primer band created";
    is $gr3->pass, 1, "gr3 primer band created";
    
}


done_testing();