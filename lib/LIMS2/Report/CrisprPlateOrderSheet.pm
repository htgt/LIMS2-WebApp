package LIMS2::Report::CrisprPlateOrderSheet;

=head1 NAME

LIMS2::Report::CrisprPlateOrderSheet

=head1 DESCRIPTION

Report for CRISPR type plates.
Order sheet showing what crisprs to order for the crispr plate.

=cut

use Moose;
use Const::Fast;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override additional_report => sub {
    return 1;
};

override plate_types => sub {
    return [ 'CRISPR' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Plate Order Sheet ' . $self->plate_name;
};

override _build_columns => sub {
    return [];
};

override iterator => sub {
    my $self = shift;

    $self->generate_crispr_plate_order_sheet_data;

    return Iterator::Simple::iter sub {
        my $datum = $self->next_report_row
            or return;

        return $datum;
    };
};

has report_data => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    default => sub{ [] },
    handles => {
        add_report_row  => 'push',
        next_report_row => 'shift',
    }
);

has crispr_data => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub{ [] },
);

=head2 generate_crispr_plate_order_sheet_data


=cut
sub generate_crispr_plate_order_sheet_data {
    my ( $self ) = @_;

    $self->build_base_report_data;
    $self->build_report;

    return;
}

sub build_base_report_data{
    my ( $self ) = @_;

    my @wells = $self->plate->wells( {}, { order_by => { -asc => 'name' } } );
    for my $well ( @wells ) {
        my ( $parent_process ) = $well->parent_processes;
        my $crispr = $parent_process->process_crispr->crispr;

        push @{ $self->crispr_data }, {
            well_name => $well->name,
            forward   => $crispr->forward_order_seq,
            reverse   => $crispr->reverse_order_seq,
            crispr_id => $crispr->id,
        };
    }

    return;
}

sub build_report {
    my ( $self ) = @_;

    for my $type ( qw( forward reverse ) ) {
        $self->add_report_row( [ 'Temp_' . $self->plate->name . '_' . $type ] );
        for my $datum ( @{ $self->crispr_data } ) {
            $self->add_report_row( [ $datum->{well_name}, $datum->{ $type }, $datum->{'crispr_id'}  ]  );
        }
        $self->add_blank_report_row;
    }

    return;
}

sub oligo_type_seq_data {
    my ( $self, $oligo_type, $plate_name ) = @_;

    for my $oligo_data ( @{ $self->oligo_data->{ $oligo_type } } ) {
        $oligo_data->{well} =~ /(?<row>\w)(?<column>\d{2})/;
        my $oligo_name = $oligo_data->{well} . '_' . $oligo_data->{crispr_id} . '_' . $oligo_type;

        my @oligo_seq_data = (
            $plate_name,
            $+{row},
            $+{column},
            $oligo_name,
            $oligo_data->{phase},
        );
        push @oligo_seq_data, $oligo_data->{seq} if $oligo_data->{seq};

        $self->add_report_row( \@oligo_seq_data );
    }

    return;
}

## no critic(RequireFinalReturn)
sub add_blank_report_row {
    shift->add_report_row( [] );
}
## use critic

__PACKAGE__->meta->make_immutable;

1;

__END__
