package LIMS2::Report::CreKiESDistributionSummary;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CreKiESDistributionSummary::VERSION = '0.343';
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

    return 'Cre Knockin ES Distribution Summary';
};

override _build_columns => sub {
    return [
        'Production Centre',
        'Genes Total',
        'Unrequested No Vector',
        'Unrequested Vector Complete',
        'Unrequested With Clones',
        'Awaiting Vectors',
        'Awaiting Electroporation',
        'Awaiting Primary QC',
        'In Primary QC',
        'Failed Primary QC',
        'Awaiting Secondary QC',
        'In Secondary QC 1 Clone',
        'In Secondary QC 2 Clones',
        'In Secondary QC 3 Clones',
        'In Secondary QC 4 Clones',
        'In Secondary QC 5 Clones',
        'In Secondary QC 5+ Clones',
        'Failed Secondary QC 1 Clone',
        'Failed Secondary QC 2 Clones',
        'Failed Secondary QC 3 Clones',
        'Failed Secondary QC 4 Clones',
        'Failed Secondary QC 5 Clones',
        'Failed Secondary QC 5+ Clones',
        'Failed Secondary QC no Clones Remain',
        'Awaiting MI Attempts',
        'MI Attempts Aborted or Inactive',
        'MI Attempts in Progress',
        'MI Attempts Chimeras Obtained',
        'MI Attempts Genotype Confirmed',
        'Error: Missing in LIMS2',
        'Error: Unrecognised Type',
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
