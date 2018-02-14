package LIMS2::Model::Util::EPPipelineIIPlate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [
        qw(
              retrieve_experiments_ep_pipeline_ii
              retrieve_experiments_by_field
              import_wge_crispr_ep_pipeline_ii
              find_projects_ep_pipeline_ii
              create_project_ep_pipeline_ii
              proj_exp_check_ep_ii
              add_exp_check_ep_ii
          )
    ]
};

sub retrieve_experiments_ep_pipeline_ii {
    my ( $model, $params ) = @_;

    my @experiments_ii;
    if ($params->{crispr_id_assembly_ii}) {
        my @temp = retrieve_experiments_by_field($model, 'crispr_id', $params->{crispr_id_assembly_ii});
        push @experiments_ii, @temp;
    }

    if ($params->{gene_id_assembly_ii}) {
        my @temp = retrieve_experiments_by_field($model, 'gene_id', $params->{gene_id_assembly_ii});
        push @experiments_ii, @temp;
    }

    if ($params->{design_id_assembly_ii}) {
        my @temp = retrieve_experiments_by_field($model, 'design_id', $params->{design_id_assembly_ii});
        push @experiments_ii, @temp;
    }

    return @experiments_ii;
}

sub retrieve_experiments_by_field {
    my ( $model, $field_name, $field_value ) = @_;

    my @experiments;

    try {
        my @exp_records = $model->resultset('Experiment')->search(
            { $field_name => $field_value },
            { distinct => 1 }
        )->all;

        for my $rec (@exp_records) {
            my %data = $rec->get_columns;
            push @experiments, \%data;
        }
    };

    return @experiments;

}

sub import_wge_crispr_ep_pipeline_ii {
    my ( $model, $params ) = @_;

    my $wge_id = $params->{wge_crispr_assembly_ii};

    my $species = $params->{species};
    my $assembly = $model->schema->resultset('SpeciesDefaultAssembly')->find( { species_id => $species } )->assembly_id;

    if ($wge_id) {
        my @crisprs = $model->import_wge_crisprs( [$wge_id], $species, $assembly );
        return @crisprs;
    }

    return;
}

sub find_projects_ep_pipeline_ii {
    my ( $model, $params ) = @_;

    my $search;
    if ($params->{gene_id_assembly_ii}) {

        if ($params->{cell_line_assembly_ii}) { $search->{cell_line_id} = $params->{cell_line_assembly_ii}; }
        if ($params->{targeting_type_assembly_ii}) { $search->{targeting_type} = $params->{targeting_type_assembly_ii}; }
        if ($params->{strategy_assembly_ii}) { $search->{strategy_id} = $params->{strategy_assembly_ii}; }
        $search->{gene_id} = $params->{gene_id_assembly_ii};

    } elsif ($params->{project_id}) {
        $search = {
            id => $params->{project_id}
        };
    }

    my @projects_rs = $model->resultset('Project')->search( $search, { distinct => 1, order_by => 'id' })->all;

    my @projects;
    for my $rec (@projects_rs) {
        my %data = $rec->get_columns;
        my @sponsors = $model->resultset('ProjectSponsor')->search( { project_id => $data{id} } )->all;
        foreach my $sponsor (@sponsors) {
            if ($sponsor->get_column('sponsor_id') ne 'All') {
                $data{sponsor_id} = $sponsor->get_column('sponsor_id');
                last;
            }
            $data{sponsor_id} = $sponsor->get_column('sponsor_id');
        }
        push @projects, \%data;
    }

    return @projects;
}

sub create_project_ep_pipeline_ii {
    my ( $model, $params ) = @_;

    # Store params common to search and create
    my $search = { species_id => $params->{species} };
    if( $params->{gene_id_assembly_ii} ) {
        $search->{gene_id} = $params->{gene_id_assembly_ii};
    }
    if( $params->{targeting_type_assembly_ii} ) {
        $search->{targeting_type} = $params->{targeting_type_assembly_ii};
    }
    if( $params->{'cell_line_assembly_ii'} ) {
        $search->{cell_line_id} = $params->{'cell_line_assembly_ii'};
    }
    if( $params->{strategy_assembly_ii} ) {
        $search->{strategy_id} = $params->{strategy_assembly_ii};
    }

    my @projects_rs = $model->schema->resultset('Project')->search( $search, { order_by => 'id' })->all;

    if(scalar @projects_rs == 0){
        # Create a new project
        if(my $sponsor = $params->{sponsor_assembly_ii}){
            $search->{sponsors_priority} = { $sponsor => undef };
        }
        my $project;
        $model->schema->txn_do(
            sub {
                try{
                    $project = $model->create_project($search);
                    return "A new project was created.";
                }
                catch{
                    $model->schema->txn_rollback;
                    return "Project creation failed with error: $_";
                };
            }
        );
    } else {
        return "Project already exists.";
    }

    return;

}

sub proj_exp_check_ep_ii {
    my ( $model, $exp_id, $cell_line_id ) = @_;

    my @proj_exp = $model->resultset('ProjectExperiment')->search({ experiment_id => $exp_id })->all;
    return if (!$cell_line_id);
    foreach my $rec (@proj_exp) {
        my $proj_rec = $model->resultset( 'Project' )->find({ id => $rec->project_id}, { columns => [ qw/cell_line_id/ ] });
        if ($proj_rec and ($proj_rec->get_column('cell_line_id') == $cell_line_id)) {
            return 1;
        }
    }

    return;
}

sub add_exp_check_ep_ii {
    my ( $model, $exp_id, $proj_id, $gene_id ) = @_;

    my $exp_rec = $model->resultset( 'Experiment' )->find({ id => $exp_id}, { columns => [ qw/gene_id/ ] });
    if ($exp_rec->get_column('gene_id') ne $gene_id) { return; }

    ## exp_id and proj_id are not in project_experiment table
    my @proj_exp_count = $model->resultset('ProjectExperiment')->search({ project_id => $proj_id, experiment_id => $exp_id })->all;
    if (scalar @proj_exp_count) { return; }

    return 1;
}

1;

__END__

