package LIMS2::Report::CrisprEPSummaryJune2015;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprEPSummaryJune2015::VERSION = '0.525';
}
## use critic


use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;
use List::MoreUtils qw( uniq any );
use Try::Tiny;
use Data::Dumper;
use Math::Round;
use Time::HiRes qw(gettimeofday tv_interval);
use LIMS2::Model::Util::CrisprESQCView qw(crispr_damage_type_for_ep_pick ep_pick_is_het);

extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has sponsor => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_sponsor',
);

has '+param_names' => (
    default => sub { [ 'species', 'sponsor' ] }
);

override _build_name => sub {
    my $self = shift;

    return 'New Crispr Electroporation Summary';

};

has summary_fields => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy_build => 1,
);

sub _build_summary_fields {
    my $self = shift;

    return [
        qw(
            sponsor_id
            design_gene_id
            design_gene_symbol
            design_id
            design_plate_name
            design_well_name
            design_type
            dna_template
            int_plate_name
            final_pick_plate_name
            final_pick_well_name
            final_pick_cassette_name
            final_pick_backbone_name
            final_pick_well_accepted
            assembly_well_id
            assembly_plate_name
            assembly_well_name
            crispr_ep_well_id
            crispr_ep_plate_name
            crispr_ep_well_name
            crispr_ep_well_cell_line
            crispr_ep_well_nuclease
            crispr_ep_well_created_ts
            to_report
        )
    ];

        # ep_colonies_picked
        # ep_colonies_total
        # ep_pick_qc_seq_pass
        # ep_pick_well_accepted

    #assembly_well_id
}

has column_map => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_column_map {
    return [
        { experiment_id            => "Experiment ID" },
        { design_id                => "Design ID" },
        { design_gene_symbol       => "Design Gene Symbol" },
        { chromosome               => "Chromosome" },
        { sponsor_id               => "Sponsor ID" },
        { design_plate_well_name   => "Design Plate_Well" },
        { dna_template             => "DNA Template" },
        { design_type              => "Design Method" },
        { vector_id                => "Vector ID" },
        { crispr_1_id              => "CRISPR 1 ID" },
        { crispr_2_id              => "CRISPR 2 ID" },
        { crispr_id_list           => "All CRISPR IDs" },
        { assembly_plate_name      => "Assembly Plate Name" },
        { assembly_well_name       => "Assembly Well Name" },
        { assembly_well_seq_verified => "Sequence Verification of Assembly" },
        { crispr_ep_well_cell_line => "Human iPS Cell Line" },
        { crispr_ep_well_nuclease  => "Nuclease" },
        { crispr_ep_plate_well_name => "HUEP Plate_Well" },
        { crispr_ep_well_created_ts => "EP Timestamp" },
        { colony_numbers           => "Colony Numbers" },
        { ep_colonies_picked       => "Clones Screened" }, # number of EP pick wells
        { nhej_of_second_allele    => "NHEJ of Second Allele" },
        { frameshift               => "NHEJ Frame Shift" },
        { 'in-frame'               => "In-Frame NHEJ" },
        { wild_type                => "Wild Type - no NHEJ" },
        { mosaic                   => "Mosaic" },
        { 'no-call'                => "No Calls" },
        { 'het'                    => "Het Clones" },
        { targeting_efficiency     => "Biallelic Targeting Efficiency" },
        { to_report                => "To report" },
        { recovery_comment         => "Recovery Comment" },
    ];
}

override _build_columns => sub {
    my $self = shift;

    return [ map { values %{$_} } @{ $self->column_map } ];
};

override iterator => sub {
    my ( $self ) = @_;

    return Iterator::Simple::iter( $self->build_ep_detail() );

};

#we don't want to change any fields that aren't boolean
#could also be undefined which we want to leave as such
sub fmt_bool {
    my ( $data ) = @_;

    return "" unless defined $data;

    #force string comparisons to avoid as $data == 0 is true with strings
    return "yes" if $data eq "1";
    return "no" if $data eq "0";

    return $data;
}

# Get resultset and store each record in a hash where result->id is the key
sub resultset_by_id{
    my ($self,$resultset,$search,$atts) = @_;

    my $t0 = [gettimeofday];

    my $rs = $self->model->schema->resultset($resultset)->search($search,$atts);

    DEBUG "Time take for $resultset query: ".tv_interval ( $t0 );

    my %results_by_id;
    while (my $result = $rs->next){
        $results_by_id{$result->id} = $result;
    }
    DEBUG "Time taken for $resultset query and store: ".tv_interval($t0);

    return \%results_by_id;
}


## no critic(ProhibitExcessComplexity)
sub build_ep_detail {
    my ( $self ) = @_;

    my @row;

    my $species = $self->model->schema->resultset('Species')->find({ id => $self->species});
    my $assembly_id = $species->default_assembly->assembly_id;

    my @summary = $self->model->schema->resultset('Summary')->search({
            crispr_ep_plate_name => { '!=', undef },
            design_species_id    => $self->species,
        },
        {
            select   => $self->summary_fields,
            group_by => $self->summary_fields,
            order_by => ['crispr_ep_plate_name','crispr_ep_well_name'],
    });

    # Retrieve assembly wells and crispr ep wells in batch with appropriate relations in prefetch
    my @assembly_well_ids = uniq map { $_->assembly_well_id } @summary;
    my $search = { 'me.id' => { -in => \@assembly_well_ids } };
    my $atts = { prefetch => 'well_assembly_qcs' };
    my $assembly_wells_by_id = $self->resultset_by_id('Well',$search,$atts);

    my @crispr_ep_well_ids = uniq map { $_->crispr_ep_well_id } @summary;
    my $ep_search = { 'me.id' => { -in => \@crispr_ep_well_ids } };
    my $ep_atts = { prefetch => 'well_colony_counts' };
    my $crispr_ep_wells_by_id = $self->resultset_by_id('Well',$ep_search,$ep_atts);

    for my $summary ( @summary ) {

        # Some CRISPR_EP plates come from OLIGO_ASSEMBLY plates
        # so do not have assembly well in summaries table
        # We skip these for now
        next unless $summary->assembly_well_id;

        my %data;

        $data{$_} = $summary->$_ for @{ $self->summary_fields };

        $data{design_plate_well_name} = $summary->design_plate_name."_".$summary->design_well_name;
        $data{crispr_ep_plate_well_name} = $summary->crispr_ep_plate_name."_".$summary->crispr_ep_well_name;
        $data{vector_id} = $summary->final_pick_plate_name."_".$summary->final_pick_well_name;

        my $assembly_well = $assembly_wells_by_id->{$summary->assembly_well_id};

        # Get experiments matching assembly well
        my @experiments = $assembly_well->experiments;
        $data{experiment_id} = join "; ", map { $_->id } @experiments;

        my @gene_projects = $self->model->schema->resultset('Project')->search({ gene_id => $summary->design_gene_id, targeting_type => 'single_targeted' })->all;

        $data{recovery_comment} = join "; ", grep { $_ } map { $_->recovery_comment } @gene_projects;

        my @sponsors = uniq map { $_->sponsor_ids } @gene_projects;

        try {
            my $index = 0;
            $index++ until ( $index >= scalar @sponsors || $sponsors[$index] eq 'All' );
            splice(@sponsors, $index, 1);
        };

        my @sponsors_abbr = map { $self->model->schema->resultset('Sponsor')->find({ id => $_ })->abbr } @sponsors;
        $data{sponsor_id} = join  ( '; ', @sponsors_abbr );

        # Get chromosome number from design
        my $design = $self->model->schema->resultset('Design')->find({
            id => $summary->design_id,
        });
        my $design_oligo_locus = $design->oligos->first->search_related( 'loci', { assembly_id => $assembly_id } )->first;
        $data{chromosome} = $design_oligo_locus->chr->name;

        # Crisprs displayed in no particular order e.g. not left then right
        # FIXME? is this a problem?
        my @crisprs = $assembly_well->crisprs;
        $data{crispr_1_id} = $crisprs[0] ? $crisprs[0]->id : undef;
        $data{crispr_2_id} = $crisprs[1] ? $crisprs[1]->id : undef;
        # Provide list of all crispr IDs in case it is group with more than 2 crisprs
        $data{crispr_id_list} = join "/", map { $_->id } @crisprs;

        # Work out assembly well QC verification result (true or false). NB: in future we may be storing
        # this as the well_accepted flag in which case can get it from summaries
        $data{assembly_well_seq_verified} = fmt_bool($assembly_well->assembly_well_qc_verified);

        $data{dna_template} = '';
        try {
            $data{dna_template} = $summary->dna_template->id;
        };

        $data{to_report} = 'no';
        if ( $summary->to_report ) {
            $data{to_report} = 'yes';
        }

        # New summary to get downstream ep pick wells
        my @epds = $self->model->schema->resultset('Summary')->search(
            { crispr_ep_well_id => $summary->crispr_ep_well_id },
            {
                select => [ qw( ep_pick_well_id ep_pick_well_accepted ) ],
                group_by => [ qw( ep_pick_well_id ep_pick_well_accepted ) ],
            }
        );

        my %num_wells;
        my $num_accepted = 0;
        for my $row ( @epds ) {
            next unless $row->ep_pick_well_id;
            $num_wells{ $row->ep_pick_well_id }++;
            $num_accepted++ if $row->ep_pick_well_accepted;
        }

        $data{ep_colonies_picked} = scalar( keys %num_wells );
        $data{ep_colonies_accepted} = $num_accepted;

        DEBUG "Finding colonly counts for crispr_ep_well_id ".$summary->crispr_ep_well_id;

        my $crispr_ep_well = $crispr_ep_wells_by_id->{$summary->crispr_ep_well_id};
        my $colony_count = $crispr_ep_well->search_related('well_colony_counts',{
            colony_count_type_id => 'total_colonies'
        })->first;
        $data{colony_numbers} = $colony_count ? $colony_count->colony_count : undef;

        # Count how many time each type of damage is seen in crispr QC
        # of all the downstream EP_PICK wells
        my %ep_pick_damage;
        foreach my $ep_pick_well_id (keys %num_wells){
            my $damage_type = crispr_damage_type_for_ep_pick($self->model,$ep_pick_well_id);
            if ($damage_type){
                $ep_pick_damage{$damage_type}++;

                if(ep_pick_is_het($self->model,$ep_pick_well_id,$data{chromosome},$damage_type)){
                    $ep_pick_damage{het}++;
                }
            }
        }

        if(%ep_pick_damage){
            my @types = ('frameshift','in-frame','wild_type','mosaic','no-call','het','splice_acceptor');

            foreach my $damage_type (@types){
                $data{$damage_type} = ($ep_pick_damage{$damage_type} ? $ep_pick_damage{$damage_type} : 0);
            }

            # Add number of splice acceptors to frameshift count
            if($data{'splice_acceptor'}){
                $data{'frameshift'} //= 0; # avoid uninitialized value errors
                $data{'frameshift'} += $data{'splice_acceptor'};
            }

            # Calculate targeting efficiency from frameshift damage counts
            if( $data{ep_colonies_picked}){
                my $efficiency = ($data{frameshift}/$data{ep_colonies_picked}) * 100;
                $data{targeting_efficiency} = round($efficiency)."%";
            }

            # Count all EP_PICKs where some damage was detected
            $data{nhej_of_second_allele} = $data{frameshift} + $data{'in-frame'} + $data{mosaic};
        }

        # use hash slice to get all the values we want out in order
        push @row, [ map { $_ } @data{ map { keys %{$_} } @{$self->column_map} } ];

    }


    return \@row;

}
## use critic


__PACKAGE__->meta->make_immutable;

1;

__END__
