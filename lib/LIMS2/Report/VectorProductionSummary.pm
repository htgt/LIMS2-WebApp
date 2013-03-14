package LIMS2::Report::VectorProductionSummary;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::VectorProductionSummary::VERSION = '0.058';
}
## use critic


use Moose;
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;
use LIMS2::Report::VectorProductionDetail;
use List::MoreUtils qw( any );
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

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append = $self->has_sponsor ? ' - Sponsor ' . $self->sponsor . ' ' : '';
    $append .= $dt->ymd;

    return 'Vector Production Summary ' . $append;
};

override _build_columns => sub {
    return [
        "Month",
        "First Allele Created", "First Allele Accepted", "First Allele Efficiency",
        "Cumulative First Allele Created", "Cumulative First Allele Accepted", "Cumulative First Allele Efficiency",
        "Second Allele (Promoter) Created", "Second Allele (Promoter) Accepted", "Second Allele (Promoter) Efficiency",
        "Cumulative Second Allele (Promoter) Created", "Cumulative Second Allele (Promoter) Accepted", "Cumulative Second Allele (Promoter) Efficiency",
        "Second Allele (Promoterless) Created", "Second Allele (Promoterless) Accepted", "Second Allele (Promoterless) Efficiency",
        "Cumulative Second Allele (Promoterless) Created", "Cumulative Second Allele (Promoterless) Accepted", "Cumulative Second Allele (Promoterless) Efficiency",
    ];
};

override iterator => sub {
    my ( $self ) = @_;

    my $date_formatter = DateTime::Format::Strptime->new( pattern => '%b %Y' );

    my $detail;
    if ( $self->has_sponsor ) {
        $detail = LIMS2::Report::VectorProductionDetail->new( model => $self->model, species => $self->species, sponsor => $self->sponsor );
    }
    else{
        $detail = LIMS2::Report::VectorProductionDetail->new( model => $self->model, species => $self->species );
    }

    my @detail_cols = @{ $detail->columns };

    my @vectors;

    my $it = $detail->iterator;

    while ( my $row = $it->next ) {
        my %h;
        @h{@detail_cols}  = @{$row};
        push @vectors, {
            created_month => DateTime::Format::ISO8601->parse_datetime( $h{'Created At'} )->truncate( to => 'month' ),
            gene_id       => $h{'Gene Id'},
            allele_type   => $self->allele_type_for( \%h ),
            accepted      => ( $h{'Accepted?'} eq 'yes' ? 1 : 0 )
        };
    }

    @vectors = sort { $a->{created_month} <=> $b->{created_month} } @vectors;

    my %cumulative;

    return Iterator::Simple::iter sub {
        my $vector = shift @vectors
            or return;
        my $month = $vector->{created_month};
        my %this_month;
        while ( $vector and $vector->{created_month} == $month ) {
            $this_month{ $vector->{allele_type} }{created}{ $vector->{gene_id} }++;
            $cumulative{ $vector->{allele_type} }{created}{ $vector->{gene_id} }++;
            if ( $vector->{accepted} ) {
                $this_month{ $vector->{allele_type} }{accepted}{ $vector->{gene_id} }++;
                $cumulative{ $vector->{allele_type} }{accepted}{ $vector->{gene_id} }++;
            }
            $vector = shift @vectors;
        }
        return [
            $date_formatter->format_datetime( $month ),
            map {
                ( $self->counts_and_efficiency( \%this_month, $_ ), $self->counts_and_efficiency( \%cumulative, $_ ) )
            } qw( first_allele second_allele_promoter second_allele_promoterless )
        ];
    }
};

sub allele_type_for {
    my ( $self, $data ) = @_;

    if ( $self->is_second_allele( $data ) ) {
        if ( $self->is_promoter( $data ) ) {
            return 'second_allele_promoter';
        }
        else {
            return 'second_allele_promoterless';
        }
    }
    else {
        return 'first_allele';
    }
}

sub is_promoter {
    my ( $self, $data ) = @_;

    return $data->{'Cassette Type'} eq 'promoter';
}

sub is_second_allele {
    my ( $self, $data ) = @_;

    return $data->{Recombinases} =~ m/\bCre\b/;
}

sub count_for {
    my ( $self, $data, $allele_type, $status ) = @_;

    return scalar keys %{ $data->{$allele_type}->{$status} || {} };
}

sub counts_and_efficiency {
    my ( $self, $data, $allele_type ) = @_;

    my $created    = $self->count_for( $data, $allele_type, 'created' );
    my $accepted   = $self->count_for( $data, $allele_type, 'accepted' );
    my $efficiency = $created > 0 ? int( $accepted * 100 / $created ) . '%' : '-';

    return( $created, $accepted, $efficiency );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
