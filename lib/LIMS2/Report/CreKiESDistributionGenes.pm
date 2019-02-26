package LIMS2::Report::CreKiESDistributionGenes;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CreKiESDistributionGenes::VERSION = '0.528';
}
## use critic


use Moose;
use Iterator::Simple qw( iter );
use LIMS2::Model::Util::CreKiESDistribution;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has '+param_names' => (
    default => sub { [ 'species' ] }
);

override _build_name => sub {
    my $self = shift;

    return 'Cre Knockin ES Distribution Genes';
};

override _build_columns => sub {
    return [
        'Production Centre',
        'Priorities',
        'Basket',
        'MGI Accession ID',
        'Marker Symbol',
        'Accepted Vectors',
        'Accepted Clones passed 1st QC',
        'Failed Clones',
        'Accepted Clones Passed 2nd QC',
        'Accepted Clones Failed 2nd QC',
        'MI Attempts Aborted or Inactive',
        'MI Attempts In Progress',
        'MI Attempts Chimeras Obtained',
        'MI Attempts Genotype Confirmed',
    ];
};

override iterator => sub {
    my $self = shift;

    my $cre_ki_es_genes_generator = LIMS2::Model::Util::CreKiESDistribution->new(
        'model' => $self->model, 'species' => $self->species
    );

    $cre_ki_es_genes_generator->generate_genes_report_data;
    my $report_data = $cre_ki_es_genes_generator->report_data;

    return iter( $report_data );
};

__PACKAGE__->meta->make_immutable;

1;

__END__
