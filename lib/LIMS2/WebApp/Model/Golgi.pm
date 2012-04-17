package LIMS2::WebApp::Model::Golgi;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config( class => 'LIMS2::Model' );

override prepare_arguments => sub {
    my ( $self, $c ) = @_;

    if ( $c->user ) {
        return {
            user       => 'webapp',
            audit_user => $c->user->user_name
        }
    }
    else {
        return {
            user => 'webapp_ro'
        }
    }
};

=head1 NAME

LIMS2::WebApp::Model::Golgi - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
