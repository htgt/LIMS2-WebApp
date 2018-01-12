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
          )
    ]
};

use LIMS2::Model::Plugin::Project qw(create_project);
use LIMS2::Model::Plugin::Crispr qw(import_wge_crisprs);

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
    my $assembly = $model->resultset('SpeciesDefaultAssembly')->find( { species_id => $species } )->assembly_id;

    if ($wge_id) {
        my @crisprs = import_wge_crisprs( [$wge_id], $species, $assembly );
        return @crisprs;
    }

    return;
}

sub find_projects_ep_pipeline_ii {
    my ( $model, $params ) = @_;

    my $search;
    if ($params->{gene_id_assembly_ii}) {

        if ($params->{cell_line_assembly_ii}) { $search->{cell_line_id} = $params->{cell_line_assembly_ii}; }
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

    my @project_results;
    my @projects_rs = $model->resultset('Project')->search( $search, { order_by => 'id' })->all;

    if(scalar @projects_rs == 0){
        # Create a new project
        if(my $sponsor = $params->{sponsor_assembly_ii}){
            $search->{sponsors_priority} = { $sponsor => undef };
        }
        my $project;
        $model->txn_do(
            sub {
                try{
                    $project = create_project($search);
                    print "New project created";
                }
                catch{
                    $model->txn_rollback;
                    print "Project creation failed with error:";
                };
            }
        );
    } else {
        print "Project already exists (see list below)";
    }

    return;

}

1;

__END__

