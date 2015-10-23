package LIMS2::Report::CrisprVectorPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprVectorPlate::VERSION = '0.348';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'CRISPR_V' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Vector Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Well Name',
        "Design Id", "Design Type", "Gene Id", "Gene Symbol", "Gene Sponsors", 'Genbank File',
        'Crispr Plate', 'Crispr Well', 'Crispr ID',
        'Backbone',
        'Created By','Created At',
        'Accepted?',
    ];
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

    my @wells_data = @{ $rs->consolidate( $self->plate_id, [ 'well_qc_sequencing_result' ] ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $crispr = $self->model->schema->resultset( 'Crispr' )->find(
            {
                id => $well_data->{crispr_ids}[0],
            },
            {
                prefetch => { 'crispr_designs' => { 'design' => 'genes' } },
            }
        );
        my ( $parent_plate, $parent_well ) = split( /_/, $well_data->{parent_wells} );

        my @data = (
            $well_data->{well_name},
            $self->crispr_design_and_gene_cols($crispr),
            $self->catalyst ? $self->catalyst->uri_for( '/public_reports/well_eng_seq', $well_data->{well_id} ) : '',
            $well_data->{parent_wells}[0]{plate_name},
            $well_data->{parent_wells}[0]{well_name},
            $crispr->id,
            $well_data->{backbone},
            $well_data->{created_by},
            $well_data->{created_at},
            $self->boolean_str( $well_data->{accepted} ),
        );
        $well_data = shift @wells_data;
        return \@data;
    };

};

__PACKAGE__->meta->make_immutable;

1;

__END__
