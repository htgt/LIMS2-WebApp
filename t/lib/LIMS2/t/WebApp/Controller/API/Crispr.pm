package LIMS2::t::WebApp::Controller::API::Crispr;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::API::Crispr;
use LIMS2::t::WebApp::Controller::API qw( construct_post );

use LIMS2::Test;
use File::Temp ':seekable';
use JSON;
use YAML;
use HTTP::Request;
use Data::Dumper;



use strict;

## no critic

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
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

sub all_tests  : Test(15)
{
    my $self = shift;
    my $mech = mech();

    my $species = 'Human';
    my %update_params = ( off_target_summary => '{0: 1}', algorithm => 'bwa' );
    my @crispr_ids;

    note( 'Testing Crispr/Pair REST API' );

    foreach my $crispr (@{ $self->crisprs_to_load }){
      my $req = construct_post('/api/single_crispr', encode_json($crispr) );
      ok $mech->request( $req ), 'created crispr';
      ok my $json = decode_json($mech->content), 'can decode json response';
      $mech->get_ok('/api/single_crispr?id='.$json->{id}, { 'content-type' => 'application/json'});
      push @crispr_ids, $json->{id};

      $update_params{id} = $json->{id};
      my $update_req = construct_post('/api/crispr_off_target_summary', encode_json(\%update_params));
      ok $mech->request($update_req), 'updated crispr off_target_summary';
      is (decode_json($mech->content)->{summary}, '{0: 1}', 'off_target_summary updated as expected');
    }

    my %pair_params = ( 
      l_id => $crispr_ids[0], 
      r_id => $crispr_ids[1], 
      spacer => '10', 
      );

    my $pair_req = construct_post('/api/crispr_pair', encode_json(\%pair_params));
    ok $mech->request( $pair_req ), 'created crispr pair';
    ok my $pair_json = decode_json($mech->content), 'can decode json response';
    is ($pair_json->{spacer}, '10', 'new pair has expected spacer');

    my %pair_update_params = (
      l_id => $crispr_ids[0],
      r_id => $crispr_ids[1],
      off_target_summary => '{0: 1}',
    );
    my $update_req = construct_post('/api/crispr_pair_off_target_summary', encode_json(\%pair_update_params));
    ok $mech->request( $update_req ), 'updated crispr pair off targets';
    is (decode_json($mech->content)->{off_target_summary}, '{0: 1}', 'off_target_summary updated');

}

sub crisprs_to_load{
    my $crisprs = Load(<<'END');
---
- locus:
      assembly: GRCh37
      chr_end: 47637233
      chr_name: '2'
      chr_start: 47637211
      chr_strand: 1
      crispr_id: 82346
  off_target_algorithm: bwa
  off_target_summary: '{0: 1, 1: 2, 2: 31, 3: 294, 4: 2736, 5: 15637}'
  pam_right: 1
  seq: TTAAAATTTTATTTTTACTTAGG
  species: Human
  type: Exonic
- locus:
      assembly: GRCh37
      chr_end: 47637261
      chr_name: '2'
      chr_start: 47637239
      chr_strand: -1
      crispr_id: 82352
  off_target_algorithm: bwa
  off_target_summary: '{0: 1, 1: 0, 2: 0, 3: 8, 4: 144, 5: 1417}'
  pam_right: 0
  seq: CCTGGCAATCTCTCTCAGTTTGA
  species: Human
  type: Exonic
END
    return $crisprs;
}

=head1 AUTHOR

Anna Farne

=cut

## use critic

1;

__END__
