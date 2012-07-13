package LIMS2::Report::DesignPlate;

use Moose;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

with 'LIMS2::Role::ReportGenerator';

has plate_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_name {
    my $self = shift;

    return 'Design Plate ' . $self->plate_name;
}

sub _build_columns {
    return [
        "Well Name", "Design Id", "Gene Id", "Gene Symbol", "Created By", "Created At",
        "PCR U", "PCR D", "PCR G", "Rec U", "Rec D", "Rec G", "Rec NS", "Rec Result",
        "Assay Pending", "Assay Complete", "Accepted?"
    ];
}

sub iterator {
    my $self = shift;

    my $plate = $self->model->retrieve_plate( { name => $self->plate_name, type_id => 'DESIGN' } );    
    
    my $wells_rs = $plate->search_related(
        wells => {},
        {
            prefetch => [
                'well_accepted_override', 'well_recombineering_results'
            ],
            order_by => { -asc => 'me.name' }
        }
    );

    return Iterator::Simple::iter sub {
        my $well = $wells_rs->next
            or return;
        my $design = $well->design;
        my @gene_ids      = uniq map { $_->gene_id } $design->genes;
        my @gene_symbols  = uniq map { $self->model->retrieve_gene( { gene => $_ } )->{marker_symbol} } @gene_ids;
        my %recombineering_results = map { $_->result_type_id => $_->result } $well->well_recombineering_results;

        return [
            $well->name,
            $design->id,
            join( q{/}, @gene_ids ),
            join( q{/}, @gene_symbols ),
            $well->created_by->name,
            $well->created_at->ymd,
            @recombineering_results{ qw( pcr_u pcr_d pcr_g rec_u rec_d rec_g rec_ns rec_result ) },
            ( $well->assay_pending ? $well->assay_pending->ymd : '' ),
            ( $well->assay_complete ? $well->assay_complete->ymd : '' ),
            ( $well->is_accepted ? 'yes' : 'no' )
        ];        
    };    
}

__PACKAGE__->meta->make_immutable;

1;

__END__
