package LIMS2::Report::HetSummary;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::HetSummary::VERSION = '0.397';
}
## use critic


use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;
use List::MoreUtils qw( uniq any );
use Try::Tiny;
use LIMS2::Model::Util::CrisprESQCView qw(crispr_damage_type_for_ep_pick ep_pick_is_het);

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

    return 'Het Summary';

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
            design_gene_id
            design_gene_symbol
            design_id
            crispr_ep_plate_name
            crispr_ep_well_name
            ep_pick_well_id
            ep_pick_plate_name
            ep_pick_well_name
        )
    ];
}

has column_map => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_column_map {
    return [
        { design_id                => "Design ID" },
        { design_gene_symbol       => "Gene Symbol" },
        { design_gene_id           => "Gene ID" },
        { chromosome               => "Chromosome" },
        { crispr_ep_plate_name     => "CRISPR_EP Plate Name" },
        { crispr_ep_well_name      => "CRISPR_EP Well Name" },
        { ep_pick_plate_name       => "EP_PICK Plate Name" },
        { ep_pick_well_name        => "EP_PICK Well Name" },
        { damage                   => "Damage" },
        { pcr_done                 => "PCR done" },
        { five_prime               => "5 band" },
        { three_prime              => "3 band" },
        { is_het                   => "Het" },
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

sub fmt_pass {
    my ( $data ) = @_;

    return "" unless defined $data;

    #force string comparisons to avoid as $data == 0 is true with strings
    return "pass" if $data eq "1";
    return "fail" if $data eq "0";

    return $data;
}

sub build_ep_detail {
    my ( $self ) = @_;

    my @row;

    my $species = $self->model->schema->resultset('Species')->find({ id => $self->species});
    my $assembly_id = $species->default_assembly->assembly_id;

    my @summary = $self->model->schema->resultset('Summary')->search({
            crispr_ep_plate_name => { '!=', undef },
            ep_pick_plate_name   => { '!=', undef },
            design_species_id    => $self->species,
            to_report            => 'true',
        },
        {
            select   => $self->summary_fields,
            group_by => $self->summary_fields,
            order_by => ['crispr_ep_plate_name','crispr_ep_well_name','ep_pick_plate_name','ep_pick_well_name'],
    });

    for my $summary ( @summary ) {
        my %data;

        $data{$_} = $summary->$_ for @{ $self->summary_fields };

        # Get chromosome number from design
        my $design = $self->model->schema->resultset('Design')->find({
            id => $summary->design_id,
        });
        my $design_oligo_locus = $design->oligos->first->search_related( 'loci', { assembly_id => $assembly_id } )->first;
        $data{chromosome} = $design_oligo_locus->chr->name;
        $data{damage} = crispr_damage_type_for_ep_pick( $self->model, $summary->ep_pick_well_id);
        $data{pcr_done} = 0;

        try{
            my $het = $self->model->schema->resultset( 'WellHetStatus' )->find(
                    { well_id => $summary->ep_pick_well_id } );

            if ( $het ) { $data{pcr_done} = 1 };

            $data{five_prime} = $het->five_prime;
            $data{five_prime} = fmt_pass($data{five_prime});

            $data{three_prime} = $het->three_prime;
            $data{three_prime} = fmt_pass($data{three_prime});

        };

        $data{pcr_done} = fmt_bool($data{pcr_done});

        $data{is_het} = ep_pick_is_het($self->model, $summary->ep_pick_well_id, $data{chromosome}, $data{damage}) unless !$data{damage};
        $data{is_het} = fmt_bool($data{is_het});

        push @row, [ map { $_ } @data{ map { keys %{$_} } @{$self->column_map} } ];

    }

    return \@row;

}

__PACKAGE__->meta->make_immutable;

1;

__END__
