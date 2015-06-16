package LIMS2::t::Model::Plugin::Gene;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Plugin::Gene;

use LIMS2::Test;
use Const::Fast;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Plugin/Gene.pm - test class for LIMS2::Model::Plugin::Gene

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

sub all_tests  : Test(17)
{
    {
	const my %GENE_DATA => ( gene_id => 'MGI:105369', gene_symbol => 'Cbx1' );
	const my @SEARCHES => (
	    { species => 'Mouse', search_term => 'Cbx1' },
	    { species => 'Mouse', search_term => 'MGI:105369' },
	    { species => 'Mouse', search_term => 'ENSMUSG00000018666' }
	);
	for my $search ( @SEARCHES ) {
	    ok my $searched = model->search_genes( $search ), 'search_genes';
	    is_deeply $searched, [ \%GENE_DATA ], '...returns expected result';
	    ok my $retrieved = model->retrieve_gene( $search ), 'retrieve_gene';
	    is_deeply $retrieved, \%GENE_DATA, '...returns expected result';
	}
    }

    {
	throws_ok{
	    model->search_genes( { species => 'Mouse', search_term => 'FooBarBaz' } )
	} 'LIMS2::Exception::NotFound', 'not found genes for made up name';
    }

    {
	const my %GENE_DATA => ( gene_id => 'HGNC:5117', gene_symbol => 'HOXB6' );
	for my $search_term ( values %GENE_DATA ) {
	    is_deeply model->retrieve_gene( { species => 'Human', search_term => $search_term } ), \%GENE_DATA,
		"Retrieve gene $search_term returns the expected result";
	}
    }

    {
	ok my $searched = model->search_genes( { species => 'Human', search_term => 'HOXB6' } ), 'search human gene';
	is_deeply $searched, [ {  gene_id => 'HGNC:5117', gene_symbol => 'HOXB6' } ],
	    '.. returns expected results';
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

