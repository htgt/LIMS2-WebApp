package LIMS2::Report::AssemblyPlate;

use Moose;
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
    # my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        'Well Name', 'Design ID', 'Gene ID', 'Gene Symbol', 'Gene Sponsors',
        'Crispr Pair ID', 'Genoverse View',
        'Left Crispr Well', 'Left Crispr Designs', 'Right Crispr Well','Right Crispr Designs',
        'Cassette', 'Cassette Resistance', 'Cassette Type', 'Backbone', #'Recombinases',
        'SF1', 'SR1', 'PF1', 'PR1', 'PF2', 'PR2', 'GF1', 'GR1', 'GF2', 'GR2', # primers
        'Created By','Created At',
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
        $DB::single=1;

        my $well = $wells_rs->next
            or return;

        my $final_vector = $well->final_vector;
        my ($left_crispr,$right_crispr) = $well->left_and_right_crispr_wells;

        my $left_designs = '-';
        my $right_designs = '-';

        if($left_crispr){
            $left_designs = join "/", map { $_->id } $left_crispr->crispr->related_designs;
        }

        if($right_crispr){
            $right_designs = join "/", map { $_->id } $right_crispr->crispr->related_designs;
        }
        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $well->name,
            $self->design_and_gene_cols($well),
            $well->crispr_pair ? $well->crispr_pair->id : '-',
            $self->button_for_genoverse(),
            $left_crispr ? $left_crispr->plate . '[' . $left_crispr->name . ']' : '-',
            $left_designs,
            $right_crispr ? $right_crispr->plate . '[' . $right_crispr->name . ']' : '-',
            $right_designs,
            $final_vector->cassette->name,
            $final_vector->cassette->resistance,
            ( $final_vector->cassette->promoter ? 'promoter' : 'promoterless' ),
            $final_vector->backbone->name,
            # join( q{/}, @{ $final_vector->recombinases } ),
            $well->crispr_primer_for({ 'primer_label' => 'SF1' }),
            $well->crispr_primer_for({ 'primer_label' => 'SR1' }),
            $well->crispr_primer_for({ 'primer_label' => 'PF1' }),
            $well->crispr_primer_for({ 'primer_label' => 'PR1' }),
            $well->crispr_primer_for({ 'primer_label' => 'PF2' }),
            $well->crispr_primer_for({ 'primer_label' => 'PR2' }),
            $well->crispr_primer_for({ 'primer_label' => 'GF1' }),
            $well->crispr_primer_for({ 'primer_label' => 'GR1' }),
            $well->crispr_primer_for({ 'primer_label' => 'GF2' }),
            $well->crispr_primer_for({ 'primer_label' => 'GR2' }),
            $well->created_by->name,
            $well->created_at->ymd,
        ];
    }
};

sub button_for_genoverse {
    my $self = shift;

    my $chr_start = 100000;
    my $chr_end = 300000;
    my $html_value =<<"END_ROW";
custom:chr_start=$chr_start;chr_end=$chr_end;label=Genoverse
END_ROW
    chomp $html_value;
    return $html_value; 

}

__PACKAGE__->meta->make_immutable;

1;

__END__
