package LIMS2::Model::Util::CrisprBrowser;
use strict;
use warnings FATAL => 'all';


=head1 NAME

LIMS2::Model::Util::CrisprBrowser

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ qw(
        crisprs_for_region
        retrieve_chromosome_id
        crisprs_to_gff
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

    # Chromosome number is looked up in the chromosomes table to get the chromosome_id
    $params->{chromosome_id} = retrieve_chromosome_id( $schema, $params->{species}, $params->{chromosome_number} );

    my $crisprs_rs = $schema->resultset('CrisprLocus')->search(
        {
            'assembly_id' => $params->{assembly_id},
            'chr_id'      => $params->{chromosome_id},
            # need all the crisprs starting with values >= start_coord
            # and whose start values are <= end_coord
            'chr_start'   => { -between => [
                $params->{start_coord},
                $params->{end_coord},
                ],
            },
        },
    );

    return $crisprs_rs;
}

=head crisp_pairs_for_region

Returns a resultset containing the paired Crisprs for the region defined by params.

Individual crisprs for a region on a chromosome must be looked up in the CrisprPairs table.
This is done by a join pulling back all the pairs in one go.

=cut

sub crisp_pairs_for_region {
    my $schema = shift;
    my $params = shift;

    my $crisprs_rs = crisprs_for_region( $schema, $params );

    # Now we adjust the resultset query with the join
    $crisprs_rs = $crisprs_rs->search( undef,
        {
            join => 'CrisprPair',
        },
    );
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

sub retrieve_chromosome_id {
    my $schema = shift;
    my $species = shift;
    my $chromosome_number = shift;

    my $chr_id = $schema->resultset('Chromosome')->find( {
            'species_id' => $species,
            'name'       => $chromosome_number,
        }
    );
    return $chr_id->id;
}

=head crisprs_to_gff

Return a reference to an array of strings.
The format of each string is standard GFF3 - that is hard tab separated fields.

=cut

sub crisprs_to_gff {
    my $crisprs_rs = shift;
    my $params = shift;

    my @crisprs_gff;

    push @crisprs_gff, "##gff-version 3";
    push @crisprs_gff, '##sequence-region lims2-region '
        . $params->{'start_coord'}
        . ' '
        . $params->{'end_coord'} ;
    push @crisprs_gff, '# Crisprs for region '
        . $params->{'species'}
        . '('
        . $params->{'assembly_id'}
        . ') '
        . $params->{'chromosome_number'}
        . ':'
        . $params->{'start_coord'}
        . '-'
        . $params->{'end_coord'} ;

        while ( my $crispr_r = $crisprs_rs->next ) {
            my $datum = $params->{'chromosome_number'};
            # biological_region is an allowed term in SOFA
            # In GFF3, this field is restricted to SOFA terms
#            $datum .= "\tLIMS2\tbiological_region\t";
            $datum .= "\tLIMS2\texons\t";
            $datum .= $crispr_r->chr_start . "\t";
            $datum .= $crispr_r->chr_end . "\t";
            $datum .= '.'; # no score value
            $datum .= "\t";
            $datum .= ( $crispr_r->chr_strand == 1 ) ? '+' : '-' ;
            $datum .= "\t";
            $datum .= '.'; # phase not available
            $datum .= "\t";
            $datum .= 'ID=' . $crispr_r->crispr_id . ';' ;
            $datum .= 'Name=' . 'LIMS2' . '-' . $crispr_r->crispr_id ;

            push @crisprs_gff, $datum ;
        }




    return \@crisprs_gff;
}


sub crispr_pairs_to_gff {

}

1;
