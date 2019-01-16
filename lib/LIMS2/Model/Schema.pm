use utf8;
package LIMS2::Model::Schema;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::VERSION = '0.521';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1SeYzxON4Pi0Z43rs8bzFw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
