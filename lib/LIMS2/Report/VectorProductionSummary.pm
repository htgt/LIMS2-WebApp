package LIMS2::Report::VectorProductionSummary;

use Moose;
use DateTime;
use DateTime::Format::Strptime;
use List::MoreUtils qw( any );
use namespace::autoclean;

with qw( LIMS2::Role::ReportGenerator );

sub _build_name {
    my $dt = DateTime->now();
    return 'Vector Production Summary ' . $dt->ymd;
}

sub _build_columns {
    return [
        "Month",
        "First Allele Created", "First Allele Accepted", "First Allele Efficiency",
        "Second Allele Created", "Second Allele Accepted", "Second Allele Efficiency",
        "First Allele Created (Cumulative)", "First Allele Accepted (Cumulative)", "First Allele Efficiency (Cumulative)",
        "Second Allele Created (Cumulative)", "Second Allele Accepted (Cumulative)", "Second Allele Efficiency (Cumulative)"
    ];
}

sub iterator {
    my ( $self ) = @_;

    my $date_formatter = DateTime::Format::Strptime->new( pattern => '%b %Y' );

    my $final_vectors_rs = $self->model->schema->resultset( 'Well' )->search(
        {
            'plate.type_id' => 'FINAL'
        },
        {
            join     => 'plate',
            prefetch => 'well_accepted_override',
            order_by => { -asc => 'me.created_at' }
        }
    );

    my $well = $final_vectors_rs->next;

    my %cumulative;

    return Iterator::Simple::iter(
        sub {
            return unless $well;
            my %this_month;
            my $created_at = $well->created_at;
            while ( $well and $self->is_same_month( $well->created_at, $created_at ) ) {
                my $allele_type = $self->is_second_allele( $well ) ? 'second_allele' : 'first_allele';
                for my $gene ( map { $_->gene_id } $well->design->genes ) {
                    $this_month{$allele_type}{created}{$gene}++;
                    $cumulative{$allele_type}{created}{$gene}++;
                    if ( $well->is_accepted ) {
                        $this_month{$allele_type}{accepted}{$gene}++;
                        $cumulative{$allele_type}{accepted}{$gene}++;
                    }
                }
                $well = $final_vectors_rs->next;
            }
            return [ $date_formatter->format_datetime( $created_at ),
                     $self->counts_and_efficiency( \%this_month ),
                     $self->counts_and_efficiency( \%cumulative )
                 ];
        }
    );
}

sub is_second_allele {
    my ( $self, $well ) = @_;

    any { $_ eq 'Cre' } @{ $well->recombinases };
}

sub is_same_month {
    my ( $self, $dt1, $dt2 ) = @_;

    return $dt1->month == $dt2->month && $dt1->year == $dt2->year;
}

sub count_for {
    my ( $self, $data, $allele_type, $status ) = @_;

    scalar keys %{ $data->{$allele_type}->{$status} || {} };
}

sub counts_and_efficiency {
    my ( $self, $data ) = @_;

    my @return;

    for my $allele_type ( qw( first_allele second_allele ) ) {
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
