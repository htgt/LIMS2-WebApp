package LIMS2::ReportGenerator::ProductionDetail;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::ProductionDetail::VERSION = '0.145';
}
## use critic


use Moose;
use Iterator::Simple qw( iflatten imap iter igrep );
use LIMS2::Exception::Implementation;
use LIMS2::AlleleRequestFactory;
use LIMS2::ReportGenerator::Plate;
use JSON qw( decode_json );
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

has sponsor => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_sponsor'
);

has sponsor_wells => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1
);

has allele_request_wells_method => (
    is  => 'ro',
    isa => 'Str'
);

has '+param_names' => (
    default => sub { [ 'species', 'plate_type', 'sponsor' ] }
);

## no critic(RequireFinalReturn)
sub _build_plate_type {
    LIMS2::Exception::Implementation->throw( "_build_plate_type() must be implemeted by a subclass" );
}
## use critic

sub _build_sponsor_wells {
    my $self = shift;

    my %sponsor_wells;

    my $method = $self->allele_request_wells_method
        or LIMS2::Exception::Implementation->throw( "allele_request_wells_method must be specified by a subclass" );

    my $arf = LIMS2::AlleleRequestFactory->new( model => $self->model, species => $self->species );
    my $project_rs = $self->model->schema->resultset('Project')->search( { sponsor_id => $self->sponsor } );
    while ( my $project = $project_rs->next ) {
        my $ar = $arf->allele_request( decode_json( $project->allele_request ) );
        next unless $ar->can( $method );
        for my $well ( @{$ar->$method} ) {
            $sponsor_wells{ $well->plate->name }{ $well->name }++;
        }
    }

    return \%sponsor_wells;
}

sub is_wanted_plate {
    my ( $self, $plate_name ) = @_;

    return 1 unless $self->has_sponsor;

    return exists $self->sponsor_wells->{$plate_name};
}

sub is_wanted_well {
    my ( $self, $plate_name, $well_name ) = @_;

    return 1 unless $self->has_sponsor;

    return exists $self->sponsor_wells->{$plate_name}{$well_name};
}

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

    return iter [] unless $self->is_wanted_plate( $plate->name );

    my $report_class = LIMS2::ReportGenerator::Plate->report_class_for( $plate->type_id );

    my $report = $report_class->new( model => $self->model, species => $self->species, plate => $plate );

    return igrep { $self->is_wanted_well( @{$_}[0,1] ) } imap { unshift @{$_}, $plate->name; $_ } $report->iterator;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
