package LIMS2::Report::AssemblyPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::AssemblyPlate::VERSION = '0.276';
}
## use critic


use Moose;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'ASSEMBLY' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Assembly Plate ' . $self->plate_name;
};

override _build_columns => sub {
    return [
        'Well Name', 'Design ID', 'Gene ID', 'Gene Symbol', 'Gene Sponsors',
        'Crispr ID', 'Crispr Design', 'Genoverse View', 'Genbank File',
        'Cassette', 'Cassette Resistance', 'Cassette Type', 'Backbone', #'Recombinases',
        'DNA Quality EGel Pass?','Sequencing QC Pass',
        'Crispr Details',
        'SF1', 'SR1', 'PF1', 'PR1', 'PF2', 'PR2', 'GF1', 'GR1', 'GF2', 'GR2', # primers
        'Created By','Created At',
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

    # prefetch and process crispr and genotyping primer data
    my $well_crisprs_data = $self->get_crispr_data( \@wells_data );
    my $genotyping_primers = $self->fetch_all_genotyping_primers( \@wells_data );

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};
        my $crisprs_data = $well_crisprs_data->{ $well_data->{well_id} };
        my $crispr = $crisprs_data->{obj};
        my $crispr_primers = $self->get_primers( $crispr, $genotyping_primers->{ $well_data->{design_id} } );
        my ( $genoverse_button, $crispr_designs );
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
            $crispr_designs = join( "/", map{ $_->design_id } $crispr->crispr_designs->all );
        }

        # build string reporting individual crispr details
        my @crispr_report_details;
        for my $cd ( @{ $crisprs_data->{crisprs} } ) {
            push @crispr_report_details,
                $cd->{crispr_well} . '(' . $cd->{crispr}->id . ') : ' . $cd->{crispr}->seq;
        }

        my $dna_quality = $well->well_dna_quality;
        my $qc_seq_result = $well->well_qc_sequencing_result;

        my @data = (
            $well_data->{well_name},
            $well_data->{design_id},
            $well_data->{gene_ids},
            $well_data->{gene_symbols},
            $well_data->{sponsors},
            $crispr ? $crispr->id . " ($crisprs_data->{type})" : 'N/A',
            $crispr_designs,
            $genoverse_button,
            $self->catalyst ? $self->catalyst->uri_for( '/public_reports/well_eng_seq', $well_data->{well_id} ) : '-',
            $well_data->{cassette},
            $well_data->{cassette_resistance},
            $well_data->{cassette_promoter},
            $well_data->{backbone},
            ( $dna_quality ? $self->boolean_str($dna_quality->egel_pass) : '' ),
            ( $qc_seq_result ? $self->boolean_str($qc_seq_result->pass) : '' ),
            join( ", ", @crispr_report_details ),
            @{ $crispr_primers }{ qw( SF1 SR1 PF1 PR1 PF2 PR2 GF1 GR1 GF2 GR2 ) },
            $well_data->{created_by},
            $well_data->{created_at},
        );

        $well_data = shift @wells_data;
        return \@data;
    };
};

=head2 get_primers

Grab the crispr primers and genotyping primers

=cut
sub get_primers {
    my ( $self, $crispr, $genotyping_primers ) = @_;
    my %primers;

    for my $gp ( @{ $genotyping_primers } ) {
        $primers{ $gp->{type} } = $gp->{seq};
    }

    return \%primers unless $crispr;

    for my $cp ( $crispr->crispr_primers->all ) {
        $primers{ $cp->get_column('primer_name') } = $cp->primer_seq;
    }

    return \%primers;
}

=head2 fetch_all_genotyping_primers

Grab all the genotyping primers for the designs on the plate upfront to
speed up the report.

=cut
sub fetch_all_genotyping_primers {
    my ( $self, $wells_data ) = @_;
    my %genotyping_primers;

    my @design_ids = uniq map { $_->{design_id} } @{ $wells_data };

    my @genotyping_primers = $self->model->schema->resultset('GenotypingPrimer')->search(
        {
            'design_id' => { 'IN' => \@design_ids },
        },
        {
            'columns' => [ qw/design_id genotyping_primer_type_id seq/ ],
            'distinct' => 1,
        }
    );

    for my $gp ( @genotyping_primers ) {
        push @{ $genotyping_primers{ $gp->design_id } },
            { type => $gp->genotyping_primer_type_id, seq => $gp->seq };
    }

    return \%genotyping_primers;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
