package LIMS2::ReportGenerator::Plate::SimpleColumns;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::Plate::SimpleColumns::VERSION = '0.314';
}
## use critic


use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate );

sub base_columns {
    return ( "Well Name", "Design Id", "Gene Id", "Gene Symbol", "Gene Sponsors", "Created By", "Created At", "Genbank File" );
}

sub base_data {
    my ( $self, $well ) = @_;

    return (
        $well->name,
        $self->design_and_gene_cols( $well ),
        $well->created_by->name,
        $well->created_at->ymd,
    );
}

=head2 base_data_quick

Quicker method to grab data when using PlateReport custom resultset.

=cut
sub base_data_quick {
    my ( $self, $data, $args ) = @_;

    my @base_data = (
        $data->{well_name},
        $data->{design_id},
        $data->{gene_ids},
        $data->{gene_symbols},
        $data->{sponsors},
        $data->{created_by},
        $data->{created_at},
    );

    unless ( $args || $args->{no_eng_seq_link} ) {
        if ( $self->catalyst ) {
            push @base_data, $self->catalyst->uri_for( '/public_reports/well_eng_seq', $data->{well_id} );
        }
        else {
            push @base_data, '-';
        }
    }

    return @base_data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
