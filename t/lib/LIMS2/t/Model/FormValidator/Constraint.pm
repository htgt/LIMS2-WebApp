package LIMS2::t::Model::FormValidator::Constraint;

use base qw(Test::Class);
use Test::Most;
use LIMS2::Test model => { classname => __PACKAGE__ }, 'test_data';

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/FormValidator/Constraint.pm - test class for LIMS2::Model::FormValidator::Constraint

NOTE: Only a handful of constraints have been tested, many more
that could be tested.

=cut

sub startup : Test(startup => 4) {
    my $test = shift;

    my $class = 'LIMS2::Model::FormValidator::Constraint';
    use_ok $class;
    can_ok $class, 'new';
    ok my $o = $class->new( model => model() ), 'can create a new object';

    isa_ok $o, $class;

    $test->{o} = $o;
};

=head2

Test a handful of constraints that use different underlying methods.
These are from WebApp::Common::FormValidator::Constraint and
LIMS2::Model::FormValidator::Constraint

=cut

# in_set
sub strand : Tests(3) {
    my $test = shift;
    my $constraint = $test->{o}->strand();

    ok $constraint->(1), '1 is valid ';
    ok $constraint->(-1), '-1 is valid';
    ok !$constraint->(2), '2 is not valid';
}

# regexp_matches
sub alphanumeric_string : Tests(3) {
    my $test = shift;
    my $constraint = $test->{o}->alphanumeric_string();

    ok $constraint->('abc123'), 'abc123 is valid';
    ok $constraint->('word'), 'word is valid';
    ok !$constraint->('%^&'), '%^& is not valid';
}

# in_resultset
sub existing_species : Tests(3) {
    my $test = shift;
    my $constraint = $test->{o}->existing_species();

    ok $constraint->('Mouse'), 'mouse is valid';
    ok $constraint->('Human'), 'human is valid';
    ok !$constraint->('Unicorn'), 'unicorn is not valid';
}

# existing_row
sub existing_plate_name : Tests(3) {
    my $test = shift;
    my $constraint = $test->{o}->existing_plate_name();

    ok $constraint->('FP4637'), 'FP4637 is valid';
    ok $constraint->('CEPD0011_2'), 'CEPD0011_2 is valid';
    ok !$constraint->('Foo'), 'Foo is not valid';
}

# eng_seq_of_type
sub existing_final_cassette : Tests(3) {
    my $test = shift;
    my $constraint = $test->{o}->existing_final_cassette();

    ok $constraint->('L1L2_gt0'), 'L1L2_gt0 is valid';
    ok $constraint->('L1L2_Bact_P'), 'L1L2_Bact_P is valid';
    ok !$constraint->('Foo'), 'Foo is not valid';
}

## use critic

1;

__END__

