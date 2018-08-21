package LIMS2::Report::AlleleDump;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::AlleleDump::VERSION = '0.510';
}
## use critic


use Moose;
use Iterator::Simple qw( iter );
#use LIMS2::Model::Util::LegacyCreKnockInProjectReport;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

override _build_name => sub {
    my $self = shift;

    return 'AlleleDump';
};

override _build_columns => sub {
    return [
        qw(
            EUCOMM
            MGI
            DESIGN_ID
            PCS_PLATE
            PCS_WELL
            PCS_QC_RESULT
            PCS_DISTRIBUTE
            PGS_PLATE
            PGS_WELL
            CASSETTE
            BACKBONE
            PGS_QC_RESULT
            PGS_DISTRIBUTE
            EPD
            ES_CELL_LINE
            EPD_DISTRIBUTE
            FP
        )
    ];
};

override iterator => sub {
    my $self = shift;

    my $allele_dump = $self->model->schema->resultset( 'AlleleDump' )->search({});
    my @report_data;

    my @cols = map { lc($_) } @{$self->_build_columns};

    while ( my $rs = $allele_dump->next ) {
        my @row_ar;
        foreach my $col ( @cols ) {
            push @row_ar, $rs->$col;
        }
        push @report_data, \@row_ar;
    }

    return iter( \@report_data );
};

__PACKAGE__->meta->make_immutable;

1;

__END__
