package LIMS2::t::Model::Util::Miseq;
use base qw/Test::Class/;
use Test::More;
use strict;
use warnings FATAL => 'all';
use LIMS2::Model::Util::Miseq qw(:all);


sub test_module_import : Test(2) {
    my @subs = qw(
      miseq_well_processes
      wells_generator
      well_builder
      convert_index_to_well_name
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
      get_api
      get_alleles_freq_path
      get_csv_from_tsv_lines
    );
    use_ok( 'LIMS2::Model::Util::Miseq', @subs );
    can_ok( __PACKAGE__, @subs );

    return;
}

sub test_get_alleles_freq_path : Test(1) {
    is(
        get_alleles_freq_path( 'base', 'miseq', 'exp', 1 ),
'base/miseq/S1_expexp/CRISPResso_on_1_S1_L001_R1_001_1_S1_L001_R2_001/Alleles_frequency_table.txt',
        'get_alleles_freq_path returns correct path'
    );
}

sub test_get_csv_from_tsv_lines : Test(3) {
    my @result   = get_csv_from_tsv_lines( ("col1") );
    my @expected = ("col1");
    is_deeply( \@result, \@expected,
        'get_csv_from_tsv_lines returns expected line' );
    my @tsv_lines = ( "row1\trow2\n", "row3\trow4" );
    my @csv_lines = ( 'row1,row2',    'row3,row4' );
    @result = get_csv_from_tsv_lines(@tsv_lines);
    is_deeply( \@result, \@csv_lines,
        'get_csv_from_tsv_lines removes trailing newline' );
    @tsv_lines = ( "col1\tcol2\tcol3\t", "col1\tcol2" );
    @csv_lines = ( "col1,col2,col3",     "col1,col2" );
    @result    = get_csv_from_tsv_lines(@tsv_lines);
    is_deeply( \@result, \@csv_lines,
        'get_csv_from_tsv_lines returns expected list of csv lines' );
}

1;
