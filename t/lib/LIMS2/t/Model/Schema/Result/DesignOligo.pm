package LIMS2::t::Model::Schema::Result::DesignOligo;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Schema::Result::DesignOligo;
use LIMS2::Test;
use Try::Tiny;
use LIMS2::Model::DBConnect;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Schema/Result/DesignOligo.pm - test class for LIMS2::Model::Schema::Result::DesignOligo

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

sub all_tests  : Test(26)
{
    note('Test getting reverse complimented oligo sequence');

    {   
	ok my $design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54767 } )
	    ,' can find design oligom, 54767, G5';

	my $oligo_seq = 'ACCTGGAGACCAGGAAATGGTGAAGTACAACAGTACATATTTTAAATTTT';
	is $design_oligo->seq, $oligo_seq , 'correct oligo seq';
	my $revcomp_oligo_seq = _revcomp_seq( $oligo_seq );

	is $design_oligo->revcomp_seq, $revcomp_oligo_seq, 'have correct reverse complimented sequence';

	ok $design_oligo->update( { seq => 'ATCGN' } ), 'can update design oligo seq, with N base';

	is $design_oligo->revcomp_seq, 'NCGAT', 'correct reverse complimented seq with N';

	ok $design_oligo->update( { seq => '23' } ), 'can update design oligo seq with nonsense data';

	throws_ok{
	    $design_oligo->revcomp_seq
	} qr/Error working out revcomp of sequence/, 'throws error when trying to revcomp invalid seq';
    }

    note( 'Testing append_seq' );

    {   
	ok my $u5_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54768 } )
	    ,' can find design oligo, 54768, U5';

	is $u5_design_oligo->append_seq, 'AAGGCGCATAACGATACCAC', 'correct append seq for U5 oligo, ins-del design';
	is $u5_design_oligo->append_seq( 'artificial-intron' ), 'GTGAGTGTGCTAGAGGGGGTG'
	    ,'correct append seq for U5 oligo, art intron design';

	throws_ok{
	    $u5_design_oligo->append_seq( 'blah' )
	} qr/Do not know append sequences for blah designs/
	    ,'throws error when sending in unknown design type';

	ok my $u3_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54763 } )
	    ,' can find design oligo, 54763, U3';

	throws_ok{
	    $u3_design_oligo->append_seq( 'deletion' )
	} qr/Undefined append sequence for U3 oligo on deletion design/
	    ,'throws error when sending in unknown design type';

	is $u3_design_oligo->append_seq, 'CCGCCTACTGCGACTATAGA', 'correct U3 append seq for KO design';

    }

    note( 'Test oligo_order_seq, -ve stranded design' );

    {   
	# -ve Stranded design oligos, 88505
	ok my $u5_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54768 } )
	    ,' can find design oligo, 54768, U5';
	ok my $u5_append_seq = $u5_design_oligo->append_seq, 'can grab U5 append seq';

	#U5 oligo on -ve stranded design must be revcomped
	my $expected_u5_order_seq = _revcomp_seq( $u5_design_oligo->seq );
	$expected_u5_order_seq .= $u5_append_seq;
	is $u5_design_oligo->oligo_order_seq, $expected_u5_order_seq, 'got expected U5 order seq';


	ok my $d3_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54769 } )
	    ,' can find design oligo, 54769, D3';
	ok my $d3_append_seq = $d3_design_oligo->append_seq, 'can grab D3 append seq';

	#D3 oligo on -ve stranded design must NOT be revcomped
	my $expected_d3_order_seq = $d3_design_oligo->seq . $d3_append_seq;
	is $d3_design_oligo->oligo_order_seq, $expected_d3_order_seq, 'got expected D3 order seq';

    }

    note( 'Test oligo_order_seq, +ve stranded design' );

    {
	# +ve Stranded design oligos, 85512
	ok my $u5_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54772 } )
	    ,' can find design oligo, 54768, U5';
	ok my $u5_append_seq = $u5_design_oligo->append_seq, 'can grab U5 append seq';

	#U5 oligo on +ve stranded design must NOT be revcomped
	my $expected_u5_order_seq = $u5_design_oligo->seq . $u5_append_seq;
	is $u5_design_oligo->oligo_order_seq, $expected_u5_order_seq, 'got expected U5 order seq';


	ok my $d3_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54773 } )
	    ,' can find design oligo, 54769, D3';
	ok my $d3_append_seq = $d3_design_oligo->append_seq, 'can grab D3 append seq';

	#D3 oligo on +ve stranded design must be revcomped
	my $expected_d3_order_seq = _revcomp_seq( $d3_design_oligo->seq );
	$expected_d3_order_seq .= $d3_append_seq;
	is $d3_design_oligo->oligo_order_seq, $expected_d3_order_seq, 'got expected D3 order seq';

    }

    sub _revcomp_seq {
	my $seq = shift;

	my $revcomp_oligo_seq = reverse( $seq );
	$revcomp_oligo_seq =~ tr/ATCG/TAGC/;

	return $revcomp_oligo_seq;
    }

}

sub _revcomp_seq {
    my $seq = shift;

    my $revcomp_oligo_seq = reverse( $seq );
    $revcomp_oligo_seq =~ tr/ATCG/TAGC/;

    return $revcomp_oligo_seq;
}


=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

