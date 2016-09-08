package LIMS2::AlleleRequestFactory;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::AlleleRequestFactory::VERSION = '0.422';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use Module::Pluggable::Object;
use LIMS2::Exception::Implementation;
use namespace::autoclean;

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub plugins {
    my $self = shift;
    return Module::Pluggable::Object->new( search_path => 'LIMS2::AlleleRequest', require => 1 )->plugins;
}

## no critic(RequireFinalReturn)
sub allele_request {
    my $self = shift;

    my %params = @_ == 1 ? %{$_[0]} : @_;

    my $targeting_type = delete $params{targeting_type}
        or LIMS2::Exception::Implementation->throw( "allele_request() requires targeting_type" );

    $params{model}   ||= $self->model;
    $params{species} ||= $self->species;

    for my $plugin ( $self->plugins ) {
        if ( $plugin->handles( $targeting_type ) ) {
            return $plugin->new( \%params );
        }
    }

    LIMS2::Exception::Implementation->throw( "Allele request targeting type '$targeting_type' not recognized" );
}
## use critic

__PACKAGE__->meta->make_immutable;

1;

__END__


