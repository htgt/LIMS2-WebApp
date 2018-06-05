package LIMS2::Model::Util::PipelineIIPlates;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [
        qw(
              retrieve_data
          )
    ]
};

sub retrieve_data {
    my ($model, $target_plate, $species) = @_;

    my @wells = $target_plate->wells;

    my @parent_wells = $wells[0]->parent_wells;
    my $parent_well = $parent_wells[0];

    my $data = {};

    ## design
    $data->{design_id} = $parent_well->design->id;
    $data->{design_type} = $parent_well->design->type->id;

    ## cell line
    $data->{cell_line} = $parent_well->first_cell_line->name;

    ## crispr
    my $crispr_id = $parent_well->process_output_wells->first->process->process_crispr->crispr_id;

    ## exp
    my $rs1 = $model->schema->resultset( 'Experiment' )->find({ design_id =>  $data->{design_id}, crispr_id => $crispr_id }, { columns => [ qw/id gene_id assigned_trivial/ ] });
    $data->{gene_id} = $rs1->get_column('gene_id');

    $data->{exp_id} = $rs1->get_column('id');
    $data->{exp_trivial} = $rs1->trivial_name;

    ## gene
    my $gene_info;
    try {
        $gene_info = $model->schema->find_gene( { search_term => $data->{gene_id}, species => $species } ) ;
    };
    $data->{gene_name} = $gene_info->{gene_symbol};

    ## sponsor
    my $rs2 = $model->schema->resultset( 'ProjectExperiment' )->find({ experiment_id => $data->{exp_id} }, { columns => [ qw/project_id/ ] });
    my $proj_id = $rs2->get_column('project_id');

    my @rs3 = $model->schema->resultset( 'ProjectSponsor' )->search({ project_id =>  $proj_id })->all;
    $data->{sponsor_id} = 'All';
    my @sponsor_ids = map { $_->sponsor_id } @rs3;
    foreach (@sponsor_ids) {
        if ($_ ne 'All') {
            $data->{sponsor_id} = $_;
            last;
        };
    }

    return $data;
}

1;

__END__

