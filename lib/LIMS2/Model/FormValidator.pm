package LIMS2::Model::FormValidator;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::FormValidator::VERSION = '0.069';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use Data::FormValidator;
use LIMS2::Model::FormValidator::Constraint;
use Hash::MoreUtils qw( slice_def );
use Log::Log4perl qw( :easy );
use namespace::autoclean;

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
    handles  => [ 'schema', 'throw' ]
);

has cached_constraint_methods => (
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        has_cached_constraint_method => 'exists',
        get_cached_constraint_method => 'get',
        set_cached_constraint_method => 'set'
    }
);

sub init_constraint_method {
    my ( $self, $constraint_name ) = @_;

    my $constraint = LIMS2::Model::FormValidator::Constraint->$constraint_name( $self->model );

    return sub {
        my $dfv = shift;
        $dfv->name_this($constraint_name);
        my $val = $dfv->get_current_constraint_value();
        return $constraint->($val);
    };
}

sub constraint_method {
    my ( $self, $constraint_name ) = @_;

    unless ( $self->has_cached_constraint_method($constraint_name) ) {
        $self->set_cached_constraint_method( $constraint_name => $self->init_constraint_method($constraint_name) );
    }

    return $self->get_cached_constraint_method($constraint_name);
}

sub post_filter {
    my ( $self, $method, $value ) = @_;

    if ( defined $value ) {
        return $self->model->$method($value);
    }
    else {
        return;
    }
}

sub check_params {
    my ( $self, $params, $spec, %opts ) = @_;

    $params ||= {};

    if ( $opts{ignore_unknown} ) {
        $params = { slice_def $params, keys %{$spec} };
    }

    my $results = Data::FormValidator->check( $params, $self->dfv_profile($spec) );

    if ( !$results->success ) {
    	DEBUG "Invalid parameters seen in ".( caller(2) )[3];
        $self->throw( Validation => { params => $params, results => $results } );
    }

    if ( $results->has_unknown && !$opts{ignore_unknown} ) {
    	DEBUG "Invalid parameters seen in ".( caller(2) )[3];
        $self->throw( Validation => { params => $params, results => $results } );
    }

    my $validated_params = $results->valid;

    while ( my ( $field, $f_spec ) = each %{$spec} ) {
        next unless $validated_params->{$field};

        if ( $f_spec->{post_filter} ) {
            $validated_params->{$field} = $self->post_filter( $f_spec->{post_filter}, $validated_params->{$field} );
        }
        if ( $f_spec->{rename} ) {
            $validated_params->{ $f_spec->{rename} } = delete $validated_params->{$field};
        }
    }

    return $validated_params;
}

sub dfv_profile {
    my ( $self, $spec ) = @_;

    my ( @required, @optional, %constraint_methods, %field_filters, %defaults );

    my $dependencies      = delete $spec->{DEPENDENCIES};
    my $dependency_groups = delete $spec->{DEPENDENCY_GROUPS};
    my $require_some      = delete $spec->{REQUIRE_SOME};

    while ( my ( $field, $f_spec ) = each %{$spec} ) {
        if ( $f_spec->{optional} ) {
            push @optional, $field;
        }
        else {
            push @required, $field;
        }
        if ( $f_spec->{validate} ) {
            $constraint_methods{$field} = $self->constraint_method( $f_spec->{validate} );
        }
        if ( $f_spec->{filter} ) {
            $field_filters{$field} = $f_spec->{filter} || [];
        }
        if ( defined $f_spec->{default} ) {
            $defaults{$field} = $f_spec->{default};
        }
        if ( not( defined $f_spec->{trim} ) or $f_spec->{trim} ) {
            push @{ $field_filters{$field} }, 'trim';
        }
    }

    return {
        required           => \@required,
        optional           => \@optional,
        defaults           => \%defaults,
        field_filters      => \%field_filters,
        constraint_methods => \%constraint_methods,
        dependencies       => $dependencies,
        dependency_groups  => $dependency_groups,
        require_some       => $require_some,
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__



