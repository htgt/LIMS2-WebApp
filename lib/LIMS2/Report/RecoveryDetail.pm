package LIMS2::Report::RecoveryDetail;

use Moose;
use MooseX::ClassAttribute;
use DateTime;
use JSON qw( decode_json );
use List::MoreUtils qw/ uniq /;
use Readonly;
use namespace::autoclean;
use Log::Log4perl qw(:easy);

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

has crispr_summary => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

has '+param_names' => (
    default => sub { [ 'species', 'sponsor', 'stage', 'gene_id' ] }
);

sub _build_crispr_summary {

};


sub _build_gene_data {
	my $self = shift;

    DEBUG "Building gene data";
    my $gene_data = {};

    my $search = { sponsor_id => $self->sponsor };
    if($self->has_gene_id){
        $search->{gene_id} = $self->gene_id;
    }
    my $project_rs = $self->model->schema->resultset('Project')->search($search);

    my $summary_stage = $self->stages->{$self->stage};
    my $next_stage_order = $summary_stage->{order} + 1;
    DEBUG "Next stage order: $next_stage_order";
    my ($next_stage_name) = grep { $self->stages->{$_}->{order} == $next_stage_order } keys %{ $self->stages };
    DEBUG "Next stage: $next_stage_name";
    my $next_stage = $self->stages->{$next_stage_name};

    # Find all project genes which have reached requested stage
    my @all_gene_ids = map { $_->gene_id } $project_rs->all;
    my @all_project_summaries = $self->model->schema->resultset('Summary')->search({
       design_gene_id => { '-in' => \@all_gene_ids },
       $summary_stage->{field_name} => { '!=', undef }
    },
    {
        columns => [ 'design_gene_id' ]
    })->all;
    my @stage_gene_ids = uniq map { $_->design_gene_id } @all_project_summaries;

    # For each gene fetch full summary and check if it has progressed to next stage or not
    GENE: foreach my $gene (@stage_gene_ids){
        if($summary_stage){
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

            if($summary_stage->{order} < $self->stages->{assembly_created}->{order}){
            	# If this is a pre-assembly stage we need to report gene's crispr status too
            }
        }
        else{
        	# Must be a crispr stage so we handle it differently

        	# Need to report the gene's summary status too
        }
    }

    return $gene_data;
}

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append .= $self->has_gene_id ? ' - Gene ' . $self->gene_id . ' ' : '';
    $append .= $dt->ymd;

    return 'Recovery Detail ' . $self->sponsor . ' ' . $self->stage . ' ' . $append;
};

override _build_columns => sub {
    my $self = shift;

    return ['Gene', @{ $self->stages->{$self->stage}->{detail_columns} }];
};

override iterator => sub {
    my ($self) = @_;

    DEBUG "getting iterator";
    my $data = $self->gene_data;
    my $stage_info = $self->stages->{$self->stage};

    my @results;

    foreach my $gene_id (keys %{$data || {}}){
    	my $summary_data = $data->{$gene_id}->{summary_data};
    	my $gene_symbol = $summary_data->[0]->design_gene_symbol;
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
    my $data = {};

    DEBUG "Getting structured data";

    return $data;
};