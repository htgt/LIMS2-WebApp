package LIMS2::CassetteFunction;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::CassetteFunction::VERSION = '0.387';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( satisfies_cassette_function ) ]
};

use LIMS2::Exception::Implementation;
use List::MoreUtils qw( any all );

use Readonly;
Readonly my $CASSETTE_FUNCTION_CHECKS => {
    ko_first                   => [ \&has_conditional_cassette, \&has_no_recombinase ],
    ko_first_promoter          => [ \&has_conditional_cassette, \&has_promoter_cassette, \&has_no_recombinase ],
    ko_first_promoterless      => [ \&has_conditional_cassette, \&has_promoterless_cassette, \&has_no_recombinase ],
    reporter_only              => [ \&has_conditional_cassette, \&has_cre_recombinase ],
    reporter_only_promoter     => [ \&has_conditional_cassette, \&has_promoter_cassette, \&has_cre_recombinase ],
    reporter_only_promoterless => [ \&has_conditional_cassette, \&has_promoterless_cassette, \&has_cre_recombinase ],
    cre_knock_in               => [ \&has_cre_cassette ]
};

sub satisfies_cassette_function {
    my ( $function, $well ) = @_;

    my $checks = $CASSETTE_FUNCTION_CHECKS->{$function}
        or LIMS2::Exception::Implementation->throw( "Unrecognized cassette function '$function'" );

    return all { $_->($well) } @{$checks};
}

sub has_conditional_cassette {
    my $well = shift;

    return $well->cassette->conditional;
}

sub has_promoter_cassette {
    my $well = shift;

    return $well->cassette->promoter;
}

sub has_promoterless_cassette {
    my $well = shift;

    return ! has_promoter_cassette($well);
}

sub has_cre_cassette {
    my $well = shift;

    return $well->cassette->cre;
}

sub has_cre_recombinase {
    my $well = shift;

    return any { $_ eq 'Cre' } @{$well->recombinases};
}

sub has_no_recombinase {
    my $well = shift;

    return @{$well->recombinases} == 0;
}

1;

__END__
