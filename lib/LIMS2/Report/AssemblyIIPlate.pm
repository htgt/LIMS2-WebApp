package LIMS2::Report::AssemblyIIPlate;

use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );
with qw( LIMS2::ReportGenerator::ColonyCounts );

#has bypass_oligo_assembly => (
#    is         => 'ro',
#    required => 0,
#);

#has orginal_design => (
#    is        =>  'ro',
#    require   => 0,
#);

has wells_data => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_wells_data {
    my ($self) = @_;
    # use custom resultset to gather data for plate report speedily
    # avoid using process graph when adding new data or all speed improvements
    # will be nullified, e.g calling $well->design
    my $rs = $self->model->schema->resultset( 'PlateReport' )->search(
        {},
        {
            bind => [ $self->plate->id ],
        }
    );

    my @wells_data = @{ $rs->consolidate( $self->plate_id ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;
    return \@wells_data;
}

override plate_types => sub {
    return [ 'ASSEMBLY_II' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Assembly Plate ' . $self->plate_name;
};

#override _build_name => sub {
#    my $self = shift;
#};

override _build_columns => sub {
    my $self = shift;

    return [
        'Well ID', 'Well Name', 'Design ID', 'Design Type', 'Gene ID', 'Gene Symbol', 'Gene Sponsors', 'Genbank File',
        $self->colony_count_column_names
    ]
};

override iterator => sub {
    my $self = shift;

    # use custom resultset to gather data for plate report speedily
    # avoid using process graph when adding new data or all speed improvements
    # will be nullified, e.g calling $well->design
    my $rs = $self->model->schema->resultset( 'PlateReport' )->search(
        {},
        {
            bind => [ $self->plate->id ],
        }
    );

    my @wells_data = @{ $rs->consolidate( $self->plate_id,
            [ 'well_qc_sequencing_result', 'well_colony_counts' ] ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};
        # list of CRISPR plate wells
        my @crispr_wells = map { $_->{plate_name} . '[' . $_->{well_name} . ']' }
            @{ $well_data->{crispr_wells}{crisprs} };

        my @data = (
            $well_data->{well_id},
            $well_data->{well_name},
            $well_data->{design_id},
            $well_data->{design_type},
            $well_data->{gene_ids},
            $well_data->{gene_symbols},
            $well_data->{sponsors},
            $self->well_eng_seq_link( $well_data ),
            $self->colony_counts( $well )
        );
        $well_data = shift @wells_data;

        return \@data;
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
