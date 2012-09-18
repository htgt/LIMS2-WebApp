package LIMS2::Report::GenesToElectroporate;

use Moose;
use DateTime;
#use LIMS2::Model::Util::GeneElectroporation qw( gene_electroporate_list );
use LIMS2::AlleleRequestFactory;
use JSON qw( decode_json );
use List::Util qw( max );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has sponsor => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_sponsor'
);

has '+param_names' => (
    default => sub { [ 'species', 'sponsor' ] }
);

has gene_electroporate_list => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_gene_electroporate_list {
    my ( $self ) = @_;

    my $arf = LIMS2::AlleleRequestFactory->new( model => $self->model, species => $self->species );
    my $project_rs = $self->model->schema->resultset('Project')->search( { sponsor_id => $self->sponsor } );

    my @electroporate_list;
    while ( my $project = $project_rs->next ) {
        my $ar = $arf->allele_request( decode_json( $project->allele_request ) );

        my %data;
        $data{gene_id}       = $ar->gene_id;
        $data{marker_symbol} = $self->model->retrieve_gene(
            { species => $self->species, search_term => $ar->gene_id } )->{gene_symbol};
        $data{valid_dna_wells} = valid_dna_wells($ar);
        $data{fep_wells}       = electroporation_wells( $ar, 'first_electroporation_wells' );
        $data{sep_wells}       = electroporation_wells( $ar, 'second_electroporation_wells' );
        push @electroporate_list, \%data;
        last;
    }

    return \@electroporate_list;
}

has [ qw(  max_num_dna_wells max_num_fep_wells max_num_sep_wells ) ] => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_max_num_dna_wells {
    my $self = shift;

    my @well_counts = map{ scalar( @{ $_->{valid_dna_wells} } ) } @{ $self->gene_electroporate_list };

    return max @well_counts;
}

sub _build_max_num_fep_wells {
    my $self = shift;

    my @well_counts = map{ scalar( @{ $_->{fep_wells} } ) } @{ $self->gene_electroporate_list };

    return max @well_counts;
}

sub _build_max_num_sep_wells {
    my $self = shift;

    my @well_counts = map{ scalar( @{ $_->{sep_wells} } ) } @{ $self->gene_electroporate_list };

    return max @well_counts;
}

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();

    return 'Genes To Electroporate ' . $dt->ymd;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Gene ID', 'Marker Symbol',
        ( 'Valid DNA Wells' ) x $self->max_num_dna_wells,
        ( 'FEP Wells' ) x $self->max_num_fep_wells,
        ( 'SEP Wells' ) x $self->max_num_sep_wells,
    ];
};

override iterator => sub {
    my ($self) = @_;

    my $electroporate_list = $self->gene_electroporate_list;

    my $result = shift @{ $electroporate_list };

    return Iterator::Simple::iter(
        sub {
            return unless $result;
            my @data = ( $result->{gene_id}, $result->{marker_symbol} );

            _print_wells( \@data, $result->{valid_dna_wells}, $self->max_num_dna_wells );
            _print_wells( \@data, $result->{fep_wells}, $self->max_num_fep_wells );
            _print_wells( \@data, $result->{sep_wells}, $self->max_num_sep_wells );

            $result = shift @{ $electroporate_list };
            return \@data;
        }
    );
};

sub _print_wells{
    my ( $data, $wells, $max_num ) = @_;

    for my $num ( 0..( $max_num - 1) ) {
        my $well = $wells->[$num];
        if ( $well ) {
            push @{ $data }, $well->plate->type_id . ' : ' . $well->as_string;
        }
        else {
            push @{ $data }, '';

        }
    }

    return;
}

sub valid_dna_wells {
    my ( $ar ) = @_;

    my %dna_wells;
    next unless $ar->can( 'all_dna_wells' );
    for my $well ( @{ $ar->all_dna_wells } ) {
        next if exists $dna_wells{ $well->as_string };

        my $dna_status = $well->well_dna_status;
        if ( $dna_status ) {
            next unless $dna_status->pass;
            $dna_wells{ $well->as_string } = $well;
        }
    }

    return [ values %dna_wells ];
}

sub electroporation_wells {
    my ( $ar, $type ) = @_;

    my %wells;
    next unless $ar->can( $type );
    for my $well ( @{ $ar->$type } ) {
        next if exists $wells{ $well->as_string };

        $wells{ $well->as_string } = $well;
    }

    return [ values %wells ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__
