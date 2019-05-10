package LIMS2::Model::Util::SponsorReportII;

use strict;
use warnings;
use Moose;
use POSIX 'strftime';
use List::Util qw/first/;
use List::MoreUtils qw( uniq );
use Try::Tiny;
use Log::Log4perl ':easy';
use Readonly;
#use experimental qw(switch);
use feature 'switch';
use Time::HiRes 'time';
use Data::Dumper;
use LIMS2::Model::Util::Miseq qw( find_miseq_data_from_experiment );

extends qw( LIMS2::ReportGenerator );

Readonly my $SUBREPORT_COLUMNS => {
    general_first => [
    'Gene ID',
    'Gene Symbol',
    'Chr',
    'Project ID',
    'Cell line',
    'Experiment',
    'Ordered Crisprs',
    'Design ID',
    'Electroporation iPSCs',
    'iPSC Colonies Picked',
    ],
    general_second => [
    'Requester',
    'Programme',
    'Sponsor',
    'Lab Head',
    ],
    primary_genotyping => [
    'Clones on MiSEQ Plate',
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

has total_gene_count => (
    is         => 'ro',
    isa        => 'Int',
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

    ## custom-sorting
    my @sorted_programmes = sort { $a cmp $b } @programmes;
    @sorted_programmes = grep { $_ ne 'Other' } @sorted_programmes;
    push @sorted_programmes, 'Other';

    return \@sorted_programmes;
};

sub _build_total_gene_count {
    my $self = shift;

    my @project_ii_rs = $self->model->schema->resultset('Project')->search(
          { strategy_id => 'Pipeline II' },
          { distinct => 1 }
        )->all;

    my @projects_ii = map { $_->id } @project_ii_rs;

    my @project_sponsor_rs = $self->model->schema->resultset('ProjectSponsor')->search(
          { project_id => { -in => \@projects_ii }, sponsor_id => { 'not in' => ['All'] }, programme_id => { 'is not' => undef } },
          { distinct => 1 }
        )->all;

    return scalar @project_sponsor_rs;
};

=head _build_sponsor_gene_count
    Build the gene count of Pipeline II sponsors
=cut

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


=head find_my_hash
    Find a matching hash in an array
=cut

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
        $abbr = $programme_rs->get_column('abbr');
        $abbr ? return $abbr : return 'None';
    }

    return $abbr;
}



## A dispatch table of subroutines for every value in the report
my $launch_report_subs = {
    gene_info             => \&get_gene_info,
    exp_info              => \&get_exp_info,
    ipscs_ep              => \&get_ipsc_electroporation,
    ep_cell_line          => \&get_electroporation_cell_line,
    ipscs_colonies_picked => \&get_ipsc_colonies_picked,
    genotyping            => \&get_genotyping_data,
};


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
}


=head get_crispr_seq
    Used to get ordered crispr sequences based on a crispr id, crispr pair id or a crispr group id
=cut

sub get_crispr_seq {
    my ($self, $search_info)= @_;
    my @seq;

    my $crispr_type = $search_info->{type};
    my $experiment = $search_info->{experiment};

    given ($crispr_type) {
        when(/^crispr$/) {
            push @seq, $experiment->crispr->seq;
            return @seq;
        }

        when(/^crispr_pair$/) {
            my $crispr_pair_id = $experiment->crispr_pair_id;
            my @crispr_pair_rs = $self->model->schema->resultset('CrisprPair')->search({
                crispr_pair_id => $crispr_pair_id,
                });

            @seq = map { $_->crispr->seq } @crispr_pair_rs;
            return @seq;

        }

        when(/^crispr_group$/) {
            my $crispr_group_id = $experiment->crispr_group_id;
            my @crispr_group_rs = $self->model->schema->resultset('CrisprGroupCrispr')->search({
                crispr_group_id => $crispr_group_id,
                });

            @seq = map { $_->crispr->seq } @crispr_group_rs;
            return @seq;
        }
    }

    return;
}


=head get_exp_info
    Get experiment info in the form of hash for downstream file creation purposes
=cut

sub get_exp_info {
    my ($self, $project_id) = @_;

    my @exps;

    my @proj_exp_rs = $self->model->schema->resultset('ProjectExperiment')->search({ project_id => $project_id, experiment_id => { 'is not' => undef }});

    foreach my $rec (@proj_exp_rs) {
        try {
            my $temp_h = {
                id               => $rec->experiment->id,
                trivial_name     => $rec->experiment->trivial_name,
                crispr_id        => $rec->experiment->crispr_id,
                crispr_pair_id   => $rec->experiment->crispr_pair_id,
                crispr_group_id  => $rec->experiment->crispr_group_id,
                design_id        => $rec->experiment->design_id,
            };

            my $crispr_search;

            if ( $temp_h->{crispr_id} ) {
                $crispr_search->{type} = 'crispr';
            } elsif ( $temp_h->{crispr_pair_id} ) {
                $crispr_search->{type} = 'crispr_pair';
            } elsif ( $temp_h->{crispr_group_id} ) {
                $crispr_search->{type} = 'crispr_group';
            } else {
                die "An experiment without a crispr?! :o ";
            }

            $crispr_search->{experiment} = $rec->experiment;
            my @crispr_result = $self->get_crispr_seq($crispr_search);
            $temp_h->{crispr_seq} = \@crispr_result;


            try{ $temp_h->{requester} = $rec->experiment->requester->id; };
            push @exps, $temp_h;
        };
    }

    return @exps;
}


=head get_ipsc_electroporation
    Get the EP II plate names/ids according to experiment info and cell line
=cut

sub get_ipsc_electroporation {
    my ($self, $exps, $cell_line_id) = @_;

    my @exps = @$exps;
    my $exps_ep_ii;
    my $flag;

    foreach my $experiment (@exps) {
        try {
            my $exp_id = $experiment->{id};
            my ($design_id, $crispr_id, $crispr_pair_id, $crispr_group_id) = ($experiment->{design_id}, $experiment->{crispr_id}, $experiment->{crispr_pair_id}, $experiment->{crispr_group_id});

            if ($design_id and $cell_line_id and ($crispr_id or $crispr_pair_id or $crispr_group_id)) {

                ## EP II plate processes incl. process_design, process_cell_line, process_crispr, process_crispr_pair, process_crispr_group
                ## the code below links an experiment attributes to an EP II plate

                my @process_design_rs = $self->model->schema->resultset('ProcessDesign')->search(
                      { design_id => $design_id }
                    )->all;
                my @process_design = map { $_->process_id } @process_design_rs;

                my @process_crispr;
                my @process_crispr_rs = $self->model->schema->resultset('ProcessCrispr')->search(
                      { crispr_id => $crispr_id }
                    )->all;
                push @process_crispr, map { $_->process_id } @process_crispr_rs;

#                TODO: uncomment once related tables are created in DB 
#                my @process_crispr_pair_rs = $self->model->schema->resultset('ProcessCrisprPair')->search(
#                      { crispr_pair_id => $crispr_pair_id }
#                    )->all;
#                push @process_crispr, map { $_->process_id } @process_crispr_pair_rs;

#                my @process_crispr_group_rs = $self->model->schema->resultset('ProcessCrisprGroup')->search(
#                      { crispr_group_id => $crispr_group_id }
#                    )->all;
#                push @process_crispr, map { $_->process_id } @process_crispr_group_rs;

                my @process_cell_line_rs = $self->model->schema->resultset('ProcessCellLine')->search(
                      { cell_line_id => $cell_line_id }
                    )->all;
                my @process_cell_line = map { $_->process_id } @process_cell_line_rs;

                my @intersect_processes;
                foreach my $pr (@process_crispr) {
                    if ((map { $_ == $pr } @process_design) and (map { $_ == $pr } @process_cell_line)) {
                        push @intersect_processes, $pr;
                    }
                }

                my @input_wells_rs;
                if (scalar @intersect_processes) {
                    @input_wells_rs = $self->model->schema->resultset('ProcessOutputWell')->search(
                          { process_id => { -in => \@intersect_processes } }
                        )->all;
                }

                my @input_wells;
                if (scalar @input_wells_rs) {
                    @input_wells = map { $_->well } @input_wells_rs;
                }

                my @ep_ii_plate_data;
                my @plate_name_tracker;
                foreach my $well (@input_wells) {
                    if ($well->plate->type_id eq 'EP_PIPELINE_II') {
                        if (!(map { $_ eq $well->plate->name } @plate_name_tracker)) {
                            my $temp_h = { name => $well->plate->name, plate_id => $well->plate->id, well_id => $well->id };
                            push @plate_name_tracker, $well->plate->name;
                            push @ep_ii_plate_data, $temp_h;
                        }
                    }
                }

                ## This flag is used to determine the color in the frontend view
                if (scalar @ep_ii_plate_data) {
                    $flag = 1;
                }

                $exps_ep_ii->{exps}->{$exp_id} = \@ep_ii_plate_data;
            }
        }
    };

    $exps_ep_ii->{has_plates} = $flag;

    return $exps_ep_ii;
}


=head get_ipsc_colonies_picked
    Get the number of colonies picked per experiment's EP II plates
=cut

sub get_ipsc_colonies_picked {
    my ($self, $exp_info) = @_;

    my $exp_colonies;
    my $total = 0;

    while (my ($exp_id, $ep_ii_plates) = each %{$exp_info}) {
        my $colonies = 0;

        foreach my $ep_ii_plate (@{$ep_ii_plates}) {
            my $ep_ii_well_id = $ep_ii_plate->{well_id};

            my @process_rs_1 = $self->model->schema->resultset('ProcessInputWell')->search({
                well_id => $ep_ii_well_id
                });

            my @process_ids = map { $_->process_id } @process_rs_1;

            my @process_rs_2 = $self->model->schema->resultset('ProcessOutputWell')->search({
                process_id => { -in => \@process_ids }
                });

            my @child_pick_wells = map { $_->well_id } @process_rs_2;

            @child_pick_wells = uniq @child_pick_wells;
            $colonies += scalar @child_pick_wells;
        }

        $exp_colonies->{$exp_id}->{picked_colonies} = $colonies;
        $total += $colonies;
    }

    $exp_colonies->{total} = $total;
    return $exp_colonies;
}


=head get_primary_genotyping
    Primary genotyping info: clones on Miseq plate / wild-type clones selected / Het clone selected / Hom clones selected
    per experiment and total per project
=cut

sub find_secondary_qc {
    my ( $self, @mwes ) = @_;
    my %data = ();
    foreach my $mwe ( @mwes ) {
        my @qc =
            map { { $_->id => $_->classification->id } }
            map { $_->miseq_well_experiments }
            map { $_->output_wells }
            map { $_->descendants->find_descendant_of_type($_, 'miseq_no_template') }
            map { $_->output_wells }
            map { $_->descendants->find_descendant_of_type($_, 'dist_qc') }
            map { $_->input_wells }
            $mwe->well->ancestors->find_process_of_type($mwe->well, 'miseq_no_template');
        if ( scalar(@qc) ) {
            $data{$mwe->well_id} = \@qc;
        }
    }
    return \%data;
}

sub get_genotyping_data {
    my ($self, $c, @exps) = @_;

    my $genotyping;
$DB::single=1;
    my @res;
    foreach my $exp_rec (@exps) {
        my @results = find_miseq_data_from_experiment($c, $exp_rec->{id});
        push @res, @results;











        my @miseq_exps_and_wells;
        my $original_exp_id = $exp_rec->{id};
        ## Get the miseq experiment id using an experiment id
        my @miseq_exp_rs = $self->model->schema->resultset('MiseqExperiment')->search({
            experiment_id => $original_exp_id,
            });

        my @miseq_exp_ids = map { $_->id } @miseq_exp_rs;

        if ( @miseq_exp_ids ) {
            foreach my $exp_id (@miseq_exp_ids) {
                @miseq_exps_and_wells = $self->model->schema->resultset('MiseqWellExperiment')->search({
                    miseq_exp_id => $exp_id,
                    });

                $genotyping->{$original_exp_id}->{primary}->{total_number_of_clones} = scalar @miseq_exps_and_wells;
                $genotyping->{total}->{total_number_of_clones} += scalar @miseq_exps_and_wells;
                
                my $secondary_qc = $self->find_secondary_qc(@miseq_exps_and_wells);
                print Dumper($secondary_qc);

                foreach my $miseq_well (@miseq_exps_and_wells) {
                    my $class = lc $miseq_well->classification->id;
                    my $status = $miseq_well->status;
                    given ($class) {
                        when(/wild type/) {
                            $genotyping->{$original_exp_id}->{primary}->{wt}++;
                            $genotyping->{total}->{primary}->{wt}++;
                            #if ($status eq 'Scanned-Out') {
                            if ( exists $secondary_qc->{$miseq_well->id} ) {
                                $genotyping->{$original_exp_id}->{secondary}->{wt}++;
                                $genotyping->{total}->{secondary}->{wt}++;
                            }
                        }
                        when(/mixed/) {
                            $genotyping->{$original_exp_id}->{primary}->{het}++;
                            $genotyping->{total}->{primary}->{het}++;
                            #if ($status eq 'Scanned-Out') {
                            if ( exists $secondary_qc->{$miseq_well->id} ) {
                                $genotyping->{$original_exp_id}->{secondary}->{het}++;
                                $genotyping->{total}->{secondary}->{het}++;
                            }
                        }
                        when(/hom/) {
                            $genotyping->{$original_exp_id}->{primary}->{hom}++;
                            $genotyping->{total}->{primary}->{hom}++;
                            #if ($status eq 'Scanned-Out') {
                            if ( exists $secondary_qc->{$miseq_well->id} ) {
                                $genotyping->{$original_exp_id}->{secondary}->{hom}++;
                                $genotyping->{total}->{secondary}->{hom}++;
                            }
                        }
                    }
                }
            }
        }
    }
$DB::single=1;
    return $genotyping;
}


=head generate_sub_report

=cut

sub generate_sub_report {
    my ($self, $c, $sponsor_id, $lab_head, $programme) = @_;

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

    my $gene_info;
    foreach my $project_rec (@project_ii_rs) {
        my $row_data;

        ## general info
        $row_data->{project_id} = $project_rec->id;
        $row_data->{cell_line} = $project_rec->cell_line->name;

        $gene_info = &{$launch_report_subs->{ 'gene_info' }}($self, $project_rec->gene_id, $self->species);
        $row_data->{gene_id} = $gene_info->{gene_id};
        $row_data->{gene_symbol} = $gene_info->{gene_symbol};
        $row_data->{chromosome} = $gene_info->{chromosome};

        $row_data->{programme} = $programme;
        $row_data->{lab_head} = $lab_head;
        $row_data->{sponsor} = $sponsor_id;

        ## experiment info
        my @proj_exps = &{$launch_report_subs->{ 'exp_info' }}($self, $project_rec->id);
        $row_data->{experiments} = \@proj_exps;

        ## EP II plate info
        my $exps_ep_ii_plate_names = &{$launch_report_subs->{ 'ipscs_ep' }}($self, \@proj_exps, $project_rec->cell_line_id);
        $row_data->{experiment_ep_ii_info} = $exps_ep_ii_plate_names;

        ## picked colonies
        $row_data->{exp_ipscs_colonies_picked} = &{$launch_report_subs->{ 'ipscs_colonies_picked' }}($self, $exps_ep_ii_plate_names->{exps});

        ## primary and secondary genotyping
        $row_data->{genotyping} = &{$launch_report_subs->{ 'genotyping' }}($self, $c, @proj_exps);

        push @data, $row_data;
    }

    my $date_format = strftime '%d %B %Y', localtime;

    $report->{date} = $date_format;
    $report->{columns} = $SUBREPORT_COLUMNS;

    my @sorted_data =  sort { $a->{gene_symbol} cmp $b->{gene_symbol} } @data;
    $report->{data} = \@sorted_data;

    return $report;

}


sub generate_total_sub_report {
    my $self = shift;

    my @total_data;
    my $total_sub_report;

    foreach my $unit ( @{$self->sponsor_gene_count} ) {

        my $curr_sponsor = $unit->{sponsor_id};
        my $curr_lab_head = $unit->{lab_head_id};
        my $curr_programme = $unit->{programme_id};

        my $current_sub_report = $self->generate_sub_report($curr_sponsor, $curr_lab_head, $curr_programme);

        push @total_data, @{$current_sub_report->{data}};
    }

    my $date_format = strftime '%d %B %Y', localtime;
    $total_sub_report->{date} = $date_format;
    $total_sub_report->{columns} = $SUBREPORT_COLUMNS;

    my @sorted_data =  sort { $a->{gene_symbol} cmp $b->{gene_symbol} } @total_data;
    $total_sub_report->{data} = \@sorted_data;

    return $total_sub_report;
}


sub save_file_data_format {
    my ($self, $data) = @_;

    my $general = '';
    my @csv_data;

## columns:
  ## gene_id => string
  ## gene_symbol => string
  ## chromosome => string
  ## project_id => string
  ## cell_line => string
  ## programme => string
  ## sponsor => string
  ## lab_head => string
  ## exp_id
  ## design_id
  ## crispr_seq
  ## ep_ii_plate_name
  ## ipscs_colonies_picked
  ## total_number_of_clones
  ## selected_wt
  ## selected_het
  ## selected_hom
  ## distributable_wt
  ## distributable_het
  ## distributable_hom

  ## experiments => array of hashes
  ## experiment_ep_ii_info => hash
  ## exp_ipscs_colonies_picked => hash
  ## genotyping => hash
    push @csv_data, "gene id,gene symbol,chromosome,project id,cell line,programme,sponsor,lab head,experiment id,design id,crispr sequence,ipscs electroporation plate names,ipscs colonies picked,miseq clones,selected wt,selected het,selected hom,distributable wt,distributable het,distributable hom";

    foreach my $data_unit (@{$data}) {
        $general = join ",", ($data_unit->{gene_id}, $data_unit->{gene_symbol}, $data_unit->{chromosome}, $data_unit->{project_id}, $data_unit->{cell_line}, $data_unit->{programme}, $data_unit->{sponsor}, $data_unit->{lab_head});

        foreach my $exp (@{$data_unit->{experiments}}) {
            my $exp_id = $exp->{id};
            my @exp_ep_ii_plates = map { $_->{name} } @{$data_unit->{experiment_ep_ii_info}->{exps}->{$exp_id}};
            my $primary_genotyping = $data_unit->{genotyping}->{$exp_id}->{primary}->{total_number_of_clones} . "," . $data_unit->{genotyping}->{$exp_id}->{primary}->{wt} . "," . $data_unit->{genotyping}->{$exp_id}->{primary}->{het} . "," . $data_unit->{genotyping}->{$exp_id}->{primary}->{hom};
            my $secondary_genotyping = $data_unit->{genotyping}->{$exp_id}->{secondary}->{wt} . "," . $data_unit->{genotyping}->{$exp_id}->{secondary}->{het} . "," . $data_unit->{genotyping}->{$exp_id}->{secondary}->{hom};
            push @csv_data, $general . "," . $exp_id . "," . $exp->{$exp_id}->{design_id} . "," . $exp->{$exp_id}->{crispr_seq} . "," . join ",", @exp_ep_ii_plates . "," . $data_unit->{exp_ipscs_colonies_picked}->{$exp_id}->{picked_colonies} . "," . $primary_genotyping . "," . $secondary_genotyping;
        }
    }

    return join "\n", @csv_data;

}

1;
