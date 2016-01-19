package LIMS2::Model::Util::ReportForSponsors::SubReport;

use Moose;
use Try::Tiny;
use Data::Dumper;
use List::MoreUtils qw(uniq);

with qw( MooseX::Log::Log4perl );

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

has custom_params => (
    is         => 'ro',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# the full item list calculated for this report
# may be needed for batch queries
has items => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 0,
);

# Some attributes to store batch query results
# so we don't have to repeat them for each item
has all_crispr_summaries => (
    is         => 'ro',
    isa        => 'HashRef',
    required   => 0,
    lazy_build => 1,
);

sub _build_all_crispr_summaries{
    my ($self) = @_;

    return $self->model->get_crispr_summaries_for_genes({
        id_list => $self->items,
        species => $self->species,
    });
}

# Base methods
# These methods are always passed the item name (gene_id in this case)
sub get_gene{
    my ($self,$gene_id) = @_;

    my $gene_info;

    try {
        $gene_info = $self->model->find_gene( {
            search_term => $gene_id,
            species     => $self->species,
        } );
    }
    catch {
        $self->log->error('Failed to fetch gene symbol for gene id : ' . $gene_id . ' and species : ' . $self->species);
    };

    $self->log->debug("Gene info: ".Dumper($gene_info));
    return $gene_info;
}

sub get_crispr_summaries{
    my ($self,$gene_id) = @_;

    my $crispr_summary = $self->all_crispr_summaries->{$gene_id};

    # Get the required counts in the base method so we don't have to repeat the loop
    my $counts = {
        crispr_wells => 0,
        accepted_crispr_v_wells => 0,
    };

    foreach my $design_id (keys %$crispr_summary){
        my $plated_crispr_summary = $crispr_summary->{$design_id}->{plated_crisprs};

        foreach my $crispr_id (keys %$plated_crispr_summary){
            my @crispr_well_ids = keys %{ $plated_crispr_summary->{$crispr_id} };

            $counts->{crispr_wells} += scalar( @crispr_well_ids );

            foreach my $crispr_well_id (@crispr_well_ids){
                my $vector_rs = $plated_crispr_summary->{$crispr_id}->{$crispr_well_id}->{CRISPR_V};

                my @accepted = grep { $_->is_accepted } $vector_rs->all;

                $counts->{accepted_crispr_v_wells} += scalar(@accepted);
            }
        }
    }
    return $counts;
}

sub get_summaries_to_report{
    my ($self,$gene_id) = @_;

    my $sponsor_id = $self->custom_params->{sponsor_id};

    my %search = (
        design_gene_id => $gene_id,
        to_report      => 't',
    );

    if ($self->species eq 'Human' || $sponsor_id eq 'Pathogen Group 2' || $sponsor_id eq 'Pathogen Group 3' ) {
        $search{'-or'} = [
            { design_type => 'gibson' },
            { design_type => 'gibson-deletion' },
        ];
    }

    if ($sponsor_id eq 'Pathogen Group 1' || $sponsor_id eq 'EUCOMMTools Recovery' || $sponsor_id eq 'Barry Short Arm Recovery') {
        $search{'sponsor_id'} = $sponsor_id;
    }

    my @columns = qw(
        design_well_id
        final_pick_well_id
        final_pick_well_accepted
        ep_well_id
        crispr_ep_well_id
        experiments
        crispr_ep_well_cell_line
    );

    my $summary_rs = $self->model->schema->resultset("Summary")->search(
        { %search },
        {
            columns => \@columns,
        }
    );

    return [ $summary_rs->all ];
}

# Category specific methods which operate on the results of
# one of the base methods

# These methods are always passed the result of the base method
# followed by an optitonal list of args from the report config

# The output of this method will be passed to the report tt for display
sub gene_symbol{
    my ($self,$gene) = @_;
    return $gene->{gene_symbol};
}

sub chr_name{
	my ($self,$gene) = @_;
	return $gene->{chromosome};
}

sub sponsors{
    my ($self,$gene) = @_;

    my $search = {
        gene_id        => $gene->{gene_id},
        targeting_type => $self->targeting_type,
    };

    my @gene_projects = $self->model->schema->resultset('Project')->search($search)->all;

    # FIXME: use sponsor abbreviated names. Tiago is adding this info to the DB at the moment
    my @sponsors = uniq map { $_->sponsor_ids } @gene_projects;
    return join ";", @sponsors;
}

sub priority{
    my ($self,$gene) = @_;
    return "test priority";
}

sub count_crispr_wells{
    my ($self,$crispr_counts) = @_;

    return $crispr_counts->{crispr_wells};
}

sub count_accepted_crispr_v{
    my ($self,$crispr_counts) = @_;

    return $crispr_counts->{accepted_crispr_v_wells};
}

sub count_designs{
    my ($self,$summaries) = @_;

    my @design = uniq map { $_->design_well_id } @$summaries;
    return scalar @design;
}

sub count_final_pick_accepted{
    my ($self,$summaries) = @_;

    my @all_accetped = grep { $_->final_pick_well_accepted and $_->final_pick_well_accepted eq 't' } @$summaries;
    my @unique = uniq map { $_->final_pick_well_id } @all_accetped;

    return scalar @unique;
}

sub _ep_well_search{
    my ($self,$summaries) = @_;

    my %eps = map { $_->ep_well_id => $_ } grep { $_->ep_well_id } @$summaries;
    my %crispr_eps = map { $_->crispr_ep_well_id => $_ } grep { $_->crispr_ep_well_id } @$summaries;

    my @all_eps = (values %eps, values %crispr_eps);

    return \@all_eps;
}

sub count_ep_wells{
    my ($self,$summaries) = @_;

    my $ep_wells = $self->_ep_well_search($summaries);
    return scalar @$ep_wells;
}

sub colony_counts_by_gene_and_ep{
    my ($self,$summaries) = @_;
    my $colony_counts = {
        total       => 0,
        by_ep_well  => {},
    };

    my $ep = $self->_ep_well_search($summaries);

    foreach my $curr_ep (@$ep) {
        my %curr_ep_data;
        my $ep_id;
        if ($curr_ep->ep_well_id) {
            $ep_id = $curr_ep->ep_well_id;
        }
        else {
            $ep_id = $curr_ep->crispr_ep_well_id;
        }

        $curr_ep_data{'experiment'} = [ split ",", $curr_ep->experiments ];
        $curr_ep_data{'cell_line'} = $curr_ep->crispr_ep_well_cell_line;

        my $total_colonies = 0;

        try {
            $total_colonies = $self->model->schema->resultset('WellColonyCount')->search({
                well_id => $ep_id,
                colony_count_type_id => 'total_colonies',
            } )->single->colony_count;
        };

        $colony_counts->{total} += $total_colonies;
        $colony_counts->{by_ep_well}->{$ep_id} = $total_colonies;
    }

    return $colony_counts->{total};
}

sub ep_pick_counts_by_gene_and_ep{
    return "TEST";
}

sub genotyped_clone_counts_by_gene_and_ep{
    return "TEST";
}

sub clone_counts_by_gene_and_ep{
    return "TEST";
}

sub het_clone_counts_by_gene_and_ep{
    return "TEST";
}

sub count_piq_accepted{
    return "TEST";
}

1;

