package LIMS2::Model::Util::PipelineIIPlates;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::PipelineIIPlates::VERSION = '0.525';
}
## use critic


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


=head
retrieve_data

This method is used to retrieve report data displayed in the EP_PICK and FP plates. The ancestor of these plates is an EP_PIPELINE_II plate.
=cut

sub retrieve_data {
    my ($model, $target_plate, $species) = @_;

    my @wells = $target_plate->wells;

    my $wells_data;
    foreach my $well (@wells) {

        my $data;
        my @parent_wells = $well->parent_wells;
        my $parent_well = $parent_wells[0];

        ## getting design data
        $data->{design_id} = $parent_well->design->id;
        $data->{design_type} = $parent_well->design->type->id;

        ## cell line data
        $data->{cell_line} = $parent_well->first_cell_line->name;

        ## crispr data
        my $crispr_id = $parent_well->process_output_wells->first->process->process_crispr->crispr_id;

        ## experiment data
        my $experiment_search = $model->schema->resultset( 'Experiment' )->find({ design_id =>  $data->{design_id}, crispr_id => $crispr_id }, { columns => [ qw/id gene_id assigned_trivial/ ] });
        $data->{gene_id} = $experiment_search->get_column('gene_id');

        $data->{exp_id} = $experiment_search->get_column('id');
        $data->{exp_trivial} = $experiment_search->trivial_name;

        ## gene notations
        my $gene_info;
        try {
            $gene_info = $model->schema->find_gene( { search_term => $data->{gene_id}, species => $species } ) ;
        };
        $data->{gene_name} = $gene_info->{gene_symbol};

        ## sponsor name
        $data->{sponsor_id} = 'All';
        try {
            my $proj_exp_search = $model->schema->resultset( 'ProjectExperiment' )->find({ experiment_id => $data->{exp_id} }, { columns => [ qw/project_id/ ] });
            my $proj_id = $proj_exp_search->get_column('project_id');

            my @proj_sponsor_search = $model->schema->resultset( 'ProjectSponsor' )->search({ project_id =>  $proj_id })->all;

            my @sponsor_ids = map { $_->sponsor_id } @proj_sponsor_search;
            foreach (@sponsor_ids) {
                if ($_ ne 'All') {
                    $data->{sponsor_id} = $_;
                    last;
                };
            }
        };
        $wells_data->{$well->name} = $data;
    }

    return $wells_data;
}

1;

__END__

