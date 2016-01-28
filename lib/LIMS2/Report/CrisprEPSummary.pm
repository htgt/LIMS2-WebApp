package LIMS2::Report::CrisprEPSummary;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprEPSummary::VERSION = '0.366';
}
## use critic


use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;
use List::MoreUtils qw( uniq );
use Try::Tiny;

extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has '+param_names' => (
    default => sub { [ 'species' ] }
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
            design_gene_symbol
            design_id
            int_plate_name
            final_pick_plate_name
            final_pick_cassette_name
            final_pick_backbone_name
            final_pick_well_accepted
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
        { sponsor_id               => "Sponsor ID" },
        { design_gene_symbol       => "Design Gene Symbol" },
        { design_id                => "Design ID" },
        { int_plate_name           => "Int Plate Name" },
        { crispr_vector            => "Crispr Vectors" },
        { crispr                   => "Crisprs" },
        { final_pick_plate_name    => "Final Pick Plate Name" },
        { final_pick_cassette_name => "Final Pick Cassette Name" },
        { final_pick_backbone_name => "Final Pick Backbone Name" },
        { final_pick_well_accepted => "Final Pick Well Accepted" },
        { assembly_plate_name      => "Assembly Plate Name" },
        { assembly_well_name       => "Assembly Well Name" },
        { crispr_ep_plate_name     => "Crispr EP Plate Name" },
        { crispr_ep_well_name      => "Crispr EP Well Name" },
        { crispr_ep_well_cell_line => "Crispr EP Well Cell Line" },
        { crispr_ep_well_nuclease  => "Crispr EP Well Nuclease" },
        { ep_colonies_picked       => "EP Colonies Picked" },
        { ep_colonies_accepted     => "EP Colonies Accepted" },
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
    });

    # for every crispr_ep well
    for my $crispr_ep_plate ( @crispr_ep_plates ) {
        my @summary = $self->model->schema->resultset('Summary')->search(
            { crispr_ep_plate_name => $crispr_ep_plate->name, sponsor_id => 'EUCOMMTools Recovery' },
            {
                select   => $self->summary_fields,
                group_by => $self->summary_fields,
                order_by => 'crispr_ep_well_name',
            }
        );

        #not a eucommtools one so skip it
        next unless @summary;

        for my $summary ( @summary ) {
            my %data;

            #push @data, [ map { fmt_bool( $summary->$_ ) } @{ $self->summary_fields } ];
            $data{$_} = $summary->$_ for @{ $self->summary_fields };

            my $assembly_well = $self->model->retrieve_well( {
                plate_name => $summary->assembly_plate_name,
                well_name  => $summary->assembly_well_name,
            } );

            my ( @crispr_vectors, @crispr_wells );
            for my $crispr_v ( $assembly_well->parent_crispr_vectors ) {
                push @crispr_vectors, _well_name( $crispr_v );
                my ( $crispr_well ) = $crispr_v->parent_crispr_wells; # will only be one value in return array
                push @crispr_wells, _well_name( $crispr_well );
            }
            $data{'crispr_vector'} = join( ' ', @crispr_vectors );
            $data{'crispr'} = join( ' ', @crispr_wells );

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

            #use hash slice to get all the values we want out in order
            push @row, [ map { $_ } @data{ map { keys %{$_} } @{$self->column_map} } ];

        }
    }

    return \@row;

}

__PACKAGE__->meta->make_immutable;

1;

__END__
