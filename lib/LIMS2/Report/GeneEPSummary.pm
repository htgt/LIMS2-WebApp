package LIMS2::Report::EPSummary;

use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
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
    return 'Gene Electroporation Summary';
};

override _build_columns => sub {
    return [
        'Gene',
        'Project',
        'Sponsor',
        'Final DNA', # dna_ from summaries
        'Left Crispr DNA',
        'Right Crispr DNA',
        'Assembly Wells', # with vector, left and right crispr DNA wells
        'EP wells', # crispr_ep from summaries with parent assembly well
        'EPD wells', # ep_picks from summaries
    ];
};

sub build_summary_data {
    my $self = shift;
    my $sponsor = shift(@_);
#    my %report_data;

    my @projects = $self->model->schema->resultset('Project')->search({
        sponsor_id     => $sponsor,
    },{
        select => [ 'gene_id' ],
    });

    # Loop through genes
    foreach my $project (@projects) {

        my @gene_designs = $self->model->schema->resultset('GeneDesign')->search({
            gene_id => $project->gene_id
        },{
            select => [ 'design_id' ],
        });

        # Loop through designs
        foreach my $gene_design (@gene_designs) {

            my $summary_dna = $self->model->schema->resultset('Summary')->search({
                design_id => $gene_design->design_id,
            });

            
            my $current_gene_design = ();


            my $gene = $summary->design_gene_symbol;
            $current_gene_design->{'gene'} = $gene;
            $current_gene_design->{'project'} = $sponsor;
    }

    my @output;

    while ( my ($key, $value) = each %report_data ) {

        push(@output, [
            $value->{'gene'},
            $value->{'project'},
        ] );
    }

    return \@output;

}




override iterator => sub {
    my ( $self ) = @_;

    my $summary_data;
    my @sponsors;

    if ( $self->sponsor ne 'All' ) {
        @sponsors = ($self->sponsor);
    }
    else {
        if ($self->species eq 'Mouse') {
                @sponsors = ('Core', 'Syboss', 'Pathogens');
        } else {
                @sponsors = ('Adams', 'Human-Core', 'Mutation', 'Pathogen', 'Skarnes', 'Transfacs');
        }
    }

    foreach my $sponsor (@sponsors) {
    	my $sponsor_data = $self->build_summary_data($sponsor);
    	push ( @{$summary_data},  @{$sponsor_data});
	}

    return Iterator::Simple::iter( $summary_data );
};

__PACKAGE__->meta->make_immutable;

1;

__END__
