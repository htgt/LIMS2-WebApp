package LIMS2::Report::RecoveryOverview;

use Moose;
use MooseX::ClassAttribute;
use DateTime;
use JSON qw( decode_json );
use Readonly;
use namespace::autoclean;
use Log::Log4perl qw(:easy);

extends qw( LIMS2::ReportGenerator );

has '+custom_template' => (
    default => 'user/report/recovery_overview.tt',
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has sponsor => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_sponsor'
);

has stage_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

has crispr_stage_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

Readonly my $STAGES => {
    design_well_created => {
        name       => 'Design Well Created',
        field_name => 'design_well_id',
        time_field => 'design_well_created_ts',
        order      => 1,
        detail_columns => [ qw(design_name design_plate_name design_well_name design_well_created_ts) ],
    },
    int_vector_created => {
        name       => 'Intermediate Vector Created',
        field_name => 'int_well_id',
        time_field => 'int_well_created_ts',
        order      => 2,
        detail_columns => [ qw(int_plate_name int_well_name int_well_created_ts int_qc_seq_pass)],
    },
    final_vector_created => {
        name       => 'Final Vector Created',
        field_name => 'final_well_id',
        time_field => 'final_well_created_ts',
        order      => 3,
        detail_columns => [ qw(final_plate_name final_well_name final_well_created_ts final_qc_seq_pass) ],
    },
    final_pick_created => {
        name       => 'Final Pick Created',
        field_name => 'final_pick_well_id',
        time_field => 'final_pick_well_created_ts',
        order      => 4,
        detail_columns => [ qw(final_pick_plate_name final_pick_well_name final_pick_well_created_ts final_pick_qc_seq_pass ) ],
    },
    assembly_created => {
        name       => 'Assembly Created',
        field_name => 'assembly_well_id',
        time_field => 'assembly_well_created_ts',
        order      => 5,
        detail_columns => [ qw(assembly_plate_name assembly_well_name assembly_well_created_ts ) ],
    },
    crispr_ep_created => {
        name       => 'Crispr EP Created',
        field_name => 'crispr_ep_well_id',
        time_field => 'crispr_ep_well_created_ts',
        order      => 6,
        detail_columns => [ qw(crispr_ep_plate_name crispr_ep_well_name crispr_ep_well_created_ts crispr_ep_well_accepted)],
    },
    ep_pick_created => {
        name       => 'EP Pick Created',
        field_name => 'ep_pick_well_id',
        time_field => 'ep_pick_well_created_ts',
        order      => 7,
        detail_columns => [ qw(ep_pick_plate_name ep_pick_well_name ep_pick_well_created_ts ep_pick_qc_seq_pass ep_pick_well_accepted)],
    },
    fp_created => {
        name       => 'Freeze Plate Created',
        field_name => 'fp_well_id',
        time_field => 'fp_well_created_ts',
        order      => 8,
        detail_columns => [ qw(fp_plate_name fp_well_name fp_well_created_ts fp_well_accepted)],
    },
    piq_created => {
        name       => 'PIQ Created',
        field_name => 'piq_well_id',
        time_field => 'piq_well_created_ts',
        order      => 9,
        detail_columns => [ qw(piq_plate_name piq_well_name piq_well_created_ts piq_well_accepted)],
    },
    piq_accepted => {
        name       => 'PIQ Accepted',
        field_name => 'piq_well_accepted',
        time_field => 'piq_well_created_ts',
        order      => 10,
        detail_columns => [ qw(piq_plate_name piq_well_name piq_well_created_ts piq_well_accepted)],
    },
};

Readonly my $CRISPR_STAGES => {
    crispr_well_created => {
        name       => 'Crispr Well Created',
        order      => 1,
    },
    crispr_vector_created => {
        name       => 'Crispr Vector Created',
        order      => 2,
    },
    crispr_dna_created => {
        name       => 'Crispr DNA Created',
        order      => 3,
    }
};

has stages => (
    is             => 'ro',
    isa            => 'HashRef',
    default        => sub{ return $STAGES },
);

has crispr_stages  => (
    is             => 'ro',
    isa            => 'HashRef',
    default        => sub{ return $CRISPR_STAGES },
);

sub _build_stage_data {
    my ($self) = @_;

    # stage_data->{stage}->{gene}->\@summary_rows

    DEBUG "Building stage data";
    my $stage_data = {};

    my $project_rs = $self->model->schema->resultset('Project')->search(
        {
            sponsor_id => $self->sponsor
        },
    );

    # ensure we only report each gene at its maximum stage by processing
    # stages from latest to earliest and not reporting a gene that already
    # has a stage higher than the max found for current project
    my $gene_max_stage;
    my %all_gene_ids;

    PROJECT: while ( my $project = $project_rs->next){
        my $gene = $project->gene_id;
        $all_gene_ids{$gene} = $gene;
        my $summary_rs = $self->model->schema->resultset('Summary')->search({
            design_gene_id => $gene,
        });
        next if $summary_rs == 0;
        # Store gene symbol if we found it in summary table
        $all_gene_ids{$gene} = $summary_rs->first->design_gene_symbol;

        foreach my $stage (sort { $STAGES->{$b}->{order} <=> $STAGES->{$a}->{order} }
                      (keys %$STAGES) ){
            my $stage_info = $STAGES->{$stage};
            my @matching_rows = $summary_rs->search( { $stage_info->{field_name} => { '!=', undef } })->all;

            if(@matching_rows){
                my $previously_seen_stage = $gene_max_stage->{$gene};
                if($previously_seen_stage){
                    if($stage_info->{order} > $STAGES->{$previously_seen_stage}->{order}){
                        # This project has a later stage for this gene
                        # so delete gene from previously seen stage
                        # and store this one instead
                        delete $stage_data->{$previously_seen_stage}->{$gene};
                        $stage_data->{$stage}->{$gene} = \@matching_rows;
                        $gene_max_stage->{$gene} = $stage;
                    }
                }
                else{
                    # We have not seen this gene before so store stage
                    $stage_data->{$stage}->{$gene} = \@matching_rows;
                    $gene_max_stage->{$gene} = $stage;
                }

                # We are only interested in the latest stage so go to next project
                next PROJECT;
            }
        }
    }

    # Store all gene ids for sponsor to use when fetching crispr data
    $stage_data->{all_gene_ids} =  \%all_gene_ids ;

    return $stage_data;
}

sub _build_crispr_stage_data {
    my ($self) = @_;

    my $crispr_stage_data = {};
    my @gene_ids = keys %{ $self->stage_data->{all_gene_ids} || {} };

    my $crispr_summaries = $self->model->get_crispr_summaries_for_genes({
        id_list => \@gene_ids,
        species => $self->species
    });

    GENE: foreach my $gene (keys %$crispr_summaries){
        my $gene_symbol = $self->stage_data->{all_gene_ids}->{$gene};
        DEBUG("finding crispr stages for gene $gene $gene_symbol");
        my $crispr_well_count;
        my $first_crispr_well_date;

        my $gene_crisprs = $crispr_summaries->{$gene} || {};
        foreach my $design (keys %$gene_crisprs){
            DEBUG("finding crispr stages for design $design");
            my $design_crisprs = $gene_crisprs->{$design}->{plated_crisprs};
            foreach my $crispr (keys %$design_crisprs){
                DEBUG("checking crispr $crispr");
                foreach my $crispr_well (keys %{ $design_crisprs->{$crispr} } ){
                    DEBUG("checking crispr well $crispr_well");
                    $crispr_well_count++;

                    my $date = $design_crisprs->{$crispr}->{$crispr_well}->{crispr_well_created};
                    $first_crispr_well_date ||= $date;
                    if($date < $first_crispr_well_date){
                        $first_crispr_well_date = $date;
                    }

                    my $dna_rs = $design_crisprs->{$crispr}->{$crispr_well}->{DNA};
                    my $vector_rs = $design_crisprs->{$crispr}->{$crispr_well}->{CRISPR_V};
                    my $assembly_rs = $design_crisprs->{$crispr}->{$crispr_well}->{ASSEMBLY};

                    if($assembly_rs != 0){
                        # Assembly created so gene is already past crispr stages
                        next GENE;
                    }
                    elsif($dna_rs != 0){
                        my $first = $dna_rs->search({},{ order_by => {'-asc' => 'me.created_at '} })->first;
                        $crispr_stage_data->{crispr_dna_created}->{$gene_symbol} = $first->created_at->dmy('/');
                        next GENE;
                    }
                    elsif($vector_rs != 0){
                        my $first = $vector_rs->search({},{ order_by => {'-asc' => 'me.created_at '} })->first;
                        $crispr_stage_data->{crispr_vector_created}->{$gene_symbol} = $first->created_at->dmy('/');
                        next GENE;
                    }
                }
            }
        }

        if($crispr_well_count){
            # We found crispr wells but no DNA or vector result sets
            $crispr_stage_data->{crispr_well_created}->{$gene_symbol} = $first_crispr_well_date;
        }
    }

    return $crispr_stage_data;
}

has '+param_names' => (
    default => sub { [ 'species', 'sponsor' ] }
);



override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append = $self->has_sponsor ? ' - Sponsor ' . $self->sponsor . ' ' : '';
    $append .= $dt->ymd;

    return 'Recovery Overview ' . $append;
};

override _build_columns => sub {
    my $self = shift;

    return [];
};

override iterator => sub {
    my ($self) = @_;

    DEBUG "getting iterator";

    my $stage_data = $self->stage_data;

    my @counts;

    foreach my $stage (sort { $CRISPR_STAGES->{$a}->{order} <=> $CRISPR_STAGES->{$b}->{order} }
                      (keys %$CRISPR_STAGES) ){
        my @genes = keys %{ $self->crispr_stage_data->{$stage} || {} };
        my $count = scalar @genes;
        my $genes = "";
        if($count){
            $genes = join ", ",  @genes ;
        }
        push @counts, [ $stage, $count, $genes ];
    }

    foreach my $stage (sort { $STAGES->{$a}->{order} <=> $STAGES->{$b}->{order} }
                      (keys %$STAGES) ){
        my @genes = keys %{ $stage_data->{$stage} || {} };
        my $count = scalar @genes;
        my $genes = "";
        if($count){
            $genes = join ", ", ( map { $stage_data->{$stage}->{$_}->[0]->design_gene_symbol } @genes );
        }
        push @counts, [ $stage, $count, $genes ];
    }

    return Iterator::Simple::iter(\@counts);
};

override structured_data => sub {
    my ($self) = @_;
    my $data = {};

    DEBUG "Getting structured data";
    $data->{sponsor} = $self->sponsor;

    my $stage_data = $self->stage_data;

    foreach my $stage (keys %$STAGES) {
        $data->{$stage}->{display_name} = $STAGES->{$stage}->{name};
        my @genes = keys %{ $stage_data->{$stage} || {} };
        foreach my $gene (@genes){
            my $summaries = $stage_data->{$stage}->{$gene};
            my $time_field = $STAGES->{$stage}->{time_field};
            my $min;
            my $gene_symbol = $summaries->[0]->design_gene_symbol;
            foreach my $summary (@$summaries){
                $min ||= $summary->$time_field;
                if($summary->$time_field < $min){
                    $min = $summary->$time_field;
                }
            }
            $data->{$stage}->{genes}->{$gene_symbol}->{stage_entry_date} = $min->dmy('/');
            $data->{$stage}->{genes}->{$gene_symbol}->{gene_id} = $gene;
        }
    }

    my $crispr_data = $self->crispr_stage_data;

    foreach my $crispr_stage (keys %$CRISPR_STAGES){
        $data->{$crispr_stage}->{display_name} = $CRISPR_STAGES->{$crispr_stage}->{name};
        my @genes = keys %{ $crispr_data->{$crispr_stage} || {} };
        foreach my $gene (@genes){
            my $date = $crispr_data->{$crispr_stage}->{$gene};
            $data->{$crispr_stage}->{genes}->{$gene}->{stage_entry_date} = $date;
        }
    }

    return $data;
};

return 1;

