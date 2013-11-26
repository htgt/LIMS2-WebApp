package LIMS2::Report::CreKiESDistributionGenes;

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
        'Basket',
        'MGI Accession ID',
        'Marker Symbol',
        'FEP-accepted Clones at WTSI',
        'PIQ wells at WTSI',
        'PIQ-accepted Clones at WTSI',
        'Imits Plans Summary',
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
