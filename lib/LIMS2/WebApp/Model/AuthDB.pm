package LIMS2::WebApp::Model::AuthDB;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Model::AuthDB::VERSION = '0.208';
}
## use critic


use strict;
use warnings;

use base 'Catalyst::Model::DBIC::Schema';

require LIMS2::Model::DBConnect;

__PACKAGE__->config(
    schema_class => 'LIMS2::Model::AuthDB',
    #connect_info => LIMS2::Model::DBConnect->params_for( 'LIMS2_DB', 'webapp_ro' )
    connect_info => LIMS2::Model::DBConnect->params_for( 'LIMS2_DB', 'lims2' )
);

=head1 NAME

LIMS2::WebApp::Model::AuthDB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<LIMS2::WebApp>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<LIMS2::Model::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.59

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
