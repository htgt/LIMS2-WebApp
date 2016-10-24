package LIMS2::Report::QcRun;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::QcRun::VERSION = '0.427';
}
## use critic


use Moose;
use LIMS2::Model::Util::QCResults qw( retrieve_qc_run_results_fast );
use HTGT::QC::Config;
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
    return $id . ' QC Run Report ';
};

override _build_columns => sub {
    my $self = shift;

    my $primers = $self->qc_run->primers;
    my @primer_fields;
    for my $primer ( @{ $primers } ) {
        push @primer_fields, map { $primer.'_'.$_ }
            qw( pass target_align_length read_length score );
    }
    my @columns = qw(
        plate_name
        well_name
        well_name_384
        gene_symbol
    );

    if ( $self->is_crispr_run ) {
        push @columns, qw( crispr_id expected_crispr_id );
    }
    else {
        push @columns, qw( design_id expected_design_id );
    }

    push @columns, qw(
        pass
        score
        num_reads
        num_valid_primers
        valid_primers_score
    );

    push @columns, @primer_fields;
    push @columns, map { $_ . "_features" } @{ $primers }; #put at the end

    return \@columns;
};

override iterator => sub {
    my ( $self ) = @_;

    my $qc_results = retrieve_qc_run_results_fast( $self->qc_run, $self->model, $self->is_crispr_run );

    my $qc_result = shift @{ $qc_results };

    return Iterator::Simple::iter(
        sub {
            return unless $qc_result;

            my @data;
            for my $column ( @{ $self->columns } ) {
                next if $column eq 'valid_primers';
                my $datum = defined $qc_result->{$column} ? $qc_result->{$column} : '';
                #make well names uppercase so the lab staff don't have to change it to upload
                $datum = uc $datum if $column =~ /well_name/;
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
