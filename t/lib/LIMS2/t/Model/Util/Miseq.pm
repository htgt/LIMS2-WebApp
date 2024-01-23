package LIMS2::t::Model::Util::Miseq;
use base qw/Test::Class/;
use Test::More;
use Test::MockObject;
use Test::Exception;
use strict;
use warnings FATAL => 'all';
use LIMS2::Model::Util::Miseq qw(:all);

sub test_module_import : Test(2) {
    my @subs = qw(
      miseq_well_processes
      wells_generator
      well_builder
      convert_index_to_well_name
      convert_well_name_to_index
      generate_summary_data
      find_folder
      find_file
      find_child_dir
      read_file_lines
      find_miseq_data_from_experiment
      query_miseq_details
      damage_classifications
      miseq_genotyping_info
      read_alleles_frequency_file
      qc_relations
      query_miseq_tree_from_experiment
      get_alleles_freq_path
      get_csv_from_tsv_lines
      get_api
    );
    use_ok( 'LIMS2::Model::Util::Miseq', @subs );
    can_ok( __PACKAGE__, @subs );

    return;
}

sub test_convert_index_to_well_name : Test(5) {
    is( convert_index_to_well_name(0),
        '',
        'convert_index_to_well_name returns empty string if index too low' );
    is( convert_index_to_well_name(500),
        '',
        'convert_index_to_well_name returns empty string if index too high' );
    is( convert_index_to_well_name(1),
        'A01',
        'convert_index_to_well_name returns correct well name or index 1' );
    is( convert_index_to_well_name(384),
        'P24',
        'convert_index_to_well_name returns correct well name for index 384' );
    is( convert_index_to_well_name(170),
        'B22',
        'convert_index_to_well_name returns correct well name for index 170' );
    return;
}

sub test_convert_well_name_to_index : Test(5) {
    is( convert_well_name_to_index(1),
        0, 'convert well_name_to_index returns 0 if number input' );
    is( convert_well_name_to_index('Z01'),
        0, 'convert well_name_to_index returns 0 if well name does not exist' );
    is( convert_well_name_to_index('A01'),
        1, 'convert well_name_to_index returns correct index for well A01' );
    is( convert_well_name_to_index('P24'),
        384, 'convert well_name_to_index returns correct index for well P24' );
    is( convert_well_name_to_index('B22'),
        170, 'convert well_name_to_index returns correct index for well B22' );
    return;
}

sub mock_api {
    my ( $file_exists, @contents ) = @_;
    my $module = 'WebAppCommon::Util::FileAccess';
    my $api    = Test::MockObject->new( \$module );
    $api->mock(
        'check_file_existence',
        sub {
            my ( $self, $path ) = @_;
            return $file_exists;
        }
    );
    $api->mock(
        'get_file_content',
        sub {
            my ( $self, $path ) = @_;
            return @contents;
        }
    );
    return $api;
}

sub test_read_alleles_frequency_file : Test(3) {
    my @file_contents    = ( "first\tline\n", "second\tline" );
    my $api              = mock_api( 1, @file_contents );
    my @expected_results = ( 'first,line', 'second,line' );
    my @results =
      LIMS2::Model::Util::Miseq::read_alleles_frequency_file( $api, 'Miseq', 1,
        'Exp' );
    is_deeply( \@results, \@expected_results,
        'read_alleles_frequency_file returns expected data' );
    $api = mock_api( 1, ('') );
    throws_ok {
        LIMS2::Model::Util::Miseq::read_alleles_frequency_file( $api, 'Miseq',
            1, 'Exp' )
    }
    qr/No data in file/,
      'read_alleles_frequency_data dies with correct error if no data in file';
    $api = mock_api( 0, ('') );
    throws_ok {
        LIMS2::Model::Util::Miseq::read_alleles_frequency_file( $api, 'Miseq',
            1, 'Exp' )
    }
    qr/No path available/,
'read_alleles_frequency_file dies with with correct error if no path found';
    return;
}

sub test_get_alleles_freq_path : Test(2) {
    my $api = mock_api( 1, '' );
    is(
        get_alleles_freq_path( 'base', 'miseq', 'exp', 1, $api ),
'base/miseq/S1_expexp/CRISPResso_on_1_S1_L001_R1_001_1_S1_L001_R2_001/Alleles_frequency_table.txt',
        'get_alleles_freq_path returns correct existing path'
    );
    $api = mock_api( 0, '' );
    is( get_alleles_freq_path( 'base', 'miseq', 'exp', 1, $api ),
        0, 'get_alleles_freq_path returns 0 if path cannot be found' );
    return;
}

sub test_get_csv_from_tsv_lines : Test(3) {
    my @result   = get_csv_from_tsv_lines( ("col1") );
    my @expected = ("col1");
    is_deeply( \@result, \@expected,
        'get_csv_from_tsv_lines returns expected line' );
    my @tsv_lines = ( "col1\tcol2\n", "col1" );
    my @csv_lines = ( 'col1,col2',    'col1' );
    @result = get_csv_from_tsv_lines(@tsv_lines);
    is_deeply( \@result, \@csv_lines,
        'get_csv_from_tsv_lines removes trailing newline' );
    @tsv_lines = ( "col1\tcol2\tcol3\t", "col1\tcol2" );
    @csv_lines = ( "col1,col2,col3",     "col1,col2" );
    @result    = get_csv_from_tsv_lines(@tsv_lines);
    is_deeply( \@result, \@csv_lines,
        'get_csv_from_tsv_lines returns expected list of csv lines' );
    return;
}

sub test_set_classification: Test(11) {
    note("Classify as WT when greater than 98% of of reads have 0 indels AND most common read is unmodified");
    {
        my $allele_data = [
          {
            "unmodified" => 1,
            "percentage_reads" => 51.1,
            "n_reads" => 511,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 1.9,
            "n_reads" => 19,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GGACA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -1,
	         "frequency" => 19
            },
            {
                "frequency" => 981,
                "indel" => 0
            }
	];

	my $classification = classify_reads($allele_data, $indel_data);

	is($classification, "WT");
    }
    
    note("Don't classify as WT when >98% of of reads have 0 indels BUT most common read is modified");
    {
        my $allele_data = [
          {
            "unmodified" => 0,
            "percentage_reads" => 51.1,
            "n_reads" => 511,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 1.9,
            "n_reads" => 19,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GGACA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -1,
	         "frequency" => 19
            },
            {
                "frequency" => 981,
                "indel" => 0
            }
	];

	my $classification = classify_reads($allele_data, $indel_data);

	isnt($classification, "WT");
    }
    note("Do not classify as WT when most common read is unmodified, but less than 98% of reads are 0 indel");
    {
        my $allele_data = [
          {
            "unmodified" => 1,
            "percentage_reads" => 51.1,
            "n_reads" => 511,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 1.9,
            "n_reads" => 19,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GGACA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -1,
	         "frequency" => 21,
            },
            {
                "frequency" => 979,
                "indel" => 0
            }
        ];

	my $classification = classify_reads($allele_data, $indel_data);

	isnt($classification, "WT");
    }

    note("Doesn't classify as WT when no reads are 0 indel");
    {
        my $allele_data = [
          {
            "unmodified" => 0,
            "percentage_reads" => 51.1,
            "n_reads" => 511,
            "hdr" => 0,
            "n_inserted" => 1,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 1.9,
            "n_reads" => 19,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GGACA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -1,
	         "frequency" => 21,
            },
            {
                "frequency" => 979,
                "indel" => 1
            }
        ];

	my $classification = classify_reads($allele_data, $indel_data);

	isnt($classification, "WT");
    }

    note("Claasify as 'K/O Hom' if most frequent indel is not 0, not a multiple of 3, and is more than 98% of reads");
    {
        my $allele_data = [
          {
            "unmodified" => 1,
            "percentage_reads" => 1.1,
            "n_reads" => 11,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 98.1,
            "n_reads" => 981,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 0.8,
            "n_reads" => 8,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 2,
            "aligned_sequence" => "GAAA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -2,
	         "frequency" =>8,
            },
            {
	        "indel" => -1,
	         "frequency" => 981,
            },
            {
	        "indel" => 0,
	         "frequency" => 11,
            },
        ];

	my $classification = classify_reads($allele_data, $indel_data);

	is($classification, "K/O Hom");
    
    }

    note("Doesn't claasify as 'K/O Hom' if most no indel is more than 98% of reads");
    {
        my $allele_data = [
          {
            "unmodified" => 1,
            "percentage_reads" => 1.1,
            "n_reads" => 11,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 97.9,
            "n_reads" => 981,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 0.8,
            "n_reads" => 8,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 2,
            "aligned_sequence" => "GAAA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -2,
	         "frequency" => 10,
            },
            {
	        "indel" => -1,
	         "frequency" => 979,
            },
            {
	        "indel" => 0,
	         "frequency" => 11,
            },
        ];

	my $classification = classify_reads($allele_data, $indel_data);

	isnt($classification, "K/O Hom");
    
    }

    note("Claasify as 'K/O Hom' if most frequent indel is not 0, and is more than 98% of reads, but IS a multiple of 3");
    {
        my $allele_data = [
          {
            "unmodified" => 1,
            "percentage_reads" => 1.1,
            "n_reads" => 11,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 98.1,
            "n_reads" => 981,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 3,
            "aligned_sequence" => "GAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 0.8,
            "n_reads" => 8,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 2,
            "aligned_sequence" => "GAAA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -2,
	         "frequency" =>8,
            },
            {
	        "indel" => -3,
	         "frequency" => 981,
            },
            {
	        "indel" => 0,
	         "frequency" => 11,
            },
        ];

	my $classification = classify_reads($allele_data, $indel_data);

	isnt($classification, "K/O Hom");
    
    }

    note("Classify as 'K/O Het' when two mot frequent indels are >98% of reads, one of the indels is zero, and the other is not divisible by 3 (i.e. is a frameshift)");
    {
        my $allele_data = [
          {
            "unmodified" => 1,
            "percentage_reads" => 49.0,
            "n_reads" => 490,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 49.1,
            "n_reads" => 491,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GGACA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 1.9,
            "n_reads" => 19,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 3,
            "aligned_sequence" => "GAA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -1,
	         "frequency" => 491
            },
            {
                "frequency" => 490,
                "indel" => 0
            },
            {
                "frequency" => 19,
                "indel" => -3
            }
	];

	my $classification = classify_reads($allele_data, $indel_data);

	is($classification, "K/O Het");
    }

    note("Don't classify as 'K/O Het' if most frequent two indels are less than 98% of total reads");
    {
        my $allele_data = [
          {
            "unmodified" => 1,
            "percentage_reads" => 39.0,
            "n_reads" => 390,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 49.1,
            "n_reads" => 491,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GGACA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 1.9,
            "n_reads" => 19,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 3,
            "aligned_sequence" => "GAA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -1,
	         "frequency" => 391
            },
            {
                "frequency" => 490,
                "indel" => 0
            },
            {
                "frequency" => 19,
                "indel" => -3
            }
	];

	my $classification = classify_reads($allele_data, $indel_data);

	isnt($classification, "K/O Het");
    }

    note("Don't classify as 'K/O Het' if non-zero indel is divisible by 3 (i.e. not frameshift)");
    {
        my $allele_data = [
          {
            "unmodified" => 1,
            "percentage_reads" => 49.0,
            "n_reads" => 490,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 49.1,
            "n_reads" => 491,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 3,
            "aligned_sequence" => "GAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 1.9,
            "n_reads" => 19,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GGACA"
          },
        ];
        my $indel_data = [
            {
                "frequency" => 491,
                "indel" => -3
            },
            {
                "frequency" => 490,
                "indel" => 0
            },
            {
                "frequency" => 19,
	        "indel" => -1,
            }
	];

	my $classification = classify_reads($allele_data, $indel_data);

	isnt($classification, "K/O Het");
    }

    note("Don't classify as K/O Het if ratio of most common to next most common indel frequency is more than 60%");
    {
        my $allele_data = [
          {
            "unmodified" => 1,
            "percentage_reads" => 60.0,
            "n_reads" => 600,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 0,
            "aligned_sequence" => "GGACAA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 39.0,
            "n_reads" => 390,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 1,
            "aligned_sequence" => "GGACA"
          },
          {
            "unmodified" => 0,
            "percentage_reads" => 1.0,
            "n_reads" => 10,
            "hdr" => 0,
            "n_inserted" => 0,
            "nhej" => 0,
            "n_mutated" => 0,
            "n_deleted" => 3,
            "aligned_sequence" => "GAA"
          },
        ];
        my $indel_data = [
            {
	        "indel" => -1,
	         "frequency" => 390
            },
            {
                "frequency" => 600,
                "indel" => 0
            },
            {
                "frequency" => 10,
                "indel" => -3
            }
	];

	my $classification = classify_reads($allele_data, $indel_data);

	isnt($classification, "K/O Het");
    }
}

1;
