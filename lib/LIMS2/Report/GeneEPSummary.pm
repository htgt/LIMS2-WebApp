package LIMS2::Report::GeneEPSummary;

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

    my @output;
    # Loop through genes
    foreach my $project (@projects) {

        my @gene_designs = $self->model->schema->resultset('GeneDesign')->search({
            gene_id => $project->gene_id
        },{
            select => [ 'design_id' ],
        });

        # Loop through designs
        foreach my $gene_design (@gene_designs) {
            my @table_row;

            my $summary_design = $self->design_summary( $gene_design->design_id );

            push @table_row,
                $summary_design->design_gene_symbol,
                $sponsor;
            push @table_row,
                $self->final_dna_wells( $summary_design );

            push @table_row,
                $self->crispr_acc_wells( $gene_design->design_id );

            push @table_row,
                $self->crispr_ep_wells( $summary_design );            
            push @table_row,
                $self->ep_pick_wells( $summary_design );            

            push @output, @table_row;
       } 
    }


#    while ( my ($key, $value) = each %report_data ) {
#
#        push(@output, [
#            $value->{'gene'},
#            $value->{'project'},
#        ] );
#    }
#
    return \@output;

}

sub design_summary {
    my $self = shift;
    my $design_id = shift;

    my $summary_design = $self->model->schema->resultset('Summary')->search({
        'design_id' => $design_id,
    });

    return $summary_design;
}

sub final_dna_wells {
    my $self = shift;
    my $source_rs = shift;

    my $source_conditions = {
        'dna_well_accepted' => 't',
    };

    my $other_conditions = {
        columns => [ qw/dna_plate_name dna_well_name/ ],
        distinct => 1,
        order_by => 'dna_plate_name, dna_well_name',
    };
    my $dna_data = $source_rs->search(
        $source_conditions,
        $other_conditions,
    );
    my $final_dna_wells;
    my @dna_wells;
    while ( my $dna_well = $dna_data->next ) {
        push @dna_wells, ($dna_well->dna_plate_name . '[' . $dna_well->dna_well_name . ']');
    }
    if ( scalar(@dna_wells) > 0 ) {
        $final_dna_wells = join( ',', @dna_wells);
    }
    else {
        $final_dna_wells = 'None';
    }   

    return $final_dna_wells;
}

sub crispr_ep_wells {
    my $self = shift;
    my $source_rs = shift;
    my $search_conditions = shift; # hashref for dbic
    my $other_conditions = shift; # hashref for dbic

    my $crispr_data;

    $search_conditions = {
        -and => [
            'crispr_ep_plate_name' => { '!=', undef },
            'crispr_ep_well_name' => { '!=', undef },
        ],
    };
    
    $other_conditions = {
         columns => [ qw/crispr_ep_plate_name crispr_ep_well_name/ ],
         distinct => 1,
         order_by => 'crispr_ep_plate_name, crispr_ep_well_name',
    };

    if ( $search_conditions && $other_conditions) {
        $crispr_data = $source_rs->search(
            $search_conditions,
            $other_conditions,
        );
    }
    else {
        $crispr_data = $source_rs;
    }
    my $final_crispr_ep_wells;
    my @crispr_ep_wells;
    while ( my $crispr_ep_well = $crispr_data->next ) {
        if ( $crispr_ep_well->crispr_ep_plate_name && $crispr_ep_well->crispr_ep_well_name ) {
            push @crispr_ep_wells, ($crispr_ep_well->crispr_ep_plate_name . '[' . $crispr_ep_well->crispr_ep_well_name . ']');
        }
    }
    if (scalar (@crispr_ep_wells) > 0 ) {
        $final_crispr_ep_wells = join( ',', @crispr_ep_wells);
    }
    else {
        $final_crispr_ep_wells = 'None';
    }

    return $final_crispr_ep_wells;
}

sub ep_pick_wells {
    my $self = shift;
    my $source_rs = shift;

    my $source_conditions = {
        'ep_pick_well_accepted' => 't',
    };
    my $other_conditions = {
        columns => [ qw/ep_pick_plate_name ep_pick_well_name/ ],
        distinct => 1, 
        order_by => 'ep_pick_plate_name, ep_pick_well_name',
    };

    my $ep_pick_data = $source_rs->search(
        $source_conditions,
        $other_conditions,
    );


    my $ep_pick_wells;
    my @ep_wells;
    while ( my $ep_pick_well = $ep_pick_data->next ) {
        push @ep_wells, ($ep_pick_well->ep_pick_plate_name . '[' . $ep_pick_well->ep_pick_well_name . ']');
    }

    if (scalar (@ep_wells) > 0 ) {
        $ep_pick_wells = join( ',', @ep_wells);
    }
    else {
        $ep_pick_wells = 'None';
    }

    return $ep_pick_wells;
}

sub crispr_acc_wells {
    my $self = shift;
    my $design_id = shift;
$DB::single=1;
    my $crispr_design_wells = $self->get_crispr_wells_for_design( $design_id); 

    return;
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
