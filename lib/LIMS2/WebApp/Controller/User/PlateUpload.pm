package LIMS2::WebApp::Controller::User::PlateUpload;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use List::MoreUtils qw(uniq);
use LIMS2::Model::Util::EPPipelineIIPlate qw( retrieve_experiments_ep_pipeline_ii
                                              retrieve_experiments_by_field 
                                              import_wge_crispr_ep_pipeline_ii 
                                              find_projects_ep_pipeline_ii 
                                              create_project_ep_pipeline_ii 
                                              proj_exp_check_ep_ii
                                              );

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::UI::PlateUpload - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return;
}

sub plate_upload_ep_pipeline_ii :Path( '/user/plate_upload_ep_pipeline_ii' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;
    my $species = $c->session->{selected_species};
    my @info_msg;
    my $cell_line_id;

    ## ----------------
    ## persistent input
    ## ----------------
    $c->stash(
        gene_id_assembly_ii        => $params->{gene_id_assembly_ii},
        cell_line_assembly_ii      => $params->{cell_line_assembly_ii},
        strategy_assembly_ii       => $params->{strategy_assembly_ii},
        targeting_type_assembly_ii => $params->{targeting_type_assembly_ii},
        sponsor_assembly_ii        => $params->{sponsor_assembly_ii},
        crispr_id_assembly_ii      => $params->{crispr_id_assembly_ii},
        wge_crispr_assembly_ii     => $params->{wge_crispr_assembly_ii},
        design_id_assembly_ii      => $params->{design_id_assembly_ii}
    );

    $params->{species} = $species;
    $params->{process_type} = 'ep_pipeline_ii';
    $params->{plate_type} = 'EP_PIPELINE_II';
    $params->{plate_name} = $params->{assembly_ii_plate_name};

    my $gene_info;
    $gene_info = try{ $c->model('Golgi')->find_gene( { search_term => $params->{gene_id_assembly_ii}, species => $species } ) };

    if ($gene_info) {
        $params->{gene_id_assembly_ii} = $gene_info->{gene_id};
    }

    ## ---------------
    ## project section
    ## ---------------
    ## - attributes
    my @cell_lines = map { { id => $_->id, name => $_->name} } $c->model('Golgi')->schema->resultset('CellLine')->all;
    $c->stash->{cell_line_options} = \@cell_lines;

    ## - persistent cell line input
    try {
        foreach my $cl (@cell_lines) {
            if ($cl->{id} eq $params->{cell_line_assembly_ii}) {
                $cell_line_id = $cl->{id};
                $c->stash(cell_line_id => $cl->{id}, cell_line_name => $cl->{name});
            }
        }
    };
    my @sponsors = sort map { $_->id } $c->model('Golgi')->schema->resultset('Sponsor')->all;
    $c->stash->{sponsors} = \@sponsors;

    ## - find projects
    my @all_projects;

    ## - persistent user input
    my @lagging_projects = split ",", $params->{lagging_projects};
    @all_projects = map { find_projects_ep_pipeline_ii($c->model('Golgi')->schema, {project_id => $_}) } @lagging_projects;

    ## - create project
    if ($params->{create_assembly_ii_project}) {
        $params->{find_assembly_ii_project} = 'find_assembly_ii_project';
        my $msg = create_project_ep_pipeline_ii($c->model('Golgi'), $params);
        push @info_msg, $msg;
    }

    ## - find projects for a gene
    if ($params->{find_assembly_ii_project}) {
        my @hit_projects = find_projects_ep_pipeline_ii($c->model('Golgi')->schema, $params);
        push @all_projects, @hit_projects;
    }

    my %seen_projs;
    my @projects = grep { ! $seen_projs{$_->{id}}++ } @all_projects;

    ## - preparing projects data for display
    @projects = ep_ii_compile_project_info($c, \@projects);
    my @lagging_project_ids = map {$_->{id}} @projects;

    $c->stash(
        hit_projects      => \@projects,
        lagging_projects  => join ",", @lagging_project_ids
    );

    ## ---------------
    ## crispr section
    ## ---------------
    ## - import crispr id from wge
    my @assembly_ii_crisprs;
    if ($params->{import_assembly_ii_crispr}) {
        @assembly_ii_crisprs = import_wge_crispr_ep_pipeline_ii($c->model('Golgi'), $params);
        unless (@assembly_ii_crisprs) {
            push @info_msg, 'Error importing Crispr ID: ' . $params->{wge_crispr_assembly_ii};
        }
        push @info_msg, 'Crispr ID was imported from WGE. ' . join ",", @assembly_ii_crisprs;
    }

    ## -------------------
    ## experiments section
    ## -------------------
    ## - keep lagging experiments
    my @lagging_exps;
    my @assembly_ii_experiments;
    my $lagging_exp_ids = $params->{lagging_exp_ids};
    if ($lagging_exp_ids) {
        @lagging_exps = map { retrieve_experiments_by_field($c->model('Golgi')->schema, 'id', $_) } (split ",", $lagging_exp_ids);
        push @assembly_ii_experiments, @lagging_exps;
    }

    ## - create experiment
    if ($params->{create_assembly_ii_experiment}) {
        try {
            my $exp_params = {
                gene_id         =>  $gene_info->{gene_id},
                design_id       =>  $params->{design_id_assembly_ii},
                crispr_id       =>  $params->{crispr_id_assembly_ii}
            };

            my $experiment = $c->model('Golgi')->create_experiment($exp_params);
            push @info_msg, 'A new experiment was created.';
        } catch {
            push @info_msg, 'Error creating new experiment.' . $_;
        };
    }

    ## - add experiment to project
    if($params->{add_exp_to_proj}){
        push @info_msg, ep_ii_add_exp_to_project($c, $params);
    }

    ## - find experiments by gene, crispr, design
    if ($params->{find_assembly_ii_experiments}) {
        push @assembly_ii_experiments, retrieve_experiments_ep_pipeline_ii($c->model('Golgi')->schema, $params);
    }

    ## - unique experiments
    my @unique_exps;
    my @exp_ids;

    ## - project existance check for experiments
    foreach my $dict (@assembly_ii_experiments) {
        if ( grep { $_ == $dict->{id} } @exp_ids) {
            next;
        }
        push @exp_ids, $dict->{id};
        my $bool = 0;
        if ($cell_line_id) {
            $bool = proj_exp_check_ep_ii($c->model('Golgi')->schema, $dict->{id}, $dict->{gene_id}, $cell_line_id);
        }
        $dict->{project_check} = $bool;
        my $info = try{ $c->model('Golgi')->find_gene( { search_term => $dict->{gene_id}, species => $species } ) };
        if ( $info ) {
            $dict->{gene_id} = $info->{gene_symbol};
        }
        push @unique_exps, $dict;
    }

    my $lagging_exps_str = join ",", @exp_ids;

    $c->stash(
        find_assembly_ii_experiments => $params->{find_assembly_ii_experiments},
        assembly_ii_experiments => \@unique_exps,
        lagging_exp_ids => $lagging_exps_str,
    );

    ## -------------
    ## plate section
    ## -------------
    ## - save plate details
    if ($params->{save_assembly_ii}) {
        my $plate_name = $c->request->params->{assembly_ii_plate_name};
        my $cell_line = $params->{cell_line_assembly_ii};
        my $sponsor = $params->{sponsor_assembly_ii};
        my $strategy = $params->{strategy_assembly_ii};
        my $targeting = $params->{targeting_type_assembly_ii};

        my @assembly_ii_wells = build_ep_pipeline_ii_well_data($c, $cell_line);
        my $assembly_ii_plate_data = {
            name       => $plate_name,
            species    => $species,
            type       => 'EP_PIPELINE_II',
            created_by => $c->user->name,
            wells      => \@assembly_ii_wells
        };

        my $plate;

        try{
            $plate = $c->model('Golgi')->create_plate( $assembly_ii_plate_data );
            $c->flash->{success_msg} = 'Created new plate ' . $plate->name;
            $c->res->redirect( $c->uri_for('/user/view_plate', { 'id' => $plate->id }) );
        } catch {
            push @info_msg, 'Error creating plate: ' . $_;
        };
    }

    if (@info_msg) {
        my $msg = join "\n", @info_msg;
        $c->stash->{info_msg} = $msg;
    }

    return;
}


sub ep_ii_compile_project_info {
    my ($c, $projects_ref) = @_;

    my @projects = @{$projects_ref};
    foreach my $proj_indx (0..$#projects) {
        try {
            my $gene_info = try{ $c->model('Golgi')->find_gene( { search_term => $projects[$proj_indx]->{gene_id}, species => $c->session->{selected_species} } ) };
            if ($gene_info) {
                $projects[$proj_indx]->{gene_id} = $gene_info->{gene_symbol};
            }
            $projects[$proj_indx]->{info} = "gene_id_assembly_ii:" . $projects[$proj_indx]->{gene_id} . ",cell_line_assembly_ii:" . $projects[$proj_indx]->{cell_line_id} . ",strategy_assembly_ii:" . $projects[$proj_indx]->{strategy_id} . ",targeting_type_assembly_ii:" . $projects[$proj_indx]->{targeting_type} . ",sponsor_assembly_ii:" . $projects[$proj_indx]->{sponsor_id};
        };
    }

    return @projects;
}

sub ep_ii_add_exp_to_project {
    my ($c, $params) = @_;

    my $project;
    my @exp_info = split ",", $params->{add_exp_to_proj};

    my $gene_info = try{ $c->model('Golgi')->find_gene( { search_term => $params->{gene_id_assembly_ii}, species => $c->session->{selected_species} } ) };
    if ($gene_info) {
        my $data = { gene_id_assembly_ii => $gene_info->{gene_id}, cell_line_assembly_ii => $params->{cell_line_assembly_ii} };
        my @projs = find_projects_ep_pipeline_ii($c->model('Golgi')->schema, $data);
        $project = $projs[0];
    }

    my $add_exp_check = 0;
    try {
        $add_exp_check = $c->model('Golgi')->add_experiment($project->{id}, $exp_info[0]);
    };

    if ($add_exp_check) {
        return 'Experiment has been added for this project ' . $project->{id};
    } else {
        return 'Could not add experiment.';
    }

}

sub build_ep_pipeline_ii_well_data {
    my ($c, $cell_line_id) = @_;

    my @wells;
    foreach my $well qw( well_01 well_02 well_03 well_04 well_05 well_06 well_07 well_08 well_09 well_10 well_11 well_12 well_13 well_14 well_15 well_16 ) {
        my $temp_exp_id = $c->request->params->{$well};

        if ($temp_exp_id) {
            my @exp_res = retrieve_experiments_by_field($c->model('Golgi')->schema, 'id', $temp_exp_id );
            my $exp = $exp_res[0];

            my @name_split = split "well_", $well;
            my $temp_data = {
                well_name    => 'A' . $name_split[1],
                design_id    => $exp->{design_id},
                crispr_id    => $exp->{crispr_id},
                cell_line    => $cell_line_id,
                process_type => 'ep_pipeline_ii'
            };
            push @wells, $temp_data;
        }
    }

    return @wells;

}

sub plate_upload_step1 :Path( '/user/plate_upload_step1' ) :Args(0) {
    my ( $self, $c ) = @_;

    my @process_types = map { $_->id } @{ $c->model('Golgi')->list_process_types };

    $c->stash(
        process_types => [ grep{ !/create_di|legacy_gateway|create_crispr/ } @process_types ],
        plate_help  => $c->model('Golgi')->plate_help_info,
    );
    return;
}

sub plate_upload_step2 :Path( '/user/plate_upload_step2' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $process_type = $c->request->params->{process_type};
    unless ( $process_type ) {
        $c->flash->{error_msg} = 'You must specify a process type';
        return $c->res->redirect('/user/plate_upload_step1');
    }

   if ($process_type eq 'ep_pipeline_ii') {
     return $c->res->redirect('/user/plate_upload_ep_pipeline_ii');
   }

    my $cell_lines = $c->model('Golgi')->schema->resultset('DnaTemplate')->search();
    my @lines;
    while (my $line = $cell_lines->next){
        push(@lines, $line->as_string);
    }
    $c->stash(
        process_type   => $process_type,
        process_fields => $c->model('Golgi')->get_process_fields( { process_type => $process_type } ),
        plate_types    => $c->model('Golgi')->get_process_plate_types( { process_type => $process_type } ),
        plate_help     => $c->model('Golgi')->plate_help_info,
        cell_lines     => \@lines,
        dna_template   => $c->request->params->{source_dna},
    );

    my $step = $c->request->params->{plate_upload_step};
    return if !$step  || $step != 2;

    my $plate = $self->process_plate_upload_form( $c );
    return unless $plate;

    $c->flash->{success_msg} = 'Created new plate ' . $plate->name;
    $c->res->redirect( $c->uri_for('/user/view_plate', { 'id' => $plate->id }) );
    return;
}

sub process_plate_upload_form :Private {
    my ( $self, $c ) = @_;

    $c->stash( $c->request->params );
    my $params = $c->request->params;
    my $well_data = $c->request->upload('datafile');
    unless ( $well_data or $params->{process_type} eq 'ep_pipeline_ii' ) {
        $c->stash->{error_msg} = 'No csv file with well data specified';
        return;
    }

    unless ( $params->{plate_name} ) {
        $c->stash->{error_msg} = 'Must specify a plate name';
        return;
    }

    unless ( $params->{plate_type} ) {
        $c->stash->{error_msg} = 'Must specify a plate type';
        return;
    }
    if ( $params->{plate_type} eq 'INT' && $params->{source_dna} eq '' ) {
        $c->stash->{error_msg} = 'Must specify a DNA template for INT vectors';
        return;
    }

    my $comment;
    if ( $params->{process_type} eq 'int_recom' ) {
        unless ( $params->{planned_wells} ) {
            $c->stash->{error_msg} = 'Must specify the number of planned post-gateway wells';
            return;
        }
        $comment = {
             comment_text  => $params->{planned_wells} .' post-gateway wells planned for wells on plate '. $params->{plate_name},
             created_by_id => $c->user->id,
             created_at    => scalar localtime,
        }
    }

    $params->{species} ||= $c->session->{selected_species};
    $params->{created_by} = $c->user->name;

    my $plate;
    my $data;
    if ($params->{process_type} ne 'ep_pipeline_ii') {
        $data = $well_data->fh;
    }
    $c->model('Golgi')->txn_do(
        sub {
            try {
                $plate = $c->model('Golgi')->create_plate_csv_upload( $params, $data);
            }
            catch {
                $c->stash->{error_msg} = 'Error encountered while creating plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
            if ( $comment ) {
                $comment->{plate_id} = $plate->id;
                $c->model('Golgi')->schema->resultset('PlateComment')->create( $comment );
            }
        }
    );

    return $plate ? $plate : undef;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;


