package LIMS2::t::Model::Schema::Result::Summary;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Schema::Result::Summary;
use LIMS2::Test;

=head1 NAME

LIMS2/t/Model/Schema/Result/Summary.pm - test class for LIMS2::Model::Schema::Result::Summary

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

sub all_tests  : Test(8)
{
    note ("Testing satisfies cassette function");

    my $summary = model->schema->resultset('Summary')->new({
	    final_pick_well_id              => 1,
	    final_pick_cassette_conditional => 1,
	    final_pick_cassette_promoter    => 1,
	    final_pick_cassette_cre         => 0,
	    final_pick_recombinase_id       => 'Cre'
    });

    my $cassettes = model->schema->resultset('CassetteFunction');

    ok $summary->satisfies_cassette_function( $cassettes->find('reporter_only') ), "...is reporter_only";
    ok $summary->satisfies_cassette_function( $cassettes->find('reporter_only_promoter') ), "...is reporter_only_promoter";
    ok !$summary->satisfies_cassette_function( $cassettes->find('ko_first') ), "...is not ko_first";

    $summary->final_pick_recombinase_id(undef);

    ok $summary->satisfies_cassette_function( $cassettes->find('ko_first') ), "...is ko_first";
    ok $summary->satisfies_cassette_function( $cassettes->find('ko_first_promoter') ), "...is ko_first_promoter";
    ok !$summary->satisfies_cassette_function( $cassettes->find('ko_first_promoterless') ), "...is not ko_first_promoterless";
    ok !$summary->satisfies_cassette_function( $cassettes->find('reporter_only') ), "...is not reporter_only";

    $summary->final_pick_cassette_cre(1);

    ok $summary->satisfies_cassette_function( $cassettes->find('cre_knock_in') ), "..is cre_knock_in";

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

1;

__END__

