package LIMS2::Report::DNAPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::DNAPlate::VERSION = '0.526';
}
## use critic


use Moose;
use namespace::autoclean;
use List::MoreUtils qw(uniq);

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

    return [
        $self->base_columns,
        'Crispr ID',
        $self->accepted_crispr_columns,
        "Cassette", "Cassette Resistance", "Backbone", "Recombinases",
        "Final Pick Vector Well", "Final Pick Vector QC Test Result", "Final Pick Vector Valid Primers", "Final Pick Vector Mixed Reads?", "Final Pick Vector Sequencing QC Pass?",
        "DNA Quality", "DNA Quality EGel Pass?", "DNA Quality Comment", "DNA Pass?", "DNA Concentration(ng/ul)", "Already Electroporated", "Child Well List", "Well Name"
    ];
};

override iterator => sub {
    my $self = shift;

    #prefetch plate child wells
    my $child_wells_rs = $self->model->schema->resultset( 'PlateChildWells' )->search(
        {}, { bind => [ $self->plate->id ] } );
    my $plate_child_wells = $child_wells_rs->child_well_hash;

    # use custom resultset to gather data for plate report speedily
    # avoid using process graph when adding new data or all speed improvements
    # will be nullified, e.g calling $well->design
    my $rs = $self->model->schema->resultset( 'PlateReport' )->search(
        {},
        {
            bind => [ $self->plate->id ],
        }
    );

    my @wells_data = @{
        $rs->consolidate( $self->plate_id,
            [ 'well_qc_sequencing_result', 'well_dna_status', 'well_dna_quality' ] )
        };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

    # Set well_design_ids hash in LIMS2::Report::Plate, see method for details
    $self->set_well_designs( \@wells_data );

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};

        # See if we have a crispr for this well, i.e. if created from crispr_v
        my ( $crispr, @base_data );
        if ( $well_data->{crispr_ids} ) {
            $crispr = $self->model->schema->resultset( 'Crispr' )->find(
                {
                    id => $well_data->{crispr_ids}[0],
                },
                {
                    prefetch => { 'experiments' => { 'design' => 'genes' } },
                }
            );
            @base_data = $self->base_data_crispr_quick( $well_data, $crispr );
        }
        else {
            @base_data = $self->base_data_quick( $well_data );
        }
        # gene_id is a list of gene_ids joined by a slash, though in reality
        # 99.9% of the designs only have one gene_id associated with them
        my $gene_id = ( split( /\//, $base_data[2] ) )[0];

        my $electroporated_wells = $self->electroporated_wells( $gene_id );

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
            # Find accepted crispr DNA wells, method in LIMS2::ReportGenerator::Plate
            @accepted_crispr_data = $self->accepted_crispr_data( $well, 'DNA' );
        }
        my $child_wells = $plate_child_wells->{ $well_data->{well_id} } || [];

        my @data = (
            @base_data,
            $crispr ? $crispr->id : '',
            @accepted_crispr_data,
            $well_data->{cassette},
            $well_data->{cassette_resistance},
            $well_data->{backbone},
            $well_data->{recombinases},
            $self->ancestor_cols_quick( $well_data, 'FINAL_PICK' ),
            ( $dna_quality ? ( $dna_quality->quality, $self->boolean_str($dna_quality->egel_pass), $dna_quality->comment_text ) : ('')x3 ),
            ( $dna_status  ? $self->boolean_str( $dna_status->pass ) : '' ),
            ( $dna_status  ? (sprintf "%.2f", $dna_status->concentration_ng_ul) : '' ),
            join (' ', @{ $electroporated_wells }),
            join (' ', @{ $child_wells } ),
            $well_data->{well_name},
        );

        $well_data = shift @wells_data;
        return \@data;
    };

};

=head2 electroporated_wells

get the already electroporated wells linked to gene_id

=cut
sub electroporated_wells {
    my ( $self, $gene_id  ) = @_;

    # work out already electroporated wells
    my @ep_sep = $self->model->schema->resultset('Summary')->search({
            design_gene_id => $gene_id,
        },
         {
             select   => [qw/ ep_plate_name ep_well_name sep_plate_name sep_well_name/],
         },
    );

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

    return \@already_ep;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
