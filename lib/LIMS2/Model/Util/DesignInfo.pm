package LIMS2::Model::Util::DesignInfo;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::DesignInfo::VERSION = '0.499';
}
## use critic


use Moose;
use LIMS2::Exception;
use namespace::autoclean;
use Try::Tiny;

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
    qw( loxp_start loxp_end target_region_start target_region_end
        cassette_start cassette_end homology_arm_start homology_arm_end start end)
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
                constrained_element_adaptor repeat_feature_adaptor
                get_best_transcript get_exon_rank )
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

sub _build_start{
    my $self = shift;

    my $min_coord;
    foreach my $oligo ($self->design->oligos){
        my $oligo_start = $oligo->current_locus->chr_start;
        if($min_coord){
            if($oligo_start < $min_coord){
                $min_coord = $oligo_start;
            }
        }
        else{
            $min_coord = $oligo_start;
        }
    }
    return $min_coord;
}

sub _build_end{
    my $self = shift;

    my $max_coord = 0;
    foreach my $oligo ($self->design->oligos){
        my $oligo_end = $oligo->current_locus->chr_end;

        if($oligo_end > $max_coord){
            $max_coord = $oligo_end;
        }
    }
    return $max_coord;
}

#TODO We are assuming that gibson designs are being treated as conditionals
#     If the design is being used as a deletion the coordinates will be different
#     Normal gibson designs can be conditional or deletion
#     deletion-gibson designs can only be deletion designs
#     Need to pass a flag in to this object if we know the design in a deletion

## no critic(Subroutines::ProhibitExcessComplexity)
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
            return $self->oligos->{D5}{start};
        }
    }

    # Assuming gibson design is used as a conditional
    if ( $self->type eq 'gibson') {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{EF}{end};
        }
        else {
            return $self->oligos->{ER}{end};
        }
    }

    if ( $self->type eq 'gibson-deletion' || $self->type eq 'conditional-inversion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'5R'}{end};
        }
        else {
            return $self->oligos->{'3F'}{end};
        }
    }

    if ( $self->type eq 'fusion-deletion') {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'U5'}{end};
        }
        else {
            return $self->oligos->{'D3'}{end};
        }
    }

    if ( $self->type =~ m/
            ^miseq #starts with "miseq"
            /xms ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'INF'}{end};
        }
        else {
            return $self->oligos->{'INR'}{start};
        }
    }
    # For nonsense designs ( have only 1 oligo ) we set the whole oligo as the
    # target region, not a ideal solution but the least painful one I can think of
    if ( $self->type eq 'nonsense' ) {
        return $self->oligos->{'N'}{start};
    }

    # Do the same for point mutation designs
    if( $self->type eq 'point-mutation'){
        return $self->oligos->{'PM'}{start};
    }

    return;
}

sub _build_target_region_end {
    my $self = shift;
    if ( $self->type eq 'deletion' || $self->type eq 'insertion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{D3}{start};
        }
        else {
            return $self->oligos->{U5}{start};
        }
    }

    if ( $self->type eq 'conditional' || $self->type eq 'artificial-intron' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{D5}{end};
        }
        else {
            return $self->oligos->{U3}{end};
        }
    }

    # Assuming gibson design is used as a conditional
    if ( $self->type eq 'gibson' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{ER}{start};
        }
        else {
            return $self->oligos->{EF}{start};
        }
    }

    if ( $self->type eq 'gibson-deletion' || $self->type eq 'conditional-inversion') {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'3F'}{start};
        }
        else {
            return $self->oligos->{'5R'}{start};
        }
    }

    if ( $self->type eq 'fusion-deletion') {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'D3'}{start};
        }
        else {
            return $self->oligos->{'U5'}{start};
        }
    }
    if ( $self->type =~ m/
            ^miseq #starts with "miseq"
            /xms ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'INR'}{start};
        }
        else {
            return $self->oligos->{'INF'}{end};
        }
    }
# For nonsense designs ( have only 1 oligo ) we set the whole oligo as the
    # target region, not a ideal solution but the least painful one I can think of
    if ( $self->type eq 'nonsense' ) {
        return $self->oligos->{'N'}{end};
    }

    # Do the same for point mutation designs
    if( $self->type eq 'point-mutation'){
        return $self->oligos->{'PM'}{end};
    }

    return;
}
## use critic

sub _build_loxp_start {
    my $self = shift;
    if ( $self->type eq 'conditional' || $self->type eq 'artificial-intron' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{D5}{end} + 1;
        }
        else {
            return $self->oligos->{D3}{end} + 1;
        }
    }

    # Assuming gibson design is used as a conditional
    if ( $self->type eq 'gibson' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{ER}{end} + 1;
        }
        else {
            return $self->oligos->{EF}{end} + 1;
        }
    }

    return;
}

sub _build_loxp_end {
    my $self = shift;
    if ( $self->type eq 'conditional' || $self->type eq 'artificial-intron' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{D3}{start} - 1;
        }
        else {
            return $self->oligos->{D5}{start} - 1;
        }
    }

    # Assuming gibson design is used as a conditional
    if ( $self->type eq 'gibson' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'3F'}{start} - 1;
        }
        else {
            return $self->oligos->{'5R'}{start} - 1;
        }
    }

    return;
}

sub _build_cassette_start {
    my $self = shift;
    if ( $self->type eq 'deletion' || $self->type eq 'insertion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{U5}{end} + 1;
        }
        else {
            return $self->oligos->{D3}{end} + 1;
        }
    }

    if ( $self->type eq 'conditional' || $self->type eq 'artificial-intron' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{U5}{end} + 1;
        }
        else {
            return $self->oligos->{U3}{end} + 1;
        }
    }

    # Assuming gibson design is used as a conditional
    if ( $self->type eq 'gibson' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'5R'}{start} + 1;
        }
        else {
            return $self->oligos->{'3F'}{start} + 1;
        }
    }

    if ( $self->type eq 'gibson-deletion') {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'5R'}{end} + 1;
        }
        else {
            return $self->oligos->{'3F'}{end} + 1;
        }
    }

    return;
}

sub _build_cassette_end {
    my $self = shift;
    if ( $self->type eq 'deletion' || $self->type eq 'insertion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{D3}{start} - 1;
        }
        else {
            return $self->oligos->{U5}{start} - 1;
        }
    }

    if ( $self->type eq 'conditional' || $self->type eq 'artificial-intron' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{U3}{start} - 1;
        }
        else {
            return $self->oligos->{U5}{start} - 1;
        }
    }

    # Assuming gibson design is used as a conditional
    if ( $self->type eq 'gibson' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{EF}{start} - 1;
        }
        else {
            return $self->oligos->{ER}{start} - 1;
        }
    }

    if ( $self->type eq 'gibson-deletion') {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'3F'}{start} - 1;
        }
        else {
            return $self->oligos->{'5R'}{start} - 1;
        }
    }

    return;
}

sub _build_homology_arm_start {
    my $self = shift;
    if ( $self->type eq 'gibson' || $self->type eq 'gibson-deletion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'5F'}{start};
        }
        else {
            return $self->oligos->{'3R'}{start};
        }
    }
    elsif ( $self->type eq 'nonsense' or $self->type eq 'point-mutation') {
        return;
    }
    else {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{G5}{start};
        }
        else {
            return $self->oligos->{G3}{start};
        }
    }
}

sub _build_homology_arm_end {
    my $self = shift;
    if ( $self->type eq 'gibson' || $self->type eq 'gibson-deletion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{'3R'}{end};
        }
        else {
            return $self->oligos->{'5F'}{end};
        }
    }
    elsif ( $self->type eq 'nonsense' ) {
        return;
    }
    else {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{G3}{end};
        }
        else {
            return $self->oligos->{G5}{end};
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
    my @oligos = $self->design->oligos(
        {
            'loci.assembly_id' => $self->default_assembly,
        },
        {
            join     => 'loci',
            prefetch => { 'loci' => 'chr' },
        },
    );

    my %design_oligos_data;
    for my $oligo ( @oligos ) {
        my $locus = $oligo->loci->first;

        my %oligo_data = (
            start      => $locus->chr_start,
            end        => $locus->chr_end,
            chromosome => $locus->chr->name,
            strand     => $locus->chr_strand,
        );
        $oligo_data{seq} = $oligo->seq;

        $design_oligos_data{ $oligo->design_oligo_type_id } = \%oligo_data;
    }

    return \%design_oligos_data;
}

sub _build_ensembl_util {
    my $self = shift;
    require LIMS2::Util::EnsEMBL;

    return LIMS2::Util::EnsEMBL->new( species => $self->design->species_id );
}

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

    #if we just got one thats ideal; go ahead and return it.
    my @genes = keys %genes_in_target_region;
    if ( @genes == 1 ) {
        #make sure the coordinates are relative to the chromosome like everything else.
        return $genes_in_target_region{ pop @genes }->transform( 'chromosome' );
    }
    elsif ( @genes > 1 ) {
        $self->log->warn("Found more than one gene for design "
                         . $self->design->id . ": " . join ", ", @genes);

        #get all mgi accession ids associated with this design (hopefully its 1)
        my @design_gene_ids = uniq map { $_->gene_id } $self->design->genes->all;

        #make sure there is only one gene associated with the design in the database
        confess scalar @design_gene_ids . " ids associated to design " . $self->design->id
            unless @design_gene_ids == 1;

        my $db_id = pop @design_gene_ids;

        #see if any of the genes we got from ensembl match the one we just got from the db
        for my $gene ( values %genes_in_target_region ) {
            my $ensembl_gene_id;
            #only get mgi accession id for mouse, obviously.
            if ( $self->design->species->id eq "Mouse" ) {
                $ensembl_gene_id = $self->get_mgi_accession_id_for_gene( $gene );
            }
            else {
                $ensembl_gene_id = $gene->external_name;
            }

            #if it matches then return it
            return $gene->transform( 'chromosome' ) if $ensembl_gene_id eq $db_id;
        }

        #none of the mgi accession ids matched, so we can't really decide which gene to pick.
        confess "Gene ID lims2 db (" . $db_id . ") not found in " . join ",", @genes;
    }

    #the design is probably broken if this happens
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
    #trap exception so we can give a more specific error
 ;   try {
        $best_transcript = $self->get_best_transcript( $self->target_gene );
    }
    catch {
        confess "Error getting transcript for " . $self->target_gene->stable_id . ":\n" . $_;
    };

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
