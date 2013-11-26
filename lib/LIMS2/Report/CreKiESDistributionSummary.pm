package LIMS2::Report::CreKiESDistributionSummary;

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

    return 'Cre Knockin ES Distribution Summary';
};

override _build_columns => sub {
    return [
        'Genes Total',
        'Genes Unrequested',
        'Genes Unpicked',
        'Unpicked (no PIQs)',
        'Unpicked (no clones)',
        'Genes Picked (accepted clones)',
        'Picked (1 clone)',
        'Picked (2 clones)',
        'Picked (3 clones)',
        'Picked (4 clones)',
        'Picked (5 clones)',
        'Picked (5+ clones)',
        'Genes Passed PIQ QC (no MI attempts)',
        'Genes Failed PIQ QC',
        'Genes with Active MI attempts',
        'Genes Failed in Mouse Production',
    ];
};

override iterator => sub {
    my $self = shift;

    my $cre_ki_es_summary_generator = LIMS2::Model::Util::CreKiESDistribution->new(
        'model' => $self->model, 'species' => $self->species
    );

    $cre_ki_es_summary_generator->generate_summary_report_data;
    my $report_data = $cre_ki_es_summary_generator->report_data;

    return iter( $report_data );
};

__PACKAGE__->meta->make_immutable;

1;

__END__
