package LIMS2::Report::DesignPlateOrderSheet;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::DesignPlateOrderSheet::VERSION = '0.338';
}
## use critic


=head1 NAME

LIMS2::Report::DesignPlateOrderSheet

=head1 DESCRIPTION

Report for DESIGN type plates.
Order sheet showing what bac clones and oligos are needed for the design plate.

=cut

use Moose;
use Const::Fast;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );


override additional_report => sub {
    return 1;
};

override plate_types => sub {
    return [ 'DESIGN' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Design Plate Order Sheet ' . $self->plate_name;
};

override _build_columns => sub {
    return [];
};

override iterator => sub {
    my $self = shift;

    $self->generate_design_plate_order_sheet_data;

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

has oligo_data => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub{ {} },
);

has bac_data => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub{ {} },
);

# gibson designs do not neen bacs, assume if one well is gibson all are
# so check first well to see if its a gibson design
has is_gibson => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

sub _build_is_gibson {
    my $self = shift;

    my $design_type = $self->plate->wells->first->design->design_type_id;
    my $is_gibson = $design_type eq 'gibson' || $design_type eq 'gibson-deletion' ? 1 : 0;

    return $is_gibson;
}

has oligo_types => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_oligo_types {
    my $self = shift;
    my @oligo_types;

    if ( $self->is_gibson ) {
        @oligo_types = qw( 5F 5R EF ER 3F 3R );
    }
    else {
        @oligo_types = qw( G5 G3 U5 U3 D5 D3 );
    }

    return \@oligo_types;
}

=head2 generate_design_plate_order_sheet_data

Generate the data we need to display in the order sheet.
Gibson design plates do not have bac data.

=cut
sub generate_design_plate_order_sheet_data {
    my ( $self ) = @_;

    $self->build_base_report_data();
    $self->oligo_seq_data;
    unless ( $self->is_gibson ) {
        $self->bac_plate_data;
        $self->bac_list;
    }

    return;
}

sub build_base_report_data{
    my ( $self ) = @_;

    my @wells = $self->plate->wells;
    for my $well ( @wells ) {
        my ( $parent_process ) = $well->parent_processes;

        my $design_id = $parent_process->process_design->design_id;
        # prefetch data to speed up query
        my $design = $self->model->schema->resultset('Design')->find(
            {
                id => $design_id,
            },
            {
                prefetch => { 'oligos' => 'loci' },
            }
        );
        $self->set_design_well_bacs( $well, $parent_process) unless $self->is_gibson;

        my $oligo_seqs = $design->oligo_order_seqs;
        for my $oligo_type ( @{ $self->oligo_types } ) {
            push @{ $self->oligo_data->{ $oligo_type } }, {
                well      => $well->name,
                design_id => $design_id,
                seq       => $oligo_seqs->{ $oligo_type },
                phase     => $design->phase,
            };
        }
    }

    return;
}

sub set_design_well_bacs {
    my ( $self, $well, $parent_process ) = @_;

    my @process_bacs = $parent_process->process_bacs( {}, { prefetch => 'bac_clone' } );
    for my $process_bac ( @process_bacs ) {
        my $bac_id = $process_bac->bac_clone->name;
        $self->bac_data->{ $process_bac->bac_plate }{ $well->name } = $bac_id;
    }

    return;
}

sub oligo_seq_data {
    my ( $self ) = @_;

    for my $oligo_type ( @{ $self->oligo_types } ) {
        my $plate_name = 'plate_' . $self->plate->name . '_' . $oligo_type;
        $self->add_report_row( [ 'Temp_' . $plate_name ] );
        $self->oligo_type_seq_data( $oligo_type, $plate_name );
        $self->add_blank_report_row;
    }

    return;
}

sub oligo_type_seq_data {
    my ( $self, $oligo_type, $plate_name ) = @_;

    for my $oligo_data ( @{ $self->oligo_data->{ $oligo_type } } ) {
        $oligo_data->{well} =~ /(?<row>\w)(?<column>\d{2})/;
        my $oligo_name = $oligo_data->{well} . '_' . $oligo_data->{design_id} . '_' . $oligo_type;

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

sub bac_plate_data {
    my ( $self ) = @_;

    foreach my $bac_plate ( "a".."d" ) {
        $self->add_blank_report_row;
        $self->add_report_row( [ $self->plate->name . $bac_plate . '_BAC1' ] );
        $self->add_report_row( [ '', (1..12) ] );

        my $wells = $self->bac_data->{$bac_plate};
        for my $row ("A".."H") {
            my @bac_plate_row = ( $row ) ;
            for my $col (1..12) {
                $col = sprintf("%02d", $col);
                my $well_name = $row . $col;
                push @bac_plate_row, $wells->{$well_name} ? $wells->{$well_name} : '';
            }
            $self->add_report_row( \@bac_plate_row );
        }
    }

    return;
}

sub bac_list {
    my ( $self ) = @_;

    foreach my $bac_plate ( "a".."d" ) {
        my @bac_names = values %{ $self->bac_data->{$bac_plate} };
        my $plate_name = $self->plate->name . $bac_plate . '_BAC2';

        $self->add_blank_report_row;
        $self->add_report_row( [ $plate_name ] );
        for my $bac_name ( @bac_names ) {
            $self->add_report_row( [ $plate_name , $bac_name ]);
        }
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
