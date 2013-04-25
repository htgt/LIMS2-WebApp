package LIMS2::Report::ElectroporationProductionSummary;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::ElectroporationProductionSummary::VERSION = '0.069';
}
## use critic


use Moose;
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;
use LIMS2::Report::FirstElectroporationProductionDetail;
use LIMS2::Report::SecondElectroporationProductionDetail;
use Iterator::Simple qw( iter );
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

    return 'Electroporation Production Summary ' . $append;
};

override _build_columns => sub {
    return [
        "Month",
        "First Allele Electroporated",
        "First Allele Picked",
        "First Allele Accepted",
        "Cumulative First Allele Electroporated",
        "Cumulative First Allele Picked",
        "Cumulative First Allele Accepted",
        "Second Allele (Promoter) Electroporated",
        "Second Allele (Promoter) Picked",
        "Second Allele (Promoter) Accepted",
        "Cumulative Second Allele (Promoter) Electroporated",
        "Cumulative Second Allele (Promoter) Picked",
        "Cumulative Second Allele (Promoter) Accepted",
        "Second Allele (Promoterless) Electroporated",
        "Second Allele (Promoterless) Picked",
        "Second Allele (Promoterless) Accepted",
        "Cumulative Second Allele (Promoterless) Electroporated",
        "Cumulative Second Allele (Promoterless) Picked",
        "Cumulative Second Allele (Promoterless) Accepted",
    ];
};

override iterator => sub {
    my ( $self ) = @_;

    my $date_formatter = DateTime::Format::Strptime->new( pattern => '%b %Y' );

    my %by_month;

    $self->summarize_first_ep( \%by_month );
    $self->summarize_second_ep( \%by_month );

    my @months = sort { $by_month{$a}{dt} <=> $by_month{$b}{dt} } keys %by_month;

    my %cumulative;

    return iter sub {
        my $month = shift @months
            or return;
        for my $k ( qw( first_ep_created first_ep_picked first_ep_accepted
                        second_ep_promoter_created second_ep_promoter_picked second_ep_promoter_accepted
                        second_ep_promoterless_created second_ep_promoterless_picked second_ep_promoterless_accepted
                  ) ) {
            for my $gene ( keys %{ $by_month{$month}{$k} } ) {
                $cumulative{$k}{$gene}++;
            }
        }
        return [
            $date_formatter->format_datetime( $by_month{$month}{dt} ),
            map { scalar keys %{$_} } (
                @{$by_month{$month}}{ qw( first_ep_created first_ep_picked first_ep_accepted ) },
                @cumulative{ qw( first_ep_created first_ep_picked first_ep_accepted ) },
                @{$by_month{$month}}{ qw( second_ep_promoter_created second_ep_promoter_picked second_ep_promoter_accepted ) },
                @cumulative{ qw( second_ep_promoter_created second_ep_promoter_picked second_ep_promoter_accepted ) },
                @{$by_month{$month}}{ qw( second_ep_promoterless_created second_ep_promoterless_picked second_ep_promoterless_accepted ) },
                @cumulative{ qw( second_ep_promoterless_created second_ep_promoterless_picked second_ep_promoterless_accepted ) }
            )
        ]
    };
};

sub summarize_first_ep {
    my ( $self, $by_month ) = @_;

    my $detail;
    if ( $self->has_sponsor ){
        $detail = LIMS2::Report::FirstElectroporationProductionDetail->new(
            model => $self->model, species => $self->species, sponsor => $self->sponsor
        );
    }
    else{
        $detail = LIMS2::Report::FirstElectroporationProductionDetail->new(
            model => $self->model, species => $self->species
        );
    }
    my @detail_cols = @{ $detail->columns };

    my $it = $detail->iterator;

    while ( my $row = $it->next ) {
        my %h;
        @h{@detail_cols}  = @{$row};
        my $created_month = DateTime::Format::ISO8601->parse_datetime( $h{'Created At'} )->truncate( to => 'month' );
        my $gene_id       = $h{'Gene Id'};
        $by_month->{$created_month}{dt} ||= $created_month;
        $by_month->{$created_month}{first_ep_created}{$gene_id}++;
        if ( $h{'Number Picked'} ) {
            $by_month->{$created_month}{first_ep_picked}{$gene_id}++;
        }
        if ( $h{'Number Accepted'} ) {
            $by_month->{$created_month}{first_ep_accepted}{$gene_id}++;
        }
    }

    return;
}

sub summarize_second_ep {
    my ( $self, $by_month ) = @_;

    my $detail;
    if ( $self->has_sponsor ) {
        $detail = LIMS2::Report::SecondElectroporationProductionDetail->new(
            model => $self->model, species => $self->species, sponsor => $self->sponsor
        );
    }
    else {
        $detail = LIMS2::Report::SecondElectroporationProductionDetail->new(
            model => $self->model, species => $self->species
        );
    }
    my @detail_cols = @{ $detail->columns };

    my $it = $detail->iterator;

    while ( my $row = $it->next ) {
        my %h;
        @h{@detail_cols}  = @{$row};
        my $created_month = DateTime::Format::ISO8601->parse_datetime( $h{'Created At'} )->truncate( to => 'month' );
        my $gene_id       = $h{'Second Allele Gene Id'};
        $by_month->{$created_month}{dt} ||= $created_month;
        my $type = 'second_ep_' .  $h{'Second Allele Cassette Type'};
        $by_month->{$created_month}{ $type . '_created' }{$gene_id}++;
        if ( $h{'Number Picked'} ) {
            $by_month->{$created_month}{ $type . '_picked' }{$gene_id}++;
        }
        if ( $h{'Number Accepted'} ) {
            $by_month->{$created_month}{ $type . '_accepted' }{$gene_id}++;
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
