package LIMS2::Model::Util::CrisprBrowser;
use strict;
use warnings FATAL => 'all';


=head1 NAME

LIMS2::Model::Util::CrisprBrowser

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ qw( crisprs_for_region_as_arrayref
                    ) ]
};

use Log::Log4perl qw( :easy );

=head2 crisprs_for_region 

Find crisprs for a specific chromosome region. The search is not design
related. The method accepts species, chromosome id, start and end coordinates.

This method is used by the browser REST api to server data for the genome browser.

dp10
=cut

sub crisprs_for_region {
    my $schema = shift;
    my $params = shift;

    my $crisprs_rs = $schema->resultset('Crispr')->search(
        {
            'loci.assembly_id' => $params->{assembly_id},
            'loci.chr_id'      => $params->{chromosome_id},
            # need all the crisprs starting with values >= start_coord
            # and whose start values are <= end_coord
            'loci.chr_start'   => { -between => [
                $params->{start_coord},
                $params->{end_coord},
                ],
            },
            #'loci.chr_end'     => { '<=', $params->{end_coord} },
            # probably not interested in the end value
        },
        {
            join     => 'loci',
#            prefetch => 'off_target_summaries',
        }
    );

    return $crisprs_rs;
}

=head crisprs_for_region_as_arrayref 

Return and array of hashrefs properly inflated for the browser.
This is suitable for serialisation as JSON.

=cut

sub crisprs_for_region_as_arrayref {
    my $schema = shift;
    my $params = shift;

    my $crisprs_rs = crisprs_for_region( $schema, $params ) ;
    $crisprs_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @crisprs;

    while ( my $hashref = $crisprs_rs->next ) {
        push @crisprs, $hashref;
    }

    return \@crisprs;
}

1;
