package LIMS2::Report::OligoAssembly;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::OligoAssembly::VERSION = '0.442';
}
## use critic


use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'OLIGO_ASSEMBLY' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Oligo Assembly Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Well ID', 'Well Name', 'Gene ID', 'Gene Symbol', 'Gene Sponsors',
        'Design ID', 'Design Type', 'Design Well', 'Crispr ID', 'Crispr Well','Genoverse View',
        'CRISPR Tracker RNA',
        'Created By','Created At', 'Report?'
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

    my @wells_data = @{ $rs->consolidate( $self->plate_id ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;
    # prefetch and process crispr data
    my $well_crisprs_data = $self->get_crispr_data( \@wells_data );

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};
        my $crisprs_data = $well_crisprs_data->{ $well_data->{well_id} };
        my $crispr = $crisprs_data->{obj};

        my $genoverse_button;
        if ( $crispr ) {
            $genoverse_button = $self->create_button_json(
                {   'design_id'      => $well_data->{design_id},
                    'crispr_type'    => $crisprs_data->{type} . '_id',
                    'crispr_type_id' => $crispr->id,
                    'plate_name'     => $self->plate_name,
                    'well_name'      => $well_data->{well_name},
                    'gene_symbol'    => $well_data->{gene_symbols},
                    'gene_ids'       => $well_data->{gene_ids},
                    'button_label'   => 'Genoverse',
                    'browser_target' => $self->plate_name . $well_data->{well_name},
                    'api_url'        => '/user/genoverse_primer_view',
                }
            );
        }

        my @crispr_report_details;
        for my $cd ( @{ $crisprs_data->{crisprs} } ) {
            push @crispr_report_details,
                $cd->{crispr_well} . '(' . $cd->{crispr}->id . ') : ' . $cd->{crispr}->seq;
        }

        my @data = (
            $well_data->{well_id},
            $well_data->{well_name},
            $well_data->{gene_ids},
            $well_data->{gene_symbols},
            $well_data->{sponsors},

            $well_data->{design_id},
            $well_data->{design_type},
            $well_data->{well_ancestors}{DESIGN}{well_name},
            $crispr ? $crispr->id . " ($crisprs_data->{type})" : 'N/A',
            $well_data->{well_ancestors}{CRISPR}{well_name},
            $genoverse_button,
            $well_data->{crispr_tracker_rna},
            $well_data->{created_by},
            $well_data->{created_at},
            $well_data->{to_report} ? 'true' : 'false',
        );
        $well_data = shift @wells_data;

        return \@data;
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
