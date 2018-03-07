package LIMS2::Report::RecoveryOverview;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::RecoveryOverview::VERSION = '0.492';
}
## use critic


use Moose;
use MooseX::ClassAttribute;
use DateTime;
use JSON qw( decode_json );
use List::MoreUtils qw( uniq );
use Readonly;
use namespace::autoclean;
use Log::Log4perl qw(:easy);

extends qw( LIMS2::ReportGenerator );
with qw( LIMS2::ReportGenerator::ColonyCounts );

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

has stages => (
    is             => 'ro',
    isa            => 'HashRef',
    lazy_build     => 1,
);

has crispr_stages  => (
    is             => 'ro',
    isa            => 'HashRef',
    lazy_build     => 1,
);
# each hash key is the name of the stage
#   name: display name of stage
#   field_name: name of column in summaries table that indicates design has reached this stage
#   time_field: name of column in summaries table containing time that the stage was reached
#   order: order that the stages occur in
#   detail_columns: names of columns in summaries table to show in RecoveryDetail report
#   extra_details: names of extra items to show in RecoveryDetail which are not in summaries table
#   extra_detail_function: subroutine to generate an arrayref of values for the extra_details (arguments
#                          passed to sub are self and a Well object with the id from <field_name>)
sub _build_stages {
    my $self = shift;

    return {
    design_well_created => {
        name       => 'Design Well Created',
        field_name => 'design_well_id',
        time_field => 'design_well_created_ts',
        order      => 1,
        detail_columns => [ qw(design_name design_plate_name design_well_name design_well_created_ts) ],
        extra_details => [ qw(recombineering_results) ],
        extra_detail_function => sub { my ($self, $well) = @_; return [ $well->recombineering_results_string ] },
    },
    int_vector_created => {
        name       => 'Intermediate Vector Created',
        field_name => 'int_well_id',
        time_field => 'int_well_created_ts',
        order      => 2,
        detail_columns => [ qw(int_plate_name int_well_name int_well_created_ts int_qc_seq_pass)],
        extra_details => [ "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?" ],
        extra_detail_function => sub { my ($self, $well) = @_; return [ $self->qc_result_cols( $well ) ] },
    },
    final_vector_created => {
        name       => 'Final Vector Created',
        field_name => 'final_well_id',
        time_field => 'final_well_created_ts',
        order      => 3,
        detail_columns => [ qw(final_plate_name final_well_name final_well_created_ts final_qc_seq_pass) ],
        extra_details => [ "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?" ],
        extra_detail_function => sub { my ($self, $well) = @_; return [ $self->qc_result_cols( $well ) ] },
    },
    final_pick_created => {
        name       => 'Final Pick Created',
        field_name => 'final_pick_well_id',
        time_field => 'final_pick_well_created_ts',
        order      => 4,
        detail_columns => [ qw(final_pick_plate_name final_pick_well_name final_pick_well_created_ts final_pick_qc_seq_pass ) ],
        extra_details => [ "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?" ],
        extra_detail_function => sub { my ($self, $well) = @_; return [ $self->qc_result_cols( $well ) ] },
    },
    assembly_created => {
        name       => 'Assembly Created',
        field_name => 'assembly_well_id',
        time_field => 'assembly_well_created_ts',
        order      => 5,
        detail_columns => [ qw(assembly_plate_name assembly_well_name assembly_well_created_ts ) ],
        extra_details => [ "Egel Pass","QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?" ],
        extra_detail_function => sub { my ($self, $well) = @_; return [ $well->egel_pass_string, $self->qc_result_cols( $well ) ] },
    },
    crispr_ep_created => {
        name       => 'Crispr EP Created',
        field_name => 'crispr_ep_well_id',
        time_field => 'crispr_ep_well_created_ts',
        order      => 6,
        detail_columns => [ qw(crispr_ep_plate_name crispr_ep_well_name crispr_ep_well_created_ts crispr_ep_well_accepted)],
        extra_details => [ $self->colony_count_column_names ],
        extra_detail_function => sub { my ($self, $well) = @_; return [ $self->colony_counts($well) ] },
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
};

sub _build_crispr_stages {

    my $self = shift;

    return {
    crispr_well_created => {
        name       => 'Crispr Well Created',
        order      => 1,
        detail_columns => [],
        wells_key      => 'crispr_wells',
        detail_columns => [ qw(plate_name name created_at accepted) ],
    },
    crispr_vector_created => {
        name       => 'Crispr Vector Created',
        order      => 2,
        detail_columns => [],
        wells_key      => 'crispr_vector_wells',
        detail_columns => [ qw(plate_name name created_at accepted) ],
    },
    crispr_dna_created => {
        name       => 'Crispr DNA Created',
        order      => 3,
        detail_columns => [],
        wells_key      => 'crispr_dna_wells',
        detail_columns => [ qw(plate_name name created_at accepted) ],
    }
    };
};

has projects => (
    is             => 'ro',
    isa            => 'ArrayRef',
    lazy_build     => 1,
    traits         => ['Array'],
    handles        => { 'find_projects' => 'grep' },
);

has all_gene_ids => (
    is             => 'ro',
    isa            => 'ArrayRef',
    lazy_build     => 1
);

has genes_with_summaries => (
    is             => 'ro',
    isa            => 'ArrayRef',
    lazy_build     => 1
);

sub _build_projects {
    my $self = shift;

    my @sponsors;
    if ( $self->sponsor eq 'All' && $self->species eq 'Mouse' ) {
        @sponsors = ('Core', 'Syboss', 'Pathogens');
    }
    if ( $self->sponsor eq 'All' && $self->species eq 'Human' ) {
        @sponsors = ('Experimental Cancer Genetics', 'Mutation', 'Pathogen', 'Stem Cell Engineering');
    }
    else {
        @sponsors = ($self->sponsor);
    }

    my $project_rs = $self->model->schema->resultset('Project')->search(
        {
            'project_sponsors.sponsor_id' => { -in => \@sponsors }
        },
        {
            join => ['project_sponsors']
        }
    );

    return [ $project_rs->all ];
}

sub _build_all_gene_ids {
    my $self = shift;

    my @all_gene_ids = uniq map { $_->gene_id } @{ $self->projects };
    return \@all_gene_ids;
}

sub _build_genes_with_summaries {
    my $self = shift;

    # Find all project genes which have reached requested stage
    my @all_project_summaries = $self->model->schema->resultset('Summary')->search({
       design_gene_id => { '-in' => $self->all_gene_ids },
    },
    {
        columns => [ 'design_gene_id' ]
    })->all;
    my @stage_gene_ids = uniq map { $_->design_gene_id } @all_project_summaries;
    return \@stage_gene_ids;
}

sub _build_stage_data {
    my ($self) = @_;

    # stage_data->{stage}->{gene}->\@summary_rows

    DEBUG "Building stage data";
    my $stage_data = {};

    my %gene_symbols;

    # FIXME: probably faster to loop through stages first then check gene
    # has not been seen in more advanced stage before adding to stage list
    GENE: foreach my $gene (@{ $self->genes_with_summaries }){
        my $summary_rs = $self->model->schema->resultset('Summary')->search({
            design_gene_id => $gene,
        });

        # Store gene symbol found in summary table
        $gene_symbols{$gene} = $summary_rs->first->design_gene_symbol;

        foreach my $stage (sort { $self->stages->{$b}->{order} <=> $self->stages->{$a}->{order} }
                      (keys %{ $self->stages }) ){
            my $stage_info = $self->stages->{$stage};
            my @matching_rows = $summary_rs->search( { $stage_info->{field_name} => { '!=', undef } })->all;

            if(@matching_rows){
                $stage_data->{$stage}->{$gene} = \@matching_rows;

                # We are only interested in the latest stage so go to next gene
                next GENE;
            }
        }
    }

    # Store all gene ids for sponsor to use when fetching crispr data
    $stage_data->{gene_symbols} =  \%gene_symbols ;

    return $stage_data;
}

sub _build_crispr_stage_data {
    my ($self) = @_;

    my $crispr_stage_data = {};

    my $crispr_summaries = $self->model->get_crispr_summaries_for_genes({
        id_list => $self->all_gene_ids,
        species => $self->species
    });

    GENE: foreach my $gene (keys %$crispr_summaries){

        DEBUG("finding crispr stages for gene $gene");
        my @crispr_well_ids;
        my ($first_crispr_well_date, $first_dna_date, $first_vector_date);
        my (@crispr_v_wells, @dna_wells);

        my $gene_crisprs = $crispr_summaries->{$gene} || {};
        foreach my $design (keys %$gene_crisprs){
            DEBUG("finding crispr stages for design $design");
            my $design_crisprs = $gene_crisprs->{$design}->{plated_crisprs};
            foreach my $crispr (keys %$design_crisprs){
                DEBUG("checking crispr $crispr");
                foreach my $crispr_well (keys %{ $design_crisprs->{$crispr} } ){
                    DEBUG("checking crispr well $crispr_well");
                    push @crispr_well_ids, $crispr_well;

                    my $date = $design_crisprs->{$crispr}->{$crispr_well}->{crispr_well_created};
                    $first_crispr_well_date = _update_earliest_date($first_crispr_well_date,$date);

                    my $dna_rs = $design_crisprs->{$crispr}->{$crispr_well}->{DNA};
                    my $vector_rs = $design_crisprs->{$crispr}->{$crispr_well}->{CRISPR_V};
                    my $assembly_rs = $design_crisprs->{$crispr}->{$crispr_well}->{ASSEMBLY};

                    if($assembly_rs != 0){
                        # Assembly created so gene is already past crispr stages
                        next GENE;
                    }
                    elsif($dna_rs != 0){
                        my $first = $dna_rs->search({},{ order_by => {'-asc' => 'me.created_at '} })->first;
                        my $dna_date = $first->created_at;
                        $first_dna_date = _update_earliest_date($first_dna_date, $dna_date);
                        push @dna_wells, $dna_rs->all;
                    }
                    elsif($vector_rs != 0){
                        my $first = $vector_rs->search({},{ order_by => {'-asc' => 'me.created_at '} })->first;
                        my $vector_date = $first->created_at;
                        $first_vector_date = _update_earliest_date($first_vector_date,$vector_date);
                        push @crispr_v_wells, $vector_rs->all;
                    }
                }
            }
        }

        if(@dna_wells){
            $crispr_stage_data->{crispr_dna_created}->{$gene} = $first_dna_date->dmy('/');
            $crispr_stage_data->{crispr_dna_wells}->{$gene} = \@dna_wells;
        }
        elsif(@crispr_v_wells){
            $crispr_stage_data->{crispr_vector_created}->{$gene} = $first_vector_date->dmy('/');
            $crispr_stage_data->{crispr_vector_wells}->{$gene} = \@crispr_v_wells;
        }
        elsif(@crispr_well_ids){
            # We found crispr wells but no DNA or vector result sets
            $crispr_stage_data->{crispr_well_created}->{$gene} = $first_crispr_well_date->dmy('/');
            my @crispr_wells = $self->model->schema->resultset('Well')->search({
                id => { '-in', \@crispr_well_ids }
            });
            $crispr_stage_data->{crispr_wells}->{$gene} = \@crispr_wells;
        }
    }

    return $crispr_stage_data;
}

sub _update_earliest_date{
    my ($earliest_date, $this_date) = @_;

    $earliest_date ||= $this_date;
    if($this_date < $earliest_date){
        $earliest_date = $this_date;
    }

    return $earliest_date;
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

    foreach my $stage (sort { $self->crispr_stages->{$a}->{order} <=> $self->crispr_stages->{$b}->{order} }
                      (keys %{ $self->crispr_stages }) ){
        my @genes = keys %{ $self->crispr_stage_data->{$stage} || {} };
        my $count = scalar @genes;
        my $genes = "";
        if($count){
            $genes = join ", ",  @genes ;
        }
        push @counts, [ $stage, $count, $genes ];
    }

    foreach my $stage (sort { $self->stages->{$a}->{order} <=> $self->stages->{$b}->{order} }
                      (keys %{ $self->stages }) ){
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

    foreach my $stage (keys %{ $self->stages }) {
        $data->{$stage}->{display_name} = $self->stages->{$stage}->{name};
        my @genes = keys %{ $stage_data->{$stage} || {} };
        foreach my $gene (@genes){
            my $summaries = $stage_data->{$stage}->{$gene};
            my $time_field = $self->stages->{$stage}->{time_field};
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

    foreach my $crispr_stage (keys %{ $self->crispr_stages }){
        $data->{$crispr_stage}->{display_name} = $self->crispr_stages->{$crispr_stage}->{name};
        my @genes = keys %{ $crispr_data->{$crispr_stage} || {} };
        foreach my $gene (@genes){
            my $gene_symbol = $self->stage_data->{gene_symbols}->{$gene} || $gene;
            my $date = $crispr_data->{$crispr_stage}->{$gene};
            $data->{$crispr_stage}->{genes}->{$gene_symbol}->{stage_entry_date} = $date;
            $data->{$crispr_stage}->{genes}->{$gene_symbol}->{gene_id} = $gene;
        }
    }

    return $data;
};

1;

