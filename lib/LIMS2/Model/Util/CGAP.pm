package LIMS2::Model::Util::CGAP;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CGAP::VERSION = '0.412';
}
## use critic


use Moose;
use LIMS2::Exception;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';
use strict;
use warnings FATAL => 'all';

use TryCatch;
use LWP::UserAgent;
use Data::Dumper;
use JSON;
use Config::Tiny;

has url_config => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_url_config{
	$ENV{ LIMS2_URL_CONFIG } or die "LIMS2_URL_CONFIG environment variable not set";
    my $conf = Config::Tiny->read( $ENV{ LIMS2_URL_CONFIG } );
    return $conf->{_};
}

sub get_barcode_for_cgap_name{
	my ($self,$name) = @_;

    my $cgap_url = $self->url_config->{cgap_name_search};

	$cgap_url .= $name;
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($cgap_url);
    my $barcode;
    if($response->is_success){
        try{
            my @results = @{ decode_json($response->content) };
            if(@results != 1){
            	die scalar(@results)." results found in cgap for $name";
            }
            my $result = $results[0];
            $barcode = $result->{donor_barcode};
        }
        catch{
            die "Cannot identify barcode in response: ".$response->content;
        }
    }
    else{
    	die "Could not get $cgap_url. $response->status_line";
    }

    return $barcode;
}

1;
