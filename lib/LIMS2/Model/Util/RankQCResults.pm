package LIMS2::Model::Util::RankQCResults;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::RankQCResults::VERSION = '0.108';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ 'rank' ]
};

# Module to provide genotyping QC result ranking
# Higher score = "better" result

my %RANKING = (
    'na'            => 9, #na should never be overwritten
    'pass_lrpcr'    => 8,
    'pass'          => 7,
    'passb'         => 6,
    'fail'          => 5,
    'present'       => 4,
    'absent'        => 3,
    'potential'     => 2,
    'fa'            => 1, #Failed Assay
);

# Fetch rank for a string, WellGenotypingResult or WellTargetingPass
sub rank{
	my ($result) = @_;

	my $value;

	if (not ref $result){
		$value = $result
	}
	elsif (ref $result eq "LIMS2::Model::Schema::Result::WellGenotypingResult"){
		$value = $result->call;
	}
	elsif( ref $result eq "LIMS2::Model::Schema::Result::WellTargetingPass"){
		$value = $result->result;
	}
	else{
		die "Do not know how to get QC result value for a ".ref $result;
	}

	my $rank = $RANKING{lc($value)} or die "No QC rank defined for value $value";

	return $rank;
}

1;
