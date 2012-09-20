package LIMS2::Report::SponsorGenesReport;

use Moose;
use DateTime;
use LIMS2::AlleleRequestFactory;
use JSON qw( decode_json );
use List::Util qw( max );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );
#TODO deal with single targeted

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

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();

    return $self->sponsor . ' Genes Report ' . $dt->ymd;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Gene ID',
        'Marker Symbol',
        '1st Allele DNA Plate',
        'FEP Plate',
        'Parent DNA Plate',
        'Well',
    ];
};

override iterator => sub {
    my ($self) = @_;

    my $gene_report = $self->create_gene_report;
    my @sorted_gene_report
        = sort { scalar( @{ $a->{marker_symbol} } ) <=> scalar( @{ $b->{marker_symbol} } ) }
        @{$gene_report};

    my $result = shift @sorted_gene_report;

    return Iterator::Simple::iter(
        sub {
            return unless $result;
            my @data = ( $result->{gene_id}, $result->{marker_symbol} );

            $result = shift @sorted_electroporate_list;
            return \@data;
        }
    );
};

sub create_gene_report {
    my $self = shift;

    my $arf = LIMS2::AlleleRequestFactory->new( model => $self->model, species => $self->species );
    my $project_rs = $self->model->schema->resultset('Project')->search( { sponsor_id => $self->sponsor } );

    my @gene_list;
    while ( my $project = $project_rs->next ) {
        my $ar = $arf->allele_request( decode_json( $project->allele_request ) );

        my %data;
        $data{gene_id}       = $ar->gene_id;
        $data{marker_symbol} = $self->model->retrieve_gene(
            { species => $self->species, search_term => $ar->gene_id } )->{gene_symbol};

        $data{first_allele_promoter_dna_wells}
            = valid_dna_wells( $ar, { type => 'first_allele_dna_wells', promoter => 1 } );
        $data{first_allele_promoterless_dna_wells}
            = valid_dna_wells( $ar, { type => 'first_allele_dna_wells', promoter => 0 } );
        $data{second_allele_promoter_dna_wells}
            = valid_dna_wells( $ar, { type => 'second_allele_dna_wells', promoter => 1 } );
        $data{second_allele_promoterless_dna_wells}
            = valid_dna_wells( $ar, { type => 'second_allele_dna_wells', promoter => 0 } );

        $data{fep_wells} = electroporation_wells( $ar, 'first_electroporation_wells' );
        $data{sep_wells} = electroporation_wells( $ar, 'second_electroporation_wells' );

        push @gene_list, \%data;
    }

    return \@gene_list;
}

sub valid_dna_wells {
    my ( $ar, $params ) = @_;

    my %dna_wells;
    my $type = $params->{type};
    next unless $ar->can( $type );
    for my $well ( @{ $ar->$type } ) {
        next if exists $dna_wells{ $well->as_string };

        my $dna_status = $well->well_dna_status;
        if ( $dna_status ) {
            next unless $dna_status->pass;
            $dna_wells{ $well->as_string } = $well;
        }

        my $cassette = $well->cassette;

        if ( $params->{promoter} ) {
            $dna_wells{ $well->as_string } = $well
                if $cassette->promoter;
        }
        else {
            $dna_wells{ $well->as_string } = $well
                unless $cassette->promoter;
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
