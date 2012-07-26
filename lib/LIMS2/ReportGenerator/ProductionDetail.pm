package LIMS2::ReportGenerator::ProductionDetail;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::ProductionDetail::VERSION = '0.011';
}
## use critic


use Moose;
use Iterator::Simple qw( iflatten imap iter );
use LIMS2::Exception::Implementation;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has plate_type => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1
);

## no critic(RequireFinalReturn)
sub _build_plate_type {
    LIMS2::Exception::Implementation->throw( "_build_plate_type() must be implemeted by a subclass" );
}
## use critic

override iterator => sub {
    my $self = shift;

    my $plate_rs = $self->model->schema->resultset( 'Plate' )->search_rs(
        {
            'me.type_id'    => $self->plate_type,
            'me.species_id' => $self->species
        }
    );

    return iflatten imap { $self->plate_report_iterator( $_ ) } iter $plate_rs;
};

sub plate_report_iterator {
    my ( $self, $plate ) = @_;

    my $report_class = LIMS2::ReportGenerator::Plate->report_class_for( $plate->type_id );

    my $report = $report_class->new( model => $self->model, species => $self->species, plate => $plate );

    return imap { unshift @{$_}, $plate->name; $_ } $report->iterator;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
