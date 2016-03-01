## no critic (ProhibitExcessMainComplexity)
package LIMS2::Report::RecoveryDetail;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::RecoveryDetail::VERSION = '0.379';
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
use Try::Tiny;
use Data::Dumper;

extends qw( LIMS2::Report::RecoveryOverview );

has '+custom_template' => (
    default => 'user/report/recovery_detail.tt',
);

has stage => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has gene_id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_gene_id',
    required  => 0,
);

has gene_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

has '+param_names' => (
    default => sub { [ 'species', 'sponsor', 'stage', 'gene_id' ] }
);

override _build_all_gene_ids => sub {
    my $self = shift;

    my $search = { 'project_sponsors.sponsor_id' => $self->sponsor };
    if($self->has_gene_id){
        $search->{gene_id} = $self->gene_id;
    }
    my $project_rs = $self->model->schema->resultset('Project')->search(
        $search,
        {
            join => 'project_sponsors',
        }
    );

    my @all_gene_ids = uniq map { $_->gene_id } $project_rs->all;
    return \@all_gene_ids;
};

override _build_genes_with_summaries => sub {
    my $self = shift;

    my $summary_stage = $self->stages->{$self->stage};
    return [] unless $summary_stage;

    # Find all project genes which have reached requested stage
    my @all_project_summaries = $self->model->schema->resultset('Summary')->search({
       design_gene_id => { '-in' => $self->all_gene_ids },
       $summary_stage->{field_name} => { '!=', undef }
    },
    {
        columns => [ 'design_gene_id' ]
    })->all;
    my @stage_gene_ids = uniq map { $_->design_gene_id } @all_project_summaries;
    return \@stage_gene_ids;
};

sub _build_gene_data {
	my $self = shift;

    DEBUG "Building gene data";
    my $gene_data = {};

    my $summary_stage = $self->stages->{$self->stage};
    if($summary_stage){
        my $next_stage_order = $summary_stage->{order} + 1;
        DEBUG "Next stage order: $next_stage_order";
        my ($next_stage_name) = grep { $self->stages->{$_}->{order} == $next_stage_order } keys %{ $self->stages };
        DEBUG "Next stage: $next_stage_name";
        my $next_stage = $self->stages->{$next_stage_name};

        # For each gene fetch full summary and check if it has progressed to next stage or not
        GENE: foreach my $gene (@{ $self->genes_with_summaries }){

    	    my $summary_rs = $self->model->schema->resultset('Summary')->search({
                design_gene_id => $gene,
                $summary_stage->{field_name} => { '!=', undef }
            });

            if($next_stage){
                my $next_stage_rs = $self->model->schema->resultset('Summary')->search({
                    design_gene_id => $gene,
                    $next_stage->{field_name} => { '!=', undef }
                });
                # Skip if gene has already reached the next stage
                next if $next_stage_rs != 0;
            }

            DEBUG "Found summary data for $gene at stage ".$self->stage;
            $gene_data->{$gene}->{summary_data} = [ $summary_rs->all ];
            $gene_data->{$gene}->{projects} =  [ $self->find_projects( sub{ $_->gene_id eq $gene } ) ];

            if($summary_stage->{order} < $self->stages->{assembly_created}->{order}){
            	# If this is a pre-assembly stage we need to report gene's crispr status too
            }
        }
    }
    else{
        # Must be a crispr stage so we handle it differently
        foreach my $gene(@{ $self->all_gene_ids }){
            my $summaries = $self->_get_crispr_summary_data_for_gene($gene);
            if(@$summaries){
                $gene_data->{$gene}->{summary_data} = $summaries;
                $gene_data->{$gene}->{projects} =  [ $self->find_projects( sub{ $_->gene_id eq $gene } ) ];
            }
        }

        # Need to report the gene's summary status too
    }

    return $gene_data;
}

sub _get_crispr_summary_data_for_gene{
    my ($self, $gene_id) = @_;

    # _build_crispr_stage_data in RecoveryOverview.pm stores well objects
    # in hash under the stage specific wells_key
    my $wells_key = $self->crispr_stages->{ $self->stage }->{wells_key};
    DEBUG "wells key: $wells_key";

    my $wells = $self->crispr_stage_data->{$wells_key}->{$gene_id};

    return $wells || [];
}

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append = $self->has_gene_id ? ' - Gene ' . $self->gene_id . ' ' : '';
    $append .= $dt->ymd;

    return 'Recovery Detail ' . $self->sponsor . ' ' . $self->stage . ' ' . $append;
};

override _build_columns => sub {
    my $self = shift;

    my $cols;
    my $extra_cols;

    if($self->stages->{$self->stage}){
        $cols = $self->stages->{$self->stage}->{detail_columns};
        $extra_cols = $self->stages->{$self->stage}->{extra_details};
    }
    else{
        $cols = $self->crispr_stages->{$self->stage}->{detail_columns};
        $extra_cols = $self->crispr_stages->{$self->stage}->{extra_details};
    }

    $extra_cols ||= [];
DEBUG("extra columns: ",Dumper($extra_cols));
    return ['Gene', @$cols, @$extra_cols];
};

override iterator => sub {
    my ($self) = @_;

    DEBUG "getting iterator";
    my $data = $self->gene_data;
    my $stage_info = $self->stages->{$self->stage} ? $self->stages->{$self->stage}
                                                   : $self->crispr_stages->{$self->stage};

    my @results;

    foreach my $gene_id (keys %{$data || {}}){
    	my $summary_data = $data->{$gene_id}->{summary_data};
    	my $gene_symbol;
        if($self->stages->{$self->stage}){
            # FIXME: this does not work for crispr summary data which is really a well
            $gene_symbol = $summary_data->[0]->design_gene_symbol;
        }
        else{
            $gene_symbol = $gene_id;
        }

    	foreach my $summary (@$summary_data){
    		my @details = ($gene_symbol);
    		push @details, (map { $summary->$_ } @{ $stage_info->{detail_columns} });
    		push @results, \@details;
    	}
    }

    return Iterator::Simple::iter(\@results);
};

override structured_data => sub {
    my ($self) = @_;
    my $extra_data = {};

    DEBUG "Getting structured data";

    my $data = $self->gene_data;
    my $stage_info = $self->stages->{$self->stage} ? $self->stages->{$self->stage}
                                                   : $self->crispr_stages->{$self->stage};
    my $field_name = $stage_info->{field_name};

    my @columns = @{ $stage_info->{detail_columns} || [] };
    push @columns, @{ $stage_info->{extra_details} || [] };

    $extra_data->{detail_columns} = \@columns;
    my @recovery_classes = map { {id => $_->id, name => $_->name} } $self->model->schema->resultset('ProjectRecoveryClass')->all;
    $extra_data->{recovery_classes} = \@recovery_classes;

    # Need to pass report params to custom report so they can be used in redirect
    $extra_data->{stage} = $self->stage;
    $extra_data->{sponsor} = $self->sponsor;
    $extra_data->{gene_id} = $self->gene_id;

    my @genes;
    foreach my $gene_id (keys %{$data || {}}){
        my @summaries;
    	my $summary_data = $data->{$gene_id}->{summary_data};
    	my $gene_symbol;
        if($self->stages->{$self->stage}){
            # FIXME: this does not work for crispr summary data which is really a well
            $gene_symbol = $summary_data->[0]->design_gene_symbol;
        }
        else{
            $gene_symbol = $gene_id;
        }

        my $gene_info = {};
        my $summary_count = 0;
    	foreach my $summary (@$summary_data){
            my @details;
            $summary_count++;
            foreach my $column (@{ $stage_info->{detail_columns} }){
                my $value = $summary->$column;
                if (ref($value) eq 'DateTime'){
                    $value = $value->dmy('/');
                }
                push @details, $value;
            }
            if( $stage_info->{extra_details} ){
                my $well_id = $summary->$field_name;
                my $well = $self->model->retrieve_well({ id => $well_id });
                my $values = $stage_info->{extra_detail_function}->($self,$well);
                push @details, @$values;
            }
            push @summaries, \@details;
    	}

        $gene_info->{gene_id} = $gene_id;
        $gene_info->{gene_symbol} = $gene_symbol;
        $gene_info->{summary_count} = $summary_count;
        $gene_info->{summaries} = \@summaries;

        my @projects;
        foreach my $project ( @{ $data->{$gene_id}->{projects} } ){
            push @projects, {
                id             => $project->id,
                recovery_class => $project->recovery_class_name,
                recovery_class_id => $project->recovery_class_id,
                concluded      => $project->effort_concluded,
                comment        => $project->recovery_comment,
                priority       => $project->priority,
            };
        }
        $gene_info->{projects} = \@projects;

        push @genes, $gene_info;
    }

    $extra_data->{genes} = \@genes;
    return $extra_data;
};

1;

