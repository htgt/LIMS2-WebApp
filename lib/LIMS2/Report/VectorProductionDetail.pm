package LIMS2::Report::VectorProductionDetail;

use Moose;
use DateTime;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

with qw( LIMS2::Role::ReportGenerator );

sub _build_name {
    my $dt = DateTime->now();
    return 'Vector Production Detail ' . $dt->ymd;    
}

sub _build_columns {
    return [
        "MGI Accession Id", "Marker Symbol", "Plate", "Well", "Created Date",
        "Design", "Cassette", "Backbone", "Recombinase", "Accepted?"
    ];
}

sub iterator {
    my ( $self, $model ) = @_;

    my $final_vectors_rs = $model->schema->resultset( 'Well' )->search(
        {
            'plate.type_id' => 'FINAL'
        },
        {
            join     => 'plate',
            prefetch => 'well_accepted_override',
            order_by => { -asc => 'me.created_at' }
        }
    );

    return Iterator::Simple::iter(
        sub {
            my $well = $final_vectors_rs->next
                or return;
            my $design = $well->design;
            my @mgi_accessions = map { $_->gene_id } $design->genes;    
            my @marker_symbols = uniq map { $_->{marker_symbol} }
                map { @{ $model->search_genes( { gene => $_ } ) } } @mgi_accessions;
            return [
                join( '/', @mgi_accessions ),
                join( '/', @marker_symbols ),
                $well->plate->name,
                $well->name,
                $well->created_at->ymd,
                $design->id,
                $well->cassette,
                $well->backbone,
                join( '/', @{$well->recombinases} ),
                ( $well->is_accepted ? 'yes': 'no' )
            ];
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
