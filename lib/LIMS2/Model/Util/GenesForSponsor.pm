package LIMS2::Model::Util::GenesForSponsor;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::GenesForSponsor::VERSION = '0.517';
}
## use critic


use Moose;
use Try::Tiny;
use List::MoreUtils qw(uniq);


=head1 NAME

LIMS2::Model::Util::GenesForSponsor

=head1 DESCRIPTION

Helper module used to retrieve genes for pipeline I and II startegies.

=cut

has model => (
    is         =>   'ro',
    isa        =>   'LIMS2::Model',
    required   =>   1
);

has targeting_type => (
    is     =>   'ro',
    isa    =>   'Str'
);

has species_id => (
    is     =>   'ro',
    isa    =>   'Str'
);

has genes_and_sponsors => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

has pipeline_ii_sponsors => (
    is         => 'ro',
    isa         => 'ArrayRef[Str]',
    lazy_build => 1,
);


=head2 _build_genes_and_sponsors

Returns every genes and its sponsor list.

=cut
sub _build_genes_and_sponsors {
    my $self = shift;

    my $genes_and_sponsors;
    my $species_id = $self->species_id;
    my $targeting_type = $self->targeting_type;

    my $sql_query =  <<"SQL_END";
SELECT p.gene_id, ps.sponsor_id, p.strategy_id FROM projects p, project_sponsors ps
WHERE ps.project_id = p.id
AND p.species_id = '$species_id'
AND p.targeting_type = '$targeting_type'
SQL_END

   my $sql_result = $self->model->schema->storage->dbh_do(
      sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare( $sql_query );
         $sth->execute or die "Unable to execute query: $dbh->errstr\n";
         $sth->fetchall_arrayref({

         });
      });

    ## create a map of gene id/sponsor list
    foreach my $record ( @$sql_result ) {
        push @{$genes_and_sponsors->{$record->{gene_id}}}, $record->{sponsor_id};
    }

    foreach my $gene ( keys %{$genes_and_sponsors} ) {
        @{$genes_and_sponsors->{$gene}} = uniq @{$genes_and_sponsors->{$gene}}
    }

    return $genes_and_sponsors;
}


=head2 _build_pipeline_ii_sponsors

Return pipeline II sponsor list.

=cut
sub _build_pipeline_ii_sponsors {
    my $self = shift;

    my $pipeline_ii_sponsors;
    my @temp_arr;
    my $sql = <<"SQL_END";
select ps.sponsor_id from projects p, project_sponsors ps where ps.project_id = p.id and p.strategy_id = 'Pipeline II'
SQL_END

   my $sql_out = $self->model->schema->storage->dbh_do(
      sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare( $sql );
         $sth->execute or die "Unable to execute query: $dbh->errstr\n";
         $sth->fetchall_arrayref({

         });
      });

    foreach my $record ( @$sql_out ) {
        if ($record->{sponsor_id} ne 'All') {
            push @temp_arr, $record->{sponsor_id};
        }
    }
    @temp_arr = uniq @temp_arr;
    $pipeline_ii_sponsors = \@temp_arr;

    return $pipeline_ii_sponsors;

}


=head2 get_sponsor_genes

Get the genes of a specific sponsor Id. If the sponsor Id is 'All', genes that appear only in pipeline II are not included.

=cut
sub get_sponsor_genes {
    my ($self, $sponsor_id) = @_;

    my @sponsor_genes;
    my @intermediate_sponsor_genes;

    ## get genes that have this sponsor id included in their list of sponsors
    foreach my $gene_id (keys %{$self->genes_and_sponsors}) {
        my @temp_sponsors = @{$self->genes_and_sponsors->{$gene_id}};

        if (grep {$_ eq $sponsor_id} @temp_sponsors) {
            push @intermediate_sponsor_genes, $gene_id;
        }
    }

    ## 'All' exception: 'All' genes should not include pipelineII-only genes
    if ($sponsor_id eq 'All') {
        my @pipeline_ii_only_genes = $self->get_pipeline_ii_genes_only();

        foreach my $temp_gene (@intermediate_sponsor_genes) {
            push @sponsor_genes, $temp_gene unless (grep {$_ eq $temp_gene} @pipeline_ii_only_genes);
        }
        return {sponsor_id => $sponsor_id, genes => \@sponsor_genes};
    }

    ## Use "Crispr Plasmids Constructed" to filter out true Pipeline II genes
    if (grep {$_ eq $sponsor_id} @{$self->pipeline_ii_sponsors}) {
        my @genes_and_cpc;
        foreach my $sponsor_gene_id (@intermediate_sponsor_genes) {
            my $crispr_plasmid_constructed = $self->crispr_plasmid_constructed_for_gene($sponsor_gene_id, $sponsor_id);
            if ($crispr_plasmid_constructed) {
                next;
            } else {
                push @genes_and_cpc, $sponsor_gene_id;
            }
        }
        return {sponsor_id => $sponsor_id, genes => \@genes_and_cpc};
    }

    return {sponsor_id => $sponsor_id, genes => \@intermediate_sponsor_genes};
}


=head2 get_pipeline_ii_genes_only

Will return pipeline II genes only.
Case: after removing 'All', if only a pipeline II gene is left.

=cut
sub get_pipeline_ii_genes_only {
    my $self = shift;

    my @pipeline_ii_genes;
    foreach my $gene_id (keys %{$self->genes_and_sponsors}) {

        my @gene_sponsors = uniq @{$self->genes_and_sponsors->{$gene_id}};
        try {
            my $index = 0;
            $index++ until ( $index >= scalar @gene_sponsors || $gene_sponsors[$index] eq 'All' );
            splice(@gene_sponsors, $index, 1);
        };

        ## get pipelineII-only genes
        if (scalar @gene_sponsors == 1 && grep {$_ eq $gene_sponsors[0]} @{$self->pipeline_ii_sponsors}) {
            push @pipeline_ii_genes, $gene_id;
        }
    }
    return @pipeline_ii_genes;
}


=head2 crispr_plasmid_constructed_for_gene

Will return the total number of crispr plasmids constructed.
Excerpt from ReposrtsForSponsors.pm

=cut
sub crispr_plasmid_constructed_for_gene {
    my ($self, $gene_id, $sponsor_id) = @_;

    my %search = ( design_gene_id => $gene_id );

    if ($self->species_id eq 'Human' || $sponsor_id eq 'Pathogen Group 2' || $sponsor_id eq 'Pathogen Group 3' ) {
        $search{'-or'} = [
                { design_type => 'gibson' },
                { design_type => 'gibson-deletion' },
                { design_type => 'fusion-deletion' },
            ];
    }

    if ($sponsor_id eq 'Pathogen Group 1' || $sponsor_id eq 'EUCOMMTools Recovery' || $sponsor_id eq 'Barry Short Arm Recovery') {
        $search{'sponsor_id'} = $sponsor_id;
    }

    my $summary_rs = $self->model->schema->resultset("Summary")->search(
        { %search },
    );

    my @design_ids = map { $_->design_id } $summary_rs->all;
    @design_ids = uniq @design_ids;

    my $designs_for_gene = {};
    my @all_design_ids;

    foreach my $design_id (uniq @design_ids){
        $designs_for_gene->{$gene_id} ||= [];

        my $arrayref = $designs_for_gene->{$gene_id};
        push @$arrayref, $design_id;
        push @all_design_ids, $design_id;
    }

    my $design_crispr_summary = $self->model->get_crispr_summaries_for_designs({ id_list => \@all_design_ids });

    return crispr_well_counts_for_gene($gene_id, $designs_for_gene, $design_crispr_summary);
}

=head2 crispr_well_counts_for_gene

For crispr plasmids constructed count.
Excerpt from ReportsForSponsors.pm

=cut
sub crispr_well_counts_for_gene{
    my ($gene_id, $gene_designs, $crispr_design_summary) = @_;

    my $crispr_vector_accepted_count = 0;

    foreach my $design_id (@{ $gene_designs->{$gene_id} || []}){
        my $plated_crispr_summary = $crispr_design_summary->{$design_id}->{plated_crisprs};

        foreach my $crispr_id (keys %$plated_crispr_summary){
            my @crispr_well_ids = keys %{ $plated_crispr_summary->{$crispr_id} };
            foreach my $crispr_well_id (@crispr_well_ids){

                # CRISPR_V well count
                my $vector_rs = $plated_crispr_summary->{$crispr_id}->{$crispr_well_id}->{CRISPR_V};

                my @accepted = grep { $_->is_accepted } $vector_rs->all;
                $crispr_vector_accepted_count += scalar(@accepted);
            }
        }
    }
    return $crispr_vector_accepted_count;
}

1;
