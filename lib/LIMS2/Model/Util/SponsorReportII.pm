package LIMS2::Model::Util::SponsorReportII;

use strict;
use warnings;
use Moose;
use POSIX 'strftime';
use List::MoreUtils qw( uniq );
use Try::Tiny;
use Log::Log4perl ':easy';
use Readonly;
use Data::Dumper;

extends qw( LIMS2::ReportGenerator );

Readonly my $SUBREPORT_COLUMNS => {
    general => [
    'Gene ID',
    'Gene Symbol',
    'Chr',
    'Programme',
    'Sponsor',
    'Lab Head',
    'Project ID',
    'Experiment ID',
    'Ordered Crisprs',
    'Design ID',
    'Electroporation iPSCs',
    'EP_II cell line',
    'iPSC Colonies Picked',
    'Requester',
    ],
    primary_genotyping => [
    'Total Number of Clones on MiSEQ Plate',
    'WT Clones Selected',
    'HET Clones Selected',
    'HOM Clones Selected',
    ],
    secondary_genotyping => [
    'WT Distributable Clones',
    'HET Distributable Clones',
    'HOM Distributable Clones',
    ],
};

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
my $launch_report_subs = {
    gene_info             => \&get_gene_info,
    exp_info              => \&get_exp_info,
    ipscs_ep              => \&get_ipsc_electroporation,
    ep_cell_line          => \&get_electroporation_cell_line,
    ipscs_colonies_picked => \&get_ipsc_colonies_picked,
};

## usage
## $dispatch_report_values->{ gene_symbol }->($gene_id)

sub get_gene_info {
    my ($self, $gene_id, $species) = @_;

    my $gene_info;
    try {
        $gene_info = $self->model->find_gene( {
            search_term => $gene_id,
            species     => $self->species,
        } );
    }
    catch {
        INFO 'Failed to fetch gene symbol for gene id : ' . $gene_id . ' and species : ' . $self->species;
    };

    return $gene_info;

        # Now we grab this from the solr index
        my $gene_symbol = $gene_info->{'gene_symbol'};
        my $chromosome = $gene_info->{'chromosome'};
}


sub get_exp_info {
    my ($self, $project_id) = @_;

    my @exps;

    my @proj_exp_rs = $self->model->schema->resultset('ProjectExperiment')->search({ project_id => $project_id });
    my @proj_exps = map { $_->experiment_id } @proj_exp_rs;

    foreach my $exp_id (@proj_exps) {
        my $exp_rs = $self->model->schema->resultset('Experiment')->find({ id => $exp_id });
        push @exps, $exp_rs;
    }

    return @exps;
}


sub get_ipsc_electroporation {
    my ($self, $exps, $cell_line_id) = @_;

    my @exps = @$exps;
    my @exps_with_ep_ii_data;

    foreach my $experiment (@exps) {
        try {
            my $exp_id = $experiment->id;
            my ($design_id, $crispr_id) = ($experiment->design_id, $experiment->crispr_id);

            if ($design_id && $crispr_id && $cell_line_id) {

                my @process_design_rs = $self->model->schema->resultset('ProcessDesign')->search(
                      { design_id => $design_id }
                    )->all;
                my @process_design = map { $_->process_id } @process_design_rs;

                my @process_crispr_rs = $self->model->schema->resultset('ProcessCrispr')->search(
                      { crispr_id => $crispr_id }
                    )->all;
                my @process_crispr = map { $_->process_id } @process_crispr_rs;

                my @process_cell_line_rs = $self->model->schema->resultset('ProcessCellLine')->search(
                      { cell_line_id => $cell_line_id }
                    )->all;
                my @process_cell_line = map { $_->process_id } @process_cell_line_rs;

                my @intersect_processes;
                foreach my $pr (@process_crispr) {
                    if ((map { $_ == $pr } @process_design) && (map { $_ == $pr } @process_cell_line)) {
                        push @intersect_processes, $pr;
                    }
                }

                my @input_wells_rs;
                if (scalar @intersect_processes) {
                    @input_wells_rs = $self->model->schema->resultset('ProcessOutputWell')->search(
                          { process_id => { -in => \@intersect_processes } }
                        )->all;
                }

                my @wells_rs;
                if (scalar @input_wells_rs) {
                    my @input_wells = map { $_->well_id } @input_wells_rs;
                    @wells_rs = $self->model->schema->resultset('Well')->search(
                          { id => { -in => \@input_wells } }
                        )->all;
                }

                my @ep_ii_plate_data;
                my @plate_name_tracker;
                foreach my $well (@wells_rs) {
                    if ($well->plate->type_id eq 'EP_PIPELINE_II') {
                        if (!(map { $_ eq $well->plate->name } @plate_name_tracker)) {
                            my $temp_h = { name => $well->plate->name, id => $well->plate->id};
                            push @plate_name_tracker, $well->plate->name;
                            push @ep_ii_plate_data, $temp_h;
                        }
                    }
                }

                $experiment->{ep_ii_plates} = \@ep_ii_plate_data;
                push @exps_with_ep_ii_data, $experiment;
            }
        }
    };

    return \@exps_with_ep_ii_data;
}

sub get_ipsc_colonies_picked {
    my ($self) = @_;
}

sub generate_sub_report {
    my ($self, $sponsor_id, $lab_head, $programme) = @_;

    my $report;
    my @data;

    my @project_sponsor_rs = $self->model->schema->resultset('ProjectSponsor')->search(
          { sponsor_id => $sponsor_id, lab_head_id => $lab_head, programme_id => $programme },
          { distinct => 1 }
        )->all;

    my @all_sponsor_projects = map { $_->project_id } @project_sponsor_rs;

    my @project_ii_rs = $self->model->schema->resultset('Project')->search(
          { strategy_id => 'Pipeline II' , id => { -in => \@all_sponsor_projects } }
        )->all;

    my ($gene_info, $sponsor_info);
    foreach my $project_rec (@project_ii_rs) {
        my $row_data;
        $row_data->{project_id} = $project_rec->id;
        $row_data->{cell_line} = $project_rec->cell_line->name;

        $gene_info = &{$launch_report_subs->{ 'gene_info' }}($self, $project_rec->gene_id, $self->species);
        $row_data->{gene_id} = $gene_info->{gene_id};
        $row_data->{gene_symbol} = $gene_info->{gene_symbol};
        $row_data->{chromosome} = $gene_info->{chromosome};

        $row_data->{programme} = $programme;
        $row_data->{lab_head} = $lab_head;
        $row_data->{sponsor} = $sponsor_id;

        my @proj_exps = &{$launch_report_subs->{ 'exp_info' }}($self, $project_rec->id);
        my $ep_ii_plate_names = &{$launch_report_subs->{ 'ipscs_ep' }}($self, \@proj_exps, $project_rec->cell_line_id);
        $row_data->{experiments} = $ep_ii_plate_names;

        push @data, $row_data;
    }

    my $date_format = strftime '%d %B %Y', localtime;

    $report->{date} = $date_format;
    $report->{columns} = $SUBREPORT_COLUMNS;
    $report->{data} = \@data;

    return $report;

}


1;

