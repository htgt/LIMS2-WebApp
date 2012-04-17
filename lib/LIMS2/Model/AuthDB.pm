use utf8;
package LIMS2::Model::AuthDB;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_classes( { 'LIMS2::Model::Schema::Result' => [ qw( User UserRole Role ) ] } ); 

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;

__END__

=pod

=head1 NAME

LIMS2::Model::AuthDB

=head1 DESCRIPTION

This is a cut-down version of L<LIMS2::Model::Schema> for use by
L<Catalyst::Plugin::Authentication>. It contains only the B<User>,
B<UserRole>, and B<Role> result classes.

=cut

