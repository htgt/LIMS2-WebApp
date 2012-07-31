package LIMS2::ReportGenerator;

use strict;
use warnings FATAL => 'all';

use Moose;
use Iterator::Simple;
use JSON;
use namespace::autoclean;

has name => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1
);

has columns => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    init_arg   => undef,
    lazy_build => 1
);

has model => (
    is         => 'ro',
    isa        => 'LIMS2::Model',
    required   => 1,
);

has cache_ttl => (
    is      => 'ro',
    isa     => 'Str',
    default => '8 hours'
);

has param_names => (
    isa     => 'ArrayRef[Str]',
    traits  => [ 'Array' ],
    handles => { param_names => 'elements' },
    default => sub { [] }
);

sub _build_name {
    confess( "_build_name() must be implemented by a subclass" );
}

sub _build_columns {
    confess( "_build_columns() must be implemented by a subclass" );
}

sub iterator {
    confess( "iterator() must be implemented by a subclass" );
}

sub boolean_str {
    my ( $self, $bool ) = @_;

    if ( $bool ) {
        return 'yes';
    }
    else {
        return 'no';
    }
}

sub cached_report {
    my $self = shift;

    my @cached = $self->model->schema->resultset('CachedReport')->search(
        {
            report_class => ref $self,
            params       => JSON->new->utf8->canonical->encode( $self->params_hash ),
            expires      => { '>' => \'current_timestamp' }
        },
        {
            order_by => { -desc => 'expires' },
            limit    => 1
        }
    );

    my @complete = grep { $_->complete } @cached;
    if ( @complete ) {
        return $complete[0];
    }
    elsif ( @cached ) {
        return $cached[0];
    }

    return;
}

sub init_cached_report {
    my ( $self, $report_id ) = @_;

    my $cache_entry = $self->model->schema->resultset('CachedReport')->create(
        {
            id           => $report_id,
            report_class => ref $self,
            params       => JSON->new->utf8->canonical->encode( $self->params_hash ),
            expires      => \sprintf( 'current_timestamp + interval \'%s\'', $self->cache_ttl )
        }
    );

    return $cache_entry;
}

sub params_hash {
    my $self = shift;

    return { map { $_ => $self->$_ }  $self->param_names };
}

__PACKAGE__->meta->make_immutable();

1;

__END__

