package LIMS2::Report::DNAPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::DNAPlate::VERSION = '0.222';
}
## use critic


use Moose;
use namespace::autoclean;
use List::MoreUtils qw(uniq);
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'DNA' ];
};

override _build_name => sub {
    my $self = shift;

    return 'DNA Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        $self->base_columns,
        $self->accepted_crispr_columns,
        "Cassette", "Cassette Resistance", "Backbone", "Recombinases",
        "Final Pick Vector Well", "Final Pick Vector QC Test Result", "Final Pick Vector Valid Primers", "Final Pick Vector Mixed Reads?", "Final Pick Vector Sequencing QC Pass?",
        "DNA Quality", "DNA Quality EGel Pass?", "DNA Quality Comment", "DNA Pass?", "DNA Concentration(ng/ul)", "Already Electroporated", "Child Well List", "Well Name"
    ];
};

override iterator => sub {
    my $self = shift;

    my $wells_rs = $self->plate->search_related(
        wells => {},
        {
            prefetch => [
                'well_accepted_override', 'well_qc_sequencing_result'
            ],
            order_by => { -asc => 'me.name' }
        }
    );

    return Iterator::Simple::iter sub {
        my $well = $wells_rs->next
            or return;

        # See if we have a crispr for this well, i.e. if created from crispr_v
        my $crispr = undef;
        try{
            my $crispr_well = $well->parent_crispr;
            $crispr = $crispr_well->crispr;
        }

        my @design_gene = $self->design_and_gene_cols( $well, $crispr );
        my $gene_id = $design_gene[1];

        my @ep_sep = $self->model->schema->resultset('Summary')->search({
                design_gene_id     => $gene_id,
            },
             {
                 select   => [qw/ ep_plate_name ep_well_name sep_plate_name sep_well_name/],
             },
        );

        # get the already electroporated plate_wells
        my @already_ep;
        foreach my $ep_sep_row (@ep_sep) {
            my $ep_plate = $ep_sep_row->ep_plate_name // '';
            my $ep_well = $ep_sep_row->ep_well_name // '';
            push(@already_ep, $ep_plate.'_'.$ep_well);

            my $sep_plate = $ep_sep_row->sep_plate_name // '';
            my $sep_well = $ep_sep_row->sep_well_name // '';
            push(@already_ep, $sep_plate.'_'.$sep_well);
        }
        # remove duplicates and empty one
        @already_ep = uniq @already_ep;
        @already_ep = grep {$_ ne '_'} @already_ep;

        my $dna_status = $well->well_dna_status;
        my $dna_quality = $well->well_dna_quality;

        my @accepted_crispr_data;
        if($crispr){
            # We don't need to show accepted crispr info if this is a crispr DNA plate
            # return the correct number of 'empty' values
            foreach my $col ($self->accepted_crispr_columns){
                push @accepted_crispr_data, '-';
            }
        }
        else{
            # Find accepted crispr DNA wells
            @accepted_crispr_data = $self->accepted_crispr_data( $well, 'DNA' );
        }

        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $self->base_data( $well, $crispr ),
            @accepted_crispr_data,
            ( $well->cassette ? $well->cassette->name : '-' ),
            ( $well->cassette ? $well->cassette->resistance : '-' ),
            ( $well->backbone ? $well->backbone->name : '-' ),
            join( q{/}, @{ $well->vector_recombinases } ),
            $self->ancestor_cols( $well, 'FINAL_PICK' ),
            ( $dna_quality ? ( $dna_quality->quality, $self->boolean_str($dna_quality->egel_pass), $dna_quality->comment_text ) : ('')x3 ),
            ( $dna_status  ? $self->boolean_str( $dna_status->pass ) : '' ),
            ( $dna_status  ? (sprintf "%.2f", $dna_status->concentration_ng_ul) : '' ),
            join (' ', @already_ep),
            $well->get_output_wells_as_string,
            $well->name,
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
