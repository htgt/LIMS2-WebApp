package LIMS2::Report::LegacyCreKnockInProjects;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::LegacyCreKnockInProjects::VERSION = '0.204';
}
## use critic


use Moose;
use Iterator::Simple qw( iter );
use LIMS2::Model::Util::LegacyCreKnockInProjectReport;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

override _build_name => sub {
    my $self = shift;

    return 'Legacy Cre KnockIn Project Report';
};

override _build_columns => sub {
    return [
        qw(
            htgt_project_id
            lims2_project_id
            marker_symbol
            mgi_gene_id
            status
        )
    ];
};

override iterator => sub {
    my $self = shift;

    my $cre_ki_report_generator = LIMS2::Model::Util::LegacyCreKnockInProjectReport->new(
        model => $self->model
    );

    $cre_ki_report_generator->generate_report_data;
    my $report_data = $cre_ki_report_generator->report_data;

    return iter( $report_data );
};

__PACKAGE__->meta->make_immutable;

1;

__END__
