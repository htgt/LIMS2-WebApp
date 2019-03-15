package LIMS2::Model::Util::BaseSpace;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::BaseSpace::VERSION = '0.531';
}
## use critic

use strict;
use warnings FATAL => 'all';
use File::Spec::Functions qw/catfile/;
use Carp;
use JSON;
use LWP::UserAgent;
use LIMS2::Model::Util::BaseSpace::Project;
use LIMS2::Model::Util::BaseSpace::Sample;

sub new {
    my $class = shift;
    my $agent = LWP::UserAgent->new( env_proxy => 1, );
    $agent->ssl_opts( verify_hostname => 0 );
    return bless {
        agent => $agent,
        token => $ENV{BASESPACE_TOKEN} // q//,
        api   => $ENV{BASESPACE_API}
          // 'https://api.basespace.illumina.com/v1pre3',
        limit => 1024,
        etags => {},
    }, $class;
}

sub get {
    my ( $self, $request, $offset ) = @_;
    $offset = $offset // 0;
    croak 'No BaseSpace credentials supplied' if not $self->{token};
    my $url = sprintf( '%s/%s?access_token=%s&limit=%d&offset=%d',
        $self->{api}, $request, $self->{token}, $self->{limit}, $offset );
    my $response = $self->{agent}->get($url);
    croak $response->message if $response->code >= 400;
    my $data     = decode_json( $response->content );
    if ( not $data->{Response} ) {
        croak $data->{ResponseStatus}->{Message};
    }
    return $data->{Response};
}

sub get_all {
    my ( $self, $request ) = @_;
    my @items = ();
    my $count = 1;  # this will be updated during the loop with the actual count
    for ( my $offset = 0 ; $offset < $count ; $offset += $self->{limit} ) {
        my $response = $self->get( $request, $offset );
        push @items, @{ $response->{Items} };
        $count = $response->{TotalCount};
    }
    return @items;
}

sub projects {
    my $self = shift;
    return
      map { LIMS2::Model::Util::BaseSpace::Project->new( $self, $_ ) }
      $self->get_all('users/current/projects');
}

sub project {
    my ( $self, $id, $populate ) = @_;
    my $project = $populate ? $self->get("projects/$id") : { Id => $id };
    return LIMS2::Model::Util::BaseSpace::Project->new( $self, $project );
}

sub sample {
    my ( $self, $id, $populate ) = @_;
    my $sample = $populate ? $self->get("samples/$id") : { Id => $id };
    return LIMS2::Model::Util::BaseSpace::Sample->new( $self, $sample );
}

sub download {
    my ( $self, $file, $path ) = @_;
    $path = $path // q/./;
    if ( exists( $self->{etags}->{ $file->etag } ) ) {
        return { path => $self->{etags}->{ $file->etag } };
    }
    my $url = sprintf( '%s/files/%s/content?access_token=%s',
        $self->{api}, $file->id, $self->{token} );
    my $index = 0;
    my $name  = $file->name;
    my $dest  = catfile( $path, $name );
    while ( -e $dest ) {
        $index++;
        $dest = catfile( $path, "$name.$index" );
    }
    $self->{etags}->{ $file->etag } = $dest;
    return {
        path     => $dest,
        response => $self->{agent}->get( $url, ':content_file' => $dest ),
    };
}

1;

__END__

