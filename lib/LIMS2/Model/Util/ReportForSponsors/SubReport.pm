package LIMS2::Model::Util::ReportForSponsors::SubReport;

use Moose;
use Try::Tiny;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use LIMS2::Model::Util::CrisprESQCView qw(crispr_damage_type_for_ep_pick ep_pick_is_het);

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

# het calling needs chromosome which is not in the summary information
# so we will store it when processing the gene information
has gene_id_to_chromosome => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# Store the list of ep picks for a well id
# with their damage type calls
# as this is used in the calculation of several categories
has ep_to_ep_pick_info => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 0,
    default     => sub{ {} },
);

sub _fetch_ep_pick_info{
    my ($self, $summaries, $ep) = @_;

    my $info;
    my $ep_well_id = $ep->ep_well_id || $ep->crispr_ep_well_id;
    if(exists $self->ep_to_ep_pick_info->{$ep_well_id}){
        $self->log->debug("Using existing ep_pick_info");
        $info = $self->ep_to_ep_pick_info->{$ep_well_id};
    }
    else{
        $info = $self->_generate_ep_pick_info($summaries,$ep);
        $self->ep_to_ep_pick_info->{$ep_well_id} = $info;
    }
    return $info;
}

sub _generate_ep_pick_info{
    my ($self, $summaries, $ep) = @_;

    $self->log->debug("Generating ep_pick_info");
    # Find the summary rows for this ep that also have ep_pick
    my $ep_well_id = $ep->ep_well_id || $ep->crispr_ep_well_id;
    my @all_ep_pick = grep { $_->ep_pick_well_id } @$summaries;
    my @pick_for_this_ep = ();

    if($ep->ep_well_id){
        @pick_for_this_ep = grep { $_->ep_well_id == $ep_well_id } @all_ep_pick;
    }
    elsif($ep->crispr_ep_well_id){
        @pick_for_this_ep = grep { $_->crispr_ep_well_id == $ep_well_id } @all_ep_pick;
    }
    my @pick_well_ids = uniq map { $_->ep_pick_well_id } @pick_for_this_ep;

    # Fetch and store damage type/het info for each ep_pick
    my $ep_pick_info = {
        ep_pick_ids => \@pick_well_ids,
    };

    foreach my $ep_pick_id (@pick_well_ids) {
        my $damage_call = crispr_damage_type_for_ep_pick($self->model,$ep_pick_id);

        if ($damage_call) {
            $ep_pick_info->{$damage_call}++;
        }
        else {
            $damage_call = '';
        }

        # Get the chromosome name that we stored earlier when processing gene info
        my $chromosome = $self->gene_id_to_chromosome->{ $pick_for_this_ep[0]->design_gene_id };

        my $is_het = ep_pick_is_het($self->model, $ep_pick_id, $chromosome, $damage_call);

        if ( defined $is_het) {
            $ep_pick_info->{het} += $is_het;
        }

    }
    return $ep_pick_info;
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

    my @projects = $self->model->schema->resultset('Project')->search({
        gene_id => $gene_id,
        targeting_type => $self->targeting_type,
        species_id => $self->species,
    });

    my @priority = uniq grep { $_ } map { $_->priority } @projects;
    $gene_info->{priority} = join ";", @priority;

    $self->log->debug("Gene info: ".Dumper($gene_info));

    # We need to store the chromosome so it can be passed to the ep_pick_is_het method
    # This assumes the gene_info will be generated before the is het score
    # FIXME: this is not ideal!
    if(defined $gene_info->{chromosome}){
        $self->gene_id_to_chromosome->{$gene_id} = $gene_info->{chromosome};
    }
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
        design_gene_id
        final_pick_well_id
        final_pick_well_accepted
        ep_well_id
        crispr_ep_well_id
        experiments
        crispr_ep_well_cell_line
        ep_pick_plate_name
        ep_pick_well_name
        ep_pick_well_accepted
        ep_pick_well_id
        piq_well_id
        piq_well_accepted
        ancestor_piq_well_id
        ancestor_piq_well_accepted
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
    return $gene->{priority};
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

sub count_design_pcr_passes{
    my ($self,$summaries) = @_;

    my @design_well_ids = uniq map { $_->design_well_id } @$summaries;
    my $pcr_passes;

    foreach my $well_id (@design_well_ids) {

        my ($l_pcr, $r_pcr) = ('', '');
        try{

            $l_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
                well_id     => $well_id,
                result_type_id => 'pcr_u',
            },{
                select => [ 'result' ],
            })->result;

            $r_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
                well_id     => $well_id,
                result_type_id => 'pcr_d',
            },{
                select => [ 'result' ],
            })->result;
        };

        if ($l_pcr eq 'pass' && $r_pcr eq 'pass') {
            $pcr_passes++;
        }
    }
    return $pcr_passes;
}

sub count_final_pick_accepted{
    my ($self,$summaries) = @_;

    my @all_accetped = grep { $_->final_pick_well_accepted } @$summaries;
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
        my $ep_id = $curr_ep->ep_well_id || $curr_ep->crispr_ep_well_id;

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
    my ($self, $summaries) = @_;

    my $counts = {
        total      => 0,
        by_ep_well => {},
    };

    my $eps = $self->_ep_well_search($summaries);

    foreach my $ep (@$eps){
        my $ep_well_id = $ep->ep_well_id || $ep->crispr_ep_well_id;
        my $ep_pick_info = $self->_fetch_ep_pick_info($summaries,$ep);

        $counts->{total} += scalar @{ $ep_pick_info->{ep_pick_ids} };
        $counts->{by_ep_well}->{$ep_well_id} = scalar @{ $ep_pick_info->{ep_pick_ids} };
    }
    return $counts->{total}
}

sub genotyped_clone_counts_by_gene_and_ep{
    my ($self, $summaries) = @_;

    my $counts = {
        total      => 0,
        by_ep_well => {},
    };

    my $eps = $self->_ep_well_search($summaries);

    foreach my $ep (@$eps){
        my $ep_well_id = $ep->ep_well_id || $ep->crispr_ep_well_id;
        my $ep_pick_info = $self->_fetch_ep_pick_info($summaries,$ep);
        my $genotyped_count = $ep_pick_info->{'wild_type'}
                            + $ep_pick_info->{'in-frame'}
                            + $ep_pick_info->{'frameshift'}
                            + $ep_pick_info->{'mosaic'};

        $counts->{total} += $genotyped_count;
        $counts->{by_ep_well}->{$ep_well_id} = $genotyped_count;
    }
    return $counts->{total};
}

sub clone_counts_by_gene_and_ep{
    my ($self, $summaries, $damage_call) = @_;

    my $counts = {
        total      => 0,
        by_ep_well => {},
    };

    my $eps = $self->_ep_well_search($summaries);

    foreach my $ep (@$eps){
        my $ep_well_id = $ep->ep_well_id || $ep->crispr_ep_well_id;
        my $ep_pick_info = $self->_fetch_ep_pick_info($summaries,$ep);
        $counts->{total} += $ep_pick_info->{$damage_call};
        $counts->{by_ep_well}->{$ep_well_id} = $ep_pick_info->{$damage_call};
    }
    return $counts->{total};
}

sub het_clone_counts_by_gene_and_ep{
    my ($self, $summaries) = @_;
    return $self->clone_counts_by_gene_and_ep($summaries,'het');
}

sub count_piq_accepted{
    my ($self, $summaries) = @_;

    my @piq = map { $_->piq_well_id }
              grep { $_->piq_well_accepted  } @$summaries;

    push @piq, map { $_->ancestor_piq_well_id }
               grep { $_->ancestor_piq_well_accepted } @$summaries;

    my @unique = uniq @piq;
    return scalar @unique;
}

1;

