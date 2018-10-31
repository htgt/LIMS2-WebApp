package LIMS2::Model::Plugin::Pipeline;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Pipeline::VERSION = '0.514';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub list_pipeline {
    my $self = shift;

    my @pipeline = map { $_->id }
        $self->schema->resultset('Pipeline')->search( {}, { order_by => { -asc => 'id' } } );

    return \@pipeline;
}

1;

__END__
