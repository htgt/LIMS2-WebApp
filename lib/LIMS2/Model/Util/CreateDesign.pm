package LIMS2::Model::Util::CreateDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CreateDesign::VERSION = '0.138';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
              exons_for_gene
              get_ensembl_gene
          )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( uniq );
use LIMS2::Model::Util::DesignTargets qw( prebuild_oligos );
use LIMS2::Util::EnsEMBL;
use LIMS2::Exception;

=head2 exons_for_gene

Given a gene name find all its exons that could be targeted for a design.
Optionally get all exons or just exons from canonical transcript.

=cut
sub exons_for_gene {
    my ( $model, $gene_name, $exon_types, $species ) = @_;

    my $gene = get_ensembl_gene( $model, $gene_name, $species );
    return unless $gene;

    my $gene_data = build_gene_data( $gene, $species );

    my $exon_data = build_gene_exon_data( $model, $gene, $gene_data->{gene_id}, $exon_types, $species );

    return ( $gene_data, $exon_data );
}

=head2 build_gene_data

Build up data about targeted gene to display to user.

=cut
sub build_gene_data {
    my ( $gene, $species ) = @_;
    my %data;

    my $canonical_transcript = $gene->canonical_transcript;
    $data{ensembl_id} = $gene->stable_id;
    if ( $species eq 'Human' ) {
        $data{gene_link} = 'http://www.ensembl.org/Homo_sapiens/Gene/Summary?g='
            . $gene->stable_id;
        $data{transcript_link} = 'http://www.ensembl.org/Homo_sapiens/Transcript/Summary?t='
            . $canonical_transcript->stable_id;

        $data{gene_id} = external_gene_id( $gene, 'HGNC' );
    }
    elsif ( $species eq 'Mouse' ) {
        $data{gene_link} = 'http://www.ensembl.org/Mus_musculus/Gene/Summary?g='
            . $gene->stable_id;
        $data{transcript_link} = 'http://www.ensembl.org/Mus_musculus/Transcript/Summary?t='
            . $canonical_transcript->stable_id;

        $data{gene_id} = external_gene_id( $gene, 'MGI' );
    }
    $data{marker_symbol} = $gene->external_name;
    $data{canonical_transcript} = $canonical_transcript->stable_id;

    $data{strand} = $gene->strand;
    $data{chr} = $gene->seq_region_name;

    return \%data;
}

=head2 external_gene_id

Work out external gene id:
Human = HGNC
Mouse = MGI

If I have multiple ids pick the first one.
If I can not find a id go back to marker symbol.

=cut
sub external_gene_id {
    my ( $gene, $type ) = @_;

    my @dbentries = @{ $gene->get_all_DBEntries( $type ) };
    my @ids = uniq map{ $_->primary_id } @dbentries;

    if ( @ids ) {
        my $id = shift @ids;
        return 'HGNC:' . $id;
    }
    else {
        # return marker symbol
        return $gene->external_name;
    }

    return;
}

=head2 build_gene_exon_data

Grab genes from given exon and build up a hash of
data to display

=cut
sub build_gene_exon_data {
    my ( $model, $gene, $gene_id, $exon_types, $species ) = @_;

    my $canonical_transcript = $gene->canonical_transcript;
    my $exons = $exon_types eq 'canonical' ? $canonical_transcript->get_all_Exons : $gene->get_all_Exons;

    my %exon_data;
    for my $exon ( @{ $exons } ) {
        my %data;
        $data{id} = $exon->stable_id;
        $data{size} = $exon->length;
        $data{chr} = $exon->seq_region_name;
        $data{start} = $exon->start;
        $data{end} = $exon->end;
        $data{start_phase} = $exon->phase;
        $data{end_phase} = $exon->end_phase;
        #TODO this may not be expected data sp12 Tue 03 Dec 2013 11:16:27 GMT
        #     not clear what constitutive means to Ensembl
        $data{constitutive} = $exon->is_constitutive ? 'yes' : 'no';

        $exon_data{ $exon->stable_id } = \%data;
    }
    designs_for_exons( $model, \%exon_data, $species, $gene_id );
    design_targets_for_exons( $model, \%exon_data, $gene->stable_id );
    exon_ranks( \%exon_data, $canonical_transcript );

    if ( $gene->strand == 1 ) {
        return [ sort { $a->{start} <=> $b->{start} } values %exon_data ];
    }
    else {
        return [ sort { $b->{start} <=> $a->{start} } values %exon_data ];
    }
    return;
}

=head2 get_ensembl_gene

Grab a ensembl gene object.
First need to work out format of gene name user has supplied

=cut
## no critic(BuiltinFunctions::ProhibitComplexMappings)
sub get_ensembl_gene {
    my ( $model, $gene_name, $species ) = @_;

    my $ga = $model->ensembl_gene_adaptor( $species );

    my $gene;
    if ( $gene_name =~ /ENS(MUS)?G\d+/ ) {
        $gene = $ga->fetch_by_stable_id( $gene_name );
    }
    elsif ( $gene_name =~ /HGNC:(\d+)/ ) {
        $gene = _fetch_by_external_name( $ga, $1, 'HGNC' );
    }
    elsif ( $gene_name =~ /MGI:(\d+)/  ) {
        $gene = _fetch_by_external_name( $ga, $1, 'MGI' );
    }
    else {
        #assume its a marker symbol
        $gene = _fetch_by_external_name( $ga, $gene_name );
    }

    return $gene;
}
## use critic

=head2 _fetch_by_external_name

Wrapper around fetching ensembl gene given external gene name.

=cut
sub _fetch_by_external_name {
    my ( $ga, $gene_name, $type ) = @_;

    my @genes = @{ $ga->fetch_all_by_external_name($gene_name, $type) };
    unless( @genes ) {
        LIMS2::Exception->throw("Unable to find gene $gene_name in EnsEMBL" );
    }

    if ( scalar(@genes) > 1 ) {
        DEBUG("Found multiple EnsEMBL genes for $gene_name");
        my @stable_ids = map{ $_->stable_id } @genes;
        $type ||= 'marker symbol';

        LIMS2::Exception->throw( "Found multiple EnsEMBL genes with $type id $gene_name,"
                . " try using one of the following EnsEMBL gene ids: "
                . join( ', ', @stable_ids ) );
    }
    else {
        return shift @genes;
    }

    return;
}

=head2 designs_for_exons

Grab any existing designs for the exons.

=cut
sub designs_for_exons {
    my ( $model, $exons, $species, $gene_id ) = @_;

    my @designs = $model->schema->resultset('Design')->search(
        {
            'genes.gene_id' => $gene_id,
            'me.species_id' => $species,
            design_type_id  => 'gibson',
        },
        {
            join     => 'genes',
            prefetch =>  { 'oligos' => { 'loci' => 'chr' } },
        },
    );

    my $assembly = $model->schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $species } )->assembly_id;

    my %data;
    while ( my( $id, $exon ) = each %{ $exons } ) {
        my @matching_designs;

        for my $design ( @designs ) {
            my $oligo_data = prebuild_oligos( $design, $assembly );
            # if no oligo data then design does not have oligos on assembly
            next unless $oligo_data;
            my $di = LIMS2::Model::Util::DesignInfo->new(
                design => $design,
                oligos => $oligo_data,
            );
            if ( $exon->{start} > $di->target_region_start
                && $exon->{end} < $di->target_region_end
                && $exon->{chr} eq $di->chr_name
            ) {
                push @matching_designs, $design;
            }
        }
        $exon->{designs} = [ map { $_->id } @matching_designs ]
            if @matching_designs;
    }

    return;
}

=head2 design_targets_for_exons

Note if any of the exons are already design targets.
This indicates they have been picked as good targets either by
a automatic target finding script or a human.

=cut
sub design_targets_for_exons {
    my ( $model, $exons, $ensembl_gene_id ) = @_;

    my $dt_rs = $model->schema->resultset('DesignTarget')->search(
        { ensembl_gene_id => $ensembl_gene_id } );

    for my $exon_id ( keys %{ $exons } ) {
        if ( my $dt = $dt_rs->find( { ensembl_exon_id => $exon_id } ) ) {
            $exons->{$exon_id}{dt} = 1;
        }
        else {
            $exons->{$exon_id}{dt} = 0;
        }
    }

    return;
}

=head2 exon_ranks

Get rank of exons on canonical transcript.
If exon not on canonical transcript rank is left blank for now.

=cut
sub exon_ranks {
    my ( $exons, $canonical_transcript ) = @_;

    my $rank = 1;
    for my $current_exon ( @{ $canonical_transcript->get_all_Exons } ) {
        my $current_id = $current_exon->stable_id;
        if ( exists $exons->{ $current_id } ) {
            $exons->{ $current_id }{rank} = $rank;
        }
        $rank++;
    }

    return;
}

1;

__END__
