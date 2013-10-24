package LIMS2::Report::VectorProductionDetail;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::VectorProductionDetail::VERSION = '0.116';
}
## use critic


use Moose;
use DateTime;
use LIMS2::AlleleRequestFactory;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::ProductionDetail );

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append = $self->has_sponsor ? ' - Sponsor ' . $self->sponsor . ' ' : '';
    $append .= $dt->ymd;

    return 'Vector Production Detail ' . $append;
};

override _build_columns => sub {
    return [
        "Plate Name", "Well Name", "Design Id", "Gene Id", "Gene Symbol",  "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?",
        "Cassette", "Cassette Type", "Backbone", "Recombinases",
        "Intermedate Well", "Intermediate QC Test Result", "Intermediate Valid Primers", "Intermediate Mixed Reads?", "Intermediate Sequencing QC Pass?",
        "Post-intermedate Well", "Post-intermediate QC Test Result", "Post-intermediate Valid Primers", "Post-intermediate Mixed Reads?", "Post-intermediate Sequencing QC Pass?",
        "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?"
    ];
};

override _build_plate_type => sub {
    'FINAL';
};

has '+allele_request_wells_method' => (
    default => 'all_vector_wells'
);

__PACKAGE__->meta->make_immutable;

1;

__END__
