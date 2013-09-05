package LIMS2::WebApp::Controller::FixtureData;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::FixtureData::VERSION = '0.102';
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

sub index :Path( '/test/fixtures' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $projectdir = $c->path_to('');
    my $dir = $projectdir->subdir('root', 'static', 'test', 'fixtures');

    my $files_ref = directory_listing($dir, '/static/test/fixtures');

    $c->res->content_type('text/text-plain');
    $c->res->body(join("\n", @{$files_ref}));

    return;
}

sub index2 :Path( '/test/data' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $projectdir = $c->path_to('');
    my $dir = $projectdir->subdir('root', 'static', 'test', 'data');

    my $files_ref = directory_listing($dir, '/static/test/data');

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
