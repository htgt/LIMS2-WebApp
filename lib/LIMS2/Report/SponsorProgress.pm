package LIMS2::Report::SponsorProgress;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::SponsorProgress::VERSION = '0.043';
}
## use critic


use Moose;
use DateTime;
use LIMS2::AlleleRequestFactory;
use JSON qw( decode_json );
use Readonly;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

Readonly my %REPORT_CATAGORIES => (
    genes => {
        name       => 'Targetted Genes',
        order      => 1,
        validation => \&has_genes,
    },
    vectors =>{
        name      => 'Vectors',
        order     => 2,
        well_type => 'allele_vector_wells'
    },
    first_vectors => {
        name      => '1st Allele Vectors',
        order     => 3,
        well_type => 'first_allele_vector_wells',
    },
    second_vectors => {
        name      => '2nd Allele Vectors',
        order     => 4,
        well_type => 'second_allele_vector_wells',
    },
    dna => {
        name       => 'Valid DNA',
        order      => 5,
        well_type  => 'allele_dna_wells',
        validation => \&has_valid_dna_wells,
    },
    first_dna => {
        name       => '1st Allele Valid DNA',
        order      => 6,
        well_type  => 'first_allele_dna_wells',
        validation => \&has_valid_dna_wells,
    },
    second_dna => {
        name       => '2nd Allele Valid DNA',
        order      => 7,
        well_type  => 'second_allele_dna_wells',
        validation => \&has_valid_dna_wells,
    },
    ep => {
        name      => 'Electroporations',
        order     => 8,
        well_type => 'allele_electroporation_wells',
    },
    first_ep => {
        name      => '1st Allele Electroporations',
        order     => 9,
        well_type => 'first_electroporation_wells',
    },
    second_ep => {
        name      => '2nd Allele Electroporations',
        order     => 10,
        well_type => 'second_electroporation_wells',
    },
    clones => {
        name       => 'Clones',
        order      => 11,
        well_type  => 'allele_pick_wells',
        validation => \&has_accepted_pick_wells,
    },
    first_clones   => {
        name       => '1st Allele Accepted Clones',
        order      => 12,
        well_type  => 'first_allele_pick_wells',
        validation => \&has_accepted_pick_wells,
    },
    second_clones => {
        name       => '2nd Allele Accepted Clones',
        order      => 13,
        well_type  => 'second_allele_pick_wells',
        validation => \&has_accepted_pick_wells,
    },
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has '+param_names' => (
    default => sub { [ 'species' ] }
);

has sponsors => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_sponsors {
    my $self = shift;

    my @sponsors = $self->model->schema->resultset('Sponsor')->search(
        { }, { order_by => { -asc => 'description' } }
    );

    return [ map{ $_->id } @sponsors ];
}

has sponsor_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_sponsor_data {
    my $self = shift;
    my %sponsor_data;

    my $arf = LIMS2::AlleleRequestFactory->new( model => $self->model, species => $self->species );

    my $project_rs = $self->model->schema->resultset('Project')->search( {} );

    while ( my $project = $project_rs->next ) {
        $self->_find_project_wells( $project, $arf, \%sponsor_data );
    }

    return \%sponsor_data;
}

sub _find_project_wells {
    my ( $self, $project, $arf, $sponsor_data ) = @_;

    my $sponsor = $project->sponsor_id;
    my $ar = $arf->allele_request( decode_json( $project->allele_request ) );

    while ( my( $name, $catagory ) = each %REPORT_CATAGORIES ) {
        my $well_type = $catagory->{well_type} || '';

        if ( exists $catagory->{validation} ) {
            $sponsor_data->{$name}{$sponsor}++
                if $catagory->{validation}->( $ar, $well_type );
        }
        else {
            $sponsor_data->{$name}{$sponsor}++
                if has_wells_of_type( $ar, $well_type );
        }
    }

    return;
}

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();

    return 'Sponsor Progress Report ' . $dt->ymd;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Stage',
        @{ $self->sponsors }
    ];
};

override iterator => sub {
    my ($self) = @_;

    my @sponsor_data;

    for my $catagory ( sort { $REPORT_CATAGORIES{$a}->{order} <=> $REPORT_CATAGORIES{$b}->{order} }
        keys %REPORT_CATAGORIES )
    {
        my $data = $self->sponsor_data->{$catagory};
        $data->{catagory} = $catagory;
        push @sponsor_data, $data;
    }

    my $result = shift @sponsor_data;

    return Iterator::Simple::iter(
        sub {
            return unless $result;
            my @data = map{ $result->{$_} } @{ $self->sponsors };
            unshift @data, $REPORT_CATAGORIES{ $result->{catagory} }{name};

            $result = shift @sponsor_data;
            return \@data;
        }
    );
};

sub has_genes {
    my ( $ar ) = @_;
    return $ar->gene_id ? 1 : 0;
}

sub has_wells_of_type {
    my ( $ar, $type ) = @_;

    return 0 unless $ar->can( $type );

    return @{ $ar->$type } ? 1 : 0;
}

sub has_valid_dna_wells{
    my ( $ar, $type ) = @_;

    return 0 unless $ar->can( $type );

    for my $well ( @{ $ar->$type } ) {
        return 1 if $well->well_dna_status;
    }

    return 0;
}

sub has_accepted_pick_wells {
    my( $ar, $type ) = @_;

    return 0 unless $ar->can( $type );

    for my $well ( @{ $ar->$type } ) {
        return 1 if $well->is_accepted;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
