package LIMS2::Model::Util::DesignInfo;

use Moose;
use LIMS2::Exception;
use namespace::autoclean;

use List::MoreUtils qw( uniq all );

with 'MooseX::Log::Log4perl';

has design => (
    is       => 'ro',
    isa      => 'LIMS2::Model::Schema::Result::Design',
    required => 1,
);

has type => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_type {
    return shift->design->design_type_id;
}

has default_assembly => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_default_assembly {
    return shift->design->species->default_assembly->assembly_id;
}

has oligos => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1,
);

has chr_strand => (
    is         => 'ro',
    isa        => 'Int',
    init_arg   => undef,
    lazy_build => 1
);

has chr_name => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1
);

has [
    qw( target_region_start target_region_end )
] => (
    is         => 'ro',
    isa        => 'Maybe[Int]',
    init_arg   => undef,
    lazy_build => 1,
);

has ensembl_util => (
    isa        => 'LIMS2::Util::EnsEMBL',
    lazy_build => 1,
    handles    => {
        #make all the functions accessible without having to do ensembl->slice_adaptor
        map { $_ => $_ }
            qw( db_adaptor gene_adaptor slice_adaptor transcript_adaptor 
                constrained_element_adaptor repeat_feature_adaptor )
    }
);

has target_region_slice => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::Slice',
    init_arg   => undef,
    lazy_build => 1,
);

has target_gene => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::Gene',
    init_arg   => undef,
    lazy_build => 1
);

has target_transcript => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::Transcript',
    init_arg   => undef,
    lazy_build => 1
);

has floxed_exons => (
    is         => 'ro',
    isa        => 'ArrayRef[Bio::EnsEMBL::Exon]',
    traits     => [ 'Array' ],
    init_arg   => undef,
    lazy_build => 1,
    handles    => {
        first_floxed_exon => [ 'get',  0 ],
        last_floxed_exon  => [ 'get', -1 ],
        num_floxed_exons  => 'count',
    },
);

sub _build_target_region_start {
    my $self = shift;

    if ( $self->type eq 'deletion' || $self->type eq 'insertion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{U5}{end};
        }
        else {
            return $self->oligos->{D3}{end};
        }
    }

    if ( $self->type eq 'conditional' || $self->type eq 'artificial-intron' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{U3}{start};
        }
        else {
            return $self->oligos->{D5}{start}
        }
    }
}

sub _build_target_region_end {
    my $self = shift;

    if ( $self->type eq 'deletion' || $self->type eq 'insertion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{D3}{start};
        }
        else {
            return $self->oligos->{U5}{start}
        }
    }

    if ( $self->type eq 'conditional' || $self->type eq 'artificial-intron' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{D5}{end}
        }
        else {
            return $self->oligos->{U3}{end};
        }
    }
}

sub _build_chr_strand {
    my $self = shift;

    my @strands = uniq map { $_->{strand} } values %{ $self->oligos };
    LIMS2::Exception->throw(
        'Design ' . $self->design->id . ' oligos have inconsistent strands'
    ) unless @strands == 1;

    return shift @strands;
}

sub _build_chr_name {
    my $self = shift;

    my @chr_names = uniq map { $_->{chromosome} } values %{ $self->oligos };
    LIMS2::Exception->throw(
        'Design ' . $self->design->id . ' oligos have inconsistent chromosomes'
    ) unless @chr_names == 1;

    return shift @chr_names;
}

# Build up oligos with information from current assembly
sub _build_oligos {
    my $self = shift;
    my %oligos;

    for my $oligo ( $self->design->oligos ) {
        my %oligo_data;
        my $locus = $oligo->loci->find( { assembly_id => $self->default_assembly } );
        LIMS2::Exception->throw( 'No locus information for oligo: ' . $oligo->design_oligo_type_id )
            unless $locus;

        %oligo_data = (
            start      => $locus->chr_start,
            end        => $locus->chr_end,
            chromosome => $locus->chr->name,
            strand     => $locus->chr_strand,
        );
        $oligo_data{seq} = $oligo->seq;

        $oligos{ $oligo->design_oligo_type_id } = \%oligo_data;
    }

    return \%oligos;
}

sub _build_ensembl_util {
    my $self = shift;
    require LIMS2::Util::EnsEMBL;

    return LIMS2::Util::EnsEMBL->new( species => $self->design->species_id );
}

#
#add actual things to call all of these builders
#

sub _build_target_region_slice {
    my $self = shift;

    return $self->slice_adaptor->fetch_by_region(
        'chromosome',
        $self->chr_name,
        $self->target_region_start,
        $self->target_region_end,
        $self->chr_strand
    );
}


sub _build_target_gene {
    my $self = shift;

    my $exons = $self->target_region_slice->get_all_Exons;
    confess "No exons found in target region"
        unless @{ $exons };

    #find all the genes that the exons in our target region belong to
    my %genes_in_target_region;
    for my $e ( @{ $exons } ) {
        my $gene = $self->gene_adaptor->fetch_by_exon_stable_id( $e->stable_id );
        $genes_in_target_region{ $gene->stable_id } ||= $gene;
    }

    #if we just got one thats ideal go ahead and return it.
    my @genes = keys %genes_in_target_region;
    if ( @genes == 1 ) {
        #make sure the coordinates are relative to the chromosome like everything else.
        return $genes_in_target_region{ pop @genes }->transform( 'chromosome' );
    }
    elsif ( @genes > 1 ) {
        #use _get_mgi_accession or whatever its called. 
        confess "Found more than one gene for design " . $self->design->id . ": " . join ", ", @genes;
    }

    #if not we have to do something else to identify the appropriate gene.
    #for now we'll just die. It could also be that no genes were found
    confess "Couldnt find any genes for design " . $self->design->id;
}

sub _build_target_transcript {
    my $self = shift;

    #first see if the target transcript specified by the design is valid. if so just return that.
    #a target transcript is optional though.
    if ( $self->design->target_transcript ) {
        my $target = $self->design->target_transcript;
        my $transcript = $self->transcript_adaptor->fetch_by_stable_id( $target );

        return $transcript if $transcript;

        $self->log->warn( "A transcript was provided ($target) but ensembl could not find it." );
    }

    #if we're here we didnt get a valid transcript, or one was not provided then find the transcript
    #with the longest translation and transcription length
    my $best_transcript;
    for my $transcript ( @{ $self->target_gene->get_all_Transcripts } ) {
        #skip non coding transcripts
        next unless $transcript->translation;

        #if we don't have a transcript already then we'll use the first coding one.
        unless ( $best_transcript ) {
            $best_transcript = $transcript;
            next;
        }

        if ( $transcript->translation->length > $best_transcript->translation->length ) {
            $best_transcript = $transcript;
        }
        elsif ( $transcript->translation->length == $best_transcript->translation->length ) {
            #only replace transcripts of equal translation length if the transcript is longer
            if ( $transcript->length > $best_transcript->length ) {
                $best_transcript = $transcript;
            }
        }
    }

    confess "Couldn't find a valid transcript for " . $self->target_gene->stable_id
        unless $best_transcript;

    return $best_transcript;
}

sub _build_floxed_exons {
    my $self = shift;

    my ( $start, $end ) = ( $self->target_region_start, $self->target_region_end );

    #retrieve all exons that are within the bounds of our target region
    my @exons = grep { $_->start <= $end and $_->end >= $start }
                    map { $_->transform( 'chromosome' ) } #map coordinates to chromosome location
                        @{ $self->target_transcript->get_all_Exons };

    return \@exons;
}

sub get_mgi_accession_id_for_gene {
    my ( $self, $gene ) = @_;

    #add a cache here if this is slow.

    #this seems to be the recommended way to do this, i couldn't find how to get just the MGI xref
    for my $db_entry ( @{ $gene->get_all_DBEntries() } ) {
        if ( $db_entry->dbname eq "MGI" ) {
            return $db_entry->primary_id;
        }
    }

    confess "Couldn't find MGI accession id for " . $gene->stable_id;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
