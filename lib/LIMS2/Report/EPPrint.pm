package LIMS2::Report::EPPrint;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::EPPrint::VERSION = '0.326';
}
## use critic


use Moose;
use List::MoreUtils qw( apply );
use namespace::autoclean;
use Log::Log4perl qw( :easy );

extends qw( LIMS2::ReportGenerator::Plate::SimpleColumns );

override additional_report => sub {
    return 1;
};

override plate_types => sub {
    return [ 'EP' ];
};

override _build_name => sub {
    my $self = shift;

    return 'EP Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    my @columns = (
        'Observed ID',
        'Symbol',
        'DNA Plate',
        'DNA Well',
        'EP Well',
    );

    return \@columns;
};

override iterator => sub {
    my $self = shift;

    my @well_list = ('A01','B01','C01','D01','E01','A02','B02','C02','D02','E02','A03','B03',
            'C03','D03','E03','A04','B04','C04','D04','E04','A05','B05','C05','D05','E05',);

    my $plate = $self->plate_name;
    my %well_hash;

    foreach my $well (@well_list) {
        $well_hash{$well}{ob_id} = '';
        $well_hash{$well}{symbol} = '';
        $well_hash{$well}{dna_plate} = '';
        $well_hash{$well}{dna_well} = '';
        $well_hash{$well}{ep_well} = "$plate".'_'."$well";
    }

    my $wells_rs = $self->plate->search_related(
        wells => {},
        {
            prefetch => ['well_accepted_override',
                         'well_colony_counts']
        }
    );

    while (my $well = $wells_rs->next) {
        $well_hash{$well->name}{symbol} = $self->design_and_gene_cols( $well );
        my $parent_well = $well->get_input_wells_as_string;
        # regex to get plate and well from PLATE[WELL]
        if ( $parent_well =~ m/(.*)\[(.*)\]/xms ) {
            $well_hash{$well->name}{dna_plate} = $1;
            $well_hash{$well->name}{dna_well} = $2;
        }
    }

    my @epprint;
    foreach my $well (@well_list) {
        push (@epprint, [
            $well_hash{$well}{ob_id},
            $well_hash{$well}{symbol},
            $well_hash{$well}{dna_plate},
            $well_hash{$well}{dna_well},
            $well_hash{$well}{ep_well},
            ]);
    }

    return Iterator::Simple::iter (\@epprint);
};


__PACKAGE__->meta->make_immutable;

1;

__END__
