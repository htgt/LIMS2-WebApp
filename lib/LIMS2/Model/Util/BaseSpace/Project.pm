package LIMS2::Model::Util::BaseSpace::Project;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::BaseSpace::Project::VERSION = '0.529';
}
## use critic

use strict;
use warnings FATAL => 'all';
use LIMS2::Model::Util::BaseSpace::Sample;

sub id {
    my $self = shift;
    return $self->{Id};
}

sub name {
    my $self = shift;
    return $self->{Name};
}

sub created {
    my $self = shift;
    return $self->{DateCreated};
}

sub samples {
    my $self = shift;
    my $id   = $self->id;
    return
      map { LIMS2::Model::Util::BaseSpace::Sample->new( $self->{api}, $_ ) }
      $self->{api}->get_all("projects/$id/samples");
}

sub files {
    my $self  = shift;
    my @files = ();
    foreach my $sample ( $self->samples ) {
        push @files, $sample->files;
    }
    return @files;
}

sub new {
    my ( $class, $api, $data ) = @_;
    return bless { %{$data}, api => $api, }, $class;
}

1;
