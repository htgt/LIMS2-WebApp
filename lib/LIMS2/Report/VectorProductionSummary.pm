package LIMS2::Report::VectorProductionSummary;

use Moose;
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;
use LIMS2::Report::VectorProductionDetail;
use List::MoreUtils qw( any );
use namespace::autoclean;

with qw( LIMS2::Role::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_name {
    my $dt = DateTime->now();
    return 'Vector Production Summary ' . $dt->ymd;
}

sub _build_columns {
    return [
        "Month",
        "First Allele Created", "First Allele Accepted", "First Allele Efficiency",
        "Second Allele (Promoter) Created", "Second Allele (Promoter) Accepted", "Second Allele (Promoter) Efficiency",
        "Second Allele (Promoterless) Created", "Second Allele (Promoterless) Accepted", "Second Allele (Promoterless) Efficiency",
        "Cumulative First Allele Created", "Cumulative First Allele Accepted", "Cumulative First Allele Efficiency",
        "Cumulative Second Allele (Promoter) Created", "Cumulative Second Allele (Promoter) Accepted", "Cumulative Second Allele (Promoter) Efficiency",
        "Cumulative Second Allele (Promoterless) Created", "Cumulative Second Allele (Promoterless) Accepted", "Cumulative Second Allele (Promoterless) Efficiency",
    ];
}

sub iterator {
    my ( $self ) = @_;

    my $date_formatter = DateTime::Format::Strptime->new( pattern => '%b %Y' );

    my $detail = LIMS2::Report::VectorProductionDetail->new( model => $self->model, species => $self->species );
    my @detail_cols = @{ $detail->columns };

    my @vectors;

    my $it = $detail->iterator;

    while ( my $row = $it->next ) {
        my %h;
        @h{@detail_cols}  = @{$row};
        push @vectors, {
            created_month => DateTime::Format::ISO8601->parse_datetime( $h{'Final Vector Created'} )->truncate( to => 'month' ),
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
            $self->counts_and_efficiency( \%this_month ),
            $self->counts_and_efficiency( \%cumulative )
        ];
    }
}

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

    return $data->{Recombinase} =~ m/\bCre\b/;
}

sub count_for {
    my ( $self, $data, $allele_type, $status ) = @_;

    return scalar keys %{ $data->{$allele_type}->{$status} || {} };
}

sub counts_and_efficiency {
    my ( $self, $data ) = @_;

    my @return;

    for my $allele_type ( qw( first_allele second_allele_promoter second_allele_promoterless ) ) {
        my $created    = $self->count_for( $data, $allele_type, 'created' );
        my $accepted   = $self->count_for( $data, $allele_type, 'accepted' );
        my $efficiency = $created > 0 ? int( $accepted * 100 / $created ) . '%' : '-';
        push @return, $created, $accepted, $efficiency;
    }

    return @return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
