package LIMS2::WebApp::Controller::FixtureData;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::FixtureData::VERSION = '0.510';
}
## use critic

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

use Path::Class;
use Data::Dumper;

=head1 NAME

LIMS2::WebApp::Controller::FixtureData - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path( '/test/fixtures' ) :Args() {
    my ( $self, $c, @components ) = @_;

    my $base = '/static/test/fixtures';
    return $self->generate_index($c, $base, @components );
}

sub index2 :Path( '/test/data' ) :Args() {
    my ( $self, $c, @components ) = @_;

    my $base = '/static/test/data';
    return $self->generate_index($c, $base, @components );
}

sub generate_index {
    my ($self, $c, $base, @components ) = @_;

    my $projectdir = $c->path_to('');
    my $abs_dir = $projectdir->subdir('root', $base, @components);
    my $path = join('/', $base, @components);
    #print STDERR Data::Dumper->Dump([\@components], [qw(*components)]);
    my $files_ref = directory_listing($abs_dir, $path);

    $c->res->content_type('text/text-plain');
    $c->res->body(join("\n", @{$files_ref}));

    return;
}

# Traverse a directory, return the listing of files in it
sub directory_listing {
    my ($dir, $path) = @_;
    my (@files);

    my $handle = $dir->open;
    while (my $file = $handle->read) {
	push(@files, "<a href=\"$path/$file\">$file</a><br>") unless (($file eq '..') || ($file eq '.'));
    }
    return(\@files);
}

=head1 AUTHOR

Lars Erlandsen

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
