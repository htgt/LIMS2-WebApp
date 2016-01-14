package LIMS2::Model::Util::ReportForSponsors::SubReport;

use Moose;

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

# Base methods
# These methods are always passed the item name (gene_id in this case)
sub get_gene{
   my ($self,$gene_id) = @_;
   return "TEST";
}

sub get_crispr_summaries{
   my ($self,$gene_id) = @_;
   return "TEST";
}

sub get_summaries_to_report{
   my ($self,$gene_id) = @_;
   return "TEST";
}

# Category specific methods which operate on the results of
# one of the base methods

# These methods are always passed the result of the base method
# followed by an optitonal list of args from the report config

# The output of this method will be passed to the report tt for display
sub gene_symbol{
    my ($self,$gene) = @_;
    return "test_symbol";
}

sub chr_name{
	my ($self,$gene) = @_;
	return "test chr";
}

sub sponsors{
    my ($self,$gene) = @_;
    return "test sponsors";
}

sub priority{
    my ($self,$gene) = @_;
    return "test priority";
}

sub count_crispr_wells{
    return "TEST";
}

sub count_accepted_crispr_v{
    return "TEST";
}

sub count_designs{
    return "TEST";
}

sub count_final_pick_accepted{
    return "TEST";
}

sub count_ep_wells{
    return "TEST";
}

sub colony_counts_by_gene_and_ep{
    return "TEST";
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

