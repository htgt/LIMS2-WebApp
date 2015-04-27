package LIMS2::Model::FormValidator;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::FormValidator::VERSION = '0.309';
}
## use critic


=head1 NAME

LIMS2::Model::FormValidator

=head1 DESCRIPTION

Subclass of WebAppCommon::FormValidator, which is where the bulk of the code is.

=cut

use warnings FATAL => 'all';

use Moose;
use LIMS2::Model::FormValidator::Constraint;
use namespace::autoclean;

extends 'WebAppCommon::FormValidator';

has '+model' => (
    isa => 'LIMS2::Model',
);

=head2 _build_constraints

Override WebAppCommon::FormValidator::Constraint to use LIMS2::Model::FormValidator::Constraint
which is itself a subclass of WebAppCommon::FormValidator::Constraint.

=cut
override _build_constraints => sub {
    my $self = shift;
    return LIMS2::Model::FormValidator::Constraint->new( model => $self->model );
};

=head2 throw

Override parent throw method to use LIMS2::Exception::Validation.
We can call throw from LIMS2::Model.

=cut
override throw => sub {
    my ( $self, $params, $results ) = @_;

    $self->model->throw( Validation => { params => $params, results => $results } );
};


__PACKAGE__->meta->make_immutable;

1;

__END__



