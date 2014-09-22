package LIMS2::Report::EPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::EPPlate::VERSION = '0.245';
}
## use critic


use Moose;
use List::MoreUtils qw( apply );
use namespace::autoclean;
use Log::Log4perl qw( :easy );

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );
with qw( LIMS2::ReportGenerator::ColonyCounts );

# XXX If it turns out EP and XEP plates don't have the same data
# stored against them (that is, colony counts) then XEP should be
# removed from here and a new report implemented. OK, so I lied. We
# include (or not) XEP counts depending on the plate type.

#TODO delete xep stuff from here as we now have a separate report for XEP plates.
#
override plate_types => sub {
    return [ 'EP' ];
};

has wants_xep_count => (
    is         => 'ro',
    isa        => 'Bool',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_wants_xep_count {
    return shift->plate->type_id ne 'XEP';
}

override _build_name => sub {
    my $self = shift;

    return 'Electroporation Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    my @columns = (
        $self->base_columns,
        "DNA Well",
        "Cassette", "Cassette Resistance", "Recombinases", "Cell Line",
        $self->colony_count_column_names,
        "Number Picked", "Number Accepted"
    );

    if ( $self->wants_xep_count ) {
        push @columns, "Number XEPs";
    }

    return \@columns;
};

override iterator => sub {
    my $self = shift;

    my $wells_rs = $self->plate->search_related(
        wells => {},
        {
            prefetch => [
                'well_accepted_override', 'well_colony_counts'
            ],
            order_by => { -asc => 'me.name' }
        }
    );

    return Iterator::Simple::iter sub {
        my $well = $wells_rs->next
            or return;

        my $process_cell_line = $well->ancestors->find_process( $well, 'process_cell_line' );
        my $cell_line = $process_cell_line ? $process_cell_line->cell_line->name : '';
        my $dna_well = $well->first_dna;

        DEBUG "Found cell_line $cell_line";

        my $cassette = $well->cassette ? $well->cassette->name : '';

        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $self->base_data( $well ),
            $dna_well->as_string,
            $cassette,
            $well->cassette->resistance,
            join( q{/}, @{ $well->recombinases } ),
            $cell_line,
            $self->colony_counts( $well ),
            $self->pick_counts( $well, 'EP_PICK' ),
            ( $self->wants_xep_count ? $self->xep_count( $well ) : () )
        ];
    };
};

sub xep_count {
    my ( $self, $well ) = @_;

    # XXX This assumes the XEPs are direct descendants of $well: we
    # aren't doing a full traversal.
    my @xeps = grep { $_->plate->type_id eq 'XEP' } $well->descendants->output_wells( $well );

    return scalar @xeps;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
