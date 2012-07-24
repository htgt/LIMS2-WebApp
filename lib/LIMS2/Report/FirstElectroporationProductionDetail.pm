package LIMS2::Report::FirstElectroporationProductionDetail;

use Moose;
use DateTime;
use List::MoreUtils qw( uniq );
use Iterator::Simple qw( iter imap iflatten );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );
with qw( LIMS2::ReportGenerator::ColonyCounts );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

override _build_name => sub {
    my $dt = DateTime->now();
    return 'First Electroporation Production Detail ' . $dt->ymd;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Gene Id', 'Gene Symbol', 'Design', 'Design Well',
        'EP Well', 'Comments', 'Cassette', 'Recombinases',
        $self->colony_count_column_names,
        '# Picked EPDs', '# Accepted EPDs'
    ];
};

override iterator => sub {
    my $self = shift;

    my $gene_design_rs = $self->model->schema->resultset( 'GeneDesign' )->search_rs(
        {
            'well.id'           => { '!=', undef },
            'design.species_id' => $self->species
        },
        {
            prefetch => [ { 'design' => { 'process_designs' => { 'process' => { 'process_output_wells' => { 'well' => 'plate' } } } } } ]
        }
    );

    return iflatten sub {
        my $gene_design = $gene_design_rs->next
            or return;

        my $gene_id     = $gene_design->gene_id;
        my $gene_symbol = $self->model->retrieve_gene( { search_term => $gene_id, species => $self->species } )->{gene_symbol};
        my $design_id   = $gene_design->design_id;

        my %attrs = (
            gene_id     => $gene_id,
            gene_symbol => $gene_symbol,
            design_id   => $design_id,
            recombinase => []
        );

        my @design_wells = map { $_->output_wells } $gene_design->design->processes;

        return iflatten imap { $self->first_ep_iterator( \%attrs, $_ ) } \@design_wells;
    };
};

sub first_ep_iterator {
    my ( $self, $attrs, $design_well ) = @_;

    $attrs->{design_well} = $design_well;

    my @first_eps = $self->collect_first_eps( $design_well, $design_well->descendants, $attrs );

    return iter sub {
        my $ep = shift @first_eps
            or return;
        return [
            $ep->{gene_id},
            $ep->{gene_symbol},
            $ep->{design_id},
            $ep->{design_well}->as_string,
            $ep->{well}->as_string,
            join( q{; }, map { $_->comment_text } $ep->{well}->well_comments ),
            $ep->{cassette}->name,
            join( q{, }, @{$ep->{recombinase}} ),
            $self->colony_counts( $ep->{well} ),
            $self->ep_pick_counts( $ep->{well}, $design_well->descendants )
        ];
    };
}

sub ep_pick_counts {
    my ( $self, $ep_well, $graph ) = @_;

    my @epds = grep { $_->plate->type_id eq 'EP_PICK' }
        $graph->output_wells( $ep_well );

    my $picked   = scalar @epds;
    my $accepted = scalar grep { $_->is_accepted } @epds;

    return ( $picked, $accepted );
}

sub collect_first_eps {
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

    my @first_eps;

    if ( $current_node->plate->type_id eq 'EP' ) {
        push @first_eps, { %{$attrs}, well => $current_node };
    }

    for my $child_well ( $graph->output_wells( $current_node ) ) {
        my %attrs = ( %{$attrs}, recombinase => [@{$attrs->{recombinase}}] );
        push @first_eps, $self->collect_first_eps( $child_well, $graph, \%attrs );
    }

    return @first_eps;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
