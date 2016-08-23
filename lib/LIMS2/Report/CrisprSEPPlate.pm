package LIMS2::Report::CrisprSEPPlate;

use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::DoubleTargeted );
with qw( LIMS2::ReportGenerator::ColonyCounts );

override plate_types => sub {
    return [ 'CRISPR_SEP' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Second Electroporation Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Well ID', 'Well Name',
        'First Design ID', 'First Design Type', 'First Gene Symbol', 'First CRISPR wells',
        'Second Design ID', 'Second Design Type', 'Second Gene Symbol', 'Second CRISPR wells',
        'Cell Line',
        'Created By','Created At', 'Report?'
    ];
};

override iterator => sub {
    my $self = shift;

    $self->prefetch_well_ancestors;

    my $gene_finder = sub { $self->model->find_genes( @_ ); };;

    my $well = shift @wells;
    return Iterator::Simple::iter sub {
        return unless $well;

        # list of CRISPR plate wells
#        my @crispr_wells = map { $_->{plate_name} . '[' . $_->{well_name} . ']' }
#            @{ $well_data->{crispr_wells}{crisprs} };

        my $first = $well->first_allele;
        my $second = $well->second_allele;

        my @data = (
            $well->id,
            $well->well_name,
            $first->design->id,
            $first->design->design_type_id,
            $first->design->gene_symbols($gene_finder),
            _format_well_names($first->parent_crispr_wells),
            $second->design->id,
            $second->design->design_type_id,
            $second->design->gene_symbols($gene_finder),
            _format_well_names($second->parent_crispr_wells),
            $well->first_cell_line->name,
            $well->created_by->name,
            $well->created_at,
            $well->to_report ? 'true' : 'false',
        );
        $well = shift @wells;

        return \@data;
    };
};


sub _format_well_names{
    my (@wells) = @_;
    my @well_names = map { $_->plate_name."[".$_->well_name."]" } @wells;
    return join ",", @well_names;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
