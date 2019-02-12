package LIMS2::ReportGenerator::Plate::SingleTargeted;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::Plate::SingleTargeted::VERSION = '0.527';
}
## use critic


use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate );

sub base_columns {
    return ( "Well Name", "Design Id", "Design Type", "Gene Id", "Gene Symbol", "Gene Sponsors", "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?", "Genbank File" );
}

sub base_data {
    my ( $self, $well, $crispr, $args ) = @_;

    my @base_data = (
        $well->name,
        $self->design_and_gene_cols($well,$crispr),
        $well->created_by->name,
        $well->created_at->ymd,
        ( $well->assay_pending ? $well->assay_pending->ymd : '' ),
        ( $well->assay_complete ? $well->assay_complete->ymd : '' ),
        $self->boolean_str( $well->is_accepted ),
    );

    unless ( $args || $args->{no_eng_seq_link} ) {
        if ( $self->catalyst ) {
            push @base_data, $self->catalyst->uri_for( '/public_reports/well_eng_seq', $well->id );
        }
        else {
            push @base_data, '-';
        }
    }

    return @base_data;
}

=head2 base_data_quick

Quicker method to grab data when using PlateReport custom resultset.

=cut
sub base_data_quick {
    my ( $self, $data, $args ) = @_;

    my @base_data = (
        $data->{well_name},
        $data->{design_id},
        $data->{design_type},
        $data->{gene_ids},
        $data->{gene_symbols},
        $data->{sponsors},
        $data->{created_by},
        $data->{created_at},
        $data->{assay_pending},
        $data->{assay_complete},
        $self->boolean_str( $data->{accepted} ),
    );

    unless ( $args || $args->{no_eng_seq_link} ) {
        push @base_data, $self->well_eng_seq_link( $data );
    }

    return @base_data;
}

=head2 base_data_crispr_quick

Quicker method to grab crispr data when using PlateReport custom resultset.

=cut
sub base_data_crispr_quick {
    my ( $self, $data, $crispr, $args ) = @_;

    my @base_data = (
        $data->{well_name},
        $self->crispr_design_and_gene_cols( $crispr ),
        $data->{created_by},
        $data->{created_at},
        $data->{assay_pending},
        $data->{assay_complete},
        $self->boolean_str( $data->{accepted} ),
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

=head2 well_eng_seq_link

Return link for a well that will generate its eng seq Genbank file
This is for use with the PlateReport custom resultset.

=cut
sub well_eng_seq_link {
    my ( $self, $well_data ) = @_;

    # nonsense designs can not currently have eng seqs generated for them..
    return 'N/A' if $well_data->{design_type} eq 'nonsense';

    if ( $self->catalyst ) {
        return $self->catalyst->uri_for( '/public_reports/well_eng_seq', $well_data->{well_id} );
    }

    return '-';
}

__PACKAGE__->meta->make_immutable;

1;

__END__
