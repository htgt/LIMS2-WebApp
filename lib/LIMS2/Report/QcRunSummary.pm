package LIMS2::Report::QcRunSummary;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::QcRunSummary::VERSION = '0.424';
}
## use critic


use Moose;
use LIMS2::Model::Util::QCResults qw( retrieve_qc_run_summary_results );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

has qc_run_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has qc_run => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::QcRun',
    lazy_build => 1,
);

has is_crispr_run => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

has '+param_names' => (
    default => sub { [ 'qc_run_id' ] }
);

sub _build_qc_run {
    my $self = shift;

    return $self->model->retrieve( 'QcRun' => { id => $self->qc_run_id } );
}

sub _build_is_crispr_run {
  my $self = shift;

  return HTGT::QC::Config->new->profile( $self->qc_run->profile )->vector_stage eq "crispr";
}

override _build_name => sub {
    my $self = shift;

    my $id = substr( $self->qc_run_id, 0, 8 );
    return $id . ' QC Run Summary Report ';
};

override _build_columns => sub {
    my $self = shift;

    my @columns = qw(
        gene_symbol
        plate_name
        well_name
        well_name_384
        pass
        valid_primers
    );

    if ( $self->is_crispr_run ) {
        unshift @columns, qw( crispr_id );
    }
    else {
        unshift @columns, qw( design_id );
    }

    return \@columns;
};

override iterator => sub {
    my ( $self ) = @_;

    my $qc_results = retrieve_qc_run_summary_results( $self->qc_run, $self->model, $self->is_crispr_run );

    my $qc_result = shift @{ $qc_results };

    return Iterator::Simple::iter(
        sub {
            return unless $qc_result;

            my @data;
            for my $column ( @{ $self->columns } ) {
                my $datum = defined $qc_result->{$column} ? $qc_result->{$column} : '';
                if($column eq "pass"){
                    $datum = $self->boolean_str($datum);
                }
                push @data, $datum;
            }

            $qc_result = shift @{ $qc_results };
            return \@data;
        }
    );
};

__PACKAGE__->meta->make_immutable;

1;

__END__
