package LIMS2::t::WebApp::Controller::PublicReports;

use base qw(Test::Class);
use Test::Most;
use HTML::TableExtract;
use Array::Compare;
use JSON qw(decode_json);

use LIMS2::WebApp::Controller::PublicReports;

use LIMS2::Test model => { classname => __PACKAGE__ };
use strict;


## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/PublicReports.pm - test class for LIMS2::WebApp::Controller::PublicReports

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

sub all_tests  : Tests {
    ok(1, "Test of LIMS2::WebApp::Controller::PublicReports");

    note('Well genotyping info for pipeline 1');
    {
        my $barcode = "1117507060";
        my $well_name = "A01";
        my $plate_name = "HUFP0043_1_A";

        my $mech = LIMS2::Test::mech();
        $mech->get_ok('/public_reports/well_genotyping_info_search');
        $mech->title_is('Design Target Report');
        $mech->get_ok('/public_reports/well_genotyping_info/1117507060');
        $mech->content_contains($plate_name);
        $mech->content_contains($well_name);
        $mech->content_contains('KOLF_2_C1');
        $mech->content_contains('CGGTCTCCATCCTACAAACA CGG');
        $mech->content_contains('HGNC:30801');

        $mech->get_ok('/public_reports/well_genotyping_info/HUFP0043_1_A/A01');
        $mech->content_contains($barcode);
        $mech->content_contains('KOLF_2_C1');
        $mech->content_contains('CGGTCTCCATCCTACAAACA CGG');
        $mech->content_contains('HGNC:30801');
    }

    note('Well genotyping info for pipeline 2 - General Info');
    {
        my $plate_name = "HUPFP1234A1";
        my $well_name = "A01";
        my $mech = LIMS2::Test::mech();

        $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

        my $page = $mech->content;

        assert_table_has_row_with_contents(
            $page,
	    "genotyping_table2",
	    ["Plate Name", "HUPFP1234A1"],
        );

        assert_table_has_row_with_contents(
            $page,
	    "genotyping_table2",
	    ["Well Name", "A01"],
        );

        assert_table_has_row_with_contents(
            $page,
	    "genotyping_table2",
	    ["Clone ID", "HUPFP1234A1_A01"],
        );

        assert_table_has_row_with_contents(
            $page,
	    "genotyping_table2",
	    ["Gene ID", "HGNC:15766"],
        );

        assert_table_has_row_with_contents(
            $page,
	    "genotyping_table2",
	    ["Gene Symbol", "ADNP"],
        );

        assert_table_has_row_with_contents(
            $page,
	    "genotyping_table2",
	    ["Species", "Human"],
        );

        assert_table_has_row_with_contents(
            $page,
	    "genotyping_table2",
	    ["Cell Line", "KOLF_2_C1"],
        );
    }

    note('Well genotyping info for pipeline 2 - Design Info');
    {
        my $plate_name = "HUPFP1234A1";
        my $well_name = "A01";
        my $mech = LIMS2::Test::mech();

        $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

        my $page = $mech->content();

        $mech->content_contains("Design Information");

        assert_table_has_row_with_contents(
            $page,
	    "design",
	    ["Design ID", "10000257"],
        );

        assert_table_has_row_with_contents(
            $page,
	    "design",
	    ["Design Type", "miseq-nhej"],
        );
    }

    note('Well genotyping info for pipeline 2 - Primer Info');
    {
        my $plate_name = "HUPFP1234A1";
        my $well_name = "A01";
        my $mech = LIMS2::Test::mech();

        $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

        my $page = $mech->content;

        $mech->content_contains("Genotyping Primers");

        assert_table_has_row_with_contents(
            $page,
	    "primers",
	    ["Type", "Chromosome", "Start", "End", "Sequence in 5'-3' orientation"],
        );

        assert_table_has_row_with_contents(
            $page,
	    "primers",
	    ["EXF", "20", "50893491", "50893510", "TTTAACTGGCCCGATGAGAG"],
        );
        assert_table_has_row_with_contents(
            $page,
	    "primers",
	    ["INF", "20", "50893696", "50893715", "CCTGGCCTACAGATTTGACT"],
        );
        # INR and EXR are on the negative strand, so the sequence is the
        # reverse complement of what is stored in LIMS2.
        assert_table_has_row_with_contents(
            $page,
	    "primers",
	    ["INR", "20", "50893896", "50893915", "CCCTTGATGCTAATTGCTCC"],
        );
        assert_table_has_row_with_contents(
            $page,
	    "primers",
	    ["EXR", "20", "50894054", "50894073", "ATGCCCGAGAAGAGAGTAGT"],
        );
    }

    note('Well genotyping info for pipeline 2 - HDR Template');
    {
        my $plate_name = "HUPFP7890A1";
        my $well_name = "A01";
        my $mech = LIMS2::Test::mech();

        $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

        $mech->content_contains("HDR Template");
        $mech->content_contains(
            "ATGGTCGCAGGTTCACCCGCCCGTTGTCCCAGCAGCGTCGGGAGCTGCGGCCGTCTCCGA" .
	    "CCGGTGTGGGGCAGCGGGCCTGTGAGACAGGACGGGCTGCCCGTGGGGGCAGCGGGT"
        );
    }

    note('Well genotyping info for pipeline 2 - CRISPRs');
    {
        my $plate_name = "HUPFP1234A1";
        my $well_name = "A01";
        my $mech = LIMS2::Test::mech();

        $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

	my $page = $mech->content();

        $mech->content_contains("CRISPR");

        assert_table_has_row_with_contents(
            $page,
            "crispr",
            ["LIMS2 ID", "187477"],
	);

        assert_table_has_row_with_contents(
            $page,
            "crispr",
            ["WGE ID", "1174490822"],
	);
        my $wge_link = $mech->find_link(text => "1174490822");
        ok(defined $wge_link, "WGE ID should be a link");
        is(
            $wge_link->url(),
            "https://wge.stemcell.sanger.ac.uk/crispr/1174490822",
            "Should link to WGE CRISPR page.",
        );

        assert_table_has_row_with_contents(
            $page,
            "crispr",
            ["Location Type", "Exonic"],
	);

        assert_table_has_row_with_contents(
            $page,
            "crispr",
            ["Location", "20:50893836-50893858"],
	);

	{  # Negative strand
            my $plate_name = "HUPFP1234A1";
            my $well_name = "A01";
            my $mech = LIMS2::Test::mech();

            $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

	    my $page = $mech->content();

            assert_table_has_row_with_contents(
                $page,
                "crispr",
                ["Strand", "-"],
	    );

            assert_table_has_row_with_contents(
                $page,
                "crispr",
                ["Sequence in 5'-3' orientation", "AGGATCGGTTCCCTTGCTTCTGG"],
            );
	}

	{  # Positive strand
            my $plate_name = "HUPFP1235A1";
            my $well_name = "A01";
            my $mech = LIMS2::Test::mech();

            $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

	    my $page = $mech->content();

            assert_table_has_row_with_contents(
                $page,
                "crispr",
                ["Strand", "+"],
	    );

            assert_table_has_row_with_contents(
                $page,
                "crispr",
                ["Sequence in 5'-3' orientation", "GCAAGGGAACCGATCCTTGGTGG"],
            );
	}
    }

    note('Well genotyping info for pipeline 2 - MiSeq QA');
    {
	# Well with miseq data available.
	{
            my $plate_name = "HUPFP1234A1";
            my $well_name = "A01";
            my $mech = LIMS2::Test::mech();

            $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

            $mech->content_contains("MiSeq QA");

            my $page = $mech->content();
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-overview",
	        ["Experiment", "HUEDQ1234_ADNP"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-overview",
	        ["Classification", "Mixed"],
            );
        }

        # Well without miseq data available.
        {
            my $plate_name = "HUPFP7890A1";
            my $well_name = "A01";
            my $mech = LIMS2::Test::mech();

            $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

            $mech->content_contains("No MiSeq information available for this well");
        }

	# Indel date
	{
            my $plate_name = "HUPFP1234A1";
            my $well_name = "A01";
            my $mech = LIMS2::Test::mech();

            $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

            $mech->content_contains("Indels");

            my $page = $mech->content();
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["Indel", "Frequency"],
            );

            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["-20", "2"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["1", "2"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["51", "1"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["-2", "3"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["4", "2"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["-11", "8953"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["-4", "2"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["-1", "8155"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
	        ["55", "3"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["50", "1"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["44", "1"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["54", "3"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["53", "1"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["52", "1"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["34", "1"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["-12", "6"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["-14", "1"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["-15", "2"],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-indels",
		["0", "12860"],  # Calculated from total reads (30000) minus sum of non-zero indel frequencies (17140).
            );

        }

	# Allele data
	{
            my $plate_name = "HUPFP1234A1";
            my $well_name = "A01";
            my $mech = LIMS2::Test::mech();

            $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

            $mech->content_contains("Alleles");

            my $page = $mech->content();

            # Table headers
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "Aligned_Sequence",
                    "NHEJ",
                    "UNMODIFIED",
                    "HDR",
                    "n_deleted",
                    "n_inserted",
                    "n_mutated",
                    "#Reads",
                    "%Reads",
                ],
            );
            # Table content
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACAACATCATCAATGGCAACGTGTCTCTCATGTATAAGAGT"
                     . "GTGCACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTGGGA"
                     . "GCTATGGCTC-----------GTATGGTTGTCGTAACTGTTGTATTCAAACGAGGTCTTG"
                     . "GAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGGACATTGTTTC",
                    "1",
                    "0",
                    "0",
                    "11",
                    "0",
                    "0",
                    "7400",
                    "24.67",
                ],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACAACATCATCAATGGCAACGTGTCTCTCATGTATAAGAGT"
                     . "GTGCACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTG"
                     . "GGAGCTATGGCTCGCTTGCCAT-AGTATGGTTGTCGTAACTGTTGTATTCAAACGAG"
                     . "GTCTTGGAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGG"
                     . "ACATTGTTTC",
                    "1",
                    "0",
                    "0",
                    "1",
                    "0",
                    "0",
                    "6511",
                    "21.7",
                ],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACAACATCATCAATGGCAACGTGTCTCTCATGTATAAGAGT"
                     . "GTGCACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTG"
                     . "GGAGCTATGGCTCGCTTGCCAT-AGTATGGTTGTCGTAACTGTTGTATTCAAACGAG"
                     . "GTCTTGGAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGA"
                     . "CATTGTTTC",
                    "1",
                    "0",
                    "0",
                    "1",
                    "0",
                    "0",
                    "93",
                    "0.31"
		],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACAACATCATCAATGGCAACGTGTCTCTCATGTATAAGAGT"
                     . "GTGCACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTG"
                     . "GGAGCTATGGCTC-----------GTATGGTTGTCGTAACTGTTGTATTCAAACGAG" 
                     . "GTCTTGGAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGA"
                     . "CATTGTTTC",
                    "1",
                    "0",
                    "0",
                    "11",
                    "0",
                    "0",
                    "80",
                    "0.27",
                ],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACAACATCATCAATGGCAACGTGTCTCTCATGTATAAGAGT"
                     . "GTGCACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTG"
                     . "GGAGCTATGACTCGCTTGCCAT-AGTATGGTTGTCGTAACTGTTGTATTCAAACGAG"
                     . "GTCTTGGAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGG"
                     . "ACATTGTTTC",
                    "1",
                    "0",
                    "0",
                    "1",
                    "0",
                    "0",
                    "41",
                    "0.14",
                ],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACAACATCATCAATGGCAACGTGTCTCTCATGTATAAGAGT"
                     . "GTGCACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTG"
                     . "GGAGCTATGGCTC-----------ATATGGTTGTCGTAACTGTTGTATTCAAACGAG"
                     . "GTCTTGGAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGG"
                     . "ACATTGTTTC",
                    "1",
                    "0",
                    "0",
                    "11",
                    "0",
                    "1",
                    "33",
                    "0.11",
                ],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACAACATCATCAATGGCAACGTGTCTCTCATGTATAAGAGT"
                     . "GTGTACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTG"
                     . "GGAGCTATGGCTCGCTTGCCAT-AGTATGGTTGTCGTAACTGTTGTATTCAAACGAG"
                     . "GTCTTGGAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGG"
                     . "ACATTGTTTC",
                    "1",
                    "0",
                    "0",
                    "1",
                    "0",
                    "0",
                    "28",
                    "0.09",
                ],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACATCATCAATGGCAACGTGTCTCTCATGTATAAGAGTGTG"
                     . "CACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTGGGA"
                     . "GCTATGGCTCGCTTGCCAT-AGTATGGTTGTCGTAACTGTTGTATTCAAACGAGGTC"
                     . "TTGGAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGGACA"
                     . "TTGTTTC",
                    "1",
                    "0",
                    "0",
                    "1",
                    "0",
                    "0",
                    "25",
                    "0.08",
                ],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACAACATCATCAATGGCAATGTGTCTCTCATGTATAAGAGT"
                     . "GTGCACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTG"
                     . "GGAGCTATGGCTCGCTTGCCAT-AGTATGGTTGTCGTAACTGTTGTATTCAAACGAG"
                     . "GTCTTGGAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGG"
                     . "ACATTGTTTC",
                    "1",
                    "0",
                    "0",
                    "1",
                    "0",
                    "0",
                    "24",
                    "0.08",
		],
            );
            assert_table_has_row_with_contents(
	        $page,
	        "miseq-alleles",
		[
                    "GACATTGATATACACAACAACAACATCATCAATGGCAACGTGTCTCTCATGTATAAGAGT"
                     . "GTGCACCTCCTACCATCATCATATCCTTTGGGGGATATATCCCTGGTTTGCACCTTG"
                     . "GGAGCTATGGCTCGCTTGCCAT-AGTATGGTTGTCGTAACTGTTGTATTAAAACGAG"
                     . "GTCTTGGAATATTTCTCGAGCTCCTTGGCCAGGTTGGAACGCGGCGTAGTTGTGGGG"
                     . "ACATTGTTTC",
                    "1",
                    "0",
                    "0",
                    "1",
                    "0",
                    "1",
                    "24",
                    "0.08",
                ],
            );
	}
    }


    note('User is warned if searching for non-FP plates');
    {
        my $plate_name = "MISEQ1";
        my $well_name = "A01";
        my $mech = LIMS2::Test::mech();

        $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");
        $mech->content_contains(
            "Clone genotyping information is only available for wells in FP plates at present." .
            " Please contact the cellular-informatics team if you'd like to be able to search" .
            " using wells in other plates."
        );
    }

    note('Well genotyping data can be got in JSON format');
    {
            my $plate_name = "HUPFP1234A1";
            my $well_name = "A01";
            my $mech = LIMS2::Test::mech();
            $mech->default_header("Accept" => "application/json");

            $mech->get_ok("/public_reports/well_genotyping_info/$plate_name/$well_name");

            my $data = decode_json($mech->content);

            # Checking one attribute should be enough to convince it's working.
            is($data->{'clone_id'}, 'HUPFP1234A1_A01');
    }
}

sub assert_table_has_row_with_contents {
    my ($html, $table_id, $expected_row) = @_;
    my $te = HTML::TableExtract->new();
    $te->parse($html);
    my @tables = $te->tables();
    my $table = _get_table_with_id(\@tables, $table_id);
    my @rows = $table->rows();
    ok(
        _check_rows_contains_expected_row(\@rows, $expected_row),
        "Table should have row: " . join(', ', @$expected_row),
    );
}

sub _get_table_with_id {
   my ($tables, $id) = @_;
   foreach my $table (@$tables) {
       if ($table->{attribs}{id} eq $id) {
           return $table;
       }
   }
   die "Can't find table with id: $id";
}

sub _check_rows_contains_expected_row {
   my ($rows, $expected_row) = @_;
   foreach my $row (@$rows) {
       if (Array::Compare->new()->simple_compare($row, $expected_row)){
           return 1;
       }
   }
   return 0;
}

sub targeting_type_validation : Tests {
    my $mech = LIMS2::Test::mech();

    ok(2, "Testing targeting type validation");

    $mech->get_ok("/public_reports/sponsor_report/single_targeted?species=Mouse");
    $mech->content_contains('Pipeline I Summary Report');
    $mech->get_ok("/public_reports/sponsor_report/single_targeted' OR 1=1; SELECT * from species?species=Mouse");
    $mech->content_contains('No projects found for this species / targeting type.');

}

=head1 AUTHOR

Josh Kent
based on template by
Lars G. Erlandsen

=cut

## use critic

1;

__END__

