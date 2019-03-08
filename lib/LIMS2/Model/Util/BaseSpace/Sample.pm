package LIMS2::Model::Util::BaseSpace::Sample;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::BaseSpace::Sample::VERSION = '0.530';
}
## use critic

use strict;
use warnings FATAL => 'all';
use LIMS2::Model::Util::BaseSpace::File;

sub id {
    my $self = shift;
    return $self->{Id};
}

sub name {
    my $self = shift;
    return $self->{Name};
}

sub sample_id {
    my $self = shift;
    return $self->{SampleId};
}

sub files {
    my $self = shift;
    my $id = $self->id;
    return map { LIMS2::Model::Util::BaseSpace::File->new($self->{api}, $_) }
        $self->{api}->get_all("samples/$id/files");
}

sub new {
    my ( $class, $api, $data ) = @_;
    return bless {
        %{$data},
        api   => $api,
    }, $class;
}

1;
