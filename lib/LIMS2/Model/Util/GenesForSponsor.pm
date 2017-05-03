package LIMS2::Model::Util::GenesForSponsor;

use Moose;

has model => (
    is         =>   'ro',
    isa        =>   'LIMS2::Model',
    required   =>   1
);

has 'targeting_type' => (
    is     =>   'ro',
    isa    =>   'Str'
);

has 'species_id' => (
    is     =>   'ro',
    isa    =>   'Str'
);

has genes_and_sponsors => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_genes_and_sponsors {
    my $self = shift;

    my $genes_and_sponsors;
    my $species_id = $self->species_id;
    my $targeting_type = $self->targeting_type;

    my $sql_query =  <<"SQL_END";
SELECT p.gene_id, ps.sponsor_id FROM projects p, project_sponsors ps
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

    return $genes_and_sponsors;
}

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

    ## 'All' exception: 'All' genes should not include DDD-only genes
    if ($sponsor_id eq 'All') {
        my @ddd_only_genes = $self->get_ddd_genes_only();
        foreach my $temp_gene (@intermediate_sponsor_genes) {
            push @sponsor_genes, $temp_gene unless (grep {$_ eq $temp_gene} @ddd_only_genes);
        }
        return {sponsor_id => $sponsor_id, genes => scalar @sponsor_genes};
    }
    return {sponsor_id => $sponsor_id, genes => scalar @intermediate_sponsor_genes};
}

sub get_ddd_genes_only {
    my $self = shift;

    my @ddd_genes;
    foreach my $gene_id (keys %{$self->genes_and_sponsors}) {
        my @gene_sponsors = @{$self->genes_and_sponsors->{$gene_id}};

        ## get DDD-only genes
        if (scalar @gene_sponsors == 1 && $gene_sponsors[0] eq 'Decipher') {
            push @ddd_genes, $gene_id;
        }
        elsif ((scalar @gene_sponsors == 2) && (grep {$_ eq 'Decipher'} @gene_sponsors) &&  (grep {$_ eq 'All'} @gene_sponsors)) {
            push @ddd_genes, $gene_id;
        }
    }
    return @ddd_genes;
}

1;
