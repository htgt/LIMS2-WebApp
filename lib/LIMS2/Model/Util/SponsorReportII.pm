package LIMS2::Model::Util::SponsorReportII;

use strict;
use warnings;
use Moose;
use Data::Dumper;

extends qw( LIMS2::ReportGenerator );

has model => (
    is         => 'ro',
    isa        => 'LIMS2::Model',
    required   => 1,
);

has species => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

has sponsor_gene_count => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_sponsor_gene_count {
    my $self = shift;
    my $sponsor_gene_count;

    my @project_ii_rs = $self->model->schema->resultset('Project')->search(
          { strategy_id => 'Pipeline II' },
          { distinct => 1 }
        )->all;

    my @projects_ii = map { $_->id } @project_ii_rs;

    my @project_sponsor_rs = $self->model->schema->resultset('ProjectSponsor')->search(
          { project_id => { -in => \@projects_ii }, sponsor_id => { 'not in' => ['All'] } },
          { distinct => 1 }
        )->all;

    foreach my $rec ( @project_sponsor_rs ) {
        $sponsor_gene_count->{$rec->sponsor_id}++;
    }

    return $sponsor_gene_count;
}

## rule-based approach

## A dispatch table of subroutines for every value in the report
my $dispatch_report_values = {
    gene_symbol           => \&get_gene_symbol,
    chromosome            => \&get_chromosome,
    sponsors              => \&get_sponsors,
    project_id            => \&get_project_id,
    experiment_id         => \&get_experiment_id,
    crisprs_seq           => \&get_crispr_sequences,
    design_id             => \&get_design_id,
    ipscs_ep              => \&get_ipsc_electroporation,
    ep_cell_line          => \&get_electroporation_cell_line,
    ipscs_colonies_picked => \&get_ipsc_colonies_picked,
};

## usage
## $dispatch_report_values->{ gene_symbol }->($gene_id)

sub get_gene_symbol {
    my ($self, $gene_id, $species) = @_;

    my $gene_info = try{ $self->model('Golgi')->find_gene( { search_term => $gene_id, species => $species_id } ) };
}


sub get_chromosome {
    my ($self, $crispr_id) = @_;

    ## using crispr_loci table?
}


sub get_sponsors {
    my ($self, $gene_id) = @_;
}


sub get_project_id {
    my ($self, $gene_id) = @_;
}


sub get_experiment_id {
    my ($self, $gene_id, $project_id) = @_;
}


sub get_crispr_sequences {
    my ($self) = @_;
}


sub get_design_id {
    my ($self) = @_;
}


sub get_ipsc_electroporation {
    my ($self) = @_;
}


sub get_electroporation_cell_line {
    my ($self) = @_;
}


sub get_ipsc_colonies_picked {
    my ($self) = @_;
}


1;
