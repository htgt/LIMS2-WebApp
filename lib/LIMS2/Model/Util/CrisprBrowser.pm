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
        crisprs_to_gff
        crispr_pairs_for_region
        crispr_pairs_to_gff 
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

=head crispr_pairs_for_region

Returns a resultset containing the paired Crisprs for the region defined by params.

Individual crisprs for a region on a chromosome must be looked up in the CrisprPair table.
This is done by a join pulling back all the pairs in one go.

=cut

sub crispr_pairs_for_region {
    my $schema = shift;
    my $params = shift;


    $params->{chromosome_id} = retrieve_chromosome_id( $schema, $params->{species}, $params->{chromosome_number} );

    my $crisprs_rs = $schema->resultset('CrisprBrowserPairs')->search( {},
        {
            bind => [
                $params->{start_coord},
                $params->{end_coord},
                $params->{chromosome_id},
                $params->{assembly_id},
            ],
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
            my %crispr_format_hash = (
                'seqid' => $params->{'chromosome_number'},
                'source' => 'LIMS2',
                'type' => 'Crispr',
                'start' => $crispr_r->chr_start,
                'end' => $crispr_r->chr_end,
                'score' => '.',
                'strand' => '+' ,
#                'strand' => '.',
                'phase' => '.',
                'attributes' => 'ID='
                    . 'C_' . $crispr_r->crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->crispr_id . ';'
                );
            my $crispr_parent_datum = prep_crispr_datum( \%crispr_format_hash );
            $crispr_format_hash{'type'} = 'CDS';
            $crispr_format_hash{'attributes'} =     'ID='
                    . $crispr_r->crispr_id . ';'
                    . 'Parent=C_' . $crispr_r->crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->crispr_id . ';'
                    . 'color=#45A825;'; # greenish
            my $crispr_child_datum = prep_crispr_datum( \%crispr_format_hash );
            push @crisprs_gff, $crispr_parent_datum, $crispr_child_datum ;
        }




    return \@crisprs_gff;
}


=head crispr_pairs_to_gff 
Returns an array representing a set of strings ready for 
concatenation to produce a GFF3 format file.

=cut

sub crispr_pairs_to_gff {
    my $crisprs_rs = shift;
    my $params = shift;
#$DB::single=1;
    my @crisprs_gff;

    push @crisprs_gff, "##gff-version 3";
    push @crisprs_gff, '##sequence-region lims2-region '
        . $params->{'start_coord'}
        . ' '
        . $params->{'end_coord'} ;
    push @crisprs_gff, '# Crispr pairs for region '
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
            my %crispr_format_hash = (
                'seqid' => $params->{'chromosome_number'},
                'source' => 'LIMS2',
                'type' => 'crispr_pair',
                'start' => $crispr_r->left_crispr_start,
                'end' => $crispr_r->right_crispr_end,
                'score' => '.',
                'strand' => '+' ,
#                'strand' => '.',
                'phase' => '.',
                'attributes' => 'ID='
                    . $crispr_r->pair_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->pair_id . ';'
                );
            my $crispr_pair_parent_datum = prep_crispr_datum( \%crispr_format_hash );
            $crispr_format_hash{'type'} = 'CDS';
            $crispr_format_hash{'end'} = $crispr_r->left_crispr_end;
            $crispr_format_hash{'attributes'} =     'ID='
                    . $crispr_r->left_crispr_id . ';'
                    . 'Parent=' . $crispr_r->pair_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->left_crispr_id . ';'
                    . 'color=#AA2424;' # reddish
                    . 'Comment=Junk;';
            my $crispr_left_datum = prep_crispr_datum( \%crispr_format_hash );
            $crispr_format_hash{'start'} = $crispr_r->right_crispr_start;
            $crispr_format_hash{'end'} = $crispr_r->right_crispr_end;
            $crispr_format_hash{'attributes'} =     'ID='
                    . $crispr_r->right_crispr_id . ';'
                    . 'Parent=' . $crispr_r->pair_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->right_crispr_id . ';'
                    . 'color=#1A8599;' # blueish
                    . 'Comment=Junk;';
#            $crispr_format_hash{'attributes'} = $crispr_r->pair_id;
            my $crispr_right_datum = prep_crispr_datum( \%crispr_format_hash );
            push @crisprs_gff, $crispr_pair_parent_datum, $crispr_left_datum, $crispr_right_datum ;
        }


    return \@crisprs_gff;
}

sub prep_crispr_datum {
    my $crispr_hr = shift;

    my @data;

    push @data, @$crispr_hr{qw/
        seqid
        source
        type
        start
        end
        score
        strand
        phase
        attributes
        /};
    my $datum = join "\t", @data;
    return $datum;
}

1;
