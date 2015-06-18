package LIMS2::Report::CrisprEPSummaryJune2015;

use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;
use List::MoreUtils qw( uniq );
use Try::Tiny;
use Data::Dumper;
use Math::Round;

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

    return 'Crispr Electroporation Summary';

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
        { vector_id                => "Vector ID" },
        { crispr_1_id              => "CRISPR 1 ID" },
        { crispr_2_id              => "CRISPR 2 ID" },
        { assembly_plate_name      => "Assembly Plate Name" },
        { assembly_well_name       => "Assembly Well Name" },
        { assembly_well_seq_verified => "Sequence Verification of Assembly" },
        { crispr_ep_well_cell_line => "Human iPS Cell Line" },
        { crispr_ep_well_nuclease  => "Nuclease" },
        { crispr_ep_plate_well_name => "HUEP Plate_Well" },
        { colony_numbers           => "Colony Numbers" },
        { ep_colonies_picked       => "Clones Screened" }, # number of EP pick wells
        { nhej_of_second_allele    => "NHEJ of Second Allele" },
        { frameshift               => "NHEJ Frame Shift" },
        { 'in-frame'               => "In-Frame NHEJ" },
        { wild_type                => "Wild Type - no NHEJ" },
        { mosaic                   => "Mosaic" },
        { 'no-call'                => "No Calls" },
        { targeting_efficiency     => "Biallelic Targeting Efficiency" },
        { recovery_comment         => "Recovery Comment" },
        #{ ep_colonies_picked       => "EP Colonies Picked" },
        #{ ep_colonies_total        => "EP Colonies Total" },
        #{ ep_pick_qc_seq_pass      => "EP Pick Qc Seq Pass" },
        #{ ep_pick_well_accepted    => "EP Pick Well Accepted" },
    ];
}

override _build_columns => sub {
    my $self = shift;

    #there are now non sumamry fields so we cant do this
    # my @fields;
    # for my $field ( @{ $self->summary_fields } ) {
    #     #capitalise every letter and replace _ with a space
    #     push @fields, join " ", map { ucfirst } split /_/, $field;
    # }

    # return \@fields;

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

sub _well_name {
    my $well = shift;

    return $well ? $well->plate->name . "[" . $well->name . "]" : "";
}

sub build_ep_detail {
    my ( $self ) = @_;

    my @row;

    # get all crispr_ep plates
    my @crispr_ep_plates = $self->model->schema->resultset('Plate')->search({
        type_id => 'CRISPR_EP',
        species_id => $self->species,
        #sponsor_id => 'EUCOMMTools Recovery',
        #name => { -in => ['HUEP0001','HUEP0002','HUEP0003','HUEP0004','HUEP0005',] } ## FIXME: single plate for testing
    });

    DEBUG "Creating summary for ".scalar(@crispr_ep_plates)." CRISPR_EP plates";
    # for every crispr_ep well

    my $assembly_id = $crispr_ep_plates[0]->species->default_assembly->assembly_id;

    my $search = {};
    if($self->has_sponsor){
        $search->{sponsor_id} = $self->sponsor;
    }

    for my $crispr_ep_plate ( @crispr_ep_plates ) {
        $search->{crispr_ep_plate_name} = $crispr_ep_plate->name;
        my @summary = $self->model->schema->resultset('Summary')->search( $search,
            {
                select   => $self->summary_fields,
                group_by => $self->summary_fields,
                order_by => 'crispr_ep_well_name',
            }
        );

        next unless @summary;

        for my $summary ( @summary ) {

            # Some CRISPR_EP plates come from OLIGO_ASSEMBLY plates
            # so do not have assembly well in summaries table
            # We skip these for now
            next unless $summary->assembly_well_id;

            my %data;

            #push @data, [ map { fmt_bool( $summary->$_ ) } @{ $self->summary_fields } ];
            $data{$_} = $summary->$_ for @{ $self->summary_fields };

            $data{crispr_ep_plate_well_name} = $summary->crispr_ep_plate_name."_".$summary->crispr_ep_well_name;
            $data{vector_id} = $summary->final_pick_plate_name."_".$summary->final_pick_well_name;

            my $assembly_well = $self->model->schema->resultset('Well')->find( {
                id => $summary->assembly_well_id,
            } );
            my @experiments = $assembly_well->experiments;
            $data{experiment_id} = join ", ", map { $_->id } @experiments;

            my $design = $self->model->schema->resultset('Design')->find({
                id => $summary->design_id,
            });
            my $design_oligo_locus = $design->oligos->first->search_related( 'loci', { assembly_id => $assembly_id } )->first;
            $data{chromosome} = $design_oligo_locus->chr->name;

            DEBUG "Fetching projects for experiments ".$data{experiment_id};
            my @projects = map { $_->project } @experiments;
            my @sponsor_ids = sort { $a cmp $b } uniq map { $_->sponsor_ids } @projects;
            $data{sponsor_id} = join "/", @sponsor_ids;
            $data{recovery_comment} = join ", ", map { $_->recovery_comment } @projects;

            # Crisprs displayed in no particular order e.g. not left then right
            # FIXME? is this a problem?
            my @crisprs = $assembly_well->crisprs;
            $data{crispr_1_id} = $crisprs[0] ? $crisprs[0]->id : undef;
            $data{crispr_2_id} = $crisprs[1] ? $crisprs[1]->id : undef;

            # Work out assembly well QC verification result (true or false). NB: in future we may be storing
            # this as the well_accepted flag in which case can get it from summaries
            $data{assembly_well_seq_verified} = fmt_bool($assembly_well->assembly_well_qc_verified);

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
            my $crispr_ep_well = $self->model->schema->resultset('Well')->find({
                id => $summary->crispr_ep_well_id
            });
            my $colony_count = $crispr_ep_well->search_related('well_colony_counts',{
                colony_count_type_id => 'remaining_unstained_colonies'
            })->first;
            $data{colony_numbers} = $colony_count ? $colony_count->colony_count : undef;

            my %ep_pick_damage;
            foreach my $ep_pick_well_id (keys %num_wells){
                my $ep_pick_well = $self->model->schema->resultset('Well')->find({
                    id => $ep_pick_well_id,
                });
                #my $qc_well = $ep_pick_well->accepted_crispr_es_qc_well;
                #next unless $qc_well;
                foreach my $qc_well($ep_pick_well->crispr_es_qc_wells){
                    # Skip QC wells that have not damage type
                    # Is this the right thing to do?
                    next unless $qc_well->crispr_damage_type_id;

                    $ep_pick_damage{ $qc_well->crispr_damage_type_id }++;
                }
            }
            DEBUG Dumper(%ep_pick_damage);
            foreach my $damage_type (keys %ep_pick_damage){
                $data{$damage_type} = $ep_pick_damage{$damage_type};
            }

            if( $data{ep_colonies_picked} and exists $data{frameshift} ){
                my $efficiency = ($data{frameshift}/$data{ep_colonies_picked}) * 100;
                $data{targeting_efficiency} = round($efficiency)."%";
            }

            $data{nhej_of_second_allele} = $data{frameshift} + $data{'in-frame'} + $data{mosaic};

            #use hash slice to get all the values we want out in order
            push @row, [ map { $_ } @data{ map { keys %{$_} } @{$self->column_map} } ];

        }
    }

    return \@row;

}

__PACKAGE__->meta->make_immutable;

1;

__END__
