package LIMS2::Report::AssemblyPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::AssemblyPlate::VERSION = '0.430';
}
## use critic


use Moose;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

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

has well_crisprs_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_well_crisprs_data {
    my $self = shift;
    return $self->get_crispr_data( $self->wells_data );
}

has genotyping_primers => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

=head2 _build_genotyping_primers

Grab all the genotyping primers for the designs on the plate upfront to
speed up the report.

=cut
sub _build_genotyping_primers {
    my ( $self ) = @_;
    my %genotyping_primers;

    my @design_ids = uniq map { $_->{design_id} } @{ $self->wells_data };

    my @genotyping_primers = $self->model->schema->resultset('GenotypingPrimer')->search(
        {
            'design_id' => { 'IN' => \@design_ids },
        },
        {
            'columns' => [ qw/design_id genotyping_primer_type_id seq is_validated/ ],
            'distinct' => 1,
        }
    );

    for my $gp ( @genotyping_primers ) {
        next if $gp->is_rejected;
        push @{ $genotyping_primers{ $gp->design_id } },
            { type => $gp->genotyping_primer_type_id, seq => $gp->seq, is_validated => $gp->is_validated };
    }

    return \%genotyping_primers;
}

has crispr_primers => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_crispr_primers {
    my $self = shift;
    my $crispr_primers = {};
    foreach my $crispr_data (values %{ $self->well_crisprs_data }){
        my $crispr = $crispr_data->{obj};
        next unless $crispr;
        my $crispr_type = $crispr_data->{type};
        my $key = $crispr->id . " (" . $crispr_type . ")";
        foreach my $primer ($crispr->crispr_primers->all){
            next if $primer->is_rejected;
            push @{ $crispr_primers->{$key} },
            { type => $primer->primer_name->primer_name, is_validated => $primer->is_validated };
        }
    }
    return $crispr_primers;
}

override plate_types => sub {
    return [ 'ASSEMBLY' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Assembly Plate ' . $self->plate_name;
};

has primer_names => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_primer_names {
    return [ qw( SF1 SR1 PF1 PR1 PF2 PR2 GF1 GR1 GF2 GR2 DF1 DR1 ER1 ) ];
}

override _build_columns => sub {
    my $self = shift;
    return [
        'Well Name', 'Design ID', 'Gene ID', 'Gene Symbol', 'Gene Sponsors',
        'Crispr ID', 'Crispr Design', 'Genoverse View', 'Genbank File',
        'Crispr Left QC', 'Crispr Right QC', 'Vector QC','QC Verified?',
        'Cassette', 'Cassette Resistance', 'Cassette Type', 'Backbone', #'Recombinases',
        'Crispr Vector Well(s)', 'Final Pick Well',
        'DNA Quality EGel Pass?','Sequencing QC Pass',
        'Crispr Details',
        @{ $self->primer_names }, # primers
        'Created By','Created At',
    ];
};

override iterator => sub {
    my $self = shift;

    my @wells_data = @{ $self->wells_data };

    # prefetch and process crispr and genotyping primer data
    my $well_crisprs_data = $self->well_crisprs_data();
    my $genotyping_primers = $self->genotyping_primers();

    my $well_data = shift @wells_data;

    # Get list of QC combo options from enum list in database schema
    my $col_info = $self->model->schema->resultset('WellAssemblyQc')->result_source->column_info('value');
    my $combo_options = $col_info->{extra}->{list};
    my %combo_common = (
        options => $combo_options,
        api_base => 'api/update_assembly_qc',
    );

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};
        my $crisprs_data = $well_crisprs_data->{ $well_data->{well_id} };
        my $crispr = $crisprs_data->{obj};
        my $crispr_primers = $self->get_primers( $crispr, $genotyping_primers->{ $well_data->{design_id} } );
        my @crispr_vectors = map{ $_->{plate_name} . '_' . $_->{well_name} } @{ $well_data->{crispr_wells}{crispr_vectors} };
        my ( $genoverse_button, $crispr_designs );
        my ( $crispr_left_qc_combo, $crispr_right_qc_combo, $vector_qc_combo );
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

## no critic(ProhibitCommaSeparatedStatements)
            $crispr_left_qc_combo = $self->create_combo_json({
                %combo_common,
                selected => '-',
                api_params => {
                    well_id => $well_data->{well_id},
                    type    => 'CRISPR_LEFT_QC',
                },
                selected => ( $well->assembly_qc_value('CRISPR_LEFT_QC') || '-' ),
            });

            $crispr_right_qc_combo = $self->create_combo_json({
                %combo_common,
                selected => '-',
                api_params => {
                    well_id => $well_data->{well_id},
                    type    => 'CRISPR_RIGHT_QC',
                },
                selected => ( $well->assembly_qc_value('CRISPR_RIGHT_QC') || '-' ),
            });

            $vector_qc_combo = $self->create_combo_json({
                %combo_common,
                selected => '-',
                api_params => {
                    well_id => $well_data->{well_id},
                    type    => 'VECTOR_QC',
                },
                selected => ( $well->assembly_qc_value('VECTOR_QC') || '-' ),
            });
        }
## use critic

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
            $crispr_left_qc_combo,
            $crispr_right_qc_combo,
            $vector_qc_combo,
            ($well->assembly_well_qc_verified // ""),
            $well_data->{cassette},
            $well_data->{cassette_resistance},
            $well_data->{cassette_promoter},
            $well_data->{backbone},
            join( ", ", @crispr_vectors ),
            $well_data->{well_ancestors}{FINAL_PICK}{well_name},
            ( $dna_quality ? $self->boolean_str($dna_quality->egel_pass) : '' ),
            ( $qc_seq_result ? $self->boolean_str($qc_seq_result->pass) : '' ),
            join( ", ", @crispr_report_details ),
            @{ $crispr_primers }{ @{ $self->primer_names } },
            $well_data->{created_by},
            $well_data->{created_at},
        );

        $well_data = shift @wells_data;
        return \@data;
    };
};

override structured_data => sub {
    my $self = shift;
    my $data;
    $data->{plate_type} = "ASSEMBLY";
    $data->{genotyping_primers} = $self->genotyping_primers;
    $data->{crispr_primers} = $self->crispr_primers;
    return $data;
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



__PACKAGE__->meta->make_immutable;

1;

__END__
