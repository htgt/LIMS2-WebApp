package LIMS2::Model::Util::BaseSpace::File;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::BaseSpace::File::VERSION = '0.527';
}
## use critic

use strict;
use warnings FATAL => 'all';
use File::Spec::Functions qw/catfile/;

sub id {
    my $self = shift;
    return $self->{Id};
}

sub name {
    my $self = shift;
    return $self->{Name};
}

sub path {
    my $self = shift;
    return $self->{Path};
}

sub created {
    my $self = shift;
    return $self->{DateCreated};
}

sub etag {
    my $self = shift;
    return $self->{ETag};
}

sub download {
    my ($self, $path) = @_;
    return $self->{api}->download($self, $path);
}

sub new {
    my ( $class, $api, $data ) = @_;
    return bless {
        %{$data},
        api  => $api,
    }, $class;
}

1;
