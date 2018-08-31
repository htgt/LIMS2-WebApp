package LIMS2::Model::Util::SponsorReportII;

use strict;
use warnings;
use Moose;
use POSIX 'strftime';
use List::MoreUtils qw( uniq );
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

has targeting_type => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

has sponsor_gene_count => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

has programmes => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub build_page_title {
    my $self = shift;

    my $dt = strftime '%d %B %Y', localtime time;

    return 'Pipeline II Summary Report ('.$self->species.', '.$self->targeting_type.' projects) on ' . $dt;
};

sub _build_programmes {
    my $self = shift;

    my @programmes_rs = $self->model->schema->resultset('Programme')->all;

    my @programmes = map { $_->id } @programmes_rs;

    return \@programmes;
};

sub _build_sponsor_gene_count {
    my $self = shift;
    my $sponsor_gene_count;
    my $interim_data;

    my @project_ii_rs = $self->model->schema->resultset('Project')->search(
          { strategy_id => 'Pipeline II' },
          { distinct => 1 }
        )->all;

    my @projects_ii = map { $_->id } @project_ii_rs;

    my @project_sponsor_rs = $self->model->schema->resultset('ProjectSponsor')->search(
          { project_id => { -in => \@projects_ii }, sponsor_id => { 'not in' => ['All', 'Test'] } },
          { distinct => 1 }
        )->all;

    foreach my $rec (@project_sponsor_rs) {
        my $current_programme = $rec->programme_id;
        if ($current_programme) {
            my $rec_hash = {
                programme_id => $rec->programme_id,
                sponsor_id => $rec->sponsor_id,
                lab_head_id => $rec->lab_head_id,
            };
            my $hash_hit_index = find_my_hash($rec_hash, $sponsor_gene_count);

            if ($hash_hit_index ne 'NA') {
                $sponsor_gene_count->[$hash_hit_index]->{gene_count}++;
            } else {
                my $concatenated_hashes = {%$rec_hash, (gene_count => 1)};
                push @{$sponsor_gene_count}, $concatenated_hashes;
            }
        }
    }

    return $sponsor_gene_count;
}

sub find_my_hash {
    my ($ref_hash, $ref_array) = @_;

    my @hash_keys = keys %{$ref_hash};

    my $index = 0;
    foreach my $temp_hash (@{$ref_array}) {
        my $total = 0;
        foreach my $key (@hash_keys) {
            if ($temp_hash->{$key} eq $ref_hash->{$key}) {
                $total++;
            }
        }

        if ($total == scalar @hash_keys) {
            return $index;
        }

        $index++;
    }

    ## 'NA' instead of '0' since '0' can be an index in a list
    return 'NA';
}

sub get_programme_abbr {
    my ($self, $programme_id) = @_;

    my $abbr = 'None';
    if ($programme_id) {
        my $programme_rs = $self->model->schema->resultset('Programme')->find({id => $programme_id}, {columns => [ qw/abbr/ ]});
        my $abbr = $programme_rs->get_column('abbr');
        $abbr ? return $abbr : return 'None';
    }

    return $abbr;
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

#    my $gene_info = try{ $self->model('Golgi')->find_gene( { search_term => $gene_id, species => $species_id } ) };
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

