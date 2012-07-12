package LIMS2::Report::VectorProductionDetail;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::VectorProductionDetail::VERSION = '0.004';
}
## use critic


use Moose;
use DateTime;
use List::MoreUtils qw( uniq );
use Iterator::Simple qw( iter imap iflatten );
use namespace::autoclean;

with qw( LIMS2::Role::ReportGenerator );

sub _build_name {
    my $dt = DateTime->now();
    return 'Vector Production Detail ' . $dt->ymd;
}

sub _build_columns {
    return [
        "MGI Accession Id", "Marker Symbol", "Design", "Design Well",
        "Final Vector Well", "Final Vector Created", "Cassette", "Backbone", "Recombinase", "Cassette Type", "Accepted?"
    ];
}

sub iterator {
    my ( $self ) = @_;

    my $gene_design_rs = $self->model->schema->resultset( 'GeneDesign' )->search_rs(
        { 'well.id' => { '!=', undef } },
        {
            prefetch => [ { 'design' => { 'process_designs' => { 'process' => { 'process_output_wells' => { 'well' => 'plate' } } } } } ]
        }
    );

    return iflatten sub {
        my $gene_design = $gene_design_rs->next
            or return;

        my $gene_id       = $gene_design->gene_id;
        my $marker_symbol = $self->model->retrieve_gene( { gene => $gene_id } )->{marker_symbol};
        my $design_id     = $gene_design->design_id;

        my %attrs = (
            gene_id       => $gene_design->gene_id,
            marker_symbol => $marker_symbol,
            design_id     => $design_id,
            recombinase   => []
        );

        my @design_wells = map { $_->output_wells } $gene_design->design->processes;

        return iflatten imap { $self->final_vectors_iterator( \%attrs, $_ ) } \@design_wells;
    }
}

sub final_vectors_iterator {
    my ( $self, $attrs, $design_well ) = @_;

    $attrs->{design_well} = $design_well;

    my @final_vectors = $self->collect_final_vectors( $design_well, $design_well->descendants, $attrs );

    return iter sub {
        my $vector = shift @final_vectors
            or return;
        return [
            $vector->{gene_id},
            $vector->{marker_symbol},
            $vector->{design_id},
            $vector->{design_well}->as_string,
            $vector->{well}->as_string,
            $vector->{well}->created_at->ymd,
            $vector->{cassette}->name,
            $vector->{backbone}->name,
            join( q{,}, @{$vector->{recombinase}} ),
            ( $vector->{cassette}->promoter ? 'promoter' : 'promoterless' ),
            ( $vector->{well}->is_accepted ? 'yes' : 'no' )
        ];
    }
}

sub collect_final_vectors {
    my ( $self, $current_node, $graph, $attrs ) = @_;

    for my $process ( $graph->input_processes( $current_node ) ) {
        if ( my $backbone = $process->process_backbone ) {
            $attrs->{backbone} = $backbone->backbone;
        }
        if ( my $cassette = $process->process_cassette ) {
            $attrs->{cassette} = $cassette->cassette;
        }
        if ( my @recombinase = $process->process_recombinases ) {
            push @{ $attrs->{recombinase} }, map { $_->recombinase_id } sort { $a->rank <=> $b->rank } @recombinase;
        }
    }

    my @final_vectors;

    if ( $current_node->plate->type_id eq 'FINAL' ) {
        push @final_vectors, { %{$attrs}, well => $current_node };
    }

    for my $child_well ( $graph->output_wells( $current_node ) ) {
        my %attrs = ( %{$attrs}, recombinase => [@{$attrs->{recombinase}}] );
        push @final_vectors, $self->collect_final_vectors( $child_well, $graph, \%attrs );
    }

    return @final_vectors;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
